"""
Shared scanning helpers for reading the Bridge RC2.1 prototype.

The prototype is one HTML file with an embedded script. We never parse it as
JavaScript: we scan it with small, explicit readers that understand string
literals well enough not to be fooled by braces, quotes and comments inside
them. Every reader is deliberately dumb and deliberately loud — it raises
rather than guessing, because a silent miss here becomes a missing screen or
an untranslated string three phases downstream.
"""

import re

SOURCE = "source/Bridge_RC2_1.html"


def read_source(path=SOURCE):
    with open(path, encoding="utf-8") as fh:
        return fh.read()


def script_region(src):
    """Offsets of the embedded script body, exclusive of the tags.

    Everything outside it is markup and prose. Scanning the whole file instead
    is how an apostrophe in "Claude's own runtime" — inside the HTML header
    comment, which is not a JavaScript comment — opens a string literal that
    swallows half the file."""
    open_tag = src.index("<script>") + len("<script>")
    close_tag = src.rindex("</script>")
    return open_tag, close_tag


def strip_comments(src):
    """Blank out comments, preserving offsets and newlines.

    HTML comments are blanked everywhere; JavaScript lexing — strings, regular
    expressions, // and /* */ — is applied only inside the script region. The
    surrounding markup is copied verbatim, because a `/` in `<meta />` is not a
    regular expression and an apostrophe in prose is not a string.
    """
    code_from, code_to = script_region(src)
    out, i, n = [], 0, len(src)
    while i < n:
        c = src[i]
        if c == "<" and src.startswith("<!--", i):
            j = src.find("-->", i + 4)
            j = n if j < 0 else j + 3
            out.append(_blank(src[i:j]))
            i = j
            continue
        if not (code_from <= i < code_to):
            out.append(c)
            i += 1
            continue
        if c in "\"'`":
            j = read_string_end(src, i)
            out.append(src[i:j])
            i = j
        elif c == "/" and i + 1 < n and src[i + 1] == "/":
            j = src.find("\n", i)
            j = n if j < 0 else j
            out.append(" " * (j - i))
            i = j
        elif c == "/" and i + 1 < n and src[i + 1] == "*":
            j = src.find("*/", i + 2)
            j = n if j < 0 else j + 2
            out.append(_blank(src[i:j]))
            i = j
        elif c == "/" and starts_regex(src, i):
            j = read_regex_end(src, i)
            out.append(src[i:j])
            i = j
        else:
            out.append(c)
            i += 1
    return "".join(out)


def _blank(text):
    """Replace a span with spaces, keeping newlines so line numbers survive."""
    return "".join(ch if ch == "\n" else " " for ch in text)


def read_string_end(js, start):
    """Given the index of an opening quote, return the index just past its close.

    Template literals need real handling rather than a search for the next
    backtick: nearly every screen in the prototype returns markup built from
    nested `${...}` interpolations, and those interpolations contain their own
    template literals. Stopping at the first inner backtick desynchronises the
    scan and silently mis-reads the rest of the file."""
    quote = js[start]
    i = start + 1
    while i < len(js):
        c = js[i]
        if c == "\\":
            i += 2
            continue
        if c == quote:
            return i + 1
        if quote == "`" and c == "$" and i + 1 < len(js) and js[i + 1] == "{":
            i = read_interpolation_end(js, i + 1)
            continue
        i += 1
    raise ValueError(f"unterminated string literal at offset {start}")


# A `/` begins a regular expression unless the previous significant token could
# end an expression. Without this, `s.replace(/[&<>"\']/g, ...)` reads as code
# plus a string opener, and the scan desynchronises for the rest of the file.
_REGEX_CANNOT_FOLLOW = re.compile(r"[)\]}A-Za-z0-9_$]\Z")
_KEYWORDS_BEFORE_REGEX = ("return", "typeof", "instanceof", "in", "of", "new",
                          "delete", "void", "throw", "case", "do", "else", "yield")


def starts_regex(js, slash):
    """Would the `/` at `slash` begin a regular expression rather than a division?"""
    k = slash - 1
    while k >= 0 and js[k] in " \t\r\n":
        k -= 1
    if k < 0:
        return True
    head = js[: k + 1]
    if not _REGEX_CANNOT_FOLLOW.search(head):
        return True
    word = re.search(r"[A-Za-z_$][A-Za-z0-9_$]*\Z", head)
    return bool(word and word.group(0) in _KEYWORDS_BEFORE_REGEX)


def read_regex_end(js, start):
    """Given the index of a `/` that opens a regex, return the index past its close."""
    i, in_class = start + 1, False
    while i < len(js):
        c = js[i]
        if c == "\\":
            i += 2
            continue
        if c == "[":
            in_class = True
        elif c == "]":
            in_class = False
        elif c == "/" and not in_class:
            i += 1
            while i < len(js) and js[i] in "dgimsuvy":
                i += 1
            return i
        elif c == "\n":
            break
        i += 1
    raise ValueError(f"unterminated regular expression at offset {start}")


def read_interpolation_end(js, brace):
    """Given the index of the `{` of a `${...}`, return the index just past its `}`."""
    depth, i = 0, brace
    while i < len(js):
        c = js[i]
        if c in "\"'`":
            i = read_string_end(js, i)
            continue
        if c == "/" and starts_regex(js, i):
            i = read_regex_end(js, i)
            continue
        if c == "{":
            depth += 1
        elif c == "}":
            depth -= 1
            if depth == 0:
                return i + 1
        i += 1
    raise ValueError(f"unterminated interpolation at offset {brace}")


def read_js_string(js, start):
    """Read a quoted literal at `start`; return (value, index past the close)."""
    end = read_string_end(js, start)
    return unescape(js[start + 1 : end - 1]), end


_ESCAPES = {"n": "\n", "t": "\t", "r": "\r", "b": "\b", "f": "\f", "0": "\0",
            "\\": "\\", "'": "'", '"': '"', "`": "`", "\n": ""}


def unescape(raw):
    out, i = [], 0
    while i < len(raw):
        c = raw[i]
        if c != "\\":
            out.append(c)
            i += 1
            continue
        nxt = raw[i + 1] if i + 1 < len(raw) else ""
        if nxt == "u":
            if i + 2 < len(raw) and raw[i + 2] == "{":
                close = raw.index("}", i + 3)
                out.append(chr(int(raw[i + 3 : close], 16)))
                i = close + 1
            else:
                out.append(chr(int(raw[i + 2 : i + 6], 16)))
                i += 6
        elif nxt == "x":
            out.append(chr(int(raw[i + 2 : i + 4], 16)))
            i += 4
        else:
            out.append(_ESCAPES.get(nxt, nxt))
            i += 2
    return "".join(out)


def find_block(js, opener, open_ch="{", close_ch="}"):
    """Find `opener`, then return the text of the balanced block that follows it.

    Brace counting skips string literals, so a `}` inside markup cannot end the
    block early — which matters here, because nearly every screen returns HTML
    containing braces."""
    at = js.find(opener)
    if at < 0:
        raise ValueError(f"could not find {opener!r} in the source")
    start = js.index(open_ch, at)
    depth, i = 0, start
    while i < len(js):
        c = js[i]
        if c in "\"'`":
            i = read_string_end(js, i)
            continue
        if c == "/" and starts_regex(js, i):
            i = read_regex_end(js, i)
            continue
        if c == open_ch:
            depth += 1
        elif c == close_ch:
            depth -= 1
            if depth == 0:
                return js[start : i + 1]
        i += 1
    raise ValueError(f"unbalanced block after {opener!r}")


def swift_string(s):
    """Quote a Swift string literal."""
    body = (s.replace("\\", "\\\\").replace('"', '\\"')
             .replace("\n", "\\n").replace("\t", "\\t").replace("\r", "\\r"))
    return f'"{body}"'


HEADER = """\
// Generated by {tool} from {src}
// Bridge RC2.1 · do not edit by hand; re-run `tools/extract_all.sh` instead.
// The prototype is the canon. This file is its shadow.
"""


def banner(tool, src=SOURCE):
    return HEADER.format(tool=tool, src=src)
