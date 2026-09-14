import SwiftUI

/// Settings: the local model, the keyed rails, and what leaves the device.
struct SettingsScreen: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        ScreenScaffold {
            ScreenHeader(screen: .ajustes, title: Key.nav_ajustes.string,
                         subtitle: L("what answers, what it costs this machine, and what leaves it"))

            LocalModelCard(model: store.deviceModel)

            Card(L("Keyed rails"),
                 trailing: L("keys are held in the Keychain, never synced off this device")) {
                Text(L("A keyed rail sends the conversation to that provider's servers. Taylor never uses one unless you agree to it, and agreement lasts only for that conversation."))
                    .font(.callout).foregroundStyle(Theme.text2)
                    .fixedSize(horizontal: false, vertical: true)
                ForEach(KeyedRail.Flavour.allCases) { RailKeyRow(flavour: $0) }
            }

            Card(L("Provenance")) {
                Text(L("Every reply records the rail that produced it and whether it left this machine. A reply with no provenance is a defect, not an omission."))
                    .font(.callout).foregroundStyle(Theme.text2)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 14) {
                    ProvenanceLabel(provenance: Provenance(
                        railID: "device", railName: L("this device"),
                        modelName: DeviceModelChoice.primary.displayName, leavesDevice: false))
                    ProvenanceLabel(provenance: Provenance(
                        railID: "openai", railName: "OpenAI",
                        modelName: KeyedRail.Flavour.openai.defaultModel, leavesDevice: true))
                }
            }
        }
    }
}

/// The local model, and whether this machine can carry it.
struct LocalModelCard: View {
    var model: DeviceModel

    var body: some View {
        Card(L("Model on this device"), trailing: L("nothing is downloaded during a session")) {
            HStack(spacing: 14) {
                DeviceBadge(model: model)
                Spacer()
                Button(L("Check this machine")) { model.refreshMemory() }
                    .buttonStyle(.bordered)
                Button(L("Load")) { Task { await model.load() } }
                    .buttonStyle(.borderedProminent)
                    .disabled(model.state.isReady)
            }

            CardGrid(minimum: 160) {
                KeyValue(label: L("Physical memory"),
                         value: String(format: "%.0f GB", model.memory.physicalGB))
                KeyValue(label: L("Available now"),
                         value: String(format: "%.1f GB", model.memory.availableGB),
                         tint: model.memory.recommended == nil ? Theme.warn : Theme.text)
                KeyValue(label: L("Recommended"),
                         value: model.memory.recommended?.displayName ?? L("No model available"))
            }

            Text(model.memory.advice).font(.caption).foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(DeviceModelChoice.all) { choice in
                HStack {
                    Text(choice.displayName).font(.callout).foregroundStyle(Theme.text)
                    Spacer()
                    Text(String(format: "%.1f GB + %.1f GB", choice.weightsGB, choice.workingGB))
                        .font(.caption).foregroundStyle(Theme.muted)
                    Button(L("Use")) { Task { await model.load(preferring: choice) } }
                        .buttonStyle(.bordered).controlSize(.small)
                }
                .padding(.vertical, 3)
            }

            Text(L("Weights, plus headroom for the conversation to grow. On a machine with 16 GB the risk is not a refusal to load but memory pressure mid-answer, so the smaller model is the right choice when the machine is already busy."))
                .font(.caption2).foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// One rail's key. Written, never read back.
struct RailKeyRow: View {
    var flavour: KeyedRail.Flavour
    @State private var entry = ""
    @State private var stored = false

    var body: some View {
        HStack(spacing: 10) {
            Text(flavour.displayName).font(.callout).foregroundStyle(Theme.text)
                .frame(width: 130, alignment: .leading)
            Text(flavour.defaultModel).font(.caption).foregroundStyle(Theme.muted)
                .frame(width: 150, alignment: .leading)

            if stored {
                StatusPill(kind: .ok, text: L("key stored"))
                Button(L("Remove")) {
                    try? Keychain.remove(flavour.keychainAccount)
                    stored = Keychain.has(flavour.keychainAccount)
                }
                .buttonStyle(.bordered).controlSize(.small)
            } else {
                SecureField(L("Paste a key"), text: $entry)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 240)
                Button(L("Save")) {
                    try? Keychain.set(entry, for: flavour.keychainAccount)
                    entry = ""
                    stored = Keychain.has(flavour.keychainAccount)
                }
                .buttonStyle(.bordered).controlSize(.small)
                .disabled(entry.isEmpty)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
        // Presence only. Reading a key back to draw a checkmark is how secrets
        // end up in screenshots.
        .onAppear { stored = Keychain.has(flavour.keychainAccount) }
    }
}
