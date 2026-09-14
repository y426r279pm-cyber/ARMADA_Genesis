import XCTest
@testable import BridgeKit

/// The port's load-bearing test.
///
/// A chain sealed in the browser must verify here, and an entry sealed here must
/// verify in the browser. The expected values in `ChainFixture.json` were
/// produced by the prototype's own `seal()`, so if Swift disagrees with them,
/// Swift is wrong.
///
/// Why this is worth a file of its own: the digest covers
/// `JSON.stringify({es, en, actor, ...extra})`, and `JSON.stringify` emits keys
/// in insertion order, at every depth. Reach for `JSONEncoder` and the hashes
/// change, so an imported browser ledger reads as tampered rather than as
/// differently encoded. `tools/verify_chain.py` shows the break: sorted keys
/// fail at seq 1.
final class CanonicalSealTests: XCTestCase {

    struct Fixture: Decodable {
        struct Entry: Decodable {
            let name: String, id: String, seq: Int, at: String, actor: String
            let es: String, en: String, payload: String, prevHash: String, hash: String
        }
        let entries: [Entry]
    }

    func fixture() throws -> [Fixture.Entry] {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "ChainFixture", withExtension: "json"),
                                "ChainFixture.json missing; run tools/chain_fixture.mjs")
        return try JSONDecoder().decode(Fixture.self, from: Data(contentsOf: url)).entries
    }

    /// The extras of a recorded payload, in the order they were sealed.
    func extras(of entry: Fixture.Entry) throws -> [(key: String, value: CanonicalJSON.Value)] {
        guard case .object(let pairs) = try CanonicalJSON.parse(entry.payload) else {
            XCTFail("payload is not an object for '\(entry.name)'")
            return []
        }
        return Array(pairs.drop { ["es", "en", "actor"].contains($0.key) })
    }

    func entries() throws -> [Seal.Entry] {
        try fixture().map { row in
            Seal.Entry(id: row.id, seq: row.seq, at: row.at, actor: row.actor,
                       es: row.es, en: row.en, extra: try extras(of: row),
                       prevHash: row.prevHash, hash: row.hash)
        }
    }

    // MARK: The fixture

    /// Rebuild each payload from its parts and confirm both the bytes and the digest.
    func testPayloadsAndDigestsMatchThePrototype() throws {
        for row in try fixture() {
            // The extras are already normalised in the recorded payload, so feed
            // the raw ones back through and let normalize() prove it reproduces
            // the same order.
            let raw = try extras(of: row).map { pair -> (key: String, value: CanonicalJSON.Value) in
                pair.key.hasPrefix("x_") && Seal.reserved.contains(String(pair.key.dropFirst(2)))
                    ? (String(pair.key.dropFirst(2)), pair.value) : pair
            }
            let payload = Seal.payload(es: row.es, en: row.en, actor: row.actor, extra: raw)
            XCTAssertEqual(payload, row.payload, "payload differs for case '\(row.name)'")

            let digest = Seal.digest(prevHash: row.prevHash, at: row.at,
                                     actor: row.actor, payload: payload)
            XCTAssertEqual(digest, row.hash, "digest differs for case '\(row.name)'")
        }
    }

    func testFixtureChainVerifies() throws {
        let chain = try entries()
        XCTAssertFalse(chain.isEmpty)
        XCTAssertEqual(Seal.verify(chain), .intact(length: chain.count))
    }

    /// Altering one entry breaks its own seal, and the report names it.
    func testTamperingBreaksTheChain() throws {
        var chain = try entries()
        chain[2].en = "sealed (altered)"
        XCTAssertEqual(Seal.verify(chain), .broken(atSeq: chain[2].seq))
    }

    /// A chain sealed here continues one imported from the browser.
    func testSealingContinuesAnImportedChain() throws {
        let imported = try entries()
        let next = Seal.seal(onto: imported, es: "nuevo", en: "new", actor: "m.rios",
                             extra: [("amount", .integer(48000))],
                             at: "2026-09-14T01:00:00.000Z", id: "continued")
        XCTAssertEqual(next.seq, imported.count + 1)
        XCTAssertEqual(next.prevHash, imported.last?.hash)
        XCTAssertEqual(Seal.verify(imported + [next]), .intact(length: imported.count + 1))
    }

    // MARK: The seeded ledger the app ships with

    func testSeededLedgerIsContiguous() throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "Seed", withExtension: "json"))
        let seed = try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any]
        let rows = try XCTUnwrap(seed?["ledger"] as? [[String: Any]], "no ledger in Seed.json")
        XCTAssertFalse(rows.isEmpty, "the seeded ledger is empty")

        var prevHash = "genesis"
        for row in rows.sorted(by: { ($0["seq"] as? Int ?? 0) < ($1["seq"] as? Int ?? 0) }) {
            XCTAssertEqual(row["prevHash"] as? String, prevHash,
                           "prevHash is not contiguous at seq \(row["seq"] ?? "?")")
            prevHash = try XCTUnwrap(row["hash"] as? String)
        }
    }

    // MARK: The rules the digest depends on

    /// Reserved names are renamed *and moved to the end*, ordered by the reserved
    /// list rather than by where they appeared. The prototype does this by
    /// deleting and re-adding the key, which in JavaScript moves it. Renaming in
    /// place produces a different hash.
    func testReservedNamesMoveToTheEnd() {
        let payload = Seal.payload(es: "reservado", en: "reserved", actor: "m.rios",
                                   extra: [("seq", .integer(99)), ("hash", .string("nope")),
                                           ("other", .integer(1))])
        XCTAssertEqual(payload,
            #"{"es":"reservado","en":"reserved","actor":"m.rios","other":1,"x_seq":99,"x_hash":"nope"}"#)
    }

    /// JavaScript prints an integral double without a fractional part.
    func testNumberFormatting() {
        XCTAssertEqual(CanonicalJSON.stringify(.number(12000)), "12000")
        XCTAssertEqual(CanonicalJSON.stringify(.number(0.05)), "0.05")
        XCTAssertEqual(CanonicalJSON.stringify(.integer(0)), "0")
    }

    /// Non-ASCII passes through as UTF-8. Escaping it would change every hash in
    /// the Spanish half of the ledger.
    func testNonASCIIIsNotEscaped() {
        XCTAssertEqual(CanonicalJSON.stringify(.string("emisión")), "\"emisión\"")
        XCTAssertEqual(CanonicalJSON.stringify(.string("⟦x⟧")), "\"⟦x⟧\"")
        XCTAssertEqual(CanonicalJSON.stringify(.string("✅")), "\"✅\"")
    }

    func testControlCharactersAreEscaped() {
        XCTAssertEqual(CanonicalJSON.stringify(.string("line\nbreak\ttab")), #""line\nbreak\ttab""#)
        XCTAssertEqual(CanonicalJSON.stringify(.string("quote \" and \\ slash")),
                       #""quote \" and \\ slash""#)
    }

    // MARK: The parser

    /// Order survives a round trip at every depth, which is the whole point of
    /// not using JSONSerialization here.
    func testParseRoundTripPreservesOrderAtEveryDepth() throws {
        let text = #"{"po":"PO-1","delta":0,"nested":{"z":1,"a":[2,{"y":3,"b":4}]}}"#
        XCTAssertEqual(CanonicalJSON.stringify(try CanonicalJSON.parse(text)), text)
    }

    func testParseRoundTripsEveryFixturePayload() throws {
        for row in try fixture() {
            XCTAssertEqual(CanonicalJSON.stringify(try CanonicalJSON.parse(row.payload)), row.payload,
                           "round trip differs for case '\(row.name)'")
        }
    }

    func testParserRejectsTrailingCharacters() {
        XCTAssertThrowsError(try CanonicalJSON.parse(#"{"a":1} junk"#))
    }

    func testParserReadsEscapesAndSurrogatePairs() throws {
        XCTAssertEqual(try CanonicalJSON.parse(#""ñ""#), .string("ñ"))
        XCTAssertEqual(try CanonicalJSON.parse(#""😀""#), .string("😀"))
    }
}
