import SwiftUI
import SwiftData

/// Stores: one distribution centre and the stores it serves.
///
/// The layer the enterprise lacks between a planogram and twenty-four thousand
/// shops. Each row shows its connector state and queue depth, because a store
/// that is offline is not a store with no exceptions — it is a store whose
/// exceptions have not arrived yet.
struct StoresScreen: View {
    @Environment(AppStore.self) private var store
    @Query private var stores: [StoreSite]
    @State private var search = ""

    var body: some View {
        ScreenScaffold {
            if !store.canWrite { ReadOnlyBanner() }

            ScreenHeader(screen: .tiendas,
                         title: Key.nav_tiendas.string,
                         subtitle: L("one distribution centre and its stores: connector, queue, agent, open cases"))

            HStack(spacing: 10) {
                Chip(text: "\(distributionCentre) · \(stores.count) \(L("stores"))", dot: Theme.led)
                Chip(text: "\(offline) \(L("with records queued offline"))",
                     dot: offline > 0 ? Theme.warn : Theme.led)
                Chip(text: Key.nav_topologia.string) { store.navigator.go(.topologia) }
            }

            Card(L("Stores")) {
                TextField(L("Search stores"), text: $search)
                    .textFieldStyle(.roundedBorder)
                ForEach(filtered, id: \.id) { site in
                    Button { store.navigator.go(.tienda, site.id) } label: {
                        StoreRow(site: site)
                    }
                    .buttonStyle(.plain)
                    Divider().overlay(Theme.line)
                }
            }
        }
    }

    private var distributionCentre: String { stores.first?.dc ?? "—" }
    private var offline: Int { stores.filter { $0.connector != "online" }.count }
    private var filtered: [StoreSite] {
        stores.filter {
            search.isEmpty || $0.name.localizedCaseInsensitiveContains(search)
            || $0.id.localizedCaseInsensitiveContains(search)
            || $0.city.localizedCaseInsensitiveContains(search)
        }
    }
}

struct StoreRow: View {
    var site: StoreSite

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(site.id).font(.callout.bold()).foregroundStyle(Theme.text)
                Text(site.name).font(.caption).foregroundStyle(Theme.text2)
            }
            .frame(width: 150, alignment: .leading)

            Text(site.city).font(.callout).foregroundStyle(Theme.text2)
                .frame(width: 110, alignment: .leading)

            StatusPill(kind: site.connector == "online" ? .ok
                            : site.connector == "queued" ? .warn : .info,
                       text: site.connector)

            if site.queued > 0 {
                Text("\(site.queued) \(L("queued"))").font(.caption).foregroundStyle(Theme.warn)
            }

            Spacer(minLength: 8)

            if site.openCases > 0 {
                StatusPill(kind: .crit, text: "\(site.openCases) \(L("open"))")
            }
            // No number here: nobody has measured planogram compliance yet, and
            // a placeholder figure would be invented evidence.
            StatusPill(kind: .info, text: L("to be measured"))
            Image(systemName: "chevron.right").font(.caption2).foregroundStyle(Theme.muted)
        }
        .padding(.vertical, 8)
    }
}

/// One store: its connector, its scoped agent, and its open work.
struct StoreScreen: View {
    @Environment(AppStore.self) private var store
    @Query private var stores: [StoreSite]
    var storeID: String?

    private var site: StoreSite? { stores.first { $0.id == storeID } }

    var body: some View {
        ScreenScaffold {
            if let site {
                ScreenHeader(screen: .tienda, title: "\(site.id) · \(site.name)",
                             subtitle: "\(site.city) · \(site.dc) · \(L("served by")) \(site.site)",
                             iconScreen: .tiendas)

                CardGrid {
                    StatCard(value: site.connector, label: L("Connector"),
                             tint: site.connector == "online" ? Theme.led : Theme.warn,
                             icon: AnyView(Image(systemName: site.connector == "online"
                                                 ? "wifi" : "wifi.slash").font(.title2)
                                .foregroundStyle(site.connector == "online" ? Theme.led : Theme.warn)))
                    StatCard(value: "\(site.queued)", label: L("Records queued offline"),
                             tint: site.queued > 0 ? Theme.warn : Theme.led,
                             icon: AnyView(Image(systemName: "tray.full").font(.title2)
                                .foregroundStyle(Theme.text2)))
                    StatCard(value: "\(site.openCases)", label: L("Open cases"),
                             tint: site.openCases > 0 ? Theme.crit : Theme.led,
                             icon: AnyView(BridgeIcon(.conciliacion, size: 28)),
                             action: { store.navigator.go(.conciliacion) })
                    StatCard(value: "\(site.tickets)", label: L("Tickets a day"),
                             icon: AnyView(Image(systemName: "cart").font(.title2)
                                .foregroundStyle(Theme.text2)))
                }

                Card(L("The offline queue")) {
                    Text(L("A store connector holds records locally when the link is down and replays them in order when it returns. A store showing no exceptions while its connector is offline has not been checked; it has not reported."))
                        .font(.callout).foregroundStyle(Theme.text2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Card(L("Planogram compliance")) {
                    StatusPill(kind: .info, text: L("to be measured"))
                    Text(L("Planned shelf against tickets and replenishment, per store. There is no published benchmark for this and no figure yet: it is the number the Discovery exists to produce."))
                        .font(.callout).foregroundStyle(Theme.text2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                ScreenHeader(screen: .tienda, title: L("Store"), iconScreen: .tiendas)
                Card { Text(L("That record no longer exists.")).foregroundStyle(Theme.muted) }
            }
        }
    }
}
