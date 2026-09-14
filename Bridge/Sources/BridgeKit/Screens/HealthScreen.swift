import SwiftUI
import SwiftData

/// Health: the cluster, and the power spine under it.
struct HealthScreen: View {
    @Environment(AppStore.self) private var store
    @Query private var nodes: [ClusterNode]
    @Query private var power: [PowerState]

    var body: some View {
        ScreenScaffold {
            ScreenHeader(screen: .salud,
                         title: Key.nav_salud.string,
                         subtitle: L("every node, its temperature and its memory, and the power behind them"))

            CardGrid {
                StatCard(value: "\(online)/\(nodes.count)", label: L("online"),
                         tint: online == nodes.count ? Theme.led : Theme.warn,
                         icon: AnyView(BridgeIcon(.salud, size: 28)))
                StatCard(value: "\(avgTemp)°", label: L("avg temp"),
                         tint: avgTemp >= 75 ? Theme.warn : Theme.text,
                         icon: AnyView(Thermometer(celsius: avgTemp)))
                StatCard(value: "\(avgMemory)%", label: L("memory"),
                         icon: AnyView(MemoryRing(usedGB: avgMemoryGB)))
                StatCard(value: ledgerCurrent ? L("current") : L("behind"),
                         label: L("ledger on every node"),
                         tint: ledgerCurrent ? Theme.led : Theme.warn,
                         icon: AnyView(BridgeIcon(.cadena, size: 28)))
            }

            Card(L("Cluster"), trailing: L("Tap a node to open it")) {
                ClusterMap(nodes: nodes) { id in store.navigator.go(.nodo, id) }
            }

            if let reading {
                Card(L("Power spine"),
                     trailing: L("solar, bank, rack, grid")) {
                    PowerSpine(power: reading)
                        .padding(.vertical, 8)
                    Button(L("Open Energy")) { store.navigator.go(.energia) }
                        .buttonStyle(.plain)
                        .font(.footnote).foregroundStyle(Theme.led)
                }
            }
        }
    }

    private var online: Int { nodes.filter { $0.status != "down" }.count }
    private var avgTemp: Int {
        nodes.isEmpty ? 0 : Int((Double(nodes.reduce(0) { $0 + $1.tempC }) / Double(nodes.count)).rounded())
    }
    private var avgMemoryGB: Int {
        nodes.isEmpty ? 0 : Int((Double(nodes.reduce(0) { $0 + $1.memGB }) / Double(nodes.count)).rounded())
    }
    private var avgMemory: Int { Int((Double(avgMemoryGB) / 256 * 100).rounded()) }
    private var ledgerCurrent: Bool { !nodes.isEmpty && nodes.allSatisfy { $0.ledger == "current" } }
    private var reading: PowerReading? { power.first.map(PowerReading.init(model:)) }
}

/// One node.
struct NodeScreen: View {
    @Environment(AppStore.self) private var store
    @Query private var nodes: [ClusterNode]
    var nodeID: String?

    private var node: ClusterNode? { nodes.first { $0.id == nodeID } }

    var body: some View {
        ScreenScaffold {
            if let node {
                // Detail screens inherit their parent's icon.
                ScreenHeader(screen: .nodo, title: node.id, subtitle: node.role, iconScreen: .salud)

                CardGrid {
                    StatCard(value: node.role, label: L("Role"),
                             icon: AnyView(BridgeIcon(.configuracion, size: 28)))
                    StatCard(value: "\(node.tempC) °C", label: L("Temperature"),
                             tint: node.tempC >= 80 ? Theme.crit : node.tempC >= 70 ? Theme.warn : Theme.text,
                             icon: AnyView(Thermometer(celsius: node.tempC)))
                    StatCard(value: "\(node.memGB) GB", label: L("Memory"),
                             icon: AnyView(MemoryRing(usedGB: node.memGB)))
                    StatCard(value: node.ledger == "current" ? L("current") : L("behind"),
                             label: L("Ledger copy"),
                             tint: node.ledger == "current" ? Theme.led : Theme.warn,
                             icon: AnyView(BridgeIcon(.cadena, size: 28)))
                }

                Card(L("Identity")) {
                    HStack(alignment: .top, spacing: 20) {
                        KeyValue(label: L("Node"), value: node.id, monospaced: true)
                        KeyValue(label: L("Serial"), value: node.serial, monospaced: true)
                        KeyValue(label: L("Status"), value: node.status,
                                 tint: node.statusColor)
                    }
                }
            } else {
                ScreenHeader(screen: .nodo, title: L("Node"), iconScreen: .salud)
                Card { Text(L("That record no longer exists.")).foregroundStyle(Theme.muted) }
            }
        }
    }
}
