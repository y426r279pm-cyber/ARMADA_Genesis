import XCTest
@testable import BridgeKit

/// The seed is what Bridge opens with, so what it contains is worth asserting.
/// These figures come from running the prototype's own `seed()`; if the
/// prototype changes, the extractor regenerates and these move with it.
final class SeedBundleTests: XCTestCase {

    func bundle() throws -> SeedBundle {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "Seed", withExtension: "json"),
                                "Seed.json missing; run tools/seed_harness.mjs")
        return try SeedBundle.load(from: url)
    }

    func testLedgerLoadsAndVerifies() throws {
        let seed = try bundle()
        XCTAssertFalse(seed.ledger.isEmpty)
        XCTAssertEqual(Seal.verify(seed.ledger), .intact(length: seed.ledger.count),
                       "the ledger Bridge ships with must verify on launch")
    }

    /// The extras of a seeded entry keep the order they were sealed in. Losing
    /// that order is the failure that reads as tampering.
    func testLedgerExtrasKeepTheirOrder() throws {
        let seed = try bundle()
        let first = try XCTUnwrap(seed.ledger.sorted { $0.seq < $1.seq }.first)
        let payload = Seal.payload(es: first.es, en: first.en, actor: first.actor,
                                   extra: first.extra)
        XCTAssertEqual(Seal.digest(prevHash: first.prevHash, at: first.at,
                                   actor: first.actor, payload: payload),
                       first.hash)
    }

    func testTheDemoPathHasRecordsToShow() throws {
        let seed = try bundle()
        for store in ["nodes", "power", "invoices", "users"] {
            XCTAssertFalse(seed.rows(store).isEmpty, "\(store) is empty")
        }
        XCTAssertEqual(seed.rows("nodes").count, 17, "the rack is 17 machines")
        XCTAssertEqual(seed.rows("power").count, 1, "one power spine")
    }

    /// Field access is forgiving because the prototype's stores are schemaless:
    /// a field only some records carry is normal, not an error.
    func testRowReadingHandlesMissingAndMixedFields() throws {
        let seed = try bundle()
        let invoice = try XCTUnwrap(seed.rows("invoices").first)
        XCTAssertFalse(invoice.string("uuid").isEmpty)
        XCTAssertGreaterThan(invoice.int("amount"), 0)
        XCTAssertEqual(invoice.string("nonexistent"), "")
        XCTAssertNil(invoice.optionalString("nonexistent"))
        XCTAssertEqual(invoice.int("nonexistent"), 0)
        XCTAssertFalse(invoice.bool("nonexistent"))
    }

    /// The power reading the Energy screens derive everything from.
    func testSeededPowerReadingIsComplete() throws {
        let seed = try bundle()
        let row = try XCTUnwrap(seed.rows("power").first)
        XCTAssertGreaterThan(row.double("solarKW"), 0)
        XCTAssertGreaterThan(row.int("batteryPct"), 0)
        XCTAssertGreaterThan(row.int("reservePct"), 0)
        XCTAssertFalse(row.string("grid").isEmpty)
    }

    /// Every node carries the fields the cluster map draws.
    func testEveryNodeCanBeDrawn() throws {
        for node in try bundle().rows("nodes") {
            XCTAssertFalse(node.string("id").isEmpty)
            XCTAssertFalse(node.string("role").isEmpty)
            XCTAssertFalse(node.string("status").isEmpty)
            XCTAssertGreaterThan(node.int("tempC"), 0)
            XCTAssertGreaterThan(node.int("memGB"), 0)
        }
    }

    /// The map groups by the first letter of a node id, with the admin node
    /// pulled out separately. If seeding ever produced ids that break that, the
    /// map would silently draw the wrong grouping.
    func testNodeIDsGroupIntoOctetsAndAnAdmin() throws {
        let ids = try bundle().rows("nodes").map { $0.string("id") }
        let admin = ids.filter { $0.range(of: #"^N\d+$"#, options: .regularExpression) != nil }
        XCTAssertEqual(admin.count, 1, "exactly one admin node")
        let octets = Set(ids.filter { !admin.contains($0) }.map { $0.prefix(1) })
        XCTAssertEqual(octets, ["K", "L"], "two octets: Kimi and Llama")
    }
}
