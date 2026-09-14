import Foundation
import CryptoKit

/// The sealed chain.
///
/// Every mutation in Bridge is witnessed by an entry here, and each entry's hash
/// covers the one before it, so an altered record breaks every seal after it.
///
/// What the seal proves, and what it does not: it witnesses that what was
/// recorded was not altered afterwards. It never proves that everything was
/// recorded, and it confers no fiscal validity on anything it seals. The RC2
/// brief is explicit about both limits and `StringAuditTests` enforces that no
/// string in the app claims otherwise.
public struct Seal: Sendable {

    /// One entry, in the prototype's field order.
    public struct Entry: Sendable, Identifiable, Equatable {
        public var id: String
        public var seq: Int
        public var at: String            // ISO 8601, as written; never reformatted
        public var actor: String
        public var es: String
        public var en: String
        public var extra: [(key: String, value: CanonicalJSON.Value)]
        public var prevHash: String
        public var hash: String

        public static func == (a: Entry, b: Entry) -> Bool { a.hash == b.hash && a.seq == b.seq }
    }

    /// Field names the chain reserves, in the order the prototype checks them.
    ///
    /// The order matters and is not alphabetical. An extra arriving under one of
    /// these is renamed `x_<name>`, and the prototype does that by deleting the
    /// key and re-adding it — which in JavaScript moves it to the *end* of the
    /// object. So renamed keys trail the untouched ones, ordered by this list
    /// rather than by where they appeared. Renaming in place instead produces a
    /// different byte sequence and therefore a different hash.
    public static let reservedOrder = ["id", "seq", "at", "actor", "es", "en", "prevHash", "hash"]
    public static let reserved = Set(reservedOrder)

    /// Apply the reserved-name rename exactly as the prototype's `seal` does.
    static func normalize(_ extra: [(key: String, value: CanonicalJSON.Value)])
        -> [(key: String, value: CanonicalJSON.Value)] {
        var kept = extra
        var renamed: [(key: String, value: CanonicalJSON.Value)] = []
        for name in reservedOrder {
            if let index = kept.firstIndex(where: { $0.key == name }) {
                renamed.append(("x_\(name)", kept.remove(at: index).value))
            }
        }
        return kept + renamed
    }

    /// `{ es, en, actor, ...extra }`, in that order. The order is the contract.
    public static func payload(es: String, en: String, actor: String,
                               extra: [(key: String, value: CanonicalJSON.Value)]) -> String {
        let pairs: [(key: String, value: CanonicalJSON.Value)] =
            [("es", .string(es)), ("en", .string(en)), ("actor", .string(actor))] + normalize(extra)
        return CanonicalJSON.stringify(.object(pairs))
    }

    /// `sha256(prevHash + at + actor + payload)`, hex, lowercase.
    public static func digest(prevHash: String, at: String, actor: String, payload: String) -> String {
        let input = prevHash + at + actor + payload
        return SHA256.hash(data: Data(input.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    /// Seal a new entry onto the end of `chain`.
    public static func seal(onto chain: [Entry], es: String, en: String, actor: String,
                            extra: [(key: String, value: CanonicalJSON.Value)] = [],
                            at: String = ISO8601DateFormatter.bridge.string(from: Date()),
                            id: String = UUID().uuidString) -> Entry {
        let previous = chain.max { $0.seq < $1.seq }
        let prevHash = previous?.hash ?? "genesis"
        let body = payload(es: es, en: en, actor: actor, extra: extra)
        return Entry(id: id, seq: (previous?.seq ?? 0) + 1, at: at, actor: actor,
                     es: es, en: en, extra: extra, prevHash: prevHash,
                     hash: digest(prevHash: prevHash, at: at, actor: actor, payload: body))
    }

    /// Walk the chain and report the first entry whose seal does not hold.
    public enum Verification: Sendable, Equatable {
        case intact(length: Int)
        case broken(atSeq: Int)

        public var isIntact: Bool { if case .intact = self { true } else { false } }
    }

    public static func verify(_ chain: [Entry]) -> Verification {
        var prevHash = "genesis"
        for entry in chain.sorted(by: { $0.seq < $1.seq }) {
            let body = payload(es: entry.es, en: entry.en, actor: entry.actor, extra: entry.extra)
            let expected = digest(prevHash: prevHash, at: entry.at, actor: entry.actor, payload: body)
            if entry.prevHash != prevHash || entry.hash != expected {
                return .broken(atSeq: entry.seq)
            }
            prevHash = entry.hash
        }
        return .intact(length: chain.count)
    }
}

extension ISO8601DateFormatter {
    /// `new Date().toISOString()` — UTC, milliseconds, trailing `Z`.
    public static let bridge: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        f.timeZone = TimeZone(secondsFromGMT: 0)
        return f
    }()
}
