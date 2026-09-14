import SwiftUI
import SwiftData

/// The console shell: a sidebar, a breadcrumb trail, and the screen itself.
///
/// `NavigationSplitView` because this was always a sidebar app — the prototype's
/// layout is a fixed rail beside a scrolling main, and that is the same shape on
/// a Mac and on an iPad in landscape.
public struct BridgeRootView: View {
    @State private var store: AppStore
    @State private var container: ModelContainer?
    @State private var loadFailure: String?

    public init(store: AppStore = AppStore()) { _store = State(initialValue: store) }

    public var body: some View {
        content
            .task { await openStore() }
    }

    /// Open the store and load the seeded ledger before anything is shown.
    ///
    /// The chain is verified here rather than lazily: a console whose evidence
    /// does not hold should say so on the way in, not when somebody happens to
    /// open the Audit screen.
    private func openStore() async {
        guard container == nil else { return }
        do {
            container = try BridgeStore.container()
            store.load(seed: try SeedBundle.bundled())
        } catch {
            loadFailure = String(describing: error)
        }
    }

    @ViewBuilder private var content: some View {
        if let loadFailure {
            StoreFailureView(message: loadFailure)
        } else if let container {
            shell.modelContainer(container)
        } else {
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity).background(Theme.bg)
        }
    }

    private var shell: some View {
        Group {
            if store.role == nil {
                FrontDoorView(store: store)
            } else {
                console
            }
        }
        .environment(store)
        .tint(Theme.led)
        .background(Theme.bg)
        .preferredColorScheme(.dark)
        .environment(\.locale, Locale(identifier: store.language.rawValue))
    }

    private var console: some View {
        NavigationSplitView {
            SidebarView(store: store)
                .navigationSplitViewColumnWidth(min: 220, ideal: 248, max: 300)
        } detail: {
            VStack(alignment: .leading, spacing: 0) {
                BreadcrumbBar(navigator: store.navigator)
                ScreenHost(screen: store.navigator.route.screen,
                           recordID: store.navigator.route.recordID)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .background(Theme.bg)
        }
        .navigationSplitViewStyle(.balanced)
    }
}

/// The front door.
///
/// The role picker is the demo stand-in for single sign-on: in production the
/// form is replaced by the institution's identity provider and roles arrive as
/// OIDC claims, at which point the picker disappears rather than being hidden.
struct FrontDoorView: View {
    let store: AppStore
    @State private var role: Role = .admin
    @State private var user: String = "m.rios"

    var body: some View {
        VStack(spacing: 14) {
            Text("A R M A D A")
                .font(.caption).tracking(4).foregroundStyle(Theme.muted)
            BridgeMark(size: 56)
            Text(Key.login_sub.string)
                .font(.subheadline).foregroundStyle(Theme.text2)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 12) {
                Picker(Key.login_role.string, selection: $role) {
                    ForEach(Role.allCases, id: \.self) { role in
                        Text(Key(rawValue: role.labelKey)?.string ?? role.rawValue).tag(role)
                    }
                }
                TextField(Key.login_user.string, text: $user)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.username)
                SecureField(Key.login_pass.string, text: .constant("••••••••"))
                    .textFieldStyle(.roundedBorder)
                    .disabled(true)
            }
            .frame(maxWidth: 380)

            Button {
                Task { await store.dispatch(.signIn(role: role, user: user)) }
            } label: {
                Text(Key.login_btn.string).frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: 380)

            Text(Key.login_note.string)
                .font(.footnote).foregroundStyle(Theme.muted)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bg)
    }
}

/// The rail. Screens absent from a role are not here at all — hidden, not greyed.
struct SidebarView: View {
    let store: AppStore

    var body: some View {
        List(selection: selection) {
            Section {
                ForEach(store.role?.screens ?? [], id: \.self) { screen in
                    Label {
                        Text(Key(rawValue: "nav_\(screen.rawValue)")?.string ?? screen.rawValue)
                    } icon: {
                        BridgeIcon(screen, size: 22)
                    }
                    .tag(screen)
                }
            } header: {
                HStack(spacing: 8) {
                    BridgeMark(size: 22)
                    Text("Bridge").font(.headline).foregroundStyle(Theme.text)
                }
                .padding(.vertical, 6)
            }
        }
        .listStyle(.sidebar)
        .safeAreaInset(edge: .bottom) { sessionFooter }
    }

    private var selection: Binding<Screen?> {
        Binding(get: { store.navigator.route.screen },
                set: { if let screen = $0 { store.navigator.go(screen) } })
    }

    /// Role, language and sign-out. No node count here: the prototype's sidebar
    /// footer carried one, and the RC2 brief forbids it before a signed
    /// discovery agreement.
    private var sessionFooter: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider().overlay(Theme.line)
            HStack {
                Text(store.user).font(.footnote).foregroundStyle(Theme.text2)
                Spacer()
                if !store.canWrite {
                    Text(Key.readonly.string)
                        .font(.caption2).foregroundStyle(Theme.warn)
                        .lineLimit(1).help(Key.readonly.string)
                }
            }
            Picker("", selection: languageBinding) {
                Text("EN").tag(AppStore.Language.en)
                Text("ES").tag(AppStore.Language.es)
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            Button(role: .destructive) {
                Task { await store.dispatch(.signOut) }
            } label: {
                Label("Sign out", systemImage: "rectangle.portrait.and.arrow.right")
                    .font(.footnote)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Theme.muted)
        }
        .padding(12)
        .background(Theme.surface)
    }

    private var languageBinding: Binding<AppStore.Language> {
        Binding(get: { store.language },
                set: { language in Task { await store.dispatch(.setLanguage(language)) } })
    }
}

/// The trail. A tap truncates rather than popping once, matching the prototype.
struct BreadcrumbBar: View {
    let navigator: Navigator

    var body: some View {
        let crumbs = navigator.crumbs
        HStack(spacing: 6) {
            ForEach(Array(crumbs.enumerated()), id: \.offset) { index, route in
                if index > 0 {
                    Image(systemName: "chevron.right")
                        .font(.caption2).foregroundStyle(Theme.muted)
                }
                if index == crumbs.count - 1 {
                    Text(route.screen.crumbLabel)
                        .font(.callout.weight(.medium)).foregroundStyle(Theme.text)
                } else {
                    Button(route.screen.crumbLabel) { navigator.jump(toCrumb: index) }
                        .buttonStyle(.plain)
                        .font(.callout).foregroundStyle(Theme.led)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Theme.bg)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Breadcrumb")
    }
}

/// Shown when the store cannot be opened.
///
/// Stated plainly rather than as an empty console: a Bridge that silently shows
/// no records looks like a Bridge with no work in it.
struct StoreFailureView: View {
    var message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "externaldrive.badge.exclamationmark")
                .font(.largeTitle).foregroundStyle(Theme.crit)
            Text(L("The local store could not be opened."))
                .font(.headline).foregroundStyle(Theme.text)
            Text(message)
                .font(.caption).foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
                .textSelection(.enabled)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bg)
    }
}
