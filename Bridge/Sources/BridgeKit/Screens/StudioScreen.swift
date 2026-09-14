import SwiftUI
import SwiftData

/// What an agent is allowed to see and act on.
///
/// This is RC2's addition: an agent scoped to one store, one supplier or one
/// route, rather than to everything. It is the layer the enterprise lacks
/// between a planogram and twenty-four thousand shops — and the reason "an agent
/// per store" means store-scoped agents on shared model services, never
/// thousands of models.
public struct AgentScope: Sendable, Equatable {
    public enum Kind: String, Sendable, CaseIterable, Identifiable {
        case accounts, store, supplier, route
        public var id: String { rawValue }

        public var label: String {
            switch self {
            case .accounts: L("All accounts")
            case .store: L("One store")
            case .supplier: L("One supplier")
            case .route: L("One route")
            }
        }

        public var explanation: String {
            switch self {
            case .accounts: L("The agent sees every account in its division. Use this only where the work genuinely spans them.")
            case .store: L("The agent sees one store's records. Twenty-four thousand scoped agents share the same model services; they are not twenty-four thousand models.")
            case .supplier: L("The agent sees one supplier across the stores that buy from it.")
            case .route: L("The agent sees one delivery route and the stores on it.")
            }
        }
    }

    public var kind: Kind
    public var target: String

    public init(kind: Kind = .accounts, target: String = "") {
        self.kind = kind
        self.target = target
    }

    /// A scope narrower than "everything" needs to name what it is narrowed to.
    /// An unnamed store scope is a scope that does not restrict anything.
    public var isComplete: Bool {
        kind == .accounts || !target.trimmingCharacters(in: .whitespaces).isEmpty
    }
}

/// The template an agent starts from.
public enum AgentTemplate: String, CaseIterable, Identifiable {
    case planogram, supplierDocuments, blank
    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .planogram: L("Planogram compliance")
        case .supplierDocuments: L("Supplier documents")
        case .blank: L("Start from nothing")
        }
    }

    public var purpose: String {
        switch self {
        case .planogram: L("Reads the planned shelf against tickets and replenishment for one store, and reports what differs. This is the Discovery measurement.")
        case .supplierDocuments: L("Watches one supplier's CFDI, receiving records and payment complements, and opens a case when they disagree.")
        case .blank: L("No template. Scope, guardrails and tone are set by hand.")
        }
    }

    public var suggestedScope: AgentScope.Kind {
        switch self {
        case .planogram: .store
        case .supplierDocuments: .supplier
        case .blank: .accounts
        }
    }
}

/// AgentStudio, step one: what this agent is for and what it may see.
///
/// The rest of the creator — tone, limits, rehearsal, publication — lands in
/// phase 5. Scope comes first because it is the step RC2 added and the one that
/// decides whether "an agent per store" is a sentence about deployment or about
/// permissions.
struct StudioScreen: View {
    @Environment(AppStore.self) private var store
    @Query private var stores: [StoreSite]
    @Query private var suppliers: [Supplier]
    @State private var template: AgentTemplate = .planogram
    @State private var scope = AgentScope(kind: .store)

    var body: some View {
        ScreenScaffold {
            if !store.canWrite { ReadOnlyBanner() }

            ScreenHeader(screen: .studio, title: "AgentStudio",
                         subtitle: L("what this agent is for, and what it is allowed to see"),
                         iconScreen: .agentes)

            Card(L("Template")) {
                ForEach(AgentTemplate.allCases) { option in
                    Button {
                        template = option
                        scope.kind = option.suggestedScope
                        scope.target = ""
                    } label: {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: template == option
                                  ? "largecircle.fill.circle" : "circle")
                                .foregroundStyle(template == option ? Theme.led : Theme.muted)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(option.label).font(.callout.bold()).foregroundStyle(Theme.text)
                                Text(option.purpose).font(.caption).foregroundStyle(Theme.text2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                }
            }

            Card(L("Scope"), trailing: L("step 1 of 7")) {
                Picker(L("Scope"), selection: $scope.kind) {
                    ForEach(AgentScope.Kind.allCases) { Text($0.label).tag($0) }
                }
                .pickerStyle(.segmented)

                Text(scope.kind.explanation).font(.caption).foregroundStyle(Theme.text2)
                    .fixedSize(horizontal: false, vertical: true)

                switch scope.kind {
                case .store:
                    Picker(L("Store"), selection: $scope.target) {
                        Text(L("Choose a store")).tag("")
                        ForEach(stores, id: \.id) { Text("\($0.id) · \($0.name)").tag($0.id) }
                    }
                case .supplier:
                    Picker(L("Supplier"), selection: $scope.target) {
                        Text(L("Choose a supplier")).tag("")
                        ForEach(suppliers, id: \.id) { Text($0.name).tag($0.id) }
                    }
                case .route:
                    TextField(L("Route"), text: $scope.target).textFieldStyle(.roundedBorder)
                case .accounts:
                    EmptyView()
                }

                if !scope.isComplete {
                    StatusPill(kind: .warn, text: L("A narrowed scope must name what it is narrowed to."))
                }
            }

            Card(L("What a scoped agent is not")) {
                Text(L("A store-scoped agent is a permission boundary, not a model. Every scoped agent in the estate runs on the same shared model services; scoping decides what it may read and act on, not what it thinks with."))
                    .font(.callout).foregroundStyle(Theme.text2)
                    .fixedSize(horizontal: false, vertical: true)
                Text(L("A person still decides. The agent recommends, and the chain records both the recommendation and the decision."))
                    .font(.caption).foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
