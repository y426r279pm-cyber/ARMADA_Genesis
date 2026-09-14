import Foundation

/// The energy model, from `ENERGY` in the prototype.
///
/// One rack: 17 machines plus network and cooling, a 21-module bifacial array,
/// a 60 kWh bank and a 10 kVA UPS. Every figure the Energy screens show is
/// derived here rather than stored, so the arithmetic is in one place and the
/// screens only present it.
///
/// Power is stated in kilowatts. The RC2 brief forbids appliance comparisons —
/// no "enough to run N homes" — and the derivations below keep to kW and hours.
public enum Energy {
    public static let modules = 21
    public static let moduleW = 700
    /// 21 × 700 W bifacial on the branch roof.
    public static let peakKW = 14.7
    public static let bankKWh = 60.0
    /// Steady rack load: 17 machines plus network and cooling.
    public static let rackKW = 2.6
    public static let upsKVA = 10.0
    public static let upsRatedMin = 30.0
    /// Illustrative daily sun hours, and hours a day the bank is already full.
    public static let sunHours = 5.2
    public static let fullBankHours = 2.5

    public static func solarShare(_ p: PowerReading) -> Double { min(1, p.solarKW / rackKW) }
    public static func surplusKW(_ p: PowerReading) -> Double { max(0, p.solarKW - rackKW) }

    /// The array is clipped only when the bank has nowhere to put the surplus.
    public static func curtailing(_ p: PowerReading) -> Bool { p.curtail && p.batteryPct >= 95 }
    public static func clippedKW(_ p: PowerReading) -> Double { p.curtail ? surplusKW(p) : 0 }
    public static func clippedKWhToday(_ p: PowerReading) -> Double { clippedKW(p) * fullBankHours }
    public static func solarKWhToday(_ p: PowerReading) -> Double { p.solarKW * sunHours }

    /// Only what sits above the reserve floor is available to spend.
    public static func usableKWh(_ p: PowerReading) -> Double {
        max(0, (Double(p.batteryPct - p.reservePct) / 100) * bankKWh)
    }
    public static func autonomyH(_ p: PowerReading) -> Double { usableKWh(p) / rackKW }
    public static func totalAutonomyH(_ p: PowerReading) -> Double {
        autonomyH(p) + Double(p.upsMin) / 60
    }

    public static func formatHours(_ h: Double) -> String {
        h >= 1 ? String(format: "%.1f h", h) : "\(Int((h * 60).rounded())) min"
    }
}

/// A power reading, as the Energy screens need it.
///
/// A plain value rather than the persisted model, so the derivations above can
/// be exercised in tests without a store.
public struct PowerReading: Sendable, Equatable {
    public var solarKW: Double
    public var batteryPct: Int
    public var grid: String
    public var islanded: Bool
    public var reservePct: Int
    public var curtail: Bool
    public var upsMin: Int

    public init(solarKW: Double = 0, batteryPct: Int = 0, grid: String = "standby",
                islanded: Bool = false, reservePct: Int = 20, curtail: Bool = false,
                upsMin: Int = 0) {
        self.solarKW = solarKW
        self.batteryPct = batteryPct
        self.grid = grid
        self.islanded = islanded
        self.reservePct = reservePct
        self.curtail = curtail
        self.upsMin = upsMin
    }
}

/// The penalty range for a missing payment complement.
///
/// The infraction is Article 83 of the CFF and the amounts are Article 84. The
/// RC2 brief flags this range as single-sourced and pending verification against
/// the DOF, so every surface that shows it is labelled EST and says so.
public enum Compliance {
    public static let repPenaltyMXN = (low: 450, high: 670)

    /// The REP is due on the fifth *calendar* day of the following month —
    /// RMF rule 2.7.1.32, calendar days, not business days.
    public static let repDueDay = 5

    /// Cancellation acceptance: three business days, silence accepts, and from
    /// 2026 a CFDI carrying a payment complement needs express acceptance.
    public static let cancellationBusinessDays = 3

    /// Days to prove a receipt once an issuer appears on the 69-B list, before
    /// the fiscal effect is lost.
    public static let list69BDays = 30
}
