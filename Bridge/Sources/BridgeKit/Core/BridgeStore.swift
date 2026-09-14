import Foundation
import SwiftData

/// The SwiftData container, and the first-launch import.
///
/// `Seed.json` is produced by running the prototype's own `seed()`, so Bridge
/// opens with exactly the records the browser opens with — the same invoices,
/// the same 17 nodes, the same ledger down to its hashes.
///
/// Import happens once. A store that already holds records is left alone, so
/// work done in a demo survives a relaunch.
@MainActor
public enum BridgeStore {

    public static func container(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema(BridgeSchema.models)
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        let container = try ModelContainer(for: schema, configurations: configuration)
        try seedIfEmpty(container.mainContext)
        return container
    }

    /// Populate an empty store from the bundled seed.
    public static func seedIfEmpty(_ context: ModelContext) throws {
        let existing = try context.fetchCount(FetchDescriptor<ClusterNode>())
        guard existing == 0 else { return }
        guard let url = Bundle.module.url(forResource: "Seed", withExtension: "json") else {
            throw SeedBundle.LoadError.missingFile
        }
        let bundle = try SeedBundle.load(from: url)
        try importRecords(bundle, into: context)
        try context.save()
    }

    /// Decode the stores the demo path needs.
    ///
    /// Only these are imported so far. The rest arrive with the screens that use
    /// them — importing a store nothing reads would be a schema no one has
    /// checked against a screen.
    static func importRecords(_ bundle: SeedBundle, into context: ModelContext) throws {
        for row in bundle.rows("nodes") {
            context.insert(ClusterNode(id: row.string("id"), role: row.string("role"),
                                       status: row.string("status"), tempC: row.int("tempC"),
                                       memGB: row.int("memGB"), serial: row.string("serial"),
                                       ledger: row.string("ledger")))
        }
        for row in bundle.rows("power") {
            context.insert(PowerState(id: row.string("id"), solarKW: row.double("solarKW"),
                                      batteryPct: row.int("batteryPct"), grid: row.string("grid"),
                                      islanded: row.bool("islanded"),
                                      reservePct: row.int("reservePct"),
                                      curtail: row.bool("curtail"), upsMin: row.int("upsMin")))
        }
        for row in bundle.rows("invoices") {
            context.insert(Invoice(id: row.string("id"), uuid: row.string("uuid"),
                                   client: row.string("client"), stage: row.string("stage"),
                                   amount: row.int("amount"), issued: row.string("issued"),
                                   repDay: row.int("repDay"),
                                   supplier: row.optionalString("supplier"),
                                   type: row.optionalString("type"),
                                   method: row.optionalString("method"),
                                   qty: row.optionalInt("qty"), price: row.optionalInt("price"),
                                   rfc: row.optionalString("rfc"), sat: row.optionalString("sat"),
                                   po: row.optionalString("po"),
                                   cancel: row.encoded("cancel")))
        }
        for row in bundle.rows("users") {
            context.insert(User(id: row.string("id"), name: row.string("name"),
                                role: row.string("role"), createdAt: row.string("createdAt")))
        }
    }
}

// MARK: Reading the seed

extension SeedBundle {
    /// The rows of one store, as ordered field lists.
    public func rows(_ store: String) -> [Row] {
        guard case .array(let items)? = raw[store] else { return [] }
        return items.compactMap { value in
            guard case .object(let pairs) = value else { return nil }
            return Row(pairs)
        }
    }

    /// One seeded record. Field access is forgiving by design: the prototype's
    /// stores are schemaless and a field only some records carry is normal, not
    /// an error.
    public struct Row: Sendable {
        let pairs: [(key: String, value: CanonicalJSON.Value)]
        init(_ pairs: [(key: String, value: CanonicalJSON.Value)]) { self.pairs = pairs }

        func value(_ key: String) -> CanonicalJSON.Value? {
            pairs.first { $0.key == key }?.value
        }

        public func string(_ key: String) -> String { optionalString(key) ?? "" }

        public func optionalString(_ key: String) -> String? {
            switch value(key) {
            case .string(let s): s
            case .integer(let i): String(i)
            case .number(let d): CanonicalJSON.number(d)
            default: nil
            }
        }

        public func int(_ key: String) -> Int { optionalInt(key) ?? 0 }

        public func optionalInt(_ key: String) -> Int? {
            switch value(key) {
            case .integer(let i): i
            case .number(let d): Int(d)
            default: nil
            }
        }

        public func double(_ key: String) -> Double {
            switch value(key) {
            case .integer(let i): Double(i)
            case .number(let d): d
            default: 0
            }
        }

        public func bool(_ key: String) -> Bool {
            if case .bool(let b)? = value(key) { return b }
            return false
        }

        /// A nested object or array, kept as the bytes it was written as so that
        /// nothing is lost before the screen that understands it is built.
        public func encoded(_ key: String) -> Data? {
            guard let value = value(key), value != .null else { return nil }
            return Data(CanonicalJSON.stringify(value).utf8)
        }
    }
}
