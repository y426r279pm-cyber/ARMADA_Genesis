import SwiftUI
import SwiftData

/// Energy: sun, bank, grid, bridge — each with its own page.
///
/// Power is stated in kilowatts throughout and there are no appliance
/// comparisons. That is the RC2 brief's rule, and it is also the honest form:
/// "enough to run N homes" is a different claim from "2.6 kW".
struct EnergyScreen: View {
    @Environment(AppStore.self) private var store
    @Query private var power: [PowerState]

    private var reading: PowerReading { power.first.map(PowerReading.init(model:)) ?? PowerReading() }

    var body: some View {
        ScreenScaffold {
            ScreenHeader(screen: .energia,
                         title: Key.nav_energia.string,
                         subtitle: L("what the array makes, what the bank holds, and how long the rack runs without either"))

            CardGrid(minimum: 250) {
                gauge(.solar) { SolarGauge(kW: reading.solarKW) }
                gauge(.baterias) { BatteryGauge(percent: reading.batteryPct,
                                                reservePercent: reading.reservePct) }
                gauge(.red) { GridGauge(state: reading.islanded ? "islanded" : reading.grid) }
                gauge(.ups) { UPSGauge(minutes: reading.upsMin) }
            }

            Card(L("Autonomy"), trailing: L("bank above the floor, plus the UPS bridge")) {
                HStack(alignment: .top, spacing: 24) {
                    KeyValue(label: L("Usable in the bank"),
                             value: String(format: "%.1f kWh", Energy.usableKWh(reading)))
                    KeyValue(label: L("Rack load"), value: String(format: "%.1f kW", Energy.rackKW))
                    KeyValue(label: L("On the bank alone"),
                             value: Energy.formatHours(Energy.autonomyH(reading)))
                    KeyValue(label: L("With the UPS bridge"),
                             value: Energy.formatHours(Energy.totalAutonomyH(reading)),
                             tint: Theme.led)
                }
                Text(L("Autonomy counts only what sits above the reserve floor; the floor is not spent."))
                    .font(.caption).foregroundStyle(Theme.muted)
            }

            if Energy.curtailing(reading) {
                Card(L("Clipping")) {
                    Text(L("The bank is full and the array is making more than the rack needs, so the surplus is being clipped."))
                        .font(.callout).foregroundStyle(Theme.text2)
                    HStack(spacing: 24) {
                        KeyValue(label: L("Surplus now"),
                                 value: String(format: "%.1f kW", Energy.surplusKW(reading)),
                                 tint: Theme.warn)
                        KeyValue(label: L("Clipped today"),
                                 value: String(format: "%.1f kWh", Energy.clippedKWhToday(reading)),
                                 tint: Theme.warn)
                    }
                }
            }
        }
    }

    private func gauge(_ screen: Screen, @ViewBuilder art: () -> some View) -> some View {
        Button { store.navigator.go(screen) } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(screen.crumbLabel).font(.headline).foregroundStyle(Theme.text)
                    Spacer()
                    Image(systemName: "chevron.right").font(.caption2).foregroundStyle(Theme.muted)
                }
                art().frame(maxWidth: .infinity)
            }
            .padding(16)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.radiusCard))
            .overlay(RoundedRectangle(cornerRadius: Theme.radiusCard).stroke(Theme.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

/// One energy page: a large gauge, the numbers behind it, and what it means.
///
/// The four pages share a shape because they answer the same question about
/// different parts of the spine: what is it doing, and what follows from that.
struct EnergyDetailScreen: View {
    @Query private var power: [PowerState]
    var screen: Screen

    private var reading: PowerReading { power.first.map(PowerReading.init(model:)) ?? PowerReading() }

    var body: some View {
        ScreenScaffold {
            ScreenHeader(screen: screen, title: screen.crumbLabel,
                         subtitle: subtitle, iconScreen: .energia)

            Card {
                HStack { Spacer(); art; Spacer() }.padding(.vertical, 8)
            }

            Card(L("Numbers")) {
                CardGrid(minimum: 180) {
                    ForEach(numbers, id: \.0) { KeyValue(label: $0.0, value: $0.1) }
                }
            }

            Card(L("What this means")) {
                Text(explanation).font(.callout).foregroundStyle(Theme.text2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder private var art: some View {
        switch screen {
        case .solar: SolarGauge(kW: reading.solarKW).scaleEffect(1.6).frame(height: 130)
        case .baterias: BatteryGauge(percent: reading.batteryPct,
                                     reservePercent: reading.reservePct).scaleEffect(1.6).frame(height: 130)
        case .red: GridGauge(state: reading.islanded ? "islanded" : reading.grid)
                .scaleEffect(1.6).frame(height: 130)
        default: UPSGauge(minutes: reading.upsMin).scaleEffect(1.6).frame(height: 130)
        }
    }

    private var subtitle: String {
        switch screen {
        case .solar: L("the array on the roof")
        case .baterias: L("the bank, and the floor it never spends")
        case .red: L("the tie to the utility, and the switch")
        default: L("the bridge that covers a transfer")
        }
    }

    private var numbers: [(String, String)] {
        switch screen {
        case .solar:
            [(L("Making now"), String(format: "%.1f kW", reading.solarKW)),
             (L("Array peak"), String(format: "%.1f kW", Energy.peakKW)),
             (L("Modules"), "\(Energy.modules) × \(Energy.moduleW) W"),
             ("\(L("Today, at")) \(Energy.sunHours) \(L("sun hours"))",
              String(format: "%.1f kWh", Energy.solarKWhToday(reading))),
             (L("Rack load"), String(format: "%.1f kW", Energy.rackKW)),
             (L("Surplus"), String(format: "%.1f kW", Energy.surplusKW(reading)))]
        case .baterias:
            [(L("Charge"), "\(reading.batteryPct)%"),
             (L("Bank capacity"), String(format: "%.0f kWh", Energy.bankKWh)),
             (L("Reserve floor"), "\(reading.reservePct)%"),
             (L("Usable above the floor"), String(format: "%.1f kWh", Energy.usableKWh(reading))),
             (L("Runs the rack for"), Energy.formatHours(Energy.autonomyH(reading)))]
        case .red:
            [(L("State"), reading.islanded ? Ll("Islanded") : reading.grid),
             (L("Switch (label)"), reading.islanded ? L("open (label)") : L("closed")),
             (L("Rack load"), String(format: "%.1f kW", Energy.rackKW))]
        default:
            [(L("Bridge remaining"), "\(reading.upsMin) min"),
             (L("Rated bridge"), "\(Int(Energy.upsRatedMin)) min"),
             (L("Unit"), String(format: "%.0f kVA", Energy.upsKVA))]
        }
    }

    private var explanation: String {
        switch screen {
        case .solar:
            L("The array feeds the rack first and the bank second. When the bank is full and the array is still making more than the rack needs, the surplus is clipped rather than stored.")
        case .baterias:
            L("The reserve floor is not available power. It is what the bank keeps back so that an unplanned transfer has something to draw on, which is why autonomy counts only what sits above it.")
        case .red:
            L("On standby the tie is closed but unused: the rack runs on sun and bank. Islanded, the switch is open and the utility is disconnected entirely.")
        default:
            L("The UPS covers the seconds between losing one source and settling on another. It is a bridge, not a supply, and its rating is stated in minutes at the rack's steady load.")
        }
    }
}
