import Foundation

/// The gate a payment approval has to pass.
///
/// Three conditions, all required: every deterministic check green, a word typed
/// by hand, and the authenticator. On Apple hardware the third is real — Touch
/// ID, Face ID or a paired Watch, with the key material in the Secure Enclave —
/// where the prototype could only draw it.
///
/// The rule that matters most is the one about timeouts. When the authenticator
/// neither confirms nor refuses — the app was backgrounded, the sensor gave up,
/// the Watch went out of range — the result is *not* approval. An ambiguous
/// timeout is never permission to pay again. That sentence is in the brief
/// because the failure it prevents is paying a supplier twice, and the reason it
/// is a type here rather than a comment is that a comment cannot fail a build.
public enum ApprovalGate {

    /// Why a gate refused. Every case is a refusal; there is no ambiguous
    /// success, which is the whole design.
    public enum Refusal: Sendable, Equatable {
        /// Checks are still failing. The rules said no before anybody was asked.
        case checksFailing(rules: [String])
        /// The typed word did not match.
        case wordMismatch
        /// The person declined, or the system refused them.
        case authenticationFailed
        /// The authenticator neither confirmed nor refused.
        ///
        /// Treated as a refusal, always. Retrying is a person's decision, made
        /// again from the start.
        case authenticationAmbiguous
        /// The role may inspect but not change.
        case readOnly
        /// Somebody already owns this decision.
        case notOwner(owner: String)

        public var message: String {
            switch self {
            case .checksFailing(let rules):
                "\(L("Approval needs every check green. Still failing:")) \(rules.joined(separator: ", "))"
            case .wordMismatch:
                L("The typed word did not match.")
            case .authenticationFailed:
                L("The authenticator refused.")
            case .authenticationAmbiguous:
                L("The authenticator neither confirmed nor refused, so nothing was approved. An ambiguous timeout is never permission to pay again.")
            case .readOnly:
                Key.readonly.string
            case .notOwner(let owner):
                "\(L("This case is owned by")) \(owner)."
            }
        }
    }

    /// What the authenticator said. Modelled with an explicit third case so that
    /// "not a failure" can never be mistaken for "a success".
    public enum AuthenticationResult: Sendable, Equatable {
        case confirmed
        case refused
        /// No answer: cancelled, backgrounded, timed out, sensor unavailable.
        case ambiguous
    }

    /// The word a person types to confirm. Deliberately not "yes" or "ok": it
    /// has to be typed deliberately, and it names what is being done.
    public static let confirmationWord = "APROBAR"

    public struct Request: Sendable {
        public var caseID: String
        public var owner: String
        public var actor: String
        public var checks: [MatchRules.Check]
        public var typedWord: String
        public var canWrite: Bool

        public init(caseID: String, owner: String, actor: String,
                    checks: [MatchRules.Check], typedWord: String, canWrite: Bool) {
            self.caseID = caseID
            self.owner = owner
            self.actor = actor
            self.checks = checks
            self.typedWord = typedWord
            self.canWrite = canWrite
        }
    }

    /// Everything that can be decided before the authenticator is asked.
    ///
    /// Asking a person for a fingerprint and *then* telling them a check was red
    /// wastes their attention and teaches them the gate is theatre.
    public static func precheck(_ request: Request) -> Refusal? {
        guard request.canWrite else { return .readOnly }
        if !request.owner.isEmpty, request.owner != request.actor {
            return .notOwner(owner: request.owner)
        }
        let failing = request.checks.filter { !$0.passed }.map(\.rule)
        if !failing.isEmpty { return .checksFailing(rules: failing) }
        guard request.typedWord.trimmingCharacters(in: .whitespacesAndNewlines)
                .caseInsensitiveCompare(confirmationWord) == .orderedSame else {
            return .wordMismatch
        }
        return nil
    }

    /// The whole gate: precheck, then the authenticator, then a decision.
    ///
    /// `authenticate` is injected so the rule about ambiguity can be tested
    /// without a fingerprint sensor — which is the only way to test it at all.
    public static func evaluate(
        _ request: Request,
        authenticate: () async -> AuthenticationResult
    ) async -> Result<Approval, Refusal> {
        if let refusal = precheck(request) { return .failure(refusal) }
        switch await authenticate() {
        case .confirmed:
            return .success(Approval(caseID: request.caseID, actor: request.actor))
        case .refused:
            return .failure(.authenticationFailed)
        case .ambiguous:
            return .failure(.authenticationAmbiguous)
        }
    }

    /// A passed gate. Only this type may reach the sealing path, so an approval
    /// cannot be fabricated from a Bool somewhere further down.
    public struct Approval: Sendable, Equatable {
        public let caseID: String
        public let actor: String
    }
}
