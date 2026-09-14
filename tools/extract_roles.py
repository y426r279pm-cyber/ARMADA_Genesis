#!/usr/bin/env python3
"""
ROLES -> Role.swift

The prototype hides screens a role may not open rather than greying them, and
renders mutating controls disabled for read-only roles. Both behaviours are
data, not code, so both survive the port as data.
"""

import os, re, sys
sys.path.insert(0, os.path.dirname(__file__))
from lib.jsscan import read_source, strip_comments, find_block, banner

OUT = "Bridge/Sources/BridgeKit/RBAC/Role.swift"

# `operator` is a Swift keyword and needs escaping in a case name.
SWIFT_KEYWORDS = {"operator", "class", "struct", "enum", "protocol", "default", "internal",
                  "static", "public", "private", "case", "func", "var", "let", "in", "is", "as"}


def ident(name):
    return f"`{name}`" if name in SWIFT_KEYWORDS else name


NOTES = {
    "admin": "Sees every screen and may change records; the wizard and the policies are theirs.",
    "enterprise": "Everything Admin sees plus the Enterprise group: supplier match, measures, stores, topology.",
    "operator": "The working roles: collections, invoices, agents, incidents.",
    "auditor": "Reads everything that carries evidence; changes nothing.",
    "reception": "The front desk: health, agents, chat, profile. Nothing financial.",
}


def parse_roles(block):
    roles = []
    for m in re.finditer(r"\b([a-z]+):\s*\{", block):
        key = m.group(1)
        if key in ("label", "screens", "write"):
            continue
        tail = block[m.end():]
        label = re.search(r'label:\s*"([^"]+)"', tail)
        screens = re.search(r"screens:\s*\[(.*?)\]", tail, re.S)
        write = re.search(r"write:\s*(true|false)", tail)
        if not (label and screens and write):
            raise ValueError(f"role {key!r} is missing label, screens or write")
        names = re.findall(r'"([a-z_]+)"', screens.group(1))
        roles.append((key, label.group(1), names, write.group(1) == "true"))
    return roles


def main():
    js = strip_comments(read_source())
    roles = parse_roles(find_block(js, "const ROLES"))
    if len(roles) != 5:
        raise SystemExit(f"expected 5 roles, found {len(roles)}: {[r[0] for r in roles]}")

    every = []
    for _, _, screens, _ in roles:
        for s in screens:
            if s not in every:
                every.append(s)

    # Screen lives in Route.swift, which knows all 43 routes rather than only the
    # 22 that reach a sidebar. Assert the two agree rather than defining it twice.
    route_file = "Bridge/Sources/BridgeKit/Router/Route.swift"
    if os.path.exists(route_file):
        known = set(re.findall(r"^    case ([a-z_]+)$", open(route_file, encoding="utf-8").read(), re.M))
        unknown = [s for s in every if s not in known]
        if unknown:
            raise SystemExit(f"roles name screens that no route defines: {unknown}\n"
                             f"run tools/extract_routes.py first")

    L = [banner("tools/extract_roles.py"), ""]
    L.append("/// Who may see and change what.")
    L.append("///")
    L.append("/// Screens absent from a role are hidden, not disabled. Mutating controls")
    L.append("/// render disabled when `canWrite` is false. Identity arrives as OIDC claims")
    L.append("/// in production; the picker on the front door is the demo stand-in.")
    L.append("public enum Role: String, CaseIterable, Sendable, Codable {")
    for key, _, _, _ in roles:
        L.append(f"    case {ident(key)}")
    L.append("")
    L.append("    /// String-catalog key for this role's display name.")
    L.append("    public var labelKey: String {")
    L.append("        switch self {")
    for key, label, _, _ in roles:
        L.append(f'        case .{ident(key)}: "{label}"')
    L.append("        }")
    L.append("    }\n")
    L.append("    /// May this role change records?")
    L.append("    public var canWrite: Bool {")
    L.append("        switch self {")
    for key, _, _, write in roles:
        L.append(f"        case .{ident(key)}: {str(write).lower()}")
    L.append("        }")
    L.append("    }\n")
    L.append("    /// Administrative roles reach the wizard and the policy editor.")
    L.append("    public var isAdmin: Bool { self == .admin || self == .enterprise }\n")
    L.append("    /// The screens this role may open, in sidebar order.")
    L.append("    public var screens: [Screen] {")
    L.append("        switch self {")
    for key, _, screens, _ in roles:
        L.append(f"        // {NOTES.get(key, '')}")
        L.append(f"        case .{ident(key)}: [{', '.join('.' + s for s in screens)}]")
    L.append("        }")
    L.append("    }\n")
    L.append("    /// Hidden, not greyed: the sidebar never advertises a screen the role cannot open.")
    L.append("    public func canOpen(_ screen: Screen) -> Bool { screens.contains(screen) }")
    L.append("}")

    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w") as fh:
        fh.write("\n".join(L) + "\n")

    print(f"roles: {len(roles)} roles, {len(every)} distinct screens -> {OUT}")
    for key, label, screens, write in roles:
        print(f"          {key:<11} {len(screens):>2} screens  write={str(write).lower():<5}  ({label})")


if __name__ == "__main__":
    main()
