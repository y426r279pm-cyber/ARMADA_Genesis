import XCTest
@testable import BridgeKit

/// The seven deterministic rules.
///
/// These are controls, not opinions, which is exactly why they are worth
/// testing: a rule that quietly passes when it should fail is worse than no rule
/// at all, because somebody is relying on it.
final class MatchRulesTests: XCTestCase {

    /// A case where everything agrees: 100 ordered, 100 received, 100 billed at
    /// the agreed price, the right RFC, in force, not on the list, unpaid.
    var clean: MatchEvidence {
        MatchEvidence(orderedQty: 100, orderedPrice: 85, orderedTotal: 8500,
                      receivedQty: 100, receivingCentre: "DC-MTY-01",
                      billedQty: 100, billedPrice: 85, billedTotal: 8500,
                      billedUUID: "3F2A-0001", billedRFC: "ABN990101AB1",
                      satStatus: "vigente", paidAmount: nil,
                      supplierRFC: "ABN990101AB1", supplierStatus: "ok")
    }

    func check(_ rule: String, _ evidence: MatchEvidence) -> MatchRules.Check {
        MatchRules.run(evidence).first { $0.rule == rule }!
    }

    func testCleanEvidencePassesEverything() {
        let checks = MatchRules.run(clean)
        XCTAssertEqual(checks.count, 7, "M-01 through M-07")
        XCTAssertTrue(checks.allSatisfy(\.passed),
                      "failing: \(checks.filter { !$0.passed }.map(\.rule))")
    }

    // MARK: M-01 · quantity

    /// Billed is compared against *received*, not ordered. What arrived is what
    /// may be billed; an order is an intention.
    func testM01ComparesBilledAgainstReceivedNotOrdered() {
        var e = clean
        e.receivedQty = 135
        e.billedQty = 140     // the seeded case: received 135, billed 140
        XCTAssertFalse(check("M-01", e).passed)

        e.billedQty = 135
        XCTAssertTrue(check("M-01", e).passed, "billed equals received, whatever was ordered")
    }

    func testM01AllowsTwoPercent() {
        var e = clean
        e.receivedQty = 100
        e.billedQty = 102                      // exactly 2%
        XCTAssertTrue(check("M-01", e).passed)
        e.billedQty = 103
        XCTAssertFalse(check("M-01", e).passed)
    }

    /// A missing receiving record fails rather than passes. Nothing to compare
    /// against is not agreement, and treating it as one would let an unreceived
    /// delivery through the gate.
    func testM01FailsWhenThereIsNoReceivingRecord() {
        var e = clean
        e.receivedQty = nil
        XCTAssertFalse(check("M-01", e).passed,
                       "a missing record must not pass by default")
    }

    // MARK: M-02 to M-06

    func testM02CatchesAPriceDifference() {
        var e = clean
        e.billedPrice = 92
        XCTAssertFalse(check("M-02", e).passed)
    }

    func testM03CatchesAnRFCMismatch() {
        var e = clean
        e.billedRFC = "XXX010101XX0"
        XCTAssertFalse(check("M-03", e).passed)
    }

    /// The duplicate-payment control. Industry runs at 0.8 to 2 percent of
    /// disbursements, so this is a rule rather than a review step.
    func testM04CatchesARepeatedUUID() {
        var e = clean
        e.uuidSeenOnAnotherPayable = true
        XCTAssertFalse(check("M-04", e).passed)
    }

    func testM05RequiresTheCFDIToBeInForce() {
        var e = clean
        e.satStatus = "cancelado"
        XCTAssertFalse(check("M-05", e).passed)
        e.satStatus = nil
        XCTAssertFalse(check("M-05", e).passed, "unknown is not in force")
    }

    func testM06CatchesAListedIssuer() {
        var e = clean
        e.supplierStatus = "69B"
        XCTAssertFalse(check("M-06", e).passed)
        XCTAssertTrue(check("M-06", e).detail.contains("30"),
                      "the detail should name the thirty-day window")
    }

    // MARK: M-07 · payment

    /// No payment passes. A case opened before payment is the normal path, and
    /// failing it would make every early case look like a discrepancy.
    func testM07PassesWhenNothingHasBeenPaid() {
        XCTAssertTrue(check("M-07", clean).passed)
    }

    func testM07CatchesAPaymentThatDoesNotMatch() {
        var e = clean
        e.paidAmount = 9000
        XCTAssertFalse(check("M-07", e).passed)
        e.paidAmount = 8500
        XCTAssertTrue(check("M-07", e).passed)
    }

    // MARK: The finding

    /// Agreement is never approval by itself. Two records can be copies of the
    /// same wrong source, so the checks decide and the agent only explains.
    func testFindingClosesOnlyWhenEveryCheckPasses() {
        let finding = MatchFinding.from(MatchRules.run(clean), guardrailsVersion: "1.4")
        XCTAssertEqual(finding.action, .close)
        XCTAssertEqual(finding.guardrailsVersion, "1.4")
    }

    /// The first failing rule leads: an RFC mismatch is not something to
    /// investigate a price difference over.
    func testFindingFollowsTheFirstFailingRule() {
        var e = clean
        e.billedPrice = 92          // M-02
        e.billedRFC = "XXX010101XX0" // M-03
        let finding = MatchFinding.from(MatchRules.run(e), guardrailsVersion: "1.4")
        XCTAssertEqual(finding.action, .inquiry, "M-02 comes first, so it leads")
    }

    /// A probable duplicate routes rather than closes, and says to hold payment.
    func testDuplicateRoutesAndHoldsPayment() {
        var e = clean
        e.uuidSeenOnAnotherPayable = true
        let finding = MatchFinding.from(MatchRules.run(e), guardrailsVersion: "1.4")
        XCTAssertEqual(finding.action, .route)
        XCTAssertTrue(finding.text.lowercased().contains("duplicate")
                      || finding.text.lowercased().contains("duplicado"))
    }

    /// Every recommendation carries the guardrails version it was written under.
    func testEveryFindingCarriesItsGuardrailsVersion() {
        for evidence in [clean, MatchEvidence()] {
            let finding = MatchFinding.from(MatchRules.run(evidence), guardrailsVersion: "2.0")
            XCTAssertEqual(finding.guardrailsVersion, "2.0")
        }
    }

    /// Empty evidence fails almost everything rather than passing it. The safe
    /// direction for a rule with nothing to read is no.
    func testEmptyEvidenceDoesNotPass() {
        let checks = MatchRules.run(MatchEvidence())
        XCTAssertFalse(checks.allSatisfy(\.passed))
        XCTAssertFalse(checks.first { $0.rule == "M-01" }!.passed)
        XCTAssertFalse(checks.first { $0.rule == "M-05" }!.passed)
    }
}
