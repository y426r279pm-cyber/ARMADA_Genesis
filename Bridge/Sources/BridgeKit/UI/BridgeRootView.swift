import SwiftUI

/// The console shell: a sidebar, a breadcrumb trail, and the screen itself.
///
/// `NavigationSplitView` because this was always a sidebar app — the prototype's
/// layout is a fixed rail beside a scrolling main, and that is the same shape on
/// a Mac and on an iPad in landscape.
public struct BridgeRootView: View {
    @State private var store: AppStore
    @Environment(\.horizontalSizeClass) private var sizeClass

    public init(store: AppStore = AppStore()) { _store = State(initialValue: store) }

    public var body: some View {
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
