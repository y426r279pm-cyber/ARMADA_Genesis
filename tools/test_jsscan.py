#!/usr/bin/env python3
"""
Regression tests for the scanner.

Three bugs were found here while extracting RC2.1, each of which silently
mis-read the file rather than failing. They are the first three tests.
"""

import os, sys
sys.path.insert(0, os.path.dirname(__file__))
from lib.jsscan import (strip_comments, find_block, read_string_end, read_js_string,
                        starts_regex, read_regex_end, script_region, unescape)

FAILURES = []


def check(name, got, want):
    if got != want:
        FAILURES.append(f"{name}\n     got  {got!r}\n     want {want!r}")


def wrap(js):
    """Minimal host document, since the scanner lexes only inside the script."""
    return "<!doctype html><html><body>\n<script>\n" + js + "\n</script>\n</body></html>\n"


# 1. A regex literal containing quote characters must not open a string.
#    `const esc = (s) => s.replace(/[&<>"']/g, ...)` desynchronised the whole file.
src = wrap('const esc = (s) => s.replace(/[&<>"\']/g, c => c);\nconst A = { x: 1 };')
check("regex with quotes", len(find_block(strip_comments(src), "const A")), len("{ x: 1 }"))

# 2. A template literal with ${...} containing nested template literals.
src = wrap("const B = { k: `<p>${items.map(i => `<i>${i}</i>`).join('')}</p>` };")
check("nested template literals", len(find_block(strip_comments(src), "const B")),
      len("{ k: `<p>${items.map(i => `<i>${i}</i>`).join('')}</p>` }"))

# 3. An apostrophe in an HTML comment is prose, not a string opener.
src = "<!-- Taylor's own mark -->\n" + wrap("const C = { y: 2 };")
check("apostrophe in HTML comment", len(find_block(strip_comments(src), "const C")), len("{ y: 2 }"))

# 4. Offsets and line numbers survive stripping, so error messages stay truthful.
src = wrap("/* one\n   two */\nconst D = { z: 3 };")
stripped = strip_comments(src)
check("offsets preserved", len(stripped), len(src))
check("lines preserved", stripped.count("\n"), src.count("\n"))

# 5. A brace inside a regex quantifier must not be counted as a block.
src = wrap('const E = { r: /[A-Z][^:]{2,40}:/ };')
check("regex quantifier braces", len(find_block(strip_comments(src), "const E")),
      len("{ r: /[A-Z][^:]{2,40}:/ }"))

# 6. Division is not a regex.
check("division not regex", starts_regex("const n = a / b;", len("const n = a ")), False)
check("regex after return", starts_regex("return /x/.test(s)", len("return ")), True)
check("regex after (", starts_regex("f(/x/)", 2), True)

# 7. A brace inside a string must not close a block.
src = wrap('const F = { s: "}" };')
check("brace inside string", len(find_block(strip_comments(src), "const F")), len('{ s: "}" }'))

# 8. Escape sequences decode.
check("unicode escape", unescape("\\u00f1"), "ñ")
check("newline escape", unescape("a\\nb"), "a\nb")
check("quote escape", unescape('a\\"b'), 'a"b')

# 9. A comment inside a string is not a comment.
src = wrap('const G = { u: "http://x/*y*/z" };')
check("comment inside string", len(find_block(strip_comments(src), "const G")),
      len('{ u: "http://x/*y*/z" }'))

# 10. The real file parses end to end.
try:
    from lib.jsscan import read_source
    real = read_source(os.path.join(os.path.dirname(__file__), "..", "source", "Bridge_RC2_1.html"))
    stripped = strip_comments(real)
    for block, opener in (("const ICONS", "{"), ("const SCREENS", "{"),
                          ("const Gfx", "("), ("const ROLES", "{"), ("const I18N", "{")):
        find_block(stripped, block, opener, {"{": "}", "(": ")"}[opener])
    check("real file: comments blanked", stripped.split("\n")[2498].strip(), "")
except FileNotFoundError:
    print("  (skipped the real-file check; run from the repository root)")

if FAILURES:
    print(f"FAIL  {len(FAILURES)} scanner test(s)\n")
    for f in FAILURES:
        print("  " + f)
    sys.exit(1)
print("scanner: all tests pass")
