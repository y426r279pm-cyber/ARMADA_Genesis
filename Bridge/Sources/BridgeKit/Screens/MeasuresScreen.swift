import SwiftUI
import SwiftData

/// Pilot measures: eight cards, each against a published benchmark.
struct MeasuresScreen: View {
    @Environment(AppStore.self) private var store
    @Query private var cases: [MatchCase]
    @Query private var invoices: [Invoice]

    var body: some View {
        ScreenScaffold {
            ScreenHeader(screen: .medidas,
                         title: Key.nav_medidas.string,
                         subtitle: L("the seven pilot measures and the store number, each against its published benchmark"))

            CardGrid(minimum: 250) {
                ForEach(Measures.all(input)) { MeasureCard(measure: $0) }
            }

            Text(L("Every figure on this screen comes from the prototype's seed and is labeled sample data until the pilot measures it. Benchmarks: Ardent Partners 2025 (cost per invoice, exceptions, cycle time, touchless), APQC and IOFM (duplicate payments), dated September 2026."))
                .font(.caption).foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var input: MeasuresInput {
        let payables = invoices.filter { $0.type == "payable" }
        let resolved = cases.filter { $0.status == "resolved" }
        return MeasuresInput(
            payablesProcessed: payables.count,
            payablesCleanFirstTime: payables.filter { invoice in
                !cases.contains { $0.invoice == invoice.id }
            }.count,
            casesResolved: resolved.count,
            casesResolvedWithoutAPerson: resolved.filter { $0.owner.isEmpty }.count,
            averageHumanMinutes: resolved.isEmpty ? 0
                : resolved.reduce(0) { $0 + $1.minutes } / resolved.count,
            averageHoursToResolve: 0,
            confirmedDuplicates: resolved.filter { item in
                MatchRules.run(store.evidence(for: item)).contains { $0.rule == "M-04" && !$0.passed }
            }.count,
            recoveryDrillOnRecord: store.chain.contains {
                $0.en.contains("F4 drill") || $0.es.contains("simulacro F4")
            })
    }
}

struct MeasureCard: View {
    var measure: Measure

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: measure.symbol).font(.title3).foregroundStyle(Theme.led)
                Text(measure.name).font(.caption).foregroundStyle(Theme.text2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Text(measure.value)
                .font(.title2.weight(.semibold))
                .foregroundStyle(measure.provenance == .toBeMeasured ? Theme.muted : Theme.text)
            Text(measure.definition).font(.caption).foregroundStyle(Theme.text2)
                .fixedSize(horizontal: false, vertical: true)
            Text(measure.benchmark).font(.caption2).foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
            // Every card says what its number is. A figure that looks measured
            // when it is seeded is how a sample ends up in a client deck.
            StatusPill(kind: measure.provenance == .toBeMeasured ? .info : .warn,
                       text: measure.provenance == .toBeMeasured
                            ? L("to be measured in Discovery") : L("sample data"))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.radiusCard))
        .overlay(RoundedRectangle(cornerRadius: Theme.radiusCard).stroke(Theme.line, lineWidth: 1))
    }
}
