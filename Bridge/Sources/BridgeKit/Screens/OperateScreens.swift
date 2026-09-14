import SwiftUI
import SwiftData

/// Collections: the accounts being chased, and by whom.
struct CollectionsScreen: View {
    @Environment(AppStore.self) private var store
    @Query private var accounts: [Account]
    @State private var search = ""

    var body: some View {
        ScreenScaffold {
            if !store.canWrite { ReadOnlyBanner() }
            ScreenHeader(screen: .cobranza, title: Key.nav_cobranza.string,
                         subtitle: L("accounts being chased, and by whom"))

            HStack(spacing: 10) {
                Chip(text: "\(accounts.count) \(L("accounts"))", dot: Theme.led)
                Chip(text: "\(escalated) \(L("escalated"))",
                     dot: escalated > 0 ? Theme.warn : Theme.led)
                SampleBadge()
            }

            Card(L("Accounts")) {
                TextField(L("Search"), text: $search).textFieldStyle(.roundedBorder)
                ForEach(filtered, id: \.id) { account in
                    Button { store.navigator.go(.cuenta, account.id) } label: {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(account.name).font(.callout).foregroundStyle(Theme.text)
                                Text(account.uuid).font(Theme.mono).foregroundStyle(Theme.muted)
                            }
                            Spacer()
                            Text("\(L("next")) \(account.next)")
                                .font(.caption).foregroundStyle(Theme.text2)
                            StatusPill(kind: account.paused ? .muted
                                            : account.escalated ? .warn : .ok,
                                       text: account.paused ? L("paused")
                                            : account.escalated ? L("escalated") : account.status)
                            Image(systemName: "chevron.right")
                                .font(.caption2).foregroundStyle(Theme.muted)
                        }
                        .padding(.vertical, 7)
                    }
                    .buttonStyle(.plain)
                    Divider().overlay(Theme.line)
                }
            }
        }
    }

    private var escalated: Int { accounts.filter(\.escalated).count }
    private var filtered: [Account] {
        accounts.filter { search.isEmpty || $0.name.localizedCaseInsensitiveContains(search) }
    }
}

/// One account.
struct AccountScreen: View {
    @Environment(AppStore.self) private var store
    @Query private var accounts: [Account]
    var accountID: String?

    private var account: Account? { accounts.first { $0.id == accountID } }

    var body: some View {
        ScreenScaffold {
            if let account {
                ScreenHeader(screen: .cuenta, title: account.name,
                             subtitle: account.uuid, iconScreen: .cobranza)

                CardGrid {
                    StatCard(value: account.status, label: L("Status"),
                             tint: account.escalated ? Theme.warn : Theme.led,
                             icon: AnyView(BridgeIcon(.cobranza, size: 28)))
                    StatCard(value: "\(account.touchesToday)", label: L("Touches today"),
                             icon: AnyView(Image(systemName: "hand.tap").font(.title2)
                                .foregroundStyle(Theme.text2)))
                    StatCard(value: account.next, label: L("Next contact"),
                             icon: AnyView(Image(systemName: "clock").font(.title2)
                                .foregroundStyle(Theme.text2)))
                }

                Card(L("Actions")) {
                    HStack(spacing: 10) {
                        Button(account.paused ? L("Resume") : L("Pause")) {
                            Task { await store.dispatch(.pauseAccount(id: account.id,
                                                                     paused: !account.paused)) }
                        }
                        .buttonStyle(.bordered)
                        .disabled(!store.canWrite)

                        Button(L("Escalate")) {
                            Task { await store.dispatch(.escalateAccount(id: account.id)) }
                        }
                        .buttonStyle(.bordered)
                        .disabled(!store.canWrite || account.escalated)
                    }
                    Text(L("Every action here is sealed to the chain with who took it."))
                        .font(.caption).foregroundStyle(Theme.muted)
                }
            } else {
                ScreenHeader(screen: .cuenta, title: L("Account"), iconScreen: .cobranza)
                Card { Text(L("That record no longer exists.")).foregroundStyle(Theme.muted) }
            }
        }
    }
}

/// Agents: what runs, under which guardrails.
struct AgentsScreen: View {
    @Environment(AppStore.self) private var store
    @Query private var agents: [Agent]

    var body: some View {
        ScreenScaffold {
            if !store.canWrite { ReadOnlyBanner() }
            ScreenHeader(screen: .agentes, title: Key.nav_agentes.string,
                         subtitle: L("what runs, under which guardrails"))

            HStack(spacing: 10) {
                Chip(text: "\(active) \(L("active"))", dot: Theme.led)
                Chip(text: "AgentStudio") { store.navigator.go(.studio) }
                SampleBadge()
            }

            CardGrid(minimum: 260) {
                ForEach(agents, id: \.id) { agent in
                    Button { store.navigator.go(.agente, agent.id) } label: {
                        AgentCard(agent: agent)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var active: Int { agents.filter { $0.status == "active" }.count }
}

struct AgentCard: View {
    var agent: Agent

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(agent.name).font(.headline).foregroundStyle(Theme.text)
                Spacer()
                StatusPill(kind: agent.status == "active" ? .ok : .muted, text: agent.status)
            }
            Text(agent.tone).font(.caption).foregroundStyle(Theme.text2)
                .fixedSize(horizontal: false, vertical: true)
            Text(agent.limits).font(.caption2).foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 8) {
                Chip(text: "v\(agent.version)")
                SampleBadge()
            }
            // The rule, on every card. An agent that appears to decide on its
            // own is the impression this product cannot afford to leave.
            Text(L("The agent recommends; a person decides."))
                .font(.caption2).foregroundStyle(Theme.muted)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.radiusCard))
        .overlay(RoundedRectangle(cornerRadius: Theme.radiusCard).stroke(Theme.line, lineWidth: 1))
    }
}

/// One agent.
struct AgentScreen: View {
    @Query private var agents: [Agent]
    var agentID: String?

    private var agent: Agent? { agents.first { $0.id == agentID } }

    var body: some View {
        ScreenScaffold {
            if let agent {
                ScreenHeader(screen: .agente, title: agent.name,
                             subtitle: agent.kind, iconScreen: .agentes)
                Card(L("Guardrails")) {
                    CardGrid(minimum: 160) {
                        KeyValue(label: L("Version"), value: "v\(agent.version)")
                        KeyValue(label: L("Status"), value: agent.status)
                        KeyValue(label: L("Published"), value: agent.publishedAt, monospaced: true)
                    }
                    KeyValue(label: L("Tone"), value: agent.tone)
                    KeyValue(label: L("Limits"), value: agent.limits)
                }
                Card(L("What this agent may not do")) {
                    Text(L("It recommends and it records. It does not approve a payment, close a case on its own, or state that a document is fiscally valid."))
                        .font(.callout).foregroundStyle(Theme.text2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                ScreenHeader(screen: .agente, title: L("Agent"), iconScreen: .agentes)
                Card { Text(L("That record no longer exists.")).foregroundStyle(Theme.muted) }
            }
        }
    }
}

/// Incidents.
struct IncidentsScreen: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        ScreenScaffold {
            if !store.canWrite { ReadOnlyBanner() }
            ScreenHeader(screen: .incidentes, title: Key.nav_incidentes.string,
                         subtitle: L("what is open, and who has it"))
            Card {
                Text(L("No incidents open."))
                    .font(.callout).foregroundStyle(Theme.muted)
                Text(L("The incidents store is written by the running console and is not seeded, so there is nothing to show until something happens."))
                    .font(.caption).foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct IncidentScreen: View {
    var incidentID: String?

    var body: some View {
        ScreenScaffold {
            ScreenHeader(screen: .incidente, title: L("Incident"), iconScreen: .incidentes)
            Card { Text(L("That record no longer exists.")).foregroundStyle(Theme.muted) }
        }
    }
}
