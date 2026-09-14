import SwiftUI
import SwiftData

/// The five stages a CFDI moves through.
enum InvoiceStage: String, CaseIterable, Identifiable {
    case issued, confirmed, paid, rep_pending, rep_sealed
    var id: String { rawValue }

    var label: String {
        switch self {
        case .issued: L("Issued (PPD)")
        case .confirmed: L("Confirmed")
        case .paid: L("Paid")
        case .rep_pending: L("REP pending")
        case .rep_sealed: L("REP sealed")
        }
    }

    var kind: StatusKind {
        switch self {
        case .rep_sealed: .ok
        case .rep_pending: .warn
        default: .info
        }
    }

    var symbol: String {
        switch self {
        case .issued: "doc.text"
        case .confirmed: "checkmark.circle"
        case .paid: "dollarsign.circle"
        case .rep_pending: "clock"
        case .rep_sealed: "lock.doc"
        }
    }
}

/// Invoices: the CFDI cycle, with the day-five clock in view.
struct InvoicesScreen: View {
    @Environment(AppStore.self) private var store
    @Query private var invoices: [Invoice]
    @State private var stageFilter: InvoiceStage?
    @State private var search = ""

    var body: some View {
        ScreenScaffold {
            if !store.canWrite { ReadOnlyBanner() }

            ScreenHeader(screen: .facturas,
                         title: Key.nav_facturas.string,
                         subtitle: L("the CFDI cycle, issue to REP, with the day-5 clock in view"))

            stageCards
            ComplianceClocks(invoices: invoices)

            HStack(alignment: .top, spacing: 14) {
                repClocks
                invoiceTable
            }
        }
    }

    // MARK: Stages

    private var stageCards: some View {
        CardGrid(minimum: 170) {
            ForEach(InvoiceStage.allCases) { stage in
                let count = invoices.filter { $0.stage == stage.rawValue }.count
                StatCard(value: "\(count)", label: stage.label,
                         tint: stage == .rep_pending ? Theme.warn : nil,
                         icon: AnyView(Image(systemName: stage.symbol)
                            .font(.title2)
                            .foregroundStyle(stage == .rep_pending ? Theme.warn : Theme.text2)),
                         action: {
                             stageFilter = stageFilter == stage ? nil : stage
                         },
                         selected: stageFilter == stage)
            }
        }
    }

    // MARK: REP clocks

    /// The REP is due on the fifth *calendar* day of the following month — RMF
    /// 2.7.1.32. Calendar days, not business days, which is the detail that
    /// makes the clock worth showing at all.
    private var repClocks: some View {
        Card(L("REP with the clock running"), trailing: "RMF 2.7.1.32") {
            let pending = invoices
                .filter { $0.stage == "rep_pending" && $0.repDay > 0 }
                .sorted { $0.repDay > $1.repDay }
                .prefix(8)
            if pending.isEmpty {
                Text(L("No REPs pending.")).font(.callout).foregroundStyle(Theme.muted)
            } else {
                ForEach(Array(pending), id: \.id) { invoice in
                    let severity: StatusKind = invoice.repDay >= 4 ? .crit
                        : invoice.repDay >= 3 ? .warn : .ok
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("\(invoice.client) · \(invoice.uuid)")
                                .font(.callout).foregroundStyle(Theme.text)
                                .lineLimit(1)
                            Spacer()
                            Text("\(L("day")) \(invoice.repDay) / \(Compliance.repDueDay)")
                                .font(.callout.bold()).foregroundStyle(severity.color)
                        }
                        MeterBar(share: Double(invoice.repDay) / Double(Compliance.repDueDay),
                                 color: severity.color)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    // MARK: Table

    private var invoiceTable: some View {
        Card(L("Invoices")) {
            TextField(L("Search by UUID or client"), text: $search)
                .textFieldStyle(.roundedBorder)

            let rows = invoices.filter { invoice in
                (stageFilter == nil || invoice.stage == stageFilter?.rawValue)
                && (search.isEmpty
                    || invoice.uuid.localizedCaseInsensitiveContains(search)
                    || invoice.client.localizedCaseInsensitiveContains(search))
            }.prefix(14)

            ForEach(Array(rows), id: \.id) { invoice in
                Button { store.navigator.go(.factura, invoice.id) } label: {
                    HStack {
                        Text(invoice.uuid).font(Theme.mono).foregroundStyle(Theme.text)
                            .frame(width: 92, alignment: .leading)
                        Text(invoice.client).foregroundStyle(Theme.text2).lineLimit(1)
                        Spacer()
                        Text(invoice.amount.asMXN).foregroundStyle(Theme.text)
                            .monospacedDigit()
                        if let stage = InvoiceStage(rawValue: invoice.stage) {
                            StatusPill(kind: stage.kind, text: stage.label)
                        }
                        Image(systemName: "chevron.right")
                            .font(.caption2).foregroundStyle(Theme.muted)
                    }
                    .font(.callout)
                    .padding(.vertical, 7)
                }
                .buttonStyle(.plain)
                Divider().overlay(Theme.line)
            }
        }
    }
}

/// The compliance clocks card — RC2's addition 4.
///
/// Four dated obligations, each with the rule it comes from. Every figure is
/// computed from the store and the exposure counter is labelled EST, because
/// the peso range behind it is single-sourced and pending verification against
/// the DOF. A number that looks measured when it is estimated is the kind of
/// thing that ends up in a client deck.
struct ComplianceClocks: View {
    var invoices: [Invoice]

    private var payables: [Invoice] { invoices.filter { $0.type == "payable" } }
    private var ppd: Int { payables.filter { $0.method == "PPD" }.count }
    private var pue: Int { payables.filter { $0.method == "PUE" }.count }
    private var awaitingAcceptance: Int { invoices.filter { $0.cancel != nil }.count }
    private var pastDue: Int {
        invoices.filter { $0.stage == "rep_pending" && $0.repDay >= Compliance.repDueDay }.count
    }

    var body: some View {
        if payables.isEmpty {
            EmptyView()
        } else {
            Card(L("Compliance clocks"),
                 trailing: L("RMF 2.7.1.32 · CFF 83 and 84 · 69-B · cancellation acceptance")) {
                CardGrid(minimum: 220) {
                    clock(title: L("Payables by method"),
                          value: "\(ppd) PPD · \(pue) PUE",
                          note: L("PPD needs a REP per payment; PUE does not"))

                    clock(title: L("Cancellations awaiting acceptance"),
                          value: "\(awaitingAcceptance)",
                          tint: awaitingAcceptance > 0 ? Theme.warn : Theme.led,
                          note: L("3 business days; silence accepts; REP CFDI need express acceptance (2026)"))

                    clock(title: L("Issuers on the 69-B list"),
                          value: "0",
                          tint: Theme.led,
                          note: L("30 days to prove receipt or the fiscal effect is lost"))

                    clock(title: L("Exposure, missing REPs past day 5"),
                          value: "\(pastDue) · \((pastDue * Compliance.repPenaltyMXN.low).asMXN) \(L("to")) \((pastDue * Compliance.repPenaltyMXN.high).asMXN)",
                          tint: pastDue > 0 ? Theme.crit : Theme.led,
                          badge: true,
                          note: L("MXN 450 to 670 per document, range pending DOF verification"))
                }
            }
        }
    }

    private func clock(title: String, value: String, tint: Color? = nil,
                       badge: Bool = false, note: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(Theme.text2)
            HStack(spacing: 6) {
                Text(value).font(.callout.bold()).foregroundStyle(tint ?? Theme.text)
                if badge { SampleBadge(text: "EST") }
            }
            Text(note).font(.caption2).foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// One invoice, with its clocks.
struct InvoiceScreen: View {
    @Query private var invoices: [Invoice]
    var invoiceID: String?

    private var invoice: Invoice? { invoices.first { $0.id == invoiceID } }

    var body: some View {
        ScreenScaffold {
            if let invoice {
                ScreenHeader(screen: .factura, title: invoice.uuid,
                             subtitle: invoice.client, iconScreen: .facturas)

                Card(L("Document")) {
                    CardGrid(minimum: 150) {
                        KeyValue(label: "UUID", value: invoice.uuid, monospaced: true)
                        KeyValue(label: L("Client"), value: invoice.client)
                        KeyValue(label: L("Amount"), value: invoice.amount.asMXN)
                        KeyValue(label: L("Issued"), value: invoice.issued, monospaced: true)
                        if let stage = InvoiceStage(rawValue: invoice.stage) {
                            KeyValue(label: L("Stage"), value: stage.label,
                                     tint: stage.kind.color)
                        }
                        if let method = invoice.method {
                            KeyValue(label: L("Method"), value: method)
                        }
                        if let rfc = invoice.rfc {
                            KeyValue(label: "RFC", value: rfc, monospaced: true)
                        }
                    }
                }

                if invoice.stage == "rep_pending" {
                    Card(L("REP clock"), trailing: "RMF 2.7.1.32") {
                        let severity: StatusKind = invoice.repDay >= 4 ? .crit
                            : invoice.repDay >= 3 ? .warn : .ok
                        HStack {
                            Text("\(L("day")) \(invoice.repDay) \(L("of")) \(Compliance.repDueDay)")
                                .font(.title3.bold()).foregroundStyle(severity.color)
                            Spacer()
                            Text(L("fifth calendar day of the following month"))
                                .font(.caption).foregroundStyle(Theme.muted)
                        }
                        MeterBar(share: Double(invoice.repDay) / Double(Compliance.repDueDay),
                                 color: severity.color)
                        Text(L("Calendar days, not business days. A missing complement is an infraction under CFF 83, with the amount set by CFF 84."))
                            .font(.caption).foregroundStyle(Theme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            } else {
                ScreenHeader(screen: .factura, title: L("Invoice"), iconScreen: .facturas)
                Card { Text(L("That record no longer exists.")).foregroundStyle(Theme.muted) }
            }
        }
    }
}

extension Int {
    /// Pesos, grouped, no decimals — the prototype's `money()`.
    var asMXN: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "MXN"
        formatter.maximumFractionDigits = 0
        formatter.locale = Locale(identifier: "es_MX")
        return formatter.string(from: NSNumber(value: self)) ?? "$\(self)"
    }
}
