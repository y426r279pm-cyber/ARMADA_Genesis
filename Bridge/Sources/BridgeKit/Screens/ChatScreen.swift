import SwiftUI

/// Taylor: a private assistant, with provenance under every reply.
struct ChatScreen: View {
    @Environment(AppStore.self) private var store
    @State private var draft = ""
    @State private var showThreads = false

    private var taylor: Taylor { store.taylor }

    var body: some View {
        HStack(spacing: 0) {
            if showThreads {
                ThreadDrawer(store: store) { showThreads = false }
                    .frame(width: 240)
                Divider().overlay(Theme.line)
            }
            conversation
        }
        .background(Theme.bg)
        .onAppear { if taylor.turns.isEmpty { taylor.start() } }
    }

    private var conversation: some View {
        VStack(spacing: 0) {
            header
            Divider().overlay(Theme.line)
            transcript
            composer
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Button { showThreads.toggle() } label: {
                Image(systemName: "sidebar.left").foregroundStyle(Theme.text2)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L("Conversations"))

            TaylorMark(size: 26)
            VStack(alignment: .leading, spacing: 1) {
                Text("Taylor").font(.headline).foregroundStyle(Theme.text)
                Text(store.deviceModel.state.label).font(.caption2).foregroundStyle(Theme.muted)
            }
            Spacer()
            DeviceBadge(model: store.deviceModel)
        }
        .padding(.horizontal, 18).padding(.vertical, 12)
        .background(Theme.surface)
    }

    private var transcript: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if taylor.turns.isEmpty {
                        Greeting(text: taylor.greeting)
                    }
                    ForEach(taylor.turns.filter { $0.who != .system }) { turn in
                        TurnBubble(turn: turn).id(turn.id)
                    }
                    if taylor.awaitingConsent {
                        ConsentPrompt(question: taylor.consentQuestion,
                                      detail: taylor.lastError) {
                            Task { await taylor.grantConsentAndRetry() }
                        }
                    } else if let error = taylor.lastError {
                        Text(error).font(.caption).foregroundStyle(Theme.warn)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(20)
                .frame(maxWidth: 820, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .onChange(of: taylor.turns.last?.text) { _, _ in
                withAnimation { proxy.scrollTo(taylor.turns.last?.id, anchor: .bottom) }
            }
        }
    }

    private var composer: some View {
        VStack(spacing: 6) {
            Divider().overlay(Theme.line)
            HStack(spacing: 10) {
                TextField(L("Ask Taylor"), text: $draft, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...6)
                    .padding(10)
                    .background(Theme.input, in: RoundedRectangle(cornerRadius: Theme.radiusCtl))
                    .onSubmit(send)
                Button(action: send) {
                    Image(systemName: "arrow.up.circle.fill").font(.title2)
                }
                .buttonStyle(.plain)
                .foregroundStyle(draft.isEmpty ? Theme.muted : Theme.led)
                .disabled(draft.isEmpty || taylor.isAnswering)
                .accessibilityLabel(L("Send"))
            }
            .padding(.horizontal, 20).padding(.bottom, 14)

            // Stated under the composer, not buried in Settings: the person
            // typing needs to know where what they type is going.
            Text(taylor.consent == .withheld
                 ? L("Nothing leaves this device unless you say so.")
                 : L("This conversation may be sent to a keyed provider."))
                .font(.caption2)
                .foregroundStyle(taylor.consent == .withheld ? Theme.muted : Theme.warn)
                .padding(.bottom, 10)
        }
        .background(Theme.surface)
    }

    private func send() {
        let question = draft
        draft = ""
        Task { await taylor.ask(question) }
    }
}

/// A reply, with where it came from.
struct TurnBubble: View {
    var turn: Turn

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 10) {
                if turn.who == .taylor { TaylorMark(size: 22) }
                Text(turn.text.isEmpty ? "…" : turn.text)
                    .font(.body)
                    .foregroundStyle(Theme.text)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(12)
                    .background(turn.who == .person ? Theme.surface2 : Theme.surface,
                                in: RoundedRectangle(cornerRadius: Theme.radiusCard))
            }
            .frame(maxWidth: .infinity,
                   alignment: turn.who == .person ? .trailing : .leading)

            if let provenance = turn.provenance {
                ProvenanceLabel(provenance: provenance)
                    .padding(.leading, turn.who == .taylor ? 32 : 0)
            }
        }
    }
}

/// The provenance line under a reply.
///
/// Never a decoration and never omitted. The whole claim of the product is that
/// the institution can tell where an answer came from, and a reply with no
/// provenance would quietly undo it.
struct ProvenanceLabel: View {
    var provenance: Provenance

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: provenance.leavesDevice ? "arrow.up.right.square" : "lock.shield")
                .font(.system(size: 10))
            Text(provenance.label).font(.caption2)
        }
        .foregroundStyle(provenance.leavesDevice ? Theme.warn : Theme.led)
        .accessibilityElement(children: .combine)
    }
}

/// Asked before anything crosses off the machine, never assumed.
struct ConsentPrompt: View {
    var question: String
    var detail: String?
    var onGrant: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(question).font(.callout).foregroundStyle(Theme.text)
                .fixedSize(horizontal: false, vertical: true)
            if let detail {
                Text(detail).font(.caption2).foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack(spacing: 10) {
                Button(L("Send it off this device"), action: onGrant)
                    .buttonStyle(.borderedProminent)
                Text(L("Only for this conversation."))
                    .font(.caption2).foregroundStyle(Theme.muted)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface2, in: RoundedRectangle(cornerRadius: Theme.radiusCard))
        .overlay(RoundedRectangle(cornerRadius: Theme.radiusCard).stroke(Theme.warn, lineWidth: 1))
    }
}

struct Greeting: View {
    var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            TaylorMark(size: 40)
            Text(text).font(.title3).foregroundStyle(Theme.text2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 24)
    }
}

/// What is loaded, and what the machine can carry.
struct DeviceBadge: View {
    var model: DeviceModel

    var body: some View {
        switch model.state {
        case .ready(let choice):
            StatusPill(kind: .ok, text: "\(choice.displayName) · \(L("on this device"))")
        case .loading(_, let progress):
            StatusPill(kind: .info, text: "\(L("loading")) \(Int(progress * 100))%")
        case .notPresent:
            StatusPill(kind: .warn, text: L("weights not on this machine"))
        case .failed:
            StatusPill(kind: .crit, text: model.state.label)
        case .checking:
            StatusPill(kind: .info, text: L("checking this machine"))
        case .idle:
            StatusPill(kind: .muted, text: L("not loaded"))
        }
    }
}

/// The conversation drawer.
struct ThreadDrawer: View {
    var store: AppStore
    var onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(L("Conversations")).font(.headline).foregroundStyle(Theme.text)
                Spacer()
                Button { onClose() } label: {
                    Image(systemName: "xmark").font(.caption).foregroundStyle(Theme.muted)
                }
                .buttonStyle(.plain)
            }
            .padding(14)

            Button {
                store.taylor.start()
            } label: {
                Label(L("New conversation"), systemImage: "square.and.pencil")
                    .font(.callout).foregroundStyle(Theme.led)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14).padding(.vertical, 8)
            }
            .buttonStyle(.plain)

            Spacer()

            // Conversations are held in memory for now. Persisting them is the
            // `chats` store, whose shape the seed cannot infer because nothing
            // seeds it — see the phase 0 note on the four unseeded stores.
            Text(L("Conversations are not kept between launches yet."))
                .font(.caption2).foregroundStyle(Theme.muted)
                .padding(14)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Theme.surface)
    }
}
