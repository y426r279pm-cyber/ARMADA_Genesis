import Foundation
import SwiftData

/// The one place records change.
///
/// The prototype routes every tap through a single delegated handler so that
/// "every mutation in one place" holds, and the chain is sealed there. In
/// SwiftUI each button carries its own closure, which would scatter that — so
/// the invariant is kept deliberately: views send an `Action`, this store
/// applies it, and sealing happens here or not at all.
///
/// The pay-off over the prototype is that `Action` is a typed enum. A branch the
/// prototype could miss at runtime is a compile error here.
@Observable
@MainActor
public final class AppStore {

    // MARK: Session

    public private(set) var role: Role?
    public private(set) var user: String = "m.rios"
    public var language: Language = .es

    public enum Language: String, Sendable, CaseIterable { case en, es }

    /// Read-only roles inspect everything and change nothing; mutating controls
    /// render disabled rather than hidden.
    public var canWrite: Bool { role?.canWrite ?? false }
    public var isAdmin: Bool { role?.isAdmin ?? false }

    // MARK: The chain

    public private(set) var chain: [Seal.Entry] = []
    public private(set) var chainState: Seal.Verification = .intact(length: 0)

    // MARK: Wiring

    public let navigator = Navigator()
    public var authenticator: Authenticator
    private let context: ModelContext?

    /// The guardrails version every agent recommendation is written under.
    ///
    /// Carried on the finding rather than assumed, so a later reader knows which
    /// rules the agent was reasoning inside when it wrote what it wrote.
    public private(set) var guardrailsVersion = "1.4"

    /// The records the match rules read. Populated from the store on load.
    private var matchEvidence: [String: MatchEvidence] = [:]

    public init(context: ModelContext? = nil, authenticator: Authenticator = .system) {
        self.context = context
        self.authenticator = authenticator
    }

    /// The four records behind one case.
    ///
    /// Returns empty evidence rather than nil when a case has no records yet:
    /// the rules then fail rather than pass, which is the safe direction. A
    /// missing record is not agreement.
    public func evidence(for item: MatchCase) -> MatchEvidence {
        matchEvidence[item.id] ?? MatchEvidence()
    }

    public func setEvidence(_ evidence: [String: MatchEvidence]) { matchEvidence = evidence }

    // MARK: Actions

    /// Everything a person can do that changes a record.
    ///
    /// Read-only navigation is not here: it does not mutate, does not seal, and
    /// belongs to `Navigator`.
    public enum Action: Sendable {
        case signIn(role: Role, user: String)
        case signOut
        case setLanguage(Language)
        case pauseAccount(id: String, paused: Bool)
        case escalateAccount(id: String)
        case openIncident(title: String, severity: String)
        case assignIncident(id: String, to: String)
        case resolveCase(id: String, outcome: String)
        case takeCase(id: String)
        case caseAction(id: String, action: MatchFinding.Action)
        /// Only a passed gate can produce the payload, so this case cannot be
        /// constructed from a loose Bool somewhere down the call chain.
        case approvePayment(ApprovalGate.Approval)
    }

    /// Apply an action, seal what it did, and report what the person should see.
    ///
    /// Every branch that changes a record seals. A branch that seals nothing
    /// should be obvious in review as a branch that changed nothing.
    @discardableResult
    public func dispatch(_ action: Action) async -> Outcome {
        switch action {
        case let .signIn(role, user):
            self.role = role
            self.user = user
            navigator.reset(to: .home)
            return .ok

        case .signOut:
            role = nil
            navigator.reset(to: .login)
            return .ok

        case let .setLanguage(language):
            self.language = language
            return .ok

        case let .pauseAccount(id, paused):
            guard canWrite else { return .refused(reason: .readOnly) }
            return await seal(
                es: paused ? "cuenta pausada" : "cuenta reanudada",
                en: paused ? "account paused" : "account resumed",
                extra: [("account", .string(id))])

        case let .escalateAccount(id):
            guard canWrite else { return .refused(reason: .readOnly) }
            return await seal(es: "cuenta escalada", en: "account escalated",
                              extra: [("account", .string(id))])

        case let .openIncident(title, severity):
            guard canWrite else { return .refused(reason: .readOnly) }
            return await seal(es: "incidente abierto", en: "incident opened",
                              extra: [("title", .string(title)), ("sev", .string(severity))])

        case let .assignIncident(id, assignee):
            guard canWrite else { return .refused(reason: .readOnly) }
            return await seal(es: "incidente asignado", en: "incident assigned",
                              extra: [("incident", .string(id)), ("to", .string(assignee))])

        case let .resolveCase(id, outcome):
            guard canWrite else { return .refused(reason: .readOnly) }
            return await seal(es: "caso resuelto", en: "case resolved",
                              extra: [("case", .string(id)), ("outcome", .string(outcome))])

        case let .takeCase(id):
            guard canWrite else { return .refused(reason: .readOnly) }
            return await seal(es: "caso tomado", en: "case taken",
                              extra: [("case", .string(id))])

        case let .caseAction(id, action):
            guard canWrite else { return .refused(reason: .readOnly) }
            // The recommendation and the decision are sealed together, so the
            // record shows what was advised as well as what was done.
            return await seal(es: "acción sobre el caso", en: "case action",
                              extra: [("case", .string(id)),
                                      ("action", .string(action.rawValue)),
                                      ("guardrails", .string(guardrailsVersion))])

        case let .approvePayment(approval):
            // The gate has already refused every path that is not an explicit
            // confirmation, including an ambiguous one. Nothing is re-decided
            // here; this only records it.
            return await seal(es: "pago aprobado en la compuerta",
                              en: "payment approved at the gate",
                              extra: [("case", .string(approval.caseID)),
                                      ("approver", .string(approval.actor)),
                                      ("guardrails", .string(guardrailsVersion))])
        }
    }

    public enum Outcome: Sendable, Equatable {
        case ok
        case sealed(seq: Int)
        case refused(reason: Refusal)

        public enum Refusal: Sendable, Equatable {
            case readOnly
            /// An ambiguous timeout is never permission to act again.
            case ambiguousTimeout
            case notPermitted
        }
    }

    // MARK: Sealing

    /// Append to the chain. The only path to it.
    private func seal(es: String, en: String,
                      extra: [(key: String, value: CanonicalJSON.Value)]) async -> Outcome {
        let entry = Seal.seal(onto: chain, es: es, en: en, actor: user, extra: extra)
        chain.append(entry)
        chainState = Seal.verify(chain)
        return .sealed(seq: entry.seq)
    }

    /// Load the seeded store and verify what it carries.
    public func load(seed: SeedBundle) {
        chain = seed.ledger
        chainState = Seal.verify(chain)
    }
}
