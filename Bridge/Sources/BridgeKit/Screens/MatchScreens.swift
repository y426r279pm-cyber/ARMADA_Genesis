import SwiftUI
import SwiftData

/// Supplier match: the case list.
struct MatchScreen: View {
    @Environment(AppStore.self) private var store
    @Query private var cases: [MatchCase]
    @Query private var invoices: [Invoice]
    @State private var search = ""

    var body: some View {
        ScreenScaffold {
            if !store.canWrite { ReadOnlyBanner() }

            ScreenHeader(screen: .conciliacion,
                         title: Key.nav_conciliacion.string,
                         subtitle: L("four records, one owning case, deterministic checks first, a person at the gate"))

            HStack(spacing: 10) {
                Chip(text: "\(cleanMatches) \(L("of")) \(payables.count) \(L("payables matched cleanly"))",
                     dot: Theme.led)
                Chip(text: "\(count(of: "open")) \(L("open"))", dot: Theme.crit)
                Chip(text: "\(count(of: "attending")) \(L("attending"))", dot: Theme.warn)
                Chip(text: "\(count(of: "resolved")) \(L("resolved"))")
            }

            Card(L("Cases")) {
                TextField(L("Search cases"), text: $search)
                    .textFieldStyle(.roundedBorder)

                if sorted.isEmpty {
                    Text(L("No cases.")).font(.callout).foregroundStyle(Theme.muted)
                }
                ForEach(sorted, id: \.id) { item in
                    Button { store.navigator.go(.caso, item.id) } label: {
                        CaseRow(item: item, checks: checks(for: item))
                    }
                    .buttonStyle(.plain)
                    Divider().overlay(Theme.line)
                }
            }

            Text(L("Deterministic rules M-01 to M-07 enforce arithmetic, identifiers, tolerance (2 percent), permissions and duplicate prevention. The agent investigates only what fails, recommends, and a person decides; two agreeing records are never approval by themselves."))
                .font(.caption).foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var payables: [Invoice] { invoices.filter { $0.type == "payable" } }

    /// A payable with no case against it matched cleanly first time.
    private var cleanMatches: Int {
        payables.filter { invoice in !cases.contains { $0.invoice == invoice.id } }.count
    }

    private func count(of status: String) -> Int { cases.filter { $0.status == status }.count }

    /// Open first, then oldest: the queue a person should work down.
    private var sorted: [MatchCase] {
        cases
            .filter { search.isEmpty || $0.title.localizedCaseInsensitiveContains(search)
                      || $0.id.localizedCaseInsensitiveContains(search) }
            .sorted {
                ($0.status == "resolved" ? 1 : 0, $0.opened) < ($1.status == "resolved" ? 1 : 0, $1.opened)
            }
    }

    private func checks(for item: MatchCase) -> [MatchRules.Check] {
        MatchRules.run(store.evidence(for: item))
    }
}

struct CaseRow: View {
    var item: MatchCase
    var checks: [MatchRules.Check]

    var body: some View {
        let failing = checks.filter { !$0.passed }.count
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.id).font(.callout.bold()).foregroundStyle(Theme.text)
                Text(item.opened).font(.caption).foregroundStyle(Theme.muted)
            }
            .frame(width: 110, alignment: .leading)

            Text(item.title).font(.callout).foregroundStyle(Theme.text2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 8)

            StatusPill(kind: failing > 0 ? .crit : .ok,
                       text: failing > 0 ? "\(failing) \(L("failing"))" : L("all pass"))
            StatusPill(kind: item.status == "open" ? .crit
                            : item.status == "attending" ? .warn : .ok,
                       text: item.status)
            Image(systemName: "chevron.right").font(.caption2).foregroundStyle(Theme.muted)
        }
        .padding(.vertical, 8)
    }
}

/// One case: the four records, the checks, the finding, and the gate.
struct CaseScreen: View {
    @Environment(AppStore.self) private var store
    @Query private var cases: [MatchCase]
    @State private var typedWord = ""
    @State private var refusal: ApprovalGate.Refusal?
    @State private var approved = false
    var caseID: String?

    private var item: MatchCase? { cases.first { $0.id == caseID } }

    var body: some View {
        ScreenScaffold(maxWidth: 1280) {
            if let item {
                let checks = MatchRules.run(store.evidence(for: item))
                let finding = MatchFinding.from(checks, guardrailsVersion: store.guardrailsVersion)

                if !store.canWrite { ReadOnlyBanner() }
                ScreenHeader(screen: .caso, title: item.id,
                             subtitle: "\(item.title) · \(item.status)",
                             iconScreen: .conciliacion)

                FourRecords(evidence: store.evidence(for: item), item: item)

                HStack(alignment: .top, spacing: 14) {
                    DeterministicChecks(checks: checks)
                    AgentFinding(finding: finding, checks: checks, item: item,
                                 typedWord: $typedWord, refusal: $refusal, approved: $approved)
                }
            } else {
                ScreenHeader(screen: .caso, title: L("Case"), iconScreen: .conciliacion)
                Card { Text(L("That record no longer exists.")).foregroundStyle(Theme.muted) }
            }
        }
    }
}

/// The four records side by side, with the fields that must agree in view.
struct FourRecords: View {
    var evidence: MatchEvidence
    var item: MatchCase

    var body: some View {
        CardGrid(minimum: 230) {
            record(L("Purchase order"), L("what was authorized"), [
                (L("Reference"), item.po),
                (L("Quantity"), MatchRules.text(evidence.orderedQty)),
                (L("Unit price"), evidence.orderedPrice.map { "$\($0)" } ?? "—"),
                (L("Total"), evidence.orderedTotal?.asMXN ?? "—"),
            ])
            record(L("Receiving record"), L("what arrived"), [
                (L("Quantity"), MatchRules.text(evidence.receivedQty)),
                (L("Distribution centre"), evidence.receivingCentre ?? "—"),
                (L("Shortfall"), shortfall),
            ])
            record(L("Supplier CFDI"), L("what was billed"), [
                ("UUID", evidence.billedUUID ?? "—"),
                (L("Quantity"), MatchRules.text(evidence.billedQty)),
                (L("Unit price"), evidence.billedPrice.map { "$\($0)" } ?? "—"),
                (L("Total"), evidence.billedTotal?.asMXN ?? "—"),
                ("RFC", evidence.billedRFC ?? "—"),
                ("SAT", evidence.satStatus ?? "—"),
            ])
            record(L("Bank record"), L("what was paid"),
                   evidence.paidAmount == nil
                   ? [(L("No payment yet"), "")]
                   : [(L("Amount"), evidence.paidAmount!.asMXN)])
        }
    }

    private var shortfall: String {
        guard let ordered = evidence.orderedQty, let received = evidence.receivedQty else { return "—" }
        return String(ordered - received)
    }

    private func record(_ title: String, _ subtitle: String,
                        _ rows: [(String, String)]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.subheadline.bold()).foregroundStyle(Theme.text)
            Text(subtitle).font(.caption).foregroundStyle(Theme.muted)
            ForEach(rows, id: \.0) { row in
                Divider().overlay(Theme.line)
                HStack(alignment: .top) {
                    Text(row.0).font(.caption).foregroundStyle(Theme.muted)
                    Spacer(minLength: 8)
                    Text(row.1).font(.caption.bold()).foregroundStyle(Theme.text)
                        .multilineTextAlignment(.trailing)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface2, in: RoundedRectangle(cornerRadius: Theme.radiusCard))
    }
}

/// The seven rules, shown apart from anything a model said.
///
/// The separation is deliberate and structural. A rule that can be stated as
/// arithmetic is a control; a model's reading of it is not. Putting them in one
/// list would invite reading the second as the first.
struct DeterministicChecks: View {
    var checks: [MatchRules.Check]

    var body: some View {
        Card(L("Deterministic checks"), trailing: L("rules, not judgement")) {
            ForEach(checks) { check in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: check.passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(check.passed ? Theme.led : Theme.crit)
                        .font(.footnote)
                    Text(check.rule).font(Theme.mono).foregroundStyle(Theme.muted)
                        .frame(width: 46, alignment: .leading)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(check.name).font(.footnote).foregroundStyle(Theme.text)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(check.detail).font(.caption2).foregroundStyle(Theme.muted)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 5)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(check.rule), \(check.name), \(check.passed ? L("passes") : L("fails"))")
                Divider().overlay(Theme.line)
            }
        }
    }
}

/// What the agent made of it, and the gate.
struct AgentFinding: View {
    @Environment(AppStore.self) private var store
    var finding: MatchFinding
    var checks: [MatchRules.Check]
    var item: MatchCase
    @Binding var typedWord: String
    @Binding var refusal: ApprovalGate.Refusal?
    @Binding var approved: Bool

    var body: some View {
        Card {
            HStack(spacing: 10) {
                TaylorMark(size: 26)
                Text(L("Agent finding")).font(.headline).foregroundStyle(Theme.text)
                Spacer()
                Text("\(L("guardrails")) v\(finding.guardrailsVersion)")
                    .font(.caption).foregroundStyle(Theme.muted)
            }

            Text(finding.text).font(.callout).foregroundStyle(Theme.text2)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 4) {
                Text("\(L("Recommended")):").font(.caption).foregroundStyle(Theme.muted)
                Text(finding.action.label).font(.caption.bold()).foregroundStyle(Theme.text)
            }
            Text(L("the agent recommends, a person decides, the chain records both"))
                .font(.caption2).foregroundStyle(Theme.muted)

            Divider().overlay(Theme.line)
            gate
        }
    }

    /// The gate. Every check green, a typed word, and the authenticator.
    @ViewBuilder private var gate: some View {
        let failing = checks.filter { !$0.passed }
        VStack(alignment: .leading, spacing: 10) {
            Text(L("Approve for payment")).font(.subheadline.bold()).foregroundStyle(Theme.text)

            if !failing.isEmpty {
                // Say why before asking for anything. A gate that collects a
                // typed word and then refuses teaches people it is theatre.
                StatusPill(kind: .crit,
                           text: "\(L("Blocked by")) \(failing.map(\.rule).joined(separator: ", "))")
            } else if approved {
                StatusPill(kind: .ok, text: L("Approved and sealed"))
            } else {
                HStack(spacing: 8) {
                    TextField(ApprovalGate.confirmationWord, text: $typedWord)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 160)
                        .disabled(!store.canWrite)
                    Button(L("Approve")) { Task { await approve() } }
                        .buttonStyle(.borderedProminent)
                        .disabled(!store.canWrite)
                }
                Text("\(Key.confirm_word_hint.string) \(ApprovalGate.confirmationWord)")
                    .font(.caption2).foregroundStyle(Theme.muted)
            }

            if let refusal {
                Text(refusal.message).font(.caption).foregroundStyle(Theme.warn)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text(L("Approval needs every check green, a typed word and the authenticator. An ambiguous timeout is never permission to pay again."))
                .font(.caption2).foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func approve() async {
        refusal = nil
        let request = ApprovalGate.Request(caseID: item.id, owner: item.owner, actor: store.user,
                                           checks: checks, typedWord: typedWord,
                                           canWrite: store.canWrite)
        switch await ApprovalGate.evaluate(request, authenticate: {
            await store.authenticator.evaluate(L("Approve this payment"))
        }) {
        case .success(let approval):
            approved = true
            typedWord = ""
            await store.dispatch(.approvePayment(approval))
        case .failure(let why):
            refusal = why
            typedWord = ""
        }
    }
}
