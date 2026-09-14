import Foundation

/// The four records a supplier case reconciles.
///
/// Purchase order — what was authorized. Receiving record — what arrived.
/// Supplier CFDI — what was billed. Bank record — what was paid. Four systems
/// of record answering four different questions, which is why a disagreement
/// between any two of them is a case rather than an error.
public struct MatchEvidence: Sendable {
    public var orderedQty: Int?
    public var orderedPrice: Int?
    public var orderedTotal: Int?
    public var receivedQty: Int?
    public var receivingCentre: String?
    public var billedQty: Int?
    public var billedPrice: Int?
    public var billedTotal: Int?
    public var billedUUID: String?
    public var billedRFC: String?
    public var satStatus: String?
    public var paidAmount: Int?
    public var supplierRFC: String?
    public var supplierStatus: String?
    public var uuidSeenOnAnotherPayable: Bool
    public var approverIsRequester: Bool

    public init(orderedQty: Int? = nil, orderedPrice: Int? = nil, orderedTotal: Int? = nil,
                receivedQty: Int? = nil, receivingCentre: String? = nil,
                billedQty: Int? = nil, billedPrice: Int? = nil, billedTotal: Int? = nil,
                billedUUID: String? = nil, billedRFC: String? = nil, satStatus: String? = nil,
                paidAmount: Int? = nil, supplierRFC: String? = nil, supplierStatus: String? = nil,
                uuidSeenOnAnotherPayable: Bool = false, approverIsRequester: Bool = false) {
        self.orderedQty = orderedQty
        self.orderedPrice = orderedPrice
        self.orderedTotal = orderedTotal
        self.receivedQty = receivedQty
        self.receivingCentre = receivingCentre
        self.billedQty = billedQty
        self.billedPrice = billedPrice
        self.billedTotal = billedTotal
        self.billedUUID = billedUUID
        self.billedRFC = billedRFC
        self.satStatus = satStatus
        self.paidAmount = paidAmount
        self.supplierRFC = supplierRFC
        self.supplierStatus = supplierStatus
        self.uuidSeenOnAnotherPayable = uuidSeenOnAnotherPayable
        self.approverIsRequester = approverIsRequester
    }
}

/// The deterministic checks, M-01 to M-07.
///
/// These are rules, not judgement. They enforce arithmetic, identifiers,
/// tolerance, permissions and duplicate prevention, and they run first and on
/// their own — the agent only investigates what they fail. The separation is the
/// point of the design: a rule that can be stated as arithmetic should never be
/// delegated to a model, and a screen that mixes the two invites reading a
/// model's opinion as a control.
///
/// Two refinements from the analysis are built in rather than assumed:
/// two agreeing records may be copies of the same wrong source, so agreement is
/// never approval by itself; and a missing record is not a pass.
public enum MatchRules {

    /// Two percent on quantity. Stated once, here.
    public static let tolerance = 0.02

    public struct Check: Sendable, Identifiable, Equatable {
        public var rule: String
        public var name: String
        public var passed: Bool
        public var detail: String
        public var id: String { rule }
    }

    public static func run(_ e: MatchEvidence) -> [Check] {
        [m01(e), m02(e), m03(e), m04(e), m05(e), m06(e), m07(e)]
    }

    /// M-01 · quantity billed within tolerance of quantity received.
    ///
    /// Against *received*, not ordered: what arrived is what may be billed.
    /// A missing receiving record fails rather than passes — nothing to compare
    /// against is not agreement.
    static func m01(_ e: MatchEvidence) -> Check {
        let passed: Bool
        if let received = e.receivedQty {
            passed = abs(Double((e.billedQty ?? 0) - received)) <= Double(received) * tolerance
        } else {
            passed = false
        }
        return Check(rule: "M-01",
                     name: L("Quantity billed within tolerance of quantity received"),
                     passed: passed,
                     detail: "\(L("ordered")) \(text(e.orderedQty)) · \(L("received")) \(text(e.receivedQty)) · \(L("billed")) \(text(e.billedQty))")
    }

    /// M-02 · unit price matches the purchase order.
    static func m02(_ e: MatchEvidence) -> Check {
        Check(rule: "M-02",
              name: L("Unit price matches the purchase order"),
              passed: e.billedPrice != nil && e.billedPrice == e.orderedPrice,
              detail: "\(L("order")) $\(text(e.orderedPrice)) · \(Ll("Invoice")) $\(text(e.billedPrice))")
    }

    /// M-03 · the RFC on the CFDI matches the supplier of record.
    static func m03(_ e: MatchEvidence) -> Check {
        Check(rule: "M-03",
              name: L("RFC on the CFDI matches the supplier of record"),
              passed: e.billedRFC != nil && e.billedRFC == e.supplierRFC,
              detail: "\(text(e.billedRFC)) · \(text(e.supplierRFC))")
    }

    /// M-04 · the UUID has not been seen before on a payable.
    ///
    /// The duplicate-payment control. Industry runs at 0.8 to 2 percent of
    /// disbursements, which is why this is a rule and not a review step.
    static func m04(_ e: MatchEvidence) -> Check {
        Check(rule: "M-04",
              name: L("UUID not seen before on a payable"),
              passed: !e.uuidSeenOnAnotherPayable,
              detail: text(e.billedUUID))
    }

    /// M-05 · the CFDI is in force at the SAT.
    static func m05(_ e: MatchEvidence) -> Check {
        Check(rule: "M-05",
              name: L("CFDI in force at the SAT"),
              passed: e.satStatus == "vigente",
              detail: text(e.satStatus))
    }

    /// M-06 · the issuer was not on the 69-B list at the issue date.
    static func m06(_ e: MatchEvidence) -> Check {
        let listed = e.supplierStatus == "69B"
        return Check(rule: "M-06",
                     name: L("Issuer not on the 69-B list at issue date"),
                     passed: !listed,
                     detail: listed ? L("on the list; 30 days to prove receipt") : L("clear"))
    }

    /// M-07 · the bank record equals the invoice amount, or there is no payment.
    ///
    /// No payment passes: a case opened before payment is the normal path, and
    /// failing it would make every early case look like a discrepancy.
    static func m07(_ e: MatchEvidence) -> Check {
        let passed: Bool
        if let paid = e.paidAmount, let billed = e.billedTotal {
            passed = abs(paid - billed) < 1
        } else {
            passed = e.paidAmount == nil
        }
        return Check(rule: "M-07",
                     name: L("Bank record equals the invoice amount, or no payment yet"),
                     passed: passed,
                     detail: e.paidAmount == nil
                        ? Ll("No payment yet")
                        : "\(Ll("Paid")) \(text(e.paidAmount)) · \(L("billed")) \(text(e.billedTotal))")
    }

    static func text(_ value: Int?) -> String { value.map(String.init) ?? "—" }
    static func text(_ value: String?) -> String { value ?? "—" }
}

/// What the agent makes of the checks that failed.
///
/// The agent investigates, writes a finding in plain words, and recommends. It
/// does not decide, and the recommendation carries the guardrails version it was
/// written under so a later reader knows which rules it was reasoning inside.
public struct MatchFinding: Sendable, Equatable {

    /// The actions a case may take, in the enterprise's approval order.
    public enum Action: String, Sendable, CaseIterable {
        case inquiry, evidence, flag, route, close

        public var label: String {
            switch self {
            case .inquiry: L("draft the supplier inquiry")
            case .evidence: L("request receiving evidence")
            case .flag: L("flag a receiving mismatch")
            case .route: L("route to the regional team")
            case .close: L("close the case")
            }
        }
    }

    public var text: String
    public var action: Action
    public var guardrailsVersion: String

    /// Derive the finding from the checks. The first failing rule leads, because
    /// an RFC mismatch is not something to investigate a price difference over.
    public static func from(_ checks: [MatchRules.Check], guardrailsVersion: String) -> MatchFinding {
        guard let first = checks.first(where: { !$0.passed }) else {
            return MatchFinding(
                text: L("All seven checks pass; the case can close and the invoice proceed to payment on its terms."),
                action: .close, guardrailsVersion: guardrailsVersion)
        }
        let (action, text) = narrative(for: first.rule)
        return MatchFinding(text: text, action: action, guardrailsVersion: guardrailsVersion)
    }

    static func narrative(for rule: String) -> (Action, String) {
        switch rule {
        case "M-01":
            (.inquiry, L("The supplier billed more than the distribution centre received. Draft the supplier inquiry with the receiving record attached; do not pay the difference."))
        case "M-02":
            (.inquiry, L("The unit price differs from the order. Ask the supplier for the price agreement or a credit note."))
        case "M-03":
            (.route, L("The RFC does not match the supplier of record. Route to the regional team before anything else."))
        case "M-04":
            (.route, L("This UUID has already been recorded on another payable. Treat as a probable duplicate; hold payment and route to central finance."))
        case "M-05":
            (.route, L("The CFDI is not in force at the SAT. Hold and confirm its status before any payment."))
        case "M-06":
            (.evidence, L("The issuer appears on the 69-B list. Gather the evidence of actual receipt within thirty days or the fiscal effect is lost."))
        default:
            (.flag, L("The bank record does not equal the invoice amount. Flag the mismatch and reconcile before anything further is paid."))
        }
    }
}
