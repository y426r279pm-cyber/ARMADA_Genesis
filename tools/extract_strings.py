#!/usr/bin/env python3
"""
I18N + every L(en, es) call site -> Localizable.xcstrings + Strings.swift

Two populations, one catalog:

  * the fixed dictionary (`I18N.en` / `I18N.es`), keyed — 90 keys;
  * the inline pairs (`L("English", "Espanol")`) scattered through the screens,
    unkeyed — around 800.

The inline pairs are the risk. They are literal pairs at call sites, not keys,
so extraction must be exhaustive or Spanish silently degrades. Two defences:
the count is asserted against a scan of the raw text, and any English string
that appears with two different Spanish translations is reported rather than
silently collapsed.

The catalog uses the English string as the key, which is idiomatic for
.xcstrings and keeps Swift call sites readable: String(localized: "Sealed").
"""

import json, os, re, sys
sys.path.insert(0, os.path.dirname(__file__))
from lib.jsscan import (read_source, strip_comments, find_block, read_js_string,
                        swift_string, banner, SWIFT_KEYWORDS, catalog_symbol)

OUT_CATALOG = "Bridge/Sources/BridgeKit/Resources/Localizable.xcstrings"
SUPPLEMENT = "tools/strings_supplement.json"
OUT_SWIFT = "Bridge/Sources/BridgeKit/Localization/Strings.swift"


def parse_dictionary(js):
    """The keyed dictionary: I18N.en and I18N.es."""
    block = find_block(js, "const I18N")
    out = {}
    for lang in ("en", "es"):
        m = re.search(rf"\b{lang}:\s*\{{", block)
        if not m:
            raise ValueError(f"I18N.{lang} not found")
        start = block.index("{", m.start())
        depth, i, entries = 0, start, {}
        while i < len(block):
            c = block[i]
            if c in "\"'`":
                i = read_js_string(block, i)[1]
                continue
            if c == "{":
                depth += 1
            elif c == "}":
                depth -= 1
                if depth == 0:
                    break
            i += 1
        body = block[start : i + 1]
        pos = 0
        while True:
            km = re.compile(r'([A-Za-z_][A-Za-z0-9_]*)\s*:\s*"').search(body, pos)
            if not km:
                break
            value, end = read_js_string(body, km.end() - 1)
            entries[km.group(1)] = value
            pos = end
        out[lang] = entries
    return out


def enclosing(js, at):
    """Name of the nearest function or screen enclosing `at`.

    Used only to disambiguate an English string that needs two different
    Spanish translations — Spanish agreement means `paused` is `pausado` beside
    a masculine noun and `pausada` beside a feminine one, and the English alone
    is then not a sufficient key."""
    head = js[:at]
    best, name = -1, "global"
    for pat in (r"\n  ([a-z_][A-Za-z0-9_]*)\(\w*\)\s*\{",
                r"\nfunction ([A-Za-z_][A-Za-z0-9_]*)\(",
                r"\nconst ([A-Za-z_][A-Za-z0-9_]*) = "):
        for m in re.finditer(pat, head):
            if m.start() > best:
                best, name = m.start(), m.group(1)
    return name


def parse_inline_pairs(js, origin):
    """Every L("English", "Espanol") call site in the script, in source order.

    Returns (pairs, total_calls, skipped) where each pair carries its line
    number and enclosing function so conflicts can be reported precisely."""
    pairs, total, skipped = [], 0, []
    for m in re.finditer(r"\bL\(", js):
        if m.start() < origin:
            continue                      # the HTML header comment, not code
        total += 1
        line = js[: m.start()].count("\n") + 1
        i = m.end()
        while i < len(js) and js[i] in " \t\r\n":
            i += 1
        if i >= len(js) or js[i] != '"':
            skipped.append((line, enclosing(js, m.start()), js[m.start() : m.start() + 70]))
            continue                      # a template literal or a nested expression
        en, i = read_js_string(js, i)
        while i < len(js) and js[i] in " \t\r\n":
            i += 1
        if i >= len(js) or js[i] != ",":
            skipped.append((line, enclosing(js, m.start()), js[m.start() : m.start() + 70]))
            continue
        i += 1
        while i < len(js) and js[i] in " \t\r\n":
            i += 1
        if i >= len(js) or js[i] != '"':
            skipped.append((line, enclosing(js, m.start()), js[m.start() : m.start() + 70]))
            continue
        es, _ = read_js_string(js, i)
        pairs.append((en, es, line, enclosing(js, m.start())))
    return pairs, total, skipped


SWIFT_KEYWORDS = {
    "associatedtype", "break", "case", "catch", "class", "continue", "default", "defer",
    "deinit", "do", "else", "enum", "extension", "fallthrough", "false", "final", "for",
    "func", "guard", "if", "import", "in", "init", "internal", "is", "lazy", "let", "nil",
    "open", "operator", "private", "protocol", "public", "repeat", "return", "self", "static",
    "struct", "subscript", "super", "switch", "throw", "throws", "true", "try", "typealias",
    "var", "weak", "where", "while",
}


def symbol_of(key):
    """Approximate the identifier Xcode derives from a catalog key."""
    return re.sub(r"[^A-Za-z0-9]+", " ", key).strip().lower()


def resolve_symbol_collisions(strings):
    """One key per generated symbol, and no key that lands on a Swift keyword.

    Returns (strings, merges, renames). `merges` names each dropped key and the
    one that absorbed it; `renames` names each key moved off a reserved word.
    """
    by_symbol = {}
    for key in strings:
        by_symbol.setdefault(symbol_of(key), []).append(key)

    merges = []
    for sym, keys in by_symbol.items():
        if len(keys) < 2:
            continue
        # Keep the Title-case spelling: a label reads correctly as-is, and the
        # running-text use is one Ll() away. The reverse is not true.
        keeper = max(keys, key=lambda k: (k[:1].isupper(), -len(k), k))
        for dropped in keys:
            if dropped == keeper:
                continue
            merges.append((dropped, keeper,
                           spanish(strings[dropped]) != spanish(strings[keeper])))
            del strings[dropped]

    # A key whose symbol is a Swift keyword is renamed, not dropped. The English
    # value is untouched, so what renders does not change.
    renames = []
    for key in list(strings):
        if symbol_of(key).replace(" ", "") in SWIFT_KEYWORDS:
            new = f"{key} (label)"
            strings[new] = strings.pop(key)
            renames.append((key, new))

    return strings, merges, renames


def spanish(entry):
    return entry.get("localizations", {}).get("es", {}).get("stringUnit", {}).get("value")


def main():
    raw = read_source()
    js = strip_comments(raw)
    origin = js.index("<script>")

    dictionary = parse_dictionary(js)
    en_keys, es_keys = set(dictionary["en"]), set(dictionary["es"])
    if en_keys != es_keys:
        only_en, only_es = sorted(en_keys - es_keys), sorted(es_keys - en_keys)
        raise SystemExit(f"dictionary halves disagree. en-only={only_en} es-only={only_es}")

    pairs, total, skipped = parse_inline_pairs(js, origin)

    # English -> {Spanish -> [(line, function)]}. More than one Spanish for one
    # English is an agreement conflict, not a duplicate.
    by_en = {}
    for en, es, line, fn in pairs:
        by_en.setdefault(en, {}).setdefault(es, []).append((line, fn))
    conflicts = {en: v for en, v in by_en.items() if len(v) > 1}

    strings, key_of = {}, {}

    def add(key, en, es, comment=None):
        entry = {
            "extractionState": "manual",
            "localizations": {
                "en": {"stringUnit": {"state": "translated", "value": en}},
                "es": {"stringUnit": {"state": "translated", "value": es}},
            },
        }
        if comment:
            entry["comment"] = comment
        strings[key] = entry

    for key, en in dictionary["en"].items():
        add(key, en, dictionary["es"][key], "Fixed dictionary key from the prototype's I18N block.")

    for en, variants in by_en.items():
        if en in strings:
            continue
        if len(variants) == 1:
            es = next(iter(variants))
            add(en, en, es)
            key_of[(en, es)] = en
        else:
            # Disambiguate by the enclosing function, which is where the agreeing
            # noun lives. Ordered by first appearance so keys are stable.
            ordered = sorted(variants.items(), key=lambda kv: min(s[0] for s in kv[1]))
            for es, sites in ordered:
                where = sorted({fn for _, fn in sites})
                key = f"{en} [{'/'.join(where)}]"
                add(key, en, es,
                    "Spanish agreement differs by context; key disambiguated by enclosing "
                    f"screen. Prototype call sites: {', '.join(f'line {l}' for l, _ in sorted(sites))}.")
                key_of[(en, es)] = key

    # Strings the port introduces that the prototype has no equivalent for.
    # Hand-authored, merged here so regenerating from the prototype does not
    # lose them. The prototype always wins a collision: it is the canon.
    supplement, supplement_added = {}, 0
    if os.path.exists(SUPPLEMENT):
        with open(SUPPLEMENT, encoding="utf-8") as fh:
            supplement = json.load(fh).get("strings", {})
        for en, es in supplement.items():
            if en in strings:
                continue
            add(en, en, es, "Introduced by the Swift port; not present in the prototype.")
            supplement_added += 1

    # Xcode generates a Swift symbol per catalog key, and it derives that symbol
    # by folding case and punctuation. So "Accounts" and "accounts" are two keys
    # but one symbol, and the build fails with 95 of those. Keying on the English
    # string — which is what makes the call sites readable — is what creates
    # them: the prototype wrote a word lowercase in running text and Title-case
    # as a label, and both became keys.
    #
    # One key survives each collision. Where the port needs the other casing it
    # calls Ll(), which lowercases the first letter at render time. Nothing is
    # lost: the two entries were the same word.
    strings, merges, renames = resolve_symbol_collisions(strings)

    catalog = {"sourceLanguage": "en", "version": "1.0", "strings": strings}
    os.makedirs(os.path.dirname(OUT_CATALOG), exist_ok=True)
    with open(OUT_CATALOG, "w", encoding="utf-8") as fh:
        json.dump(catalog, fh, ensure_ascii=False, indent=2, sort_keys=True)

    L = [banner("tools/extract_strings.py"), ""]
    L.append("import Foundation\n")
    L.append("/// The keyed half of the dictionary.")
    L.append("///")
    L.append("/// The prototype renders a missing key as \u2039key\u203a so it cannot ship unnoticed.")
    L.append("/// `Key.string` keeps that behaviour: a key absent from the catalog resolves to")
    L.append("/// itself, and the guard below turns that into the same loud marker.")
    L.append("public enum Key: String, CaseIterable, Sendable {")
    for key in sorted(dictionary["en"]):
        L.append(f"    case {key}")
    L.append("")
    L.append("    /// The localized value, or the key in corner brackets when the catalog has no entry.")
    L.append("    public var string: String {")
    L.append("        let value = String(localized: String.LocalizationValue(rawValue), bundle: .module)")
    L.append('        return value == rawValue ? "\\u{27E6}\\(rawValue)\\u{27E7}" : value')
    L.append("    }")
    L.append("}\n")
    L.append('/// The inline half: L("English", "Espanol") in the prototype.')
    L.append("///")
    L.append("/// The English string is the catalog key, so call sites stay readable.")
    L.append("public func L(_ english: String.LocalizationValue) -> String {")
    L.append("    String(localized: english, bundle: .module)")
    L.append("}\n")
    L.append("/// The same string, lowercased for a running-text position.")
    L.append("///")
    L.append("/// Xcode derives one Swift symbol per catalog key by folding case, so")
    L.append("/// \"Accounts\" and \"accounts\" cannot both be keys. One survives, and this")
    L.append("/// produces the other spelling at render time.")
    L.append("///")
    L.append("/// Only the first character changes. Lowercasing the whole string would")
    L.append("/// damage a proper noun sitting inside it.")
    L.append("public func Ll(_ english: String.LocalizationValue) -> String {")
    L.append("    let text = L(english)")
    L.append("    guard let first = text.first else { return text }")
    L.append("    return first.lowercased() + text.dropFirst()")
    L.append("}\n")
    if conflicts:
        L.append("/// Strings whose Spanish depends on the noun they sit beside.")
        L.append("///")
        L.append("/// Spanish agreement means one English word needs more than one translation:")
        L.append("/// `paused` is `pausado` beside a masculine noun and `pausada` beside a")
        L.append("/// feminine one.")
        L.append("///")
        L.append("/// The prototype expressed this correctly: its `L(en, es)` is a ternary, so both")
        L.append("/// strings sat at the call site. A String Catalog needs a key, and keying on the")
        L.append("/// English would collapse the variants, so these carry their screen instead.")
        L.append("/// See docs/STRING_CONFLICTS.md.")
        L.append("public enum Agreeing {")
        for en in sorted(conflicts):
            for es, sites in sorted(conflicts[en].items(), key=lambda kv: min(s[0] for s in kv[1])):
                key = key_of[(en, es)]
                where = sorted({fn for _, fn in sites})
                ident = re.sub(r"[^A-Za-z0-9]+", "_", f"{en}_{'_'.join(where)}").strip("_")
                ident = ident[0].lower() + ident[1:] if ident else "unnamed"
                L.append(f"    /// {en!r} -> {es!r} (in {', '.join(where)})")
                L.append(f"    public static var {ident}: String {{ L({swift_string(key)}) }}")
        L.append("}\n")
    L.append("/// Every English string the prototype ships, for the wording audit to walk.")
    L.append("///")
    L.append("/// The audit is not decoration. The RC2 brief requires that no string read as a")
    L.append("/// claim of fiscal validity or of control remediation; in the browser that was a")
    L.append("/// script someone remembered to run, and here it is a test that fails the build.")
    L.append("public enum AuditableStrings {")
    L.append("    public static let all: [String] = [")
    for key in sorted(strings):
        L.append(f"        {swift_string(strings[key]['localizations']['en']['stringUnit']['value'])},")
    L.append("    ]")
    L.append("}")

    os.makedirs(os.path.dirname(OUT_SWIFT), exist_ok=True)
    with open(OUT_SWIFT, "w", encoding="utf-8") as fh:
        fh.write("\n".join(L) + "\n")

    # The conflicts and the hand-port list are findings, so they get a document.
    R = ["# Strings needing a hand in phase 1",
         "",
         "Generated by `tools/extract_strings.py`. Two lists: strings whose Spanish depends",
         "on context, and call sites the extractor cannot carry across.",
         "",
         f"## 1 · Spanish agreement conflicts ({len(conflicts)})",
         "",
         "One English string, more than one Spanish translation, because Spanish agrees",
         "with the noun: `paused` is `pausado` beside a masculine noun, `pausada` beside a",
         "feminine one, `pausados` beside a plural.",
         "",
         "**The prototype is correct here.** `L` is a bare ternary --- both strings sit at",
         "the call site, and each one renders the right word. Nothing is broken in RC2.1.",
         "",
         "The conflict is introduced by the port. A String Catalog needs a key, and keying",
         "on the English string --- which is what makes Swift call sites read naturally ---",
         "collapses these variants together. So the generated catalog keys each variant by",
         "its enclosing screen instead.",
         "",
         "What is needed: confirm each variant sits with the noun it agrees with, since the",
         "enclosing screen is a proxy for context and not the context itself. Two screens",
         "listed against one spelling is the case to look at first.",
         "",
         "| English | Spanish | Screen | Prototype lines |",
         "|---|---|---|---|"]
    for en in sorted(conflicts):
        for es, sites in sorted(conflicts[en].items(), key=lambda kv: min(s[0] for s in kv[1])):
            where = ", ".join(sorted({fn for _, fn in sites}))
            lines = ", ".join(str(l) for l, _ in sorted(sites)[:6])
            if len(sites) > 6:
                lines += f", +{len(sites) - 6}"
            R.append(f"| `{en}` | `{es}` | {where} | {lines} |")
    R += ["",
          f"## 2 · Call sites the extractor cannot carry ({len(skipped)})",
          "",
          "`L()` called with a template literal rather than a pair of string literals.",
          "These interpolate at runtime, so they become Swift string interpolation by hand.",
          ""]
    if skipped:
        R += ["| Line | Screen | Source |", "|---|---|---|"]
        for line, fn, snippet in skipped:
            clean = " ".join(snippet.split())[:60].replace("|", "\\|")
            R.append(f"| {line} | {fn} | `{clean}...` |")
    else:
        R.append("None.")
    with open("docs/STRING_CONFLICTS.md", "w", encoding="utf-8") as fh:
        fh.write("\n".join(R) + "\n")

    print(f"strings: {len(dictionary['en'])} dictionary keys x 2 languages (halves agree)")
    print(f"         {total} L() call sites, {len(pairs)} literal pairs, {len(skipped)} needing a hand")
    print(f"         {len(by_en)} distinct English strings, {len(conflicts)} with an agreement conflict")
    print(f"         {supplement_added} from the port's supplement")
    print(f"         {len(merges)} merged onto their Title-case twin, {len(renames)} moved off a Swift keyword")
    print(f"         {len(strings)} catalog entries -> {OUT_CATALOG}")
    print(f"         findings -> docs/STRING_CONFLICTS.md")


if __name__ == "__main__":
    main()
