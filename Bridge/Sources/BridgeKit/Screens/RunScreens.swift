import SwiftUI
import SwiftData

/// Models installed on the cluster.
///
/// In a client build every name here is neutral, and the catalogue of what
/// *could* be installed is not reachable at all — a list of candidate models is
/// a list of model names.
struct ModelsScreen: View {
    @Environment(AppStore.self) private var store
    @Query private var models: [InstalledModel]

    var body: some View {
        ScreenScaffold {
            ScreenHeader(screen: .modelos, title: Key.nav_modelos.string,
                         subtitle: L("what is installed on the cluster"))

            CardGrid(minimum: 260) {
                ForEach(models, id: \.id) { model in
                    Button { store.navigator.go(.modelo, model.id) } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(DemoMode.modelName(model.name))
                                .font(.headline).foregroundStyle(Theme.text)
                            Text(model.version).font(.caption).foregroundStyle(Theme.text2)
                            StatusPill(kind: model.status == "ok" ? .ok : .warn,
                                       text: model.status == "ok" ? L("installed") : model.status)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.radiusCard))
                        .overlay(RoundedRectangle(cornerRadius: Theme.radiusCard)
                            .stroke(Theme.line, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }

            if DemoMode.showsModelCatalogue {
                Button(L("Latest models")) { store.navigator.go(.catalogo) }
                    .buttonStyle(.bordered)
            }
        }
    }
}

struct ModelScreen: View {
    @Query private var models: [InstalledModel]
    var modelID: String?

    var body: some View {
        ScreenScaffold {
            if let model = models.first(where: { $0.id == modelID }) {
                ScreenHeader(screen: .modelo, title: DemoMode.modelName(model.name),
                             subtitle: model.version, iconScreen: .modelos)
                Card(L("Installed")) {
                    CardGrid(minimum: 170) {
                        KeyValue(label: L("Name"), value: DemoMode.modelName(model.name))
                        KeyValue(label: L("Version"), value: model.version, monospaced: true)
                        KeyValue(label: L("Status"), value: model.status,
                                 tint: model.status == "ok" ? Theme.led : Theme.warn)
                        KeyValue(label: L("Activated"), value: model.activatedAt, monospaced: true)
                    }
                }
            } else {
                ScreenHeader(screen: .modelo, title: L("Model"), iconScreen: .modelos)
                Card { Text(L("That record no longer exists.")).foregroundStyle(Theme.muted) }
            }
        }
    }
}

/// The catalogue of what could be installed. Not reachable in a client build.
struct CatalogueScreen: View {
    var body: some View {
        ScreenScaffold {
            ScreenHeader(screen: .catalogo, title: Key.nav_catalogo.string,
                         subtitle: L("what could be installed"))
            if DemoMode.showsModelCatalogue {
                Card(L("Candidates")) {
                    Text(L("The catalogue is internal. It names model families, parameter counts and sources, none of which belong in a client conversation before a signed discovery agreement."))
                        .font(.callout).foregroundStyle(Theme.text2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                NotInThisBuild()
            }
        }
    }
}

/// The hardware planner. Hidden in a client build: it shows a bill of materials
/// and list prices, which section 7 forbids outright.
struct ConfigurationScreen: View {
    @Query private var nodes: [ClusterNode]

    var body: some View {
        ScreenScaffold {
            ScreenHeader(screen: .configuracion, title: Key.nav_configuracion.string,
                         subtitle: L("the cluster as hardware"))
            if DemoMode.showsConfiguration {
                Card(L("This rack")) {
                    CardGrid(minimum: 170) {
                        KeyValue(label: L("Machines"), value: DemoMode.nodeCount(nodes.count))
                        KeyValue(label: L("Octets"), value: "\(max(1, nodes.count / 8))")
                        KeyValue(label: L("Steady load"),
                                 value: String(format: "%.1f kW", Energy.rackKW))
                    }
                    Text(L("The planner stays internal. It carries a bill of materials and list prices, and neither belongs in front of a client before a signed discovery agreement."))
                        .font(.caption).foregroundStyle(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                NotInThisBuild()
            }
        }
    }
}

/// Integrations: what Bridge is connected to.
struct IntegrationsScreen: View {
    @Environment(AppStore.self) private var store
    @Query private var integrations: [Integration]

    var body: some View {
        ScreenScaffold {
            if !store.canWrite { ReadOnlyBanner() }
            ScreenHeader(screen: .integraciones, title: Key.nav_integraciones.string,
                         subtitle: L("what Bridge is connected to"))

            Card(L("Connected")) {
                if integrations.isEmpty {
                    Text(L("Nothing connected yet.")).font(.callout).foregroundStyle(Theme.muted)
                }
                ForEach(integrations, id: \.id) { integration in
                    Button { store.navigator.go(.integracion, integration.id) } label: {
                        HStack {
                            Text(integration.name).font(.callout).foregroundStyle(Theme.text)
                            Spacer()
                            StatusPill(kind: integration.status == "ok" ? .ok : .warn,
                                       text: integration.status == "ok" ? L("connected") : integration.status)
                            Image(systemName: "chevron.right")
                                .font(.caption2).foregroundStyle(Theme.muted)
                        }
                        .padding(.vertical, 7)
                    }
                    .buttonStyle(.plain)
                    Divider().overlay(Theme.line)
                }
                Button(L("Connect something")) { store.navigator.go(.conectar) }
                    .buttonStyle(.bordered)
                    .disabled(!store.canWrite)
            }
        }
    }
}

struct IntegrationScreen: View {
    @Query private var integrations: [Integration]
    var integrationID: String?

    var body: some View {
        ScreenScaffold {
            if let integration = integrations.first(where: { $0.id == integrationID }) {
                ScreenHeader(screen: .integracion, title: integration.name,
                             subtitle: integration.template, iconScreen: .integraciones)
                Card(L("Connection")) {
                    CardGrid(minimum: 170) {
                        KeyValue(label: L("Family"), value: integration.family)
                        KeyValue(label: L("Endpoint"), value: integration.endpoint, monospaced: true)
                        KeyValue(label: L("Status"), value: integration.status,
                                 tint: integration.status == "ok" ? Theme.led : Theme.warn)
                        KeyValue(label: L("Last tested"), value: integration.lastTest, monospaced: true)
                    }
                    Text(L("Secrets for this connection are held in the Keychain and are never displayed after they are entered."))
                        .font(.caption).foregroundStyle(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                ScreenHeader(screen: .integracion, title: "API", iconScreen: .integraciones)
                Card { Text(L("That record no longer exists.")).foregroundStyle(Theme.muted) }
            }
        }
    }
}

/// The connection wizard, with the validators the prototype uses.
struct ConnectScreen: View {
    @Environment(AppStore.self) private var store
    @State private var host = ""
    @State private var port = "443"
    @State private var rfc = ""
    @State private var clabe = ""

    var body: some View {
        ScreenScaffold {
            if !store.canWrite { ReadOnlyBanner() }
            ScreenHeader(screen: .conectar, title: L("Connect"),
                         subtitle: L("where it is, and who it says it is"),
                         iconScreen: .integraciones)

            Card(L("Endpoint")) {
                ValidatedField(label: L("Host"), text: $host, validate: Validator.host)
                ValidatedField(label: L("Port"), text: $port, validate: Validator.port)
            }

            Card(L("Identity")) {
                ValidatedField(label: "RFC", text: $rfc, validate: Validator.rfc)
                ValidatedField(label: "CLABE", text: $clabe, validate: Validator.clabe)
                Text(L("The CLABE check digit is verified here. Eighteen digits that merely look right are accepted by a form and refused by a bank, and the person who typed them finds out days later."))
                    .font(.caption).foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

/// A field that says what is wrong while it is being typed, not on submit.
struct ValidatedField: View {
    var label: String
    @Binding var text: String
    var validate: (String) -> Validator.Result

    var body: some View {
        let result = text.isEmpty ? Validator.Result.valid : validate(text)
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption).foregroundStyle(Theme.muted)
            TextField(label, text: $text)
                .textFieldStyle(.roundedBorder)
                .overlay(RoundedRectangle(cornerRadius: 6)
                    .stroke(result.isValid ? Color.clear : Theme.crit, lineWidth: 1))
            if !result.isValid {
                Text(result.message).font(.caption2).foregroundStyle(Theme.crit)
            }
        }
    }
}

/// The installer. Internal: it reports how many machines it found.
struct InstallerScreen: View {
    var body: some View {
        ScreenScaffold {
            ScreenHeader(screen: .installer, title: L("Installer"),
                         subtitle: L("bring a rack up"), iconScreen: .configuracion)
            if DemoMode.canShow(.installer) {
                Card(L("Steps")) {
                    Text(L("The installer discovers machines, forms the octets, installs the models and seals the first event. It reports how many machines it found, which is a node count, so it stays internal."))
                        .font(.callout).foregroundStyle(Theme.text2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                NotInThisBuild()
            }
        }
    }
}

/// Shown where a screen is absent from this build rather than empty.
///
/// Said plainly. An empty screen invites the question of what was removed, and
/// the honest answer is better than the guess.
struct NotInThisBuild: View {
    var body: some View {
        Card {
            HStack(spacing: 10) {
                Image(systemName: "eye.slash").foregroundStyle(Theme.muted)
                Text(L("This screen is not part of the client build."))
                    .font(.callout).foregroundStyle(Theme.text2)
            }
            Text(L("It carries node counts, model names or prices, which are internal until a discovery agreement is signed."))
                .font(.caption).foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
