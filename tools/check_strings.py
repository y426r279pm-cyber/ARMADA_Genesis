#!/usr/bin/env python3
"""
Every L("...") in the Swift must exist in the catalog.

A missing key does not fail at runtime — `String(localized:)` falls back to the
key itself — so the Spanish build would quietly render English. That is the kind
of defect nobody notices until it is in front of a Spanish-speaking client, so
it is checked here instead.
"""

import json, re, sys, pathlib

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
        for m in re.finditer(r'\bL\("((?:[^"\\]|\\.)*)"\)', text):
            used.setdefault(m.group(1), set()).add(path.name)

    missing = sorted(k for k in used if k not in catalog)
    monolingual = sorted(k for k, v in catalog.items()
                         if set(v.get("localizations", {})) != {"en", "es"})

    print(f"strings: {len(used)} L() keys in Swift, {len(catalog)} in the catalog")
    if missing:
        print(f"\n  MISSING from the catalog ({len(missing)}) — these render English in Spanish:")
        for key in missing:
            print(f"    {key!r}  ({', '.join(sorted(used[key]))})")
        print("\n  Add them to tools/strings_supplement.json and re-run extract_strings.py.")
    if monolingual:
        print(f"\n  Entries missing a language ({len(monolingual)}):")
        for key in monolingual[:20]:
            print(f"    {key!r}")

    if missing or monolingual:
        return 1
    print("         every L() key resolves in both languages")
    return 0


if __name__ == "__main__":
    sys.exit(main())
