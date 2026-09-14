import SwiftUI
import SwiftData

/// Home: the whole system on one panel.
///
/// The prototype groups the tiles into Operate, Intelligence, Trust, Run and
/// Govern, each card carrying its icon, a one-line purpose and a live figure.
/// The grouping is the argument — it says the console has five kinds of work in
/// it — so it is kept rather than flattened into an alphabetical grid.
struct HomeScreen: View {
    @Environment(AppStore.self) private var store
    @Query private var nodes: [ClusterNode]
    @Query private var power: [PowerState]
    @Query private var invoices: [Invoice]
    @Query private var users: [User]

    /// Reception sees the essentials and nothing financial. Not a reduced
    /// version of the admin screen: a different screen.
    private var isReception: Bool { store.role == .reception }

    var body: some View {
        ScreenScaffold {
            if isReception { receptionView } else { fullView }
        }
    }

    // MARK: Reception

    private var receptionView: some View {
        VStack(alignment: .leading, spacing: 18) {
            ScreenHeader(screen: .home,
                         title: L("Reception view"),
                         subtitle: L("Your login shows the essentials; everything else stays private by role."))
            CardGrid {
                StatCard(value: "\(onlineNodes)/\(nodes.count)",
                         label: L("System health"),
                         icon: AnyView(BridgeIcon(.salud, size: 28)),
                         action: { store.navigator.go(.salud) })
                StatCard(value: "—", label: L("Agents running"),
                         icon: AnyView(BridgeIcon(.agentes, size: 28)),
                         action: { store.navigator.go(.agentes) })
                StatCard(value: L("Open chat"), label: "Bridge",
                         icon: AnyView(TaylorMark(size: 28)),
                         action: { store.navigator.go(.chat) })
            }
        }
    }

    // MARK: The console

    private var fullView: some View {
        VStack(alignment: .leading, spacing: 20) {
            greeting
            chips
            ForEach(HomeGroup.all, id: \.title) { group in
                if !visible(group).isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(group.title)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Theme.muted)
                            .textCase(.uppercase)
                            .tracking(1)
                        CardGrid(minimum: 240) {
                            ForEach(visible(group), id: \.self) { screen in
                                HomeTile(screen: screen, hint: hint(for: screen)) {
                                    store.navigator.go(screen)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var greeting: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(Key.good_morning.string), \(displayName)")
                    .font(.largeTitle.weight(.semibold)).foregroundStyle(Theme.text)
                Text(Key.one_panel.string).font(.subheadline).foregroundStyle(Theme.text2)
            }
            Spacer()
            BridgeMark(size: 44)
        }
    }

    /// The live figures the prototype shows across the top.
    ///
    /// No node count here: the RC2 brief forbids one before a signed discovery
    /// agreement, so the cluster chip says whether it is healthy, not how big.
    private var chips: some View {
        HStack(spacing: 10) {
            Chip(text: allHealthy ? Key.chip_cluster.string : L("Cluster needs attention"),
                 dot: allHealthy ? Theme.led : Theme.warn) { store.navigator.go(.salud) }
            if let p = reading {
                Chip(text: "\(p.islanded ? L("Islanded") : Key.chip_sun.string) · \(String(format: "%.1f", p.solarKW)) kW",
                     dot: Theme.power) { store.navigator.go(.energia) }
            }
            Chip(text: "\(repPending) \(L("REP pending"))",
                 dot: repPending > 0 ? Theme.warn : Theme.led) { store.navigator.go(.facturas) }
            SampleBadge()
        }
    }

    // MARK: Data

    private var displayName: String {
        users.first { $0.id == store.user }?.name ?? store.user
    }
    private var onlineNodes: Int { nodes.filter { $0.status != "down" }.count }
    private var allHealthy: Bool { !nodes.isEmpty && onlineNodes == nodes.count }
    private var repPending: Int { invoices.filter { $0.stage == "rep_pending" }.count }
    private var reading: PowerReading? { power.first.map(PowerReading.init(model:)) }

    private func visible(_ group: HomeGroup) -> [Screen] {
        group.screens.filter { store.role?.canOpen($0) == true }
    }

    /// The live figure a tile shows under its name.
    private func hint(for screen: Screen) -> String? {
        switch screen {
        case .salud: allHealthy ? Key.chip_cluster.string : L("needs attention")
        case .facturas: "\(repPending) \(L("REP pending"))"
        case .energia: reading.map { String(format: "%.1f kW", $0.solarKW) }
        case .cadena: "\(store.chain.count) \(L("sealed"))"
        default: nil
        }
    }
}

/// One Home tile.
struct HomeTile: View {
    var screen: Screen
    var hint: String?
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    BridgeIcon(screen, size: 34)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(Key(rawValue: "nav_\(screen.rawValue)")?.string ?? screen.rawValue)
                            .font(.headline).foregroundStyle(Theme.text)
                        if let blurb = HomeGroup.blurb(for: screen) {
                            Text(blurb).font(.caption).foregroundStyle(Theme.text2)
                                .fixedSize(horizontal: false, vertical: true)
                                .multilineTextAlignment(.leading)
                        }
                    }
                    Spacer(minLength: 0)
                }
                if let hint {
                    Chip(text: hint)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 112, alignment: .topLeading)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.radiusCard))
            .overlay(RoundedRectangle(cornerRadius: Theme.radiusCard).stroke(Theme.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

/// Home's five groups, from the prototype's `HOME_GROUPS`.
struct HomeGroup {
    var title: String
    var screens: [Screen]

    static var all: [HomeGroup] {
        [
            HomeGroup(title: L("Operate"), screens: [.cobranza, .facturas, .conciliacion, .tiendas]),
            HomeGroup(title: L("Intelligence"), screens: [.agentes, .chat, .modelos, .catalogo]),
            HomeGroup(title: L("Trust"), screens: [.cadena, .auditoria, .politicas, .datos]),
            HomeGroup(title: L("Run"), screens: [.salud, .energia, .topologia, .incidentes,
                                                 .actualizar, .configuracion]),
            HomeGroup(title: L("Govern"), screens: [.medidas, .integraciones, .ajustes, .perfil]),
        ]
    }

    /// One line saying what a screen is for, from `SCREEN_BLURB`.
    static func blurb(for screen: Screen) -> String? {
        switch screen {
        case .cobranza: L("accounts being chased, and by whom")
        case .facturas: L("the CFDI cycle, issue to REP")
        case .conciliacion: L("four records, one owning case")
        case .tiendas: L("stores, their connectors and queues")
        case .agentes: L("what runs, under which guardrails")
        case .chat: L("a private assistant with provenance")
        case .modelos: L("what is installed on the cluster")
        case .catalogo: L("what could be installed")
        case .cadena: L("every action, sealed in order")
        case .auditoria: L("what the seal proves, and what it does not")
        case .politicas: L("guardrails and terms, versioned")
        case .datos: L("what is held, and who may see it")
        case .salud: L("nodes, temperature, memory")
        case .energia: L("sun, bank, grid, bridge")
        case .topologia: L("stores, regions, recovery")
        case .incidentes: L("what is open, and who has it")
        case .actualizar: L("what changed, and what it replaced")
        case .configuracion: L("the cluster as hardware")
        case .medidas: L("the pilot, measured")
        case .integraciones: L("what Bridge is connected to")
        case .ajustes: L("console settings")
        case .perfil: L("your account")
        default: nil
        }
    }
}

extension PowerReading {
    init(model: PowerState) {
        self.init(solarKW: model.solarKW, batteryPct: model.batteryPct, grid: model.grid,
                  islanded: model.islanded, reservePct: model.reservePct,
                  curtail: model.curtail, upsMin: model.upsMin)
    }
}
