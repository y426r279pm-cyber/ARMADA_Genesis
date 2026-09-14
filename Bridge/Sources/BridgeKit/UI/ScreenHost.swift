// Written once by tools, then maintained by hand. Unlike the files under
// Theme/, Router/Route.swift, RBAC/, Icons/, Model/ and Localization/, this one
// is NOT regenerated: replace a stub with the real screen as each is built.
//
// The switch has no `default` on purpose. A route added to the prototype and
// picked up by tools/extract_routes.py will break this build until somebody
// decides what it shows, which is the correct moment to decide it.

import SwiftUI

/// Resolves a route to its screen.
struct ScreenHost: View {
    let screen: Screen
    let recordID: String?

    var body: some View {
        switch screen {
        case .login:
            // Handled by BridgeRootView before the console is shown.
            EmptyView()

        // MARK: Phase 2 · the demo path (built)
        case .auditoria: AuditScreen()
        case .baterias: EnergyDetailScreen(screen: .baterias)
        case .cadena: ChainScreen()
        case .energia: EnergyScreen()
        case .evento: EventScreen(eventID: recordID)
        case .factura: InvoiceScreen(invoiceID: recordID)
        case .facturas: InvoicesScreen()
        case .home: HomeScreen()
        case .nodo: NodeScreen(nodeID: recordID)
        case .red: EnergyDetailScreen(screen: .red)
        case .salud: HealthScreen()
        case .solar: EnergyDetailScreen(screen: .solar)
        case .ups: EnergyDetailScreen(screen: .ups)

        // MARK: Phase 3 · the Enterprise group (built)
        case .caso: CaseScreen(caseID: recordID)
        case .conciliacion: MatchScreen()
        case .medidas: MeasuresScreen()
        case .sitio: SiteScreen(siteID: recordID)
        case .studio: StudioScreen()
        case .tienda: StoreScreen(storeID: recordID)
        case .tiendas: StoresScreen()
        case .topologia: TopologyScreen()

        // MARK: Phase 4 · Taylor
        case .chat: ScreenStub(.chat, recordID: recordID, phase: 4)

        // MARK: Phase 5 · the rest
        case .actualizar: ScreenStub(.actualizar, recordID: recordID, phase: 5)
        case .agente: ScreenStub(.agente, recordID: recordID, phase: 5)
        case .agentes: ScreenStub(.agentes, recordID: recordID, phase: 5)
        case .ajustes: ScreenStub(.ajustes, recordID: recordID, phase: 5)
        case .catalogo: ScreenStub(.catalogo, recordID: recordID, phase: 5)
        case .cobranza: ScreenStub(.cobranza, recordID: recordID, phase: 5)
        case .conectar: ScreenStub(.conectar, recordID: recordID, phase: 5)
        case .configuracion: ScreenStub(.configuracion, recordID: recordID, phase: 5)
        case .cuenta: ScreenStub(.cuenta, recordID: recordID, phase: 5)
        case .datos: ScreenStub(.datos, recordID: recordID, phase: 5)
        case .incidente: ScreenStub(.incidente, recordID: recordID, phase: 5)
        case .incidentes: ScreenStub(.incidentes, recordID: recordID, phase: 5)
        case .installer: ScreenStub(.installer, recordID: recordID, phase: 5)
        case .integracion: ScreenStub(.integracion, recordID: recordID, phase: 5)
        case .integraciones: ScreenStub(.integraciones, recordID: recordID, phase: 5)
        case .modelo: ScreenStub(.modelo, recordID: recordID, phase: 5)
        case .modelos: ScreenStub(.modelos, recordID: recordID, phase: 5)
        case .perfil: ScreenStub(.perfil, recordID: recordID, phase: 5)
        case .politicas: ScreenStub(.politicas, recordID: recordID, phase: 5)
        case .usuario: ScreenStub(.usuario, recordID: recordID, phase: 5)
        }
    }
}

/// A screen that has not been built yet.
///
/// Deliberately plain, and deliberately honest about being a stub: a
/// half-dressed screen invites being mistaken for a finished one.
struct ScreenStub: View {
    let screen: Screen
    let recordID: String?
    let phase: Int

    init(_ screen: Screen, recordID: String?, phase: Int) {
        self.screen = screen
        self.recordID = recordID
        self.phase = phase
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                BridgeIcon(screen, size: 40)
                VStack(alignment: .leading, spacing: 2) {
                    Text(Key(rawValue: "nav_\(screen.rawValue)")?.string ?? screen.rawValue)
                        .font(.largeTitle.weight(.semibold))
                        .foregroundStyle(Theme.text)
                    if let recordID {
                        Text(recordID).font(Theme.mono).foregroundStyle(Theme.muted)
                    }
                }
            }
            Text("Not built yet \u{00B7} phase \(phase)")
                .font(.footnote)
                .foregroundStyle(Theme.warn)
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(Theme.surface2, in: Capsule())
            Spacer()
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
