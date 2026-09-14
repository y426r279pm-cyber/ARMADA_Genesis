import SwiftUI

/// The chain: every action, sealed in order.
struct ChainScreen: View {
    @Environment(AppStore.self) private var store
    @State private var search = ""

    var body: some View {
        ScreenScaffold {
            ScreenHeader(screen: .cadena,
                         title: Key.nav_cadena.string,
                         subtitle: L("every action, sealed in order, each seal covering the one before it"))

            CardGrid {
                StatCard(value: "\(store.chain.count)", label: L("sealed events"),
                         icon: AnyView(BridgeIcon(.cadena, size: 28)))
                StatCard(value: verificationText, label: L("chain state"),
                         tint: store.chainState.isIntact ? Theme.led : Theme.crit,
                         icon: AnyView(Image(systemName: store.chainState.isIntact
                                             ? "checkmark.seal" : "exclamationmark.triangle")
                            .font(.title2)
                            .foregroundStyle(store.chainState.isIntact ? Theme.led : Theme.crit)))
            }

            Card(L("Events"), trailing: L("newest first")) {
                TextField(L("Search"), text: $search)
                    .textFieldStyle(.roundedBorder)

                let rows = store.chain
                    .sorted { $0.seq > $1.seq }
                    .filter { entry in
                        search.isEmpty
                        || entry.en.localizedCaseInsensitiveContains(search)
                        || entry.es.localizedCaseInsensitiveContains(search)
                        || entry.actor.localizedCaseInsensitiveContains(search)
                    }

                if rows.isEmpty {
                    Text(L("Nothing sealed yet.")).font(.callout).foregroundStyle(Theme.muted)
                }
                ForEach(rows, id: \.id) { entry in
                    Button { store.navigator.go(.evento, entry.id) } label: {
                        HStack(spacing: 12) {
                            Text("#\(entry.seq)").font(Theme.mono).foregroundStyle(Theme.muted)
                                .frame(width: 48, alignment: .leading)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(store.language == .es ? entry.es : entry.en)
                                    .foregroundStyle(Theme.text)
                                Text(entry.actor).font(.caption).foregroundStyle(Theme.muted)
                            }
                            Spacer()
                            Text(entry.hash.prefix(12) + "…")
                                .font(Theme.mono).foregroundStyle(Theme.led)
                            Image(systemName: "chevron.right")
                                .font(.caption2).foregroundStyle(Theme.muted)
                        }
                        .font(.callout)
                        .padding(.vertical, 7)
                    }
                    .buttonStyle(.plain)
                    Divider().overlay(Theme.line)
                }
            }
        }
    }

    private var verificationText: String {
        switch store.chainState {
        case .intact: L("intact")
        case .broken(let seq): "\(L("broken at")) #\(seq)"
        }
    }
}

/// One sealed event, and the seal itself.
struct EventScreen: View {
    @Environment(AppStore.self) private var store
    var eventID: String?

    private var entry: Seal.Entry? { store.chain.first { $0.id == eventID } }

    var body: some View {
        ScreenScaffold {
            if let entry {
                ScreenHeader(screen: .evento,
                             title: "#\(entry.seq)",
                             subtitle: store.language == .es ? entry.es : entry.en,
                             iconScreen: .cadena)

                Card(L("Event")) {
                    CardGrid(minimum: 170) {
                        KeyValue(label: L("Sequence"), value: "\(entry.seq)", monospaced: true)
                        KeyValue(label: L("When"), value: entry.at, monospaced: true)
                        KeyValue(label: L("Actor"), value: entry.actor)
                        KeyValue(label: "English", value: entry.en)
                        KeyValue(label: "Español", value: entry.es)
                    }
                }

                if !entry.extra.isEmpty {
                    Card(L("Recorded with the event")) {
                        CardGrid(minimum: 170) {
                            ForEach(entry.extra, id: \.key) { pair in
                                KeyValue(label: pair.key,
                                         value: plain(pair.value),
                                         monospaced: true)
                            }
                        }
                    }
                }

                Card(L("The seal")) {
                    KeyValue(label: L("Previous hash"), value: entry.prevHash, monospaced: true)
                    KeyValue(label: L("This hash"), value: entry.hash,
                             monospaced: true, tint: Theme.led)
                    Text(L("The seal covers the previous seal, so altering any earlier event breaks every seal after it."))
                        .font(.caption).foregroundStyle(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                ScreenHeader(screen: .evento, title: L("Event"), iconScreen: .cadena)
                Card { Text(L("That record no longer exists.")).foregroundStyle(Theme.muted) }
            }
        }
    }

    private func plain(_ value: CanonicalJSON.Value) -> String {
        if case .string(let s) = value { return s }
        return CanonicalJSON.stringify(value)
    }
}

/// Audit: what the seal proves, and what it does not.
///
/// The subtitle is not decoration. The RC2 brief requires the honest limit to be
/// stated on this screen: a seal proves that what was recorded was not altered,
/// and never that everything was recorded. Bridge produces evidence about its
/// own records; whether a control is effective is a different finding, made by
/// someone else.
struct AuditScreen: View {
    @Environment(AppStore.self) private var store
    @State private var lastCheck: Seal.Verification?

    var body: some View {
        ScreenScaffold {
            ScreenHeader(screen: .auditoria,
                         title: Key.nav_auditoria.string,
                         subtitle: L("a seal proves that what was recorded was not altered; it does not prove that everything was recorded"))

            Card(L("Verify the chain")) {
                Text(L("Every seal is recomputed from the event it covers and the seal before it. A mismatch names the first event that does not hold."))
                    .font(.callout).foregroundStyle(Theme.text2)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 12) {
                    Button(L("Verify now")) { lastCheck = Seal.verify(store.chain) }
                        .buttonStyle(.borderedProminent)
                    if let lastCheck {
                        switch lastCheck {
                        case .intact(let length):
                            StatusPill(kind: .ok, text: "\(L("intact")) · \(length) \(L("events"))")
                        case .broken(let seq):
                            StatusPill(kind: .crit, text: "\(L("broken at")) #\(seq)")
                        }
                    }
                }
            }

            Card(L("What this evidence is")) {
                VStack(alignment: .leading, spacing: 10) {
                    limit(L("It proves"),
                          L("that the records Bridge holds are the records Bridge wrote, in the order it wrote them."),
                          tint: Theme.led)
                    limit(L("It does not prove"),
                          L("that everything which happened was recorded. A seal cannot witness an event that never reached it."),
                          tint: Theme.warn)
                    limit(L("It is not"),
                          L("a statement about whether a control is effective, and it confers no fiscal validity on any document it seals."),
                          tint: Theme.warn)
                }
            }
        }
    }

    private func limit(_ title: String, _ body: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(.footnote.bold()).foregroundStyle(tint)
            Text(body).font(.callout).foregroundStyle(Theme.text2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
