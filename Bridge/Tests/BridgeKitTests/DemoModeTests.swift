import XCTest
@testable import BridgeKit

/// The client build, audited.
///
/// Daniel's section 7 forbids node counts, model names, bills of materials and
/// prices before a signed discovery agreement. RC1 broke four of those rules.
/// These tests are what stops RC2's answer from being a promise.
///
/// The check that matters most runs against the *redacted seed file itself*,
/// not against a running app: a demo mode that hides a name still ships it, and
/// a resource in the bundle is reachable by a screenshot, a crash log, or
/// anybody who opens the app package.
final class DemoModeTests: XCTestCase {

    /// Both seeds ship with BridgeKit, not with the tests, so the library's
    /// bundle is the one to ask. `SeedBundle` exposes it for exactly this.
    func seedText(_ resource: String) throws -> String {
        let url = try XCTUnwrap(SeedBundle.resourceURL(resource),
                                "\(resource).json missing; run tools/redact_seed.py")
        return try String(contentsOf: url, encoding: .utf8)
    }

    // MARK: The redacted seed

    /// No forbidden name survives into the client seed.
    func testTheClientSeedCarriesNoModelName() throws {
        let text = try seedText("Seed.client")
        for name in DemoMode.forbiddenInClientBuild {
            XCTAssertFalse(text.range(of: "\\b\(name)\\b",
                                      options: [.regularExpression, .caseInsensitive]) != nil,
                           "'\(name)' survives into Seed.client.json")
        }
    }

    /// The internal seed *does* carry them, which is what makes the test above
    /// meaningful. Without this, a redactor that emptied the file would pass.
    func testTheInternalSeedStillCarriesThem() throws {
        let text = try seedText("Seed")
        XCTAssertTrue(text.range(of: "\\bKimi\\b", options: [.regularExpression, .caseInsensitive]) != nil,
                      "the internal seed should be unredacted; if not, the redaction test proves nothing")
    }

    /// Same console, not a smaller one. A client demo that shows fewer records
    /// is a demo of a different product.
    func testTheClientSeedHasTheSameShape() throws {
        let internalSeed = try JSONSerialization.jsonObject(
            with: Data(try seedText("Seed").utf8)) as? [String: Any] ?? [:]
        let clientSeed = try JSONSerialization.jsonObject(
            with: Data(try seedText("Seed.client").utf8)) as? [String: Any] ?? [:]

        for (store, value) in internalSeed {
            guard let rows = value as? [Any] else { continue }
            let clientRows = clientSeed[store] as? [Any]
            XCTAssertEqual(clientRows?.count, rows.count,
                           "store '\(store)' has a different record count in the client seed")
        }
    }

    /// Node roles are neutral in the client seed.
    func testClientNodeRolesAreNeutral() throws {
        let seed = try JSONSerialization.jsonObject(
            with: Data(try seedText("Seed.client").utf8)) as? [String: Any] ?? [:]
        let nodes = seed["nodes"] as? [[String: Any]] ?? []
        XCTAssertFalse(nodes.isEmpty)
        for node in nodes {
            let role = node["role"] as? String ?? ""
            XCTAssertFalse(role.isEmpty, "a node with no role reads as missing data")
            for name in DemoMode.forbiddenInClientBuild {
                XCTAssertFalse(role.localizedCaseInsensitiveContains(name),
                               "node role '\(role)' names a model")
            }
        }
    }

    // MARK: The redaction helpers

    /// A vaguer count is still a count. "the rack" is not "around twenty".
    func testNodeCountIsReplacedNotBlurred() {
        if DemoMode.isClientBuild {
            XCTAssertEqual(DemoMode.nodeCount(17), L("the rack"))
            XCTAssertEqual(DemoMode.nodeCount(17, of: 17), L("the rack"))
            XCTAssertFalse(DemoMode.nodeCount(17).contains("17"))
        } else {
            XCTAssertEqual(DemoMode.nodeCount(17), "17")
            XCTAssertEqual(DemoMode.nodeCount(16, of: 17), "16/17")
        }
    }

    func testModelNamesBecomeTheTwoNeutralNames() {
        guard DemoMode.isClientBuild else {
            XCTAssertEqual(DemoMode.modelName("Kimi K2 Thinking"), "Kimi K2 Thinking",
                           "the internal build shows the real name")
            return
        }
        XCTAssertEqual(DemoMode.modelName("Kimi K2 Thinking"), L("escalation model"))
        XCTAssertEqual(DemoMode.modelName("Llama 4"), L("routine model"))
        for name in ["Kimi K2 Thinking", "Llama 4", "Qwen 2.5"] {
            XCTAssertFalse(DemoMode.modelName(name).localizedCaseInsensitiveContains(
                name.split(separator: " ").first.map(String.init) ?? name))
        }
    }

    /// Configuration and the catalogue are absent, not empty. An emptied screen
    /// invites the question of what was removed.
    func testForbiddenScreensAreHiddenNotEmptied() {
        for screen in DemoMode.hiddenScreens {
            XCTAssertEqual(DemoMode.canShow(screen), !DemoMode.isClientBuild,
                           "\(screen.rawValue) should be absent from a client build")
        }
        XCTAssertEqual(DemoMode.showsConfiguration, !DemoMode.isClientBuild)
        XCTAssertEqual(DemoMode.showsModelCatalogue, !DemoMode.isClientBuild)
    }

    /// The seed the app loads follows the build, so the two steps cannot drift.
    func testTheSeedResourceFollowsTheBuild() {
        XCTAssertEqual(DemoMode.seedResource, DemoMode.isClientBuild ? "Seed.client" : "Seed")
    }

    /// Every figure is labelled in both builds. The rule is about not showing a
    /// result before one is measured, and that applies internally too.
    func testEveryFigureIsLabelledInBothBuilds() {
        XCTAssertTrue(DemoMode.labelsEveryFigureAsSample)
    }
}

/// The field validators.
final class ValidatorTests: XCTestCase {

    /// Verified against two published CLABEs. The check digit is the point: a
    /// form that accepts eighteen plausible digits and a bank that refuses them
    /// is a failure discovered days later by the person who typed them.
    func testCLABEChecksItsCheckDigit() {
        XCTAssertTrue(Validator.clabe("002010077777777771").isValid)
        XCTAssertTrue(Validator.clabe("032180000118359719").isValid)
        XCTAssertFalse(Validator.clabe("002010077777777772").isValid,
                       "a wrong check digit must not pass")
        XCTAssertFalse(Validator.clabe("00201007777777777").isValid, "17 digits")
        XCTAssertFalse(Validator.clabe("").isValid)
    }

    func testRFCShape() {
        XCTAssertTrue(Validator.rfc("ABN990101AB1").isValid, "company: 12")
        XCTAssertTrue(Validator.rfc("RIOM850101HN4").isValid, "person: 13")
        XCTAssertFalse(Validator.rfc("ABN99").isValid)
        XCTAssertFalse(Validator.rfc("ABN9901O1AB1X").isValid)
    }

    func testURLAndHostAndPort() {
        XCTAssertTrue(Validator.url("https://api.finkok.com/servicios/soap").isValid)
        XCTAssertFalse(Validator.url("ftp://example.com").isValid)
        XCTAssertFalse(Validator.url("not a url").isValid)

        XCTAssertTrue(Validator.host("bridge.armada.local").isValid)
        XCTAssertFalse(Validator.host("not a host").isValid)

        XCTAssertTrue(Validator.port("443").isValid)
        XCTAssertFalse(Validator.port("0").isValid)
        XCTAssertFalse(Validator.port("65536").isValid)
        XCTAssertFalse(Validator.port("https").isValid)
    }

    func testPEMShape() {
        XCTAssertTrue(Validator.pem("-----BEGIN CERTIFICATE-----\nMIIB\n-----END CERTIFICATE-----").isValid)
        XCTAssertFalse(Validator.pem("MIIB").isValid)
    }

    /// Every refusal explains itself. A validator that says only "invalid" gets
    /// worked around rather than understood.
    func testEveryRefusalCarriesAMessage() {
        let refusals = [Validator.clabe("1"), Validator.rfc("x"), Validator.url("x"),
                        Validator.host("a b"), Validator.port("x"), Validator.pem("x"),
                        Validator.text("  "), Validator.secret("x")]
        for refusal in refusals {
            XCTAssertFalse(refusal.isValid)
            XCTAssertFalse(refusal.message.isEmpty)
        }
    }
}

/// Policy versioning and the clause diff.
final class PolicyTests: XCTestCase {

    func testVersionBumps() {
        XCTAssertEqual(Policies.nextVersion(after: "1.4", major: false), "1.5")
        XCTAssertEqual(Policies.nextVersion(after: "1.4", major: true), "2.0")
        XCTAssertEqual(Policies.nextVersion(after: "2.0", major: false), "2.1")
    }

    /// Reflowing a paragraph is not a rewrite of every line in it, so the diff
    /// works in clauses rather than lines.
    func testReflowingIsNotAChange() {
        let before = "1. Los agentes se identifican\n   como software."
        let after = "1. Los agentes se identifican como software."
        let changes = Policies.diff(before, after)
        XCTAssertTrue(changes.allSatisfy { $0.kind == .unchanged },
                      "whitespace alone is not a change")
    }

    func testAChangedClauseIsReportedWithItsPrevious() {
        let before = "1. Uno.\n2. Dos."
        let after = "1. Uno.\n2. Dos, con detalle."
        let changes = Policies.diff(before, after)
        let changed = changes.filter { $0.kind == .changed }
        XCTAssertEqual(changed.count, 1)
        XCTAssertEqual(changed.first?.previous, "2. Dos.")
    }

    func testAddedAndRemovedClauses() {
        XCTAssertEqual(Policies.diff("1. Uno.", "1. Uno.\n2. Dos.")
            .filter { $0.kind == .added }.count, 1)
        XCTAssertEqual(Policies.diff("1. Uno.\n2. Dos.", "1. Uno.")
            .filter { $0.kind == .removed }.count, 1)
    }

    func testSummaryReadsPlainlyWhenNothingChanged() {
        XCTAssertEqual(Policies.summary(of: Policies.diff("1. Uno.", "1. Uno.")), L("No change."))
    }
}
