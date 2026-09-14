import Foundation

/// The seeded store, read from `Seed.json`.
///
/// The file is produced by running the prototype's own `seed()` — see
/// `tools/seed_harness.mjs` — so what Bridge opens with here is exactly what it
/// opens with in the browser, down to the ledger hashes.
///
/// The ledger is decoded with the order-preserving parser rather than
/// `JSONDecoder`, because its extras must keep the order they were sealed in or
/// the chain will not verify.
public struct SeedBundle: Sendable {
    public var ledger: [Seal.Entry]
    public var raw: [String: CanonicalJSON.Value]

    public static func load(from url: URL) throws -> SeedBundle {
        let text = try String(contentsOf: url, encoding: .utf8)
        guard case .object(let top) = try CanonicalJSON.parse(text) else {
            throw LoadError.notAnObject
        }
        var raw: [String: CanonicalJSON.Value] = [:]
        for pair in top { raw[pair.key] = pair.value }

        guard case .array(let rows)? = raw["ledger"] else {
            throw LoadError.missingStore("ledger")
        }
        return SeedBundle(ledger: try rows.map(entry(from:)), raw: raw)
    }

    /// A seed resource inside BridgeKit's own bundle.
    ///
    /// Exposed so the demo-mode audit can read both seeds directly. The audit
    /// has to inspect the shipped file, not a running app: a name that is hidden
    /// at render time is still in the bundle, where a screenshot or an unzipped
    /// app package will find it.
    public static func resourceURL(_ name: String) -> URL? {
        Bundle.module.url(forResource: name, withExtension: "json")
    }

    /// Load the copy bundled with the app.
    public static func bundled() throws -> SeedBundle {
        guard let url = Bundle.module.url(forResource: DemoMode.seedResource,
                                          withExtension: "json") else {
            throw LoadError.missingFile
        }
        return try load(from: url)
    }

    static func entry(from value: CanonicalJSON.Value) throws -> Seal.Entry {
        guard case .object(let pairs) = value else { throw LoadError.notAnObject }
        func string(_ key: String) throws -> String {
            guard case .string(let s)? = pairs.first(where: { $0.key == key })?.value else {
                throw LoadError.missingField(key)
            }
            return s
        }
        let seq: Int
        switch pairs.first(where: { $0.key == "seq" })?.value {
        case .integer(let i): seq = i
        case .number(let d): seq = Int(d)
        default: throw LoadError.missingField("seq")
        }
        // Everything not reserved is an extra, in the order it was written.
        let extra = pairs.filter { !Seal.reserved.contains($0.key) }
        return Seal.Entry(id: try string("id"), seq: seq, at: try string("at"),
                          actor: try string("actor"), es: try string("es"),
                          en: try string("en"), extra: extra,
                          prevHash: try string("prevHash"), hash: try string("hash"))
    }

    public enum LoadError: Error, Equatable {
        case missingFile
        case notAnObject
        case missingStore(String)
        case missingField(String)
    }

    /// How many records each store carries, for the health and settings screens.
    public var counts: [(store: String, records: Int)] {
        raw.compactMap { key, value in
            guard case .array(let rows) = value else { return nil }
            return (key, rows.count)
        }
        .sorted { $0.records > $1.records }
    }
}
