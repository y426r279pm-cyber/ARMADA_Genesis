#!/usr/bin/env python3
"""
Every L("...") in the Swift must exist in the catalog.

A missing key does not fail at runtime — `String(localized:)` falls back to the
key itself — so the Spanish build would quietly render English. That is the kind
of defect nobody notices until it is in front of a Spanish-speaking client, so
it is checked here instead.
"""

import json, os, re, sys, pathlib
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lib.jsscan import catalog_symbol, SWIFT_KEYWORDS

CATALOG = "Bridge/Sources/BridgeKit/Resources/Localizable.xcstrings"
SOURCES = "Bridge/Sources"


def strip_comments(swift):
    """Drop // and /* */ so an `L("...")` written inside a doc comment is not
    mistaken for a call site."""
    out, i, n = [], 0, len(swift)
    while i < n:
        c = swift[i]
        if c == '"':
            j = i + 1
            while j < n:
                if swift[j] == "\\":
                    j += 2
                    continue
                if swift[j] == '"':
                    j += 1
                    break
                j += 1
            out.append(swift[i:j])
            i = j
        elif c == "/" and i + 1 < n and swift[i + 1] == "/":
            j = swift.find("\n", i)
            i = n if j < 0 else j
        elif c == "/" and i + 1 < n and swift[i + 1] == "*":
            j = swift.find("*/", i + 2)
            i = n if j < 0 else j + 2
        else:
            out.append(c)
            i += 1
    return "".join(out)


def main():
    with open(CATALOG, encoding="utf-8") as fh:
        catalog = json.load(fh)["strings"]

    used = {}
    for path in pathlib.Path(SOURCES).rglob("*.swift"):
        text = strip_comments(path.read_text(encoding="utf-8"))
        for m in re.finditer(r'\bLl?\("((?:[^"\\]|\\.)*)"\)', text):
            used.setdefault(m.group(1), set()).add(path.name)

    # Xcode generates one Swift symbol per catalog key, folding case and
    # punctuation. Two keys that fold together fail the build, and so does a key
    # that folds onto a Swift keyword. Ninety-five of those are how the first
    # Xcode build was spent, so they are checked here now.
    symbols = {}
    collisions = []
    keywords = []
    for key in catalog:
        symbol = catalog_symbol(key)
        if symbol in symbols:
            collisions.append((symbols[symbol], key))
        else:
            symbols[symbol] = key
        if symbol.replace(" ", "") in SWIFT_KEYWORDS:
            keywords.append(key)

    missing = sorted(k for k in used if k not in catalog)
    monolingual = sorted(k for k, v in catalog.items()
                         if set(v.get("localizations", {})) != {"en", "es"})

    print(f"strings: {len(used)} L()/Ll() keys in Swift, {len(catalog)} in the catalog")
    if missing:
        print(f"\n  MISSING from the catalog ({len(missing)}) — these render English in Spanish:")
        for key in missing:
            print(f"    {key!r}  ({', '.join(sorted(used[key]))})")
        print("\n  Add them to tools/strings_supplement.json and re-run extract_strings.py.")
    if monolingual:
        print(f"\n  Entries missing a language ({len(monolingual)}):")
        for key in monolingual[:20]:
            print(f"    {key!r}")

    if collisions:
        print(f"\n  SYMBOL COLLISIONS ({len(collisions)}) — Xcode will reject these:")
        for first, second in collisions[:20]:
            print(f"    {first!r} and {second!r} fold to the same Swift symbol")
        print("\n  extract_strings.py merges these automatically; if they are here,")
        print("  the collision pass did not run or something reintroduced them.")
    if keywords:
        print(f"\n  KEYS ON A SWIFT KEYWORD ({len(keywords)}): {keywords}")
        print("  These need the '(label)' qualifier — see catalog_key() in tools/lib/jsscan.py.")

    if missing or monolingual or collisions or keywords:
        return 1
    print("         every L() key resolves in both languages")
    print(f"         {len(catalog)} keys, no symbol collisions, none on a Swift keyword")
    return 0


if __name__ == "__main__":
    sys.exit(main())
