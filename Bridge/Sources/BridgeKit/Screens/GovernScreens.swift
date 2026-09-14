import SwiftUI
import SwiftData

/// Policies: guardrails and terms, versioned, with a clause-level diff.
struct PoliciesScreen: View {
    @Environment(AppStore.self) private var store
    @Query private var policies: [Policy]
    @State private var selected: String?
    @State private var draft = ""
    @State private var editing = false
    @State private var major = false

    var body: some View {
        ScreenScaffold(maxWidth: 1180) {
            if !store.canWrite { ReadOnlyBanner() }
            ScreenHeader(screen: .politicas, title: L("Policies"),
                         subtitle: L("guardrails and terms, versioned"), iconScreen: .politicas)

            HStack(alignment: .top, spacing: 14) {
                Card(L("Documents")) {
                    ForEach(policies, id: \.id) { policy in
                        Button {
                            selected = policy.id
                            draft = policy.text
                            editing = false
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(policy.displayTitle).font(.callout).foregroundStyle(Theme.text)
                                    Text("v\(policy.version)").font(.caption)
                                        .foregroundStyle(Theme.muted)
                                }
                                Spacer()
                                if selected == policy.id {
                                    Image(systemName: "checkmark").font(.caption)
                                        .foregroundStyle(Theme.led)
                                }
                            }
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(.plain)
                        Divider().overlay(Theme.line)
                    }
                }
                .frame(maxWidth: 280)

                if let policy = policies.first(where: { $0.id == selected }) {
                    editor(policy)
                } else {
                    Card { Text(L("Choose a document.")).foregroundStyle(Theme.muted) }
                }
            }
        }
    }

    @ViewBuilder private func editor(_ policy: Policy) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Card(policy.displayTitle, trailing: "v\(policy.version)") {
                if editing {
                    TextEditor(text: $draft)
                        .font(.body)
                        .frame(minHeight: 260)
                        .scrollContentBackground(.hidden)
                        .background(Theme.input, in: RoundedRectangle(cornerRadius: Theme.radiusCtl))
                } else {
                    Text(policy.text).font(.body).foregroundStyle(Theme.text2)
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)
                }

                HStack(spacing: 10) {
                    Button(editing ? L("Cancel") : L("Edit")) {
                        editing.toggle()
                        draft = policy.text
                    }
                    .buttonStyle(.bordered)
                    .disabled(!store.canWrite)

                    if editing {
                        Toggle(L("Major change"), isOn: $major)
                            .toggleStyle(.switch)
                        Text("→ v\(Policies.nextVersion(after: policy.version, major: major))")
                            .font(.caption).foregroundStyle(Theme.led)
                        Button(L("Publish")) {
                            Task {
                                await store.dispatch(.publishPolicy(
                                    id: policy.id,
                                    version: Policies.nextVersion(after: policy.version, major: major)))
                                editing = false
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(draft == policy.text)
                    }
                }
            }

            if editing, draft != policy.text {
                let changes = Policies.diff(policy.text, draft)
                Card(L("What changes"), trailing: Policies.summary(of: changes)) {
                    ForEach(changes.filter { $0.kind != .unchanged }) { change in
                        DiffRow(change: change)
                    }
                }
            }

            Card(L("Why a policy is versioned rather than edited")) {
                Text(L("An agent's recommendation carries the guardrails version it was written beneath. For that to be readable later, the version has to still exist — so publishing writes a new one instead of replacing the old."))
                    .font(.callout).foregroundStyle(Theme.text2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct DiffRow: View {
    var change: Policies.Change

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 8) {
                Text(marker).font(Theme.mono).foregroundStyle(tint)
                Text(label).font(.caption2).foregroundStyle(tint)
            }
            if let previous = change.previous {
                Text(previous).font(.caption).foregroundStyle(Theme.muted)
                    .strikethrough()
                    .fixedSize(horizontal: false, vertical: true)
            }
            if change.kind != .removed {
                Text(change.text).font(.caption).foregroundStyle(Theme.text)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(change.text).font(.caption).foregroundStyle(Theme.muted)
                    .strikethrough()
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 5)
    }

    private var marker: String {
        switch change.kind {
        case .added: "+"
        case .removed: "−"
        case .changed: "~"
        case .unchanged: " "
        }
    }

    private var tint: Color {
        switch change.kind {
        case .added: Theme.led
        case .removed: Theme.crit
        case .changed: Theme.warn
        case .unchanged: Theme.muted
        }
    }

    private var label: String {
        switch change.kind {
        case .added: L("added")
        case .removed: L("removed")
        case .changed: L("changed")
        case .unchanged: ""
        }
    }
}

/// Data: what is held, and who may see it.
struct DataScreen: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        ScreenScaffold {
            ScreenHeader(screen: .datos, title: Key.nav_datos.string,
                         subtitle: L("what is held, and who may see it"))

            CardGrid {
                StatCard(value: "\(store.chain.count)", label: Ll("Sealed events"),
                         icon: AnyView(BridgeIcon(.cadena, size: 28)),
                         action: { store.navigator.go(.cadena) })
                // Not routed through DemoMode: a count of record stores is not a
                // node count, and redacting what the rule never covered would be
                // its own kind of dishonesty.
                StatCard(value: "\(store.seedCounts.count)", label: L("stores of records"),
                         icon: AnyView(BridgeIcon(.datos, size: 28)))
                StatCard(value: "\(store.seedCounts.reduce(0) { $0 + $1.records })",
                         label: L("records held"),
                         icon: AnyView(Image(systemName: "tray.2").font(.title2)
                            .foregroundStyle(Theme.text2)))
            }

            Card(L("What is held")) {
                ForEach(store.seedCounts, id: \.store) { entry in
                    HStack {
                        Text(entry.store).font(Theme.mono).foregroundStyle(Theme.text2)
                        Spacer()
                        Text("\(entry.records)").font(.callout).foregroundStyle(Theme.text)
                            .monospacedDigit()
                    }
                    .padding(.vertical, 3)
                    Divider().overlay(Theme.line)
                }
            }

            Card(L("Rights over this data")) {
                Text(L("Access, rectification, cancellation and objection are handled under a two-custodian flow: one person raises the request, a second approves it, and the chain records both. That flow belongs to the consumer product and is not demonstrated here."))
                    .font(.callout).foregroundStyle(Theme.text2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

/// My profile.
struct ProfileScreen: View {
    @Environment(AppStore.self) private var store
    @Query private var users: [User]

    var body: some View {
        ScreenScaffold {
            ScreenHeader(screen: .perfil, title: Key.nav_perfil.string,
                         subtitle: L("your account"))
            Card(L("Session")) {
                CardGrid(minimum: 170) {
                    KeyValue(label: L("User"), value: displayName)
                    KeyValue(label: L("Role"),
                             value: store.role.map { Key(rawValue: $0.labelKey)?.string ?? $0.rawValue } ?? "—")
                    KeyValue(label: L("May change records"),
                             value: store.canWrite ? L("yes") : L("no"),
                             tint: store.canWrite ? Theme.led : Theme.warn)
                }
                Text(L("Roles arrive from the institution's identity provider in production. The picker on the front door is the demo stand-in."))
                    .font(.caption).foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var displayName: String {
        users.first { $0.id == store.user }?.name ?? store.user
    }
}

/// One user, for an administrator.
struct UserScreen: View {
    @Query private var users: [User]
    var userID: String?

    var body: some View {
        ScreenScaffold {
            if let user = users.first(where: { $0.id == userID }) {
                ScreenHeader(screen: .usuario, title: user.name,
                             subtitle: user.role, iconScreen: .ajustes)
                Card(L("Account")) {
                    CardGrid(minimum: 170) {
                        KeyValue(label: L("User"), value: user.id, monospaced: true)
                        KeyValue(label: L("Role"), value: user.role)
                        KeyValue(label: L("Created"), value: user.createdAt, monospaced: true)
                    }
                }
            } else {
                ScreenHeader(screen: .usuario, title: L("User"), iconScreen: .ajustes)
                Card { Text(L("That record no longer exists.")).foregroundStyle(Theme.muted) }
            }
        }
    }
}

/// Update: what changed, and what it replaced.
struct UpdateScreen: View {
    var body: some View {
        ScreenScaffold {
            ScreenHeader(screen: .actualizar, title: Key.nav_actualizar.string,
                         subtitle: L("what changed, and what it replaced"))
            Card(L("Channel")) {
                CardGrid(minimum: 170) {
                    KeyValue(label: L("Channel"), value: L("stable"))
                    KeyValue(label: L("Applied"), value: L("current"), tint: Theme.led)
                }
                Text(L("An update is proposed, reviewed and sealed like anything else: what it replaces is recorded, and a person applies it."))
                    .font(.callout).foregroundStyle(Theme.text2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

extension Policy {
    /// The seeded policies are keyed by role rather than carrying a title, so
    /// the name shown comes from the key. Unknown keys show the key itself,
    /// which is better than a blank row.
    var displayTitle: String {
        switch id {
        case "guardrails": L("Guardrails")
        case "tos": L("Terms of service")
        case "terms": L("Terms of use")
        case "guidelines": L("Conduct guidelines")
        default: id
        }
    }
}
