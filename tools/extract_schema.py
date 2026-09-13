#!/usr/bin/env python3
"""
STORES + the seeded records -> SwiftData models

The prototype's stores are schemaless documents, so the schema is whatever the
seed actually contains. Inferring it from the seeded records rather than from
the source is deliberate: it describes the data the app really holds, and it
makes every optional field visible as one that some records lack.
"""

import json, os, re, sys
from collections import OrderedDict
sys.path.insert(0, os.path.dirname(__file__))
from lib.jsscan import read_source, strip_comments, find_block, banner

SEED = "Bridge/Sources/BridgeKit/Resources/Seed.json"
OUT = "Bridge/Sources/BridgeKit/Model/Stores.swift"

SWIFT_KEYWORDS = {"case", "class", "default", "enum", "extension", "func", "import",
                  "in", "let", "operator", "protocol", "public", "repeat", "return",
                  "static", "struct", "subscript", "switch", "var", "where", "while",
                  "for", "if", "else", "do", "catch", "throw", "as", "is", "nil",
                  "self", "super", "true", "false", "internal", "private", "open",
                  "continue", "break", "guard", "defer", "init", "deinit", "typealias"}

# The stores, in the prototype's own order, with what each one holds.
PURPOSE = {
    "accounts": "Collections accounts: who is being chased, for what, and when next.",
    "invoices": "CFDI invoices through the five stages, with their REP clocks.",
    "agents": "The agent roster: scope, guardrails version, status, counts.",
    "models": "Models installed on the cluster.",
    "ledger": "The sealed chain. Append-only; see CanonicalSeal.",
    "incidents": "Open and closed incidents.",
    "nodes": "Cluster nodes: role, temperature, memory, status.",
    "power": "The power spine: solar, battery, grid, islanding.",
    "updates": "Update channel state and history.",
    "users": "People with a login and a role.",
    "settings": "Console settings, one record.",
    "chat": "Chat turns.",
    "integrations": "Configured connectors, by family.",
    "jobs": "Background jobs.",
    "installer": "Installer progress and findings.",
    "policies": "Guardrails, terms of service, terms of use; versioned with a diff.",
    "chats": "Chat threads, as distinct from their turns.",
    "suppliers": "Suppliers behind the supplier-match case model.",
    "pos": "Purchase orders: what was authorized.",
    "receipts": "Receiving records: what arrived.",
    "bankrecs": "Bank records: what was paid.",
    "cases": "The owning case per cross-store exception. One owner, always.",
    "stores": "OXXO stores and their connector state.",
    "sites": "Sites in the topology: core, recovery, regional, South America.",
    "topology": "The topology view's own state.",
}


def ident(name):
    safe = re.sub(r"[^A-Za-z0-9_]", "_", name)
    if safe in SWIFT_KEYWORDS:
        return f"`{safe}`"
    return safe


def type_name(store):
    """`bankrecs` -> `BankRec`, `pos` -> `PurchaseOrder`, and so on."""
    special = {"pos": "PurchaseOrder", "bankrecs": "BankRecord", "chat": "ChatTurn",
               "chats": "ChatThread", "receipts": "ReceivingRecord",
               "settings": "SettingsRecord", "policies": "Policy", "stores": "StoreSite",
               "cases": "MatchCase", "sites": "Site", "topology": "TopologyState",
               "installer": "InstallerState", "power": "PowerState",
               # `Model` would read as SwiftData's macro; `Ledger` and `Node` are
               # vague next to a cluster node and a chain entry.
               "models": "InstalledModel", "ledger": "LedgerEntry", "nodes": "ClusterNode"}
    if store in special:
        return special[store]
    base = store[:-1] if store.endswith("s") and not store.endswith("ss") else store
    return base[0].upper() + base[1:]


def infer(values):
    """A Swift type for a column, from every value seen in it."""
    kinds = set()
    for v in values:
        if v is None:
            kinds.add("null")
        elif isinstance(v, bool):
            kinds.add("Bool")
        elif isinstance(v, int):
            kinds.add("Int")
        elif isinstance(v, float):
            kinds.add("Int" if float(v).is_integer() else "Double")
        elif isinstance(v, str):
            kinds.add("String")
        elif isinstance(v, list):
            kinds.add("[String]" if all(isinstance(x, str) for x in v if x is not None) else "Data")
        elif isinstance(v, dict):
            kinds.add("Data")
        else:
            kinds.add("String")
    kinds.discard("null")
    if kinds == {"Int", "Double"}:
        kinds = {"Double"}
    if len(kinds) > 1:
        return "Data"          # genuinely mixed; stored as encoded JSON
    return kinds.pop() if kinds else "String"


def main():
    js = strip_comments(read_source())
    stores = re.findall(r'"([a-z]+)"', find_block(js, "const STORES", "[", "]"))
    with open(SEED, encoding="utf-8") as fh:
        seed = json.load(fh)

    L = [banner("tools/extract_schema.py"), ""]
    L.append("import Foundation")
    L.append("import SwiftData\n")
    L.append("/// The 25 document stores, typed.")
    L.append("///")
    L.append("/// The prototype keeps schemaless documents in IndexedDB, so these shapes are")
    L.append("/// inferred from what `seed()` actually produces. A field that only some records")
    L.append("/// carry is optional here, which is the honest reading; a field no seeded record")
    L.append("/// carries cannot be inferred at all, and those stores are marked below.")
    L.append("///")
    L.append("/// `id` is the key path in every store, matching the prototype's `keyPath: \"id\"`.\n")

    described, bare = [], []
    for store in stores:
        rows = seed.get(store) or []
        name = type_name(store)
        if not rows:
            bare.append((store, name))
            continue
        described.append((store, name, len(rows)))

        columns = OrderedDict()
        for row in rows:
            for k in row:
                columns.setdefault(k, [])
        for row in rows:
            for k in columns:
                columns[k].append(row.get(k))

        L.append(f"/// {PURPOSE.get(store, '')}")
        L.append(f"/// Seeded with {len(rows)} record{'s' if len(rows) != 1 else ''}.")
        L.append("@Model")
        L.append(f"public final class {name} {{")
        for col, values in columns.items():
            present = sum(1 for r in rows if col in r and r[col] is not None)
            swift = infer(values)
            optional = present < len(rows)
            attr = "    @Attribute(.unique) " if col == "id" else "    "
            L.append(f"{attr}public var {ident(col)}: {swift}{'?' if optional else ''}"
                     + ("" if col == "id" else ""))
            if optional:
                L[-1] += f"   // {present}/{len(rows)} records"
        L.append("")
        args = ", ".join(
            f"{ident(c)}: {infer(v)}{'?' if sum(1 for r in rows if c in r and r[c] is not None) < len(rows) else ''}"
            + (" = nil" if sum(1 for r in rows if c in r and r[c] is not None) < len(rows) else "")
            for c, v in columns.items())
        L.append(f"    public init({args}) {{")
        for col in columns:
            L.append(f"        self.{ident(col)} = {ident(col)}")
        L.append("    }")
        L.append("}\n")

    if bare:
        L.append("// MARK: - Stores the seed does not populate")
        L.append("//")
        L.append("// These exist in the prototype's STORES list but hold nothing after seeding,")
        L.append("// so there is no shape to infer. They are written by the running app, and")
        L.append("// each needs its schema taken from the code that writes it:")
        for store, name in bare:
            L.append(f"//   {store:<12} -> {name:<16} {PURPOSE.get(store, '')}")
        L.append("")

    L.append("/// Every model in the store, for the SwiftData container.")
    L.append("public enum BridgeSchema {")
    L.append("    public static let models: [any PersistentModel.Type] = [")
    for _, name, _ in described:
        L.append(f"        {name}.self,")
    L.append("    ]")
    L.append("}")

    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as fh:
        fh.write("\n".join(L) + "\n")

    print(f"schema: {len(described)} models from {len(stores)} stores -> {OUT}")
    for store, name, n in described:
        print(f"          {store:<14} {name:<18} {n:>4} seeded")
    if bare:
        print(f"        {len(bare)} stores unseeded, shape not inferable: {', '.join(s for s, _ in bare)}")


if __name__ == "__main__":
    main()
