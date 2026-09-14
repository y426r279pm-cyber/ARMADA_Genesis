import XCTest
@testable import BridgeKit

/// The Energy screens present arithmetic rather than stored figures, so the
/// arithmetic is what is worth testing. Every case below is a claim the console
/// makes on screen.
final class EnergyTests: XCTestCase {

    /// The seeded reading: 3.9 kW from the array, a bank at 94%, grid on
    /// standby, 22 minutes of UPS bridge.
    let seeded = PowerReading(solarKW: 3.9, batteryPct: 94, grid: "standby",
                              islanded: false, reservePct: 20, curtail: true, upsMin: 22)

    /// Autonomy counts only what sits above the reserve floor. The floor is not
    /// available power, and treating it as such would overstate how long the
    /// rack survives a transfer.
    func testUsableEnergyExcludesTheReserveFloor() {
        // (94 - 20)% of 60 kWh = 44.4 kWh
        XCTAssertEqual(Energy.usableKWh(seeded), 44.4, accuracy: 0.001)

        let atFloor = PowerReading(batteryPct: 20, reservePct: 20)
        XCTAssertEqual(Energy.usableKWh(atFloor), 0,
                       "a bank at the floor has nothing to spend")

        let belowFloor = PowerReading(batteryPct: 5, reservePct: 20)
        XCTAssertEqual(Energy.usableKWh(belowFloor), 0,
                       "below the floor is still nothing, never negative")
    }

    func testAutonomyIsUsableEnergyOverRackLoad() {
        // 44.4 kWh at 2.6 kW
        XCTAssertEqual(Energy.autonomyH(seeded), 44.4 / 2.6, accuracy: 0.001)
        XCTAssertEqual(Energy.totalAutonomyH(seeded),
                       44.4 / 2.6 + 22.0 / 60, accuracy: 0.001,
                       "the UPS bridge is added in hours, not minutes")
    }

    /// The array is clipped only when the bank is nearly full *and* curtailment
    /// is on. Either alone is not clipping.
    func testClippingNeedsBothAFullBankAndCurtailment() {
        XCTAssertFalse(Energy.curtailing(seeded), "94% is not yet full")

        let full = PowerReading(solarKW: 3.9, batteryPct: 96, reservePct: 20, curtail: true)
        XCTAssertTrue(Energy.curtailing(full))

        let fullNoCurtail = PowerReading(solarKW: 3.9, batteryPct: 96, curtail: false)
        XCTAssertFalse(Energy.curtailing(fullNoCurtail))
    }

    func testSurplusIsWhatTheRackDoesNotTake() {
        XCTAssertEqual(Energy.surplusKW(seeded), 3.9 - 2.6, accuracy: 0.001)

        let dim = PowerReading(solarKW: 1.0)
        XCTAssertEqual(Energy.surplusKW(dim), 0, "never negative: the array is not a load")
    }

    func testSolarShareCapsAtOne() {
        XCTAssertEqual(Energy.solarShare(seeded), 1.0, accuracy: 0.001,
                       "3.9 kW more than covers a 2.6 kW rack")
        XCTAssertEqual(Energy.solarShare(PowerReading(solarKW: 1.3)), 0.5, accuracy: 0.001)
    }

    /// Hours below one read as minutes, which is the difference between "0.4 h"
    /// and "24 min" on a screen somebody is reading under pressure.
    func testHoursFormatFallsBackToMinutes() {
        XCTAssertEqual(Energy.formatHours(2.0), "2.0 h")
        XCTAssertEqual(Energy.formatHours(0.4), "24 min")
    }

    /// The array is 21 modules at 700 W, which is where the peak comes from.
    func testPeakMatchesTheArray() {
        XCTAssertEqual(Double(Energy.modules * Energy.moduleW) / 1000, Energy.peakKW,
                       accuracy: 0.001)
    }
}

/// The compliance figures the Invoices screen shows.
final class ComplianceTests: XCTestCase {

    /// The REP is due on the fifth *calendar* day of the following month, RMF
    /// 2.7.1.32. Business days would be a different and wrong clock.
    func testREPIsDueOnTheFifthDay() {
        XCTAssertEqual(Compliance.repDueDay, 5)
    }

    /// Cancellation acceptance is three *business* days — a different unit from
    /// the REP clock, which is exactly why both are stated rather than assumed.
    func testCancellationWindowIsBusinessDays() {
        XCTAssertEqual(Compliance.cancellationBusinessDays, 3)
    }

    func test69BEvidenceWindow() {
        XCTAssertEqual(Compliance.list69BDays, 30)
    }

    /// The penalty range is single-sourced and pending DOF verification, so it
    /// must stay a range. A single figure would read as settled.
    func testPenaltyIsARangeNotAFigure() {
        XCTAssertLessThan(Compliance.repPenaltyMXN.low, Compliance.repPenaltyMXN.high)
        XCTAssertEqual(Compliance.repPenaltyMXN.low, 450)
        XCTAssertEqual(Compliance.repPenaltyMXN.high, 670)
    }
}
