import SwiftUI
import SwiftData

/// Topology: where every cluster sits, from one rack to a country.
///
/// Two deployments behind one dropdown: a single rack, and an enterprise with a
/// core, a recovery site, regional facilities and the stores that report to
/// them. The note under the map is the important part — store count alone never
/// sets the number of clusters. Placement follows measured latency,
/// connectivity, data isolation and resilience, and the view records those per
/// site rather than implying a formula.
struct TopologyScreen: View {
    @Environment(AppStore.self) private var store
    @Query private var sites: [Site]
    @State private var deployment: Deployment = .enterprise

    enum Deployment: String, CaseIterable, Identifiable {
        case bank, enterprise
        var id: String { rawValue }
        var label: String {
            switch self {
            case .bank: L("Bank: one rack (Banregio pattern)")
            case .enterprise: L("Enterprise: core, regional, South America, stores")
            }
        }
    }

    var body: some View {
        ScreenScaffold(maxWidth: 1280) {
            ScreenHeader(screen: .topologia,
                         title: Key.nav_topologia.string,
                         subtitle: L("where every cluster sits, from one rack to a country; placement follows measured latency, connectivity, data isolation and resilience"))

            HStack(spacing: 12) {
                Picker(L("Deployment"), selection: $deployment) {
                    ForEach(Deployment.allCases) { Text($0.label).tag($0) }
                }
                .frame(maxWidth: 380)
                Text(L("tap a site for its cluster map"))
                    .font(.caption).foregroundStyle(Theme.muted)
            }

            if deployment == .bank {
                BankTopology()
            } else {
                EnterpriseTopology(sites: sites) { store.navigator.go(.sitio, $0) }
            }

            Text(L("Store count alone never sets the number of clusters. Every site carries the same hardware and infrastructure rules as the bank's rack: octets of eight plus an admin node, Thunderbolt 5 with RDMA inside the octet, the enterprise's internal network between sites."))
                .font(.caption).foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// The single-rack pattern.
struct BankTopology: View {
    var body: some View {
        Card(L("One rack")) {
            Text(L("Console and cluster share a site. Everything the institution runs sits in one room, on one power spine, with one store of records."))
                .font(.callout).foregroundStyle(Theme.text2)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 14) {
                tier(L("Rack"), L("two octets and an admin node"), Theme.led, "server.rack")
                arrow
                tier(L("Console"), L("same site"), Theme.info, "display")
            }
            .padding(.top, 6)
        }
    }

    private var arrow: some View {
        Image(systemName: "arrow.right").foregroundStyle(Theme.muted)
    }

    private func tier(_ title: String, _ subtitle: String,
                      _ color: Color, _ symbol: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: symbol).font(.title).foregroundStyle(color)
            Text(title).font(.subheadline.bold()).foregroundStyle(Theme.text)
            Text(subtitle).font(.caption2).foregroundStyle(Theme.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(14)
        .background(Theme.surface2, in: RoundedRectangle(cornerRadius: Theme.radiusCard))
    }
}

/// The enterprise: core, recovery, regional, and the stores beneath them.
struct EnterpriseTopology: View {
    var sites: [Site]
    var onOpen: (String) -> Void

    /// Grouped by kind so the shape of the estate reads at a glance, in the
    /// order data actually flows: core, its recovery, the regions, the shops.
    private var order: [(kind: String, title: String, subtitle: String)] {
        [("core", L("Core"), L("cross-store reconciliation, supplier cases, approval controls")),
         ("recovery", L("Recovery"), L("replicated state and tested recovery capacity")),
         ("regional", L("Regional"), L("shared clusters serving store workloads and regional investigators")),
         ("stores", L("Stores"), L("lightweight connector with a protected offline queue"))]
    }

    var body: some View {
        ForEach(order, id: \.kind) { group in
            let members = sites.filter { $0.kind == group.kind }
            if !members.isEmpty {
                Card(group.title, trailing: group.subtitle) {
                    CardGrid(minimum: 220) {
                        ForEach(members, id: \.id) { site in
                            Button { onOpen(site.id) } label: { SiteTile(site: site) }
                                .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
}

struct SiteTile: View {
    var site: Site

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(site.name).font(.subheadline.bold()).foregroundStyle(Theme.text)
                Spacer()
                Image(systemName: "chevron.right").font(.caption2).foregroundStyle(Theme.muted)
            }
            Text(site.city).font(.caption).foregroundStyle(Theme.muted)

            // Latency and replication lag are what placement is actually decided
            // on, so they sit on the tile rather than inside it.
            HStack(spacing: 14) {
                figure(L("nodes"), "\(site.nodes)")
                figure(L("latency"), "\(site.latency) ms",
                       tint: site.latency > 40 ? Theme.warn : Theme.text)
                if site.kind == "recovery" {
                    figure(L("lag"), "\(site.lag) s", tint: site.lag > 0 ? Theme.warn : Theme.led)
                }
                if site.queued > 0 {
                    figure(L("queued"), "\(site.queued)", tint: Theme.warn)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface2, in: RoundedRectangle(cornerRadius: Theme.radiusCard))
    }

    private func figure(_ label: String, _ value: String, tint: Color = Theme.text) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(value).font(.footnote.bold()).foregroundStyle(tint)
            Text(label).font(.caption2).foregroundStyle(Theme.muted)
        }
    }
}

/// One site, and the cluster it runs.
///
/// The node list is generated from the site's node count on the same rule the
/// rack follows: octets of eight, plus an admin node when one is left over.
struct SiteScreen: View {
    @Query private var sites: [Site]
    var siteID: String?

    private var site: Site? { sites.first { $0.id == siteID } }

    var body: some View {
        ScreenScaffold(maxWidth: 1280) {
            if let site {
                ScreenHeader(screen: .sitio, title: site.name,
                             subtitle: "\(site.city) · \(site.nodes) \(L("nodes")) · \(L("latency to core")) \(site.latency) ms",
                             iconScreen: .topologia)

                CardGrid {
                    StatCard(value: "\(site.nodes)", label: L("nodes"),
                             icon: AnyView(BridgeIcon(.salud, size: 28)))
                    StatCard(value: "\(site.latency) ms", label: L("latency to core"),
                             tint: site.latency > 40 ? Theme.warn : Theme.text,
                             icon: AnyView(Image(systemName: "timer").font(.title2)
                                .foregroundStyle(Theme.text2)))
                    StatCard(value: site.stores > 0 ? "\(site.stores)" : "—", label: L("stores served"),
                             icon: AnyView(BridgeIcon(.tiendas, size: 28)))
                    if site.kind == "recovery" {
                        StatCard(value: "\(site.lag) s", label: L("replication lag"),
                                 tint: site.lag > 0 ? Theme.warn : Theme.led,
                                 icon: AnyView(Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(.title2).foregroundStyle(Theme.text2)))
                    }
                }

                Card(L("Cluster"), trailing: L("octets of eight plus an admin node")) {
                    ClusterMap(nodes: Self.nodes(for: site)) { _ in }
                }
            } else {
                ScreenHeader(screen: .sitio, title: L("Site"), iconScreen: .topologia)
                Card { Text(L("That record no longer exists.")).foregroundStyle(Theme.muted) }
            }
        }
    }

    /// Generated, not stored. The prototype does the same: a site's cluster
    /// follows from its node count and its kind, so there is nothing to record.
    static func nodes(for site: Site) -> [ClusterNode] {
        (0..<site.nodes).map { index in
            let octet = index / 8
            let isAdmin = index == site.nodes - 1 && site.nodes % 8 == 1
            let prefix = site.kind == "recovery" ? "R" : String(UnicodeScalar(65 + octet)!)
            let id = isAdmin ? "N\(site.nodes)" : "\(prefix)\(index % 8 + 1)"
            let seed = (Int(site.id.unicodeScalars.first?.value ?? 65) + index * 7) % 23
            return ClusterNode(
                id: id,
                role: isAdmin ? "Admin + spare"
                    : site.kind == "recovery" ? "Replica" : octet == 0 ? "Kimi shard" : "Llama 4",
                status: seed == 5 ? "warn" : "ok",
                tempC: 56 + (seed % 9) + (seed == 5 ? 22 : 0),
                memGB: 200 - (seed % 6) * 7,
                serial: "SN \(5200 + index)",
                ledger: "current")
        }
    }
}
