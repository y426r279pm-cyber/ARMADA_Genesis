import XCTest
@testable import BridgeKit

/// The approval gate.
///
/// The rule this file exists for is the one about ambiguity: when the
/// authenticator neither confirms nor refuses, nothing is approved. The failure
/// it prevents is paying a supplier twice, and a comment cannot fail a build.
final class ApprovalGateTests: XCTestCase {

    func passing() -> [MatchRules.Check] {
        MatchRules.run(MatchEvidence(orderedQty: 100, orderedPrice: 85, orderedTotal: 8500,
                                     receivedQty: 100, billedQty: 100, billedPrice: 85,
                                     billedTotal: 8500, billedUUID: "U-1", billedRFC: "R-1",
                                     satStatus: "vigente", supplierRFC: "R-1",
                                     supplierStatus: "ok"))
    }

    func request(word: String = ApprovalGate.confirmationWord,
                 owner: String = "", actor: String = "m.rios",
                 canWrite: Bool = true,
                 checks: [MatchRules.Check]? = nil) -> ApprovalGate.Request {
        ApprovalGate.Request(caseID: "CASE-105", owner: owner, actor: actor,
                             checks: checks ?? passing(), typedWord: word, canWrite: canWrite)
    }

    // MARK: The rule that matters

    /// An ambiguous timeout is never permission to pay again.
    func testAmbiguousAuthenticationIsRefusedNotApproved() async {
        let result = await ApprovalGate.evaluate(request()) { .ambiguous }
        guard case .failure(let why) = result else {
            return XCTFail("an ambiguous authenticator must never approve")
        }
        XCTAssertEqual(why, .authenticationAmbiguous)
    }

    /// And it is not quietly a success either: nothing but `.confirmed` approves.
    func testOnlyAnExplicitConfirmationApproves() async {
        for outcome in [ApprovalGate.AuthenticationResult.refused, .ambiguous] {
            let result = await ApprovalGate.evaluate(request()) { outcome }
            if case .success = result {
                XCTFail("\(outcome) must not approve")
            }
        }
        let confirmed = await ApprovalGate.evaluate(request()) { .confirmed }
        guard case .success(let approval) = confirmed else {
            return XCTFail("a confirmed authenticator should approve")
        }
        XCTAssertEqual(approval.caseID, "CASE-105")
        XCTAssertEqual(approval.actor, "m.rios")
    }

    /// A device that cannot ask is ambiguous, not a pass.
    func testAnUnavailableAuthenticatorDoesNotApprove() async {
        let result = await ApprovalGate.evaluate(request()) {
            await Authenticator.always(.ambiguous).evaluate("reason")
        }
        if case .success = result { XCTFail("an unavailable authenticator must not approve") }
    }

    // MARK: Everything decided before the sensor

    /// A red check blocks before anybody is asked for a fingerprint. Asking and
    /// then refusing teaches people the gate is theatre.
    func testFailingChecksBlockBeforeAuthentication() async {
        var evidence = MatchEvidence(receivedQty: 100, billedQty: 140)
        evidence.satStatus = "vigente"
        var asked = false
        let result = await ApprovalGate.evaluate(request(checks: MatchRules.run(evidence))) {
            asked = true
            return .confirmed
        }
        XCTAssertFalse(asked, "the authenticator must not be reached with checks failing")
        guard case .failure(.checksFailing(let rules)) = result else {
            return XCTFail("expected a checks-failing refusal")
        }
        XCTAssertTrue(rules.contains("M-01"))
    }

    func testTheWordMustMatch() {
        XCTAssertEqual(ApprovalGate.precheck(request(word: "yes")), .wordMismatch)
        XCTAssertEqual(ApprovalGate.precheck(request(word: "")), .wordMismatch)
        XCTAssertNil(ApprovalGate.precheck(request(word: "aprobar")),
                     "case and surrounding space should not matter; the deliberation does")
        XCTAssertNil(ApprovalGate.precheck(request(word: "  APROBAR  ")))
    }

    func testReadOnlyRolesCannotApprove() {
        XCTAssertEqual(ApprovalGate.precheck(request(canWrite: false)), .readOnly)
    }

    /// One owning case. Somebody else's decision is not yours to make, which is
    /// how two agents are prevented from opening two disputes on one invoice.
    func testOnlyTheOwnerMayApprove() {
        XCTAssertEqual(ApprovalGate.precheck(request(owner: "a.luna", actor: "m.rios")),
                       .notOwner(owner: "a.luna"))
        XCTAssertNil(ApprovalGate.precheck(request(owner: "m.rios", actor: "m.rios")))
        XCTAssertNil(ApprovalGate.precheck(request(owner: "", actor: "m.rios")),
                     "an unclaimed case may be taken")
    }

    /// Refusals explain themselves. A gate that says only "no" gets worked
    /// around rather than understood.
    func testEveryRefusalCarriesAMessage() {
        let refusals: [ApprovalGate.Refusal] = [
            .checksFailing(rules: ["M-01"]), .wordMismatch, .authenticationFailed,
            .authenticationAmbiguous, .readOnly, .notOwner(owner: "a.luna"),
        ]
        for refusal in refusals {
            XCTAssertFalse(refusal.message.isEmpty, "\(refusal) has no message")
        }
        XCTAssertTrue(ApprovalGate.Refusal.authenticationAmbiguous.message
            .lowercased().contains("never"),
            "the ambiguity refusal should say plainly that it is never permission")
    }

    // MARK: What reaches the chain

    /// A passed gate seals, and a refused one seals nothing.
    @MainActor
    func testApprovalSealsAndRefusalDoesNot() async {
        let store = AppStore(authenticator: .always(.ambiguous))
        await store.dispatch(.signIn(role: .enterprise, user: "m.rios"))
        let before = store.chain.count

        let refused = await ApprovalGate.evaluate(request()) {
            await store.authenticator.evaluate("reason")
        }
        if case .success = refused { XCTFail("should have refused") }
        XCTAssertEqual(store.chain.count, before, "a refused gate must seal nothing")

        let approval = ApprovalGate.Approval(caseID: "CASE-105", actor: "m.rios")
        let outcome = await store.dispatch(.approvePayment(approval))
        XCTAssertEqual(outcome, .sealed(seq: before + 1))
        XCTAssertTrue(store.chainState.isIntact)
    }

    /// The seal records who approved and under which guardrails, so the decision
    /// can be read back with the rules it was made under.
    @MainActor
    func testTheSealRecordsApproverAndGuardrails() async {
        let store = AppStore()
        await store.dispatch(.signIn(role: .enterprise, user: "m.rios"))
        await store.dispatch(.approvePayment(.init(caseID: "CASE-105", actor: "m.rios")))
        let entry = try? XCTUnwrap(store.chain.last)
        let keys = entry?.extra.map(\.key) ?? []
        XCTAssertEqual(keys, ["case", "approver", "guardrails"])
    }
}
