import XCTest
@testable import BridgeKit

/// Taylor, and the boundary that matters.
///
/// The prototype tries rails in order and takes the first that works. Here the
/// ladder must not cross from a rail that keeps text on the machine to one that
/// posts it elsewhere without the person saying so — falling through on a
/// timeout would send institutional material off-device because a local model
/// was slow, and nobody would be told. These tests exist to keep that true
/// through every later refactor.
@MainActor
final class TaylorTests: XCTestCase {

    /// An engine that answers instantly with a fixed string.
    func workingEngine(_ reply: String = "local reply") -> LocalEngine {
        LocalEngine(isPresent: { _ in true },
                    load: { _, progress in progress(1.0) },
                    generate: { _, onDelta in onDelta(reply); return reply })
    }

    /// An engine that is present and loads, then refuses to answer.
    func failingEngine() -> LocalEngine {
        LocalEngine(isPresent: { _ in true },
                    load: { _, progress in progress(1.0) },
                    generate: { _, _ in throw RailError.timedOut })
    }

    func taylor(engine: LocalEngine, keyed: [KeyedRail] = []) async -> Taylor {
        let device = DeviceModel(engine: engine)
        await device.load(preferring: .fallback)
        return Taylor(device: device, keyed: keyed)
    }

    // MARK: The boundary

    /// With no consent, an off-device rail is never even offered to the ladder.
    func testOffDeviceRailsAreAbsentWithoutConsent() async {
        let taylor = await taylor(engine: workingEngine(),
                                  keyed: [KeyedRail(flavour: .openai)])
        let rails = await taylor.availableRails()
        XCTAssertTrue(rails.allSatisfy { !$0.leavesDevice },
                      "no rail that leaves the device may appear before consent")
    }

    /// And a local failure does not quietly become an off-device answer.
    func testALocalFailureDoesNotFallOffTheDevice() async {
        let taylor = await taylor(engine: failingEngine(),
                                  keyed: [KeyedRail(flavour: .openai)])
        await taylor.ask("what is open?")

        XCTAssertFalse(taylor.turns.contains { $0.provenance?.leavesDevice == true },
                       "nothing may be answered off-device without consent")
        XCTAssertTrue(taylor.awaitingConsent,
                      "the person should be asked rather than the question silently failing")
    }

    /// Consent is per conversation and has to be given, not defaulted.
    func testConsentIsWithheldByDefault() async {
        let taylor = await taylor(engine: workingEngine())
        XCTAssertEqual(taylor.consent, .withheld)
    }

    /// Starting a new conversation does not inherit the last one's consent.
    func testNewConversationDoesNotInheritConsent() async {
        let taylor = await taylor(engine: workingEngine())
        taylor.consent = .grantedForThisConversation
        let fresh = Taylor(device: DeviceModel(engine: workingEngine()))
        XCTAssertEqual(fresh.consent, .withheld)
    }

    /// The question asked before crossing names what actually happens.
    func testTheConsentQuestionSaysWhatItMeans() async {
        let taylor = await taylor(engine: workingEngine())
        let question = taylor.consentQuestion.lowercased()
        XCTAssertTrue(question.contains("leave this machine") || question.contains("salir")
                      || question.contains("saldría"),
                      "the question must say that the text leaves the machine")
    }

    // MARK: Provenance

    /// Every reply carries where it came from. A reply without provenance would
    /// quietly undo the claim the product is built on.
    func testEveryReplyCarriesProvenance() async {
        let taylor = await taylor(engine: workingEngine())
        await taylor.ask("hello")
        let replies = taylor.turns.filter { $0.who == .taylor }
        XCTAssertFalse(replies.isEmpty)
        for reply in replies {
            XCTAssertNotNil(reply.provenance, "a reply with no provenance is a defect")
            XCTAssertEqual(reply.provenance?.leavesDevice, false)
        }
    }

    func testProvenanceLabelDistinguishesOnAndOffDevice() {
        let local = Provenance(railID: "device", railName: "this device",
                               modelName: "Qwen", leavesDevice: false)
        let remote = Provenance(railID: "openai", railName: "OpenAI",
                                modelName: "gpt", leavesDevice: true)
        XCTAssertNotEqual(local.label, remote.label)
        XCTAssertTrue(remote.label.contains(L("left this device")))
        XCTAssertTrue(local.label.contains(L("on this device")))
    }

    /// Keyed rails are off-device whoever runs them.
    func testEveryKeyedRailLeavesTheDevice() {
        for flavour in KeyedRail.Flavour.allCases {
            XCTAssertTrue(KeyedRail(flavour: flavour).leavesDevice, "\(flavour) must be off-device")
        }
    }

    // MARK: Conversation

    func testAQuestionAndItsAnswerAreBothKept() async {
        let taylor = await taylor(engine: workingEngine("the answer"))
        await taylor.ask("the question")
        let visible = taylor.turns.filter { $0.who != .system }
        XCTAssertEqual(visible.map(\.who), [.person, .taylor])
        XCTAssertEqual(visible.last?.text, "the answer")
    }

    func testEmptyQuestionsAreIgnored() async {
        let taylor = await taylor(engine: workingEngine())
        await taylor.ask("   ")
        XCTAssertTrue(taylor.turns.isEmpty)
    }

    /// A failed rail leaves no half-written reply behind: a stub bubble reads as
    /// an answer.
    func testAFailedRailLeavesNoStubReply() async {
        let taylor = await taylor(engine: failingEngine())
        await taylor.ask("hello")
        XCTAssertFalse(taylor.turns.contains { $0.who == .taylor },
                       "a failed rail must not leave an empty reply")
        XCTAssertEqual(taylor.turns.filter { $0.who == .person }.count, 1)
    }

    /// The system turn states the limits rather than implying them.
    func testTheSystemTurnForbidsValidityClaims() async {
        let taylor = await taylor(engine: workingEngine())
        let text = taylor.systemTurn.text.lowercased()
        XCTAssertTrue(text.contains("valid") || text.contains("válid") || text.contains("valid"),
                      "the system turn should address fiscal validity")
        XCTAssertTrue(text.contains("person decides") || text.contains("persona decide"),
                      "the system turn should say a person decides")
    }

    /// Taylor introduces herself without naming an institution. The same console
    /// is shown to more than one, and a greeting naming the wrong one ends a
    /// conversation.
    func testTheGreetingNamesNoInstitution() async {
        let greeting = await taylor(engine: workingEngine()).greeting
        for name in ["FEMSA", "OXXO", "Banregio", "Coca-Cola", "Spin"] {
            XCTAssertFalse(greeting.localizedCaseInsensitiveContains(name),
                           "the greeting must stay institution-neutral; found \(name)")
        }
    }
}

/// The memory budget behind the on-device model.
final class DeviceModelTests: XCTestCase {

    /// Settled against a 16 GB machine: 7 to 9 GB of budget after everything
    /// else, and the low end is the one to plan for.
    func testRecommendationFollowsAvailableMemory() {
        let roomy = MemoryReport(physicalGB: 16, availableGB: 9)
        XCTAssertEqual(roomy.recommended, .primary)

        let tight = MemoryReport(physicalGB: 16, availableGB: 3.5)
        XCTAssertEqual(tight.recommended, .fallback,
                       "a loaded machine should get the model that runs, not the bigger one")

        let full = MemoryReport(physicalGB: 16, availableGB: 1.0)
        XCTAssertNil(full.recommended, "better to say no than to swap mid-answer")
        XCTAssertFalse(full.advice.isEmpty)
    }

    /// The headroom is deliberate, not spare capacity to spend.
    func testThePrimaryModelLeavesRoomOnASixteenGigMachine() {
        XCTAssertLessThan(DeviceModelChoice.primary.totalGB, 7.0,
                          "the full model plus its working set must fit the low end of the budget")
        XCTAssertLessThan(DeviceModelChoice.fallback.totalGB,
                          DeviceModelChoice.primary.totalGB)
    }

    /// Weights are never fetched mid-session. A four-gigabyte download in front
    /// of a client is not recoverable.
    /// A small reference box, because a `@Sendable` closure cannot capture a
    /// mutable local.
    final class Flag: @unchecked Sendable {
        var raised = false
    }

    @MainActor
    func testAMissingModelIsReportedRatherThanDownloaded() async {
        let askedToLoad = Flag()
        let absent = LocalEngine(isPresent: { _ in false },
                                 load: { _, _ in askedToLoad.raised = true },
                                 generate: { _, _ in "" })
        let model = DeviceModel(engine: absent)
        await model.load(preferring: .fallback)

        XCTAssertFalse(askedToLoad.raised, "absent weights must not trigger a download")
        guard case .notPresent = model.state else {
            return XCTFail("expected .notPresent, got \(model.state)")
        }
    }

    @MainActor
    func testAnUnavailableEngineFailsHonestly() async {
        let model = DeviceModel(engine: .unavailable)
        await model.load(preferring: .primary)
        XCTAssertFalse(model.state.isReady)
        XCTAssertFalse(model.state.label.isEmpty)
    }

    @MainActor
    func testAReadyModelReportsItsChoice() async {
        let engine = LocalEngine(isPresent: { _ in true },
                                 load: { _, progress in progress(1.0) },
                                 generate: { _, _ in "x" })
        let model = DeviceModel(engine: engine)
        await model.load(preferring: .primary)
        XCTAssertTrue(model.state.isReady)
        XCTAssertEqual(model.choice, .primary)
    }
}
