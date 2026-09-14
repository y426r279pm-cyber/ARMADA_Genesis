import Foundation

/// The eight pilot measures.
///
/// Seven from Daniel's note plus the planogram number, each read against a
/// published benchmark. The Discovery is measurable or it is not a Discovery,
/// and this screen is where that claim is either kept or not.
///
/// Every figure is computed from the store and carries a label saying what it
/// is. Seven are `sampleData` — real arithmetic over seeded records, which is
/// not the same as a measurement. The eighth is `toBeMeasured`: there is no
/// number for planogram compliance yet, and inventing one would be the exact
/// failure the brief's rule against unmeasured results is written to prevent.
public struct Measure: Sendable, Identifiable {
    public enum Provenance: Sendable, Equatable {
        /// Computed from seeded records. Arithmetic, not evidence.
        case sampleData
        /// No figure yet. The pilot produces it or nobody does.
        case toBeMeasured
    }

    public var id: String
    public var name: String
    public var value: String
    public var definition: String
    public var benchmark: String
    public var provenance: Provenance
    public var symbol: String
}

/// The published benchmarks the cards are read against.
///
/// Dated, and attributed on the screen. A benchmark without a date is a number
/// somebody will still be quoting in two years.
public enum Benchmarks {
    public static let source = "Ardent Partners 2025 · APQC · IOFM"
    public static let dated = "September 2026"

    public static let costPerInvoiceAverageUSD = 9.40
    public static let costPerInvoiceBestUSD = 2.78
    public static let exceptionRateAverage = 0.14
    public static let exceptionRateBest = 0.09
    public static let cycleDaysAverage = 9.2
    public static let cycleDaysBest = 3.1
    public static let touchlessAverage = 0.326
    public static let touchlessBest = 0.492
    public static let cleanMatchLow = 0.50
    public static let cleanMatchHigh = 0.65
    public static let duplicatePaymentsLow = 0.008
    public static let duplicatePaymentsHigh = 0.02

    /// A loaded hourly rate, used only to turn minutes into a cost. Marked EST
    /// wherever it surfaces, because it is an assumption rather than a figure.
    public static let loadedHourlyRateMXN = 380.0
}

/// What the Measures screen needs, computed in one place so it can be tested
/// without a view.
public struct MeasuresInput: Sendable {
    public var payablesProcessed: Int
    public var payablesCleanFirstTime: Int
    public var casesResolved: Int
    public var casesResolvedWithoutAPerson: Int
    public var averageHumanMinutes: Int
    public var averageHoursToResolve: Int
    public var confirmedDuplicates: Int
    public var recoveryDrillOnRecord: Bool

    public init(payablesProcessed: Int = 0, payablesCleanFirstTime: Int = 0,
                casesResolved: Int = 0, casesResolvedWithoutAPerson: Int = 0,
                averageHumanMinutes: Int = 0, averageHoursToResolve: Int = 0,
                confirmedDuplicates: Int = 0, recoveryDrillOnRecord: Bool = false) {
        self.payablesProcessed = payablesProcessed
        self.payablesCleanFirstTime = payablesCleanFirstTime
        self.casesResolved = casesResolved
        self.casesResolvedWithoutAPerson = casesResolvedWithoutAPerson
        self.averageHumanMinutes = averageHumanMinutes
        self.averageHoursToResolve = averageHoursToResolve
        self.confirmedDuplicates = confirmedDuplicates
        self.recoveryDrillOnRecord = recoveryDrillOnRecord
    }
}

public enum Measures {

    public static func all(_ input: MeasuresInput) -> [Measure] {
        [
            Measure(id: "clean-match",
                    name: L("Correct automatic matches"),
                    value: input.payablesProcessed > 0
                        ? "\(input.payablesCleanFirstTime) / \(input.payablesProcessed)" : "—",
                    definition: L("payables with every check green and no case"),
                    benchmark: L("best in class: 65% first-time clean match (Ardent 2025)"),
                    provenance: .sampleData, symbol: "checkmark.circle"),

            Measure(id: "touchless",
                    name: L("Exceptions resolved without a person"),
                    value: input.casesResolved > 0
                        ? "\(input.casesResolvedWithoutAPerson) / \(input.casesResolved)" : "—",
                    definition: L("cases closed on the agent's own recommendation"),
                    benchmark: L("best in class: 49% touchless (Ardent 2025)"),
                    provenance: .sampleData, symbol: "hand.raised.slash"),

            Measure(id: "human-minutes",
                    name: L("Human minutes per case"),
                    value: input.averageHumanMinutes > 0 ? "\(input.averageHumanMinutes) min" : "—",
                    definition: L("clocked while a person holds the case"),
                    benchmark: L("benchmark: 10 to 15 minutes manual, under 2 automated"),
                    provenance: .sampleData, symbol: "clock"),

            Measure(id: "time-to-resolve",
                    name: L("Time to resolve"),
                    value: input.averageHoursToResolve > 0 ? "\(input.averageHoursToResolve) h" : "—",
                    definition: L("opened to closed"),
                    benchmark: L("best in class: 3.1 days cycle (Ardent 2025)"),
                    provenance: .sampleData, symbol: "timer"),

            Measure(id: "duplicates",
                    name: L("Duplicate payments confirmed"),
                    value: "\(input.confirmedDuplicates)",
                    definition: L("cases where M-04 failed and was proven"),
                    benchmark: L("industry: 0.8 to 2% of disbursements (APQC, IOFM)"),
                    provenance: .sampleData, symbol: "doc.on.doc"),

            Measure(id: "cost-per-case",
                    name: L("Cost per processed case"),
                    value: costPerCase(input.averageHumanMinutes),
                    definition: L("minutes × a loaded hourly rate; EST"),
                    benchmark: L("best in class: US$2.78 per invoice (Ardent 2025)"),
                    provenance: .sampleData, symbol: "banknote"),

            Measure(id: "recovery",
                    name: L("Recovery and evidence completeness"),
                    value: input.recoveryDrillOnRecord ? L("drill passed") : L("no drill yet"),
                    definition: L("F4 drill on record and the dossier verifies"),
                    benchmark: L("Phase 0 gate: failover inside ten minutes"),
                    provenance: .sampleData, symbol: "arrow.triangle.2.circlepath"),

            // The Discovery number. FEMSA does not have it, which is the reason
            // it is worth measuring — and the reason it must not be invented.
            Measure(id: "planogram",
                    name: L("Planogram compliance"),
                    value: L("to be measured"),
                    definition: L("planned shelf against tickets and replenishment, per store"),
                    benchmark: L("no published benchmark; the Discovery number"),
                    provenance: .toBeMeasured, symbol: "square.grid.3x3"),
        ]
    }

    /// Minutes at a loaded rate. An estimate built on an assumption, and labelled
    /// as one everywhere it appears.
    static func costPerCase(_ minutes: Int) -> String {
        guard minutes > 0 else { return "—" }
        let pesos = Double(minutes) / 60 * Benchmarks.loadedHourlyRateMXN
        return "$\(Int(pesos.rounded())) MXN EST"
    }
}
