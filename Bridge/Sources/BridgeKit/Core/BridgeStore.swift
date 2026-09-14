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
        for row in bundle.rows("suppliers") {
            context.insert(Supplier(id: row.string("id"), name: row.string("name"),
                                    rfc: row.string("rfc"), status: row.string("status"),
                                    terms: row.int("terms"), openCases: row.int("openCases")))
        }
        for row in bundle.rows("pos") {
            context.insert(PurchaseOrder(id: row.string("id"), supplier: row.string("supplier"),
                                         date: row.string("date"), qty: row.int("qty"),
                                         price: row.int("price"), total: row.int("total")))
        }
        for row in bundle.rows("receipts") {
            context.insert(ReceivingRecord(id: row.string("id"), po: row.string("po"),
                                           date: row.string("date"), qty: row.int("qty"),
                                           dc: row.string("dc")))
        }
        for row in bundle.rows("bankrecs") {
            context.insert(BankRecord(id: row.string("id"), invoice: row.string("invoice"),
                                      date: row.string("date"), amount: row.int("amount"),
                                      reference: row.string("reference")))
        }
        for row in bundle.rows("cases") {
            context.insert(MatchCase(id: row.string("id"), invoice: row.string("invoice"),
                                     po: row.string("po"), supplier: row.string("supplier"),
                                     status: row.string("status"), title: row.string("title"),
                                     owner: row.string("owner"), opened: row.string("opened"),
                                     minutes: row.int("minutes"), agent: row.string("agent"),
                                     actions: [], finding: row.string("finding")))
        }
        for row in bundle.rows("stores") {
            context.insert(StoreSite(id: row.string("id"), name: row.string("name"),
                                     city: row.string("city"), dc: row.string("dc"),
                                     site: row.string("site"), connector: row.string("connector"),
                                     queued: row.int("queued"), openCases: row.int("openCases"),
                                     agent: row.string("agent"),
                                     planogram: row.optionalString("planogram"),
                                     tickets: row.int("tickets")))
        }
        for row in bundle.rows("sites") {
            context.insert(Site(id: row.string("id"), name: row.string("name"),
                                city: row.string("city"), kind: row.string("kind"),
                                nodes: row.int("nodes"), octets: row.int("octets"),
                                stores: row.int("stores"), queued: row.int("queued"),
                                lag: row.int("lag"), latency: row.int("latency")))
        }
    }

    /// Assemble the four records behind every case, once, at load.
    ///
    /// Built here rather than looked up per view so the rules always see the
    /// same evidence, and so a duplicate UUID is detected across the whole set
    /// of payables rather than whatever happens to be on screen.
    public static func evidence(from bundle: SeedBundle) -> [String: MatchEvidence] {
        let invoices = bundle.rows("invoices")
        let orders = bundle.rows("pos")
        let receipts = bundle.rows("receipts")
        let payments = bundle.rows("bankrecs")
        let suppliers = bundle.rows("suppliers")

        var uuidCounts: [String: Int] = [:]
        for invoice in invoices where invoice.string("type") == "payable" {
            uuidCounts[invoice.string("uuid"), default: 0] += 1
        }

        var result: [String: MatchEvidence] = [:]
        for item in bundle.rows("cases") {
            let invoice = invoices.first { $0.string("id") == item.string("invoice") }
            let order = orders.first { $0.string("id") == item.string("po") }
            let receipt = receipts.first { $0.string("po") == item.string("po") }
            let payment = payments.first { $0.string("invoice") == item.string("invoice") }
            let supplier = suppliers.first { $0.string("id") == item.string("supplier") }
            let uuid = invoice?.string("uuid")

            result[item.string("id")] = MatchEvidence(
                orderedQty: order?.optionalInt("qty"),
                orderedPrice: order?.optionalInt("price"),
                orderedTotal: order?.optionalInt("total"),
                receivedQty: receipt?.optionalInt("qty"),
                receivingCentre: receipt?.optionalString("dc"),
                billedQty: invoice?.optionalInt("qty"),
                billedPrice: invoice?.optionalInt("price"),
                billedTotal: invoice?.optionalInt("amount"),
                billedUUID: uuid,
                billedRFC: invoice?.optionalString("rfc"),
                satStatus: invoice?.optionalString("sat"),
                paidAmount: payment?.optionalInt("amount"),
                supplierRFC: supplier?.optionalString("rfc"),
                supplierStatus: supplier?.optionalString("status"),
                uuidSeenOnAnotherPayable: uuid.map { (uuidCounts[$0] ?? 0) > 1 } ?? false)
        }
        return result
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
