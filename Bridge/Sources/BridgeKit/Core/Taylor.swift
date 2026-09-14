import Foundation

/// Taylor: who answers, and under what conditions.
///
/// The prototype tries rails in order and takes the first that works. That is
/// right for a browser prototype and wrong here, for one reason: the ladder
/// crosses from a rail that keeps text on the machine to rails that post it to
/// somebody else's server. Falling through that boundary on a timeout would send
/// institutional material off-device because a local model was slow, and nobody
/// would be told.
///
/// So the boundary is not a position in a list. `Taylor` will fall back freely
/// among on-device rails, and will *never* cross to an off-device rail unless
/// the person has said so for this conversation. When no on-device rail can
/// answer and consent has not been given, it says so and stops.
@Observable
@MainActor
public final class Taylor {

    /// Whether answers may leave the machine, and on whose say-so.
    public enum OffDeviceConsent: Sendable, Equatable {
        /// The default. Nothing leaves.
        case withheld
        /// Granted for this conversation, deliberately, after being asked.
        case grantedForThisConversation
    }

    public private(set) var turns: [Turn] = []
    public private(set) var isAnswering = false
    public private(set) var lastError: String?
    public var consent: OffDeviceConsent = .withheld

    /// Set when an answer could not be given locally and consent is withheld.
    /// The chat turns this into a question rather than an error.
    public private(set) var awaitingConsent = false

    private let device: DeviceModel
    private let keyed: [KeyedRail]

    public init(device: DeviceModel, keyed: [KeyedRail] = KeyedRail.Flavour.allCases.map {
        KeyedRail(flavour: $0)
    }) {
        self.device = device
        self.keyed = keyed
    }

    /// How Taylor introduces herself.
    ///
    /// Institution-neutral by design: the same console is shown to more than one
    /// institution, and a greeting naming one of them in front of another is the
    /// kind of detail that ends a conversation.
    public var greeting: String {
        L("I am Taylor. I answer from the records this console holds, and every reply says where it came from.")
    }

    /// The system turn every conversation starts with.
    ///
    /// It states the limits rather than implying them. An assistant that will be
    /// asked about fiscal documents should not be free to sound certain about
    /// their validity.
    var systemTurn: Turn {
        Turn(who: .system, text: [
            L("You are Taylor, a software assistant inside a private console."),
            L("Answer from the records you are given. Say plainly when you do not know."),
            L("Never state that a document is fiscally valid: the console witnesses what was recorded and does not rule on validity."),
            L("Never claim to have taken an action. You recommend; a person decides."),
        ].joined(separator: " "))
    }

    public func start(_ existing: [Turn] = []) {
        turns = existing
        lastError = nil
        awaitingConsent = false
    }

    /// Ask a question and stream the reply.
    public func ask(_ question: String) async {
        let trimmed = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isAnswering else { return }
        lastError = nil
        awaitingConsent = false
        turns.append(Turn(who: .person, text: trimmed))
        await answer()
    }

    /// Grant consent and retry the question that needed it.
    public func grantConsentAndRetry() async {
        consent = .grantedForThisConversation
        awaitingConsent = false
        await answer()
    }

    private func answer() async {
        isAnswering = true
        defer { isAnswering = false }

        let context = [systemTurn] + turns
        var failures: [String] = []

        for rail in await availableRails() {
            let index = turns.count
            turns.append(Turn(who: .taylor, text: "", provenance: rail.provenance))
            do {
                let text = try await rail.answer(context) { [weak self] delta in
                    Task { @MainActor in
                        guard let self, self.turns.indices.contains(index) else { return }
                        self.turns[index].text += delta
                    }
                }
                if turns.indices.contains(index) {
                    turns[index].text = text
                    turns[index].provenance = rail.provenance
                }
                return
            } catch {
                // Drop the half-written reply rather than leaving a stub that
                // reads as an answer.
                if turns.indices.contains(index) { turns.remove(at: index) }
                failures.append("\(rail.name): \((error as? RailError)?.message ?? error.localizedDescription)")
            }
        }

        // Nothing on-device could answer. Ask before crossing, never assume.
        if consent == .withheld, await hasAnOffDeviceRail() {
            awaitingConsent = true
            lastError = failures.isEmpty ? nil : failures.joined(separator: " · ")
            return
        }
        lastError = failures.isEmpty
            ? L("No rail is ready. Load the local model, or add a key in Settings.")
            : failures.joined(separator: " · ")
    }

    /// The rails that may answer right now, in order.
    ///
    /// On-device first, always. Off-device rails appear only once consent has
    /// been given for this conversation.
    func availableRails() async -> [any Rail] {
        var rails: [any Rail] = []
        let local = DeviceRail(model: device)
        if await local.isReady { rails.append(local) }
        if consent == .grantedForThisConversation {
            for rail in keyed {
                if await rail.isReady { rails.append(rail) }
            }
        }
        return rails
    }

    func hasAnOffDeviceRail() async -> Bool {
        for rail in keyed {
            if await rail.isReady { return true }
        }
        return false
    }

    /// What the person is being asked to agree to, named precisely.
    public var consentQuestion: String {
        L("No model on this device can answer right now. A keyed rail can, but the conversation would be sent to that provider's servers and would leave this machine. Send it?")
    }
}
