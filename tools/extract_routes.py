#!/usr/bin/env python3
"""
Every SCREENS entry -> Route.swift

The screens are registered in four places: the object literal, three
`Object.assign(SCREENS, {...})` blocks, and ten `SCREENS.name = function` lines.
Reading only the literal finds 17 of them and silently misses the rest — which
includes the whole Enterprise group, the one RC2 was built for.

A screen that takes `p` is a detail screen and carries a record id. The
breadcrumb labels come from `crumbLabel`, which is also where the parent
relationships live.
"""

import os, re, sys
sys.path.insert(0, os.path.dirname(__file__))
from lib.jsscan import (read_source, strip_comments, find_block, read_string_end,
                        starts_regex, read_regex_end, swift_string, banner)

OUT = "Bridge/Sources/BridgeKit/Router/Route.swift"
KEY = re.compile(r'([A-Za-z_$][\w$]*|"[^"]+")\s*\(\s*(p?)\s*\)\s*\{')


def body_of(block, at):
    """The balanced `{...}` body starting at `at`."""
    depth, i = 0, at
    while i < len(block):
        c = block[i]
        if c in "\"'`":
            i = read_string_end(block, i)
            continue
        if c == "/" and starts_regex(block, i):
            i = read_regex_end(block, i)
            continue
        if c == "{":
            depth += 1
        elif c == "}":
            depth -= 1
            if depth == 0:
                return block[at : i + 1]
        i += 1
    return block[at:]


def object_keys(block):
    """Top-level `name(p?) {` keys of an object literal.

    A screen is a detail screen if its body reads `state.params`, not if it
    declares an argument — the prototype passes the record id through `state`
    rather than through the call."""
    keys, depth, i = [], 0, 0
    while i < len(block):
        c = block[i]
        if c in "\"'`":
            i = read_string_end(block, i)
            continue
        if c == "/" and starts_regex(block, i):
            i = read_regex_end(block, i)
            continue
        if c == "{":
            depth += 1
            i += 1
            continue
        if c == "}":
            depth -= 1
            i += 1
            continue
        if depth == 1:
            m = KEY.match(block, i)
            if m:
                body = body_of(block, m.end() - 1)
                keys.append((m.group(1).strip('"'), "state.params" in body))
                i = m.end() - 1
                continue
        i += 1
    return keys


def main():
    js = strip_comments(read_source())

    screens = object_keys(find_block(js, "const SCREENS"))
    found_in = {k: "literal" for k, _ in screens}

    for m in re.finditer(r"Object\.assign\(SCREENS,\s*\{", js):
        block = find_block(js[m.start():], "Object.assign")
        for k, p in object_keys(block):
            if k not in found_in:
                screens.append((k, p))
                found_in[k] = "Object.assign"

    for m in re.finditer(r"SCREENS\.([A-Za-z_$][\w$]*)\s*=\s*function\s*\([^)]*\)\s*\{", js):
        k = m.group(1)
        if k not in found_in:
            body = body_of(js, m.end() - 1)
            screens.append((k, "state.params" in body))
            found_in[k] = "assignment"

    # Breadcrumb labels; the rest fall back to nav_<route> in the catalog.
    crumbs = {}
    block = find_block(js, "const crumbLabel")
    for m in re.finditer(r'\n\s{4}("?[a-z-]+"?):\s*(L\("([^"]*)",\s*"([^"]*)"\)|"([^"]*)")', block):
        key = m.group(1).strip('"')
        crumbs[key] = m.group(3) if m.group(3) is not None else m.group(5)

    detail = [k for k, p in screens if p]

    L = [banner("tools/extract_routes.py"), ""]
    L.append("import Foundation\n")
    L.append("/// Every screen Bridge can route to.")
    L.append("///")
    L.append("/// The raw value is the prototype's route name and is load-bearing: it keys the")
    L.append("/// string catalog (`nav_<raw>`), the icon set, and the seeded ledger. Registered")
    L.append("/// in four places in the prototype — the object literal, three `Object.assign`")
    L.append("/// blocks and ten direct assignments — so this list is the union of all four.")
    L.append("public enum Screen: String, CaseIterable, Sendable, Codable {")
    for name, _ in sorted(screens):
        L.append(f"    case {name}")
    L.append("")
    L.append("    /// Detail screens carry a record id; landing screens do not.")
    L.append("    public var takesRecord: Bool {")
    L.append("        switch self {")
    L.append(f"        case {', '.join('.' + d for d in sorted(detail))}: true")
    L.append("        default: false")
    L.append("        }")
    L.append("    }\n")
    L.append("    /// The label this screen shows in a breadcrumb trail.")
    L.append("    ///")
    L.append("    /// Detail screens carry their own short label; everything else falls back to")
    L.append("    /// its sidebar name.")
    L.append("    public var crumbLabel: String {")
    L.append("        switch self {")
    for key in sorted(crumbs):
        ident = key.replace("-", "_")
        if ident in {k for k, _ in screens} or ident == key:
            L.append(f"        case .{ident}: L({swift_string(crumbs[key])})")
    L.append("        default: Key(rawValue: \"nav_\\(rawValue)\")?.string ?? rawValue")
    L.append("        }")
    L.append("    }")
    L.append("}\n")

    L.append("/// One place in the navigation stack: a screen, and the record it is showing.")
    L.append("public struct Route: Hashable, Sendable, Codable {")
    L.append("    public var screen: Screen")
    L.append("    public var recordID: String?\n")
    L.append("    public init(_ screen: Screen, _ recordID: String? = nil) {")
    L.append("        self.screen = screen")
    L.append("        self.recordID = recordID")
    L.append("    }\n")
    L.append("    /// The prototype's `data-open=\"route:id\"` form, which the ledger also records.")
    L.append("    public var token: String { recordID.map { \"\\(screen.rawValue):\\($0)\" } ?? screen.rawValue }\n")
    L.append("    public init?(token: String) {")
    L.append("        let parts = token.split(separator: \":\", maxSplits: 1)")
    L.append("        guard let screen = Screen(rawValue: String(parts[0])) else { return nil }")
    L.append("        self.init(screen, parts.count > 1 ? String(parts[1]) : nil)")
    L.append("    }")
    L.append("}")

    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as fh:
        fh.write("\n".join(L) + "\n")

    by_source = {}
    for k, _ in screens:
        by_source.setdefault(found_in[k], []).append(k)
    print(f"routes: {len(screens)} screens ({len(detail)} take a record) -> {OUT}")
    for where, names in by_source.items():
        print(f"          {where:<14} {len(names):>2}: {', '.join(sorted(names))}")
    print(f"        {len(crumbs)} breadcrumb labels")


if __name__ == "__main__":
    main()
