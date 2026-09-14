import Foundation
#if canImport(Darwin)
import Darwin
#endif

/// The weights Bridge can run locally.
///
/// Settled against a 16 GB demo machine: after macOS, Bridge itself and whatever
/// else is open, the budget is 7 to 9 GB and the low end is the one to plan for.
/// See `docs/ON_DEVICE_MODEL.md`.
public struct DeviceModelChoice: Sendable, Equatable, Identifiable {
    public var id: String
    public var displayName: String
    /// Weights on disk and resident in unified memory, approximately.
    public var weightsGB: Double
    /// Headroom for the KV cache as a conversation grows.
    public var workingGB: Double

    public var totalGB: Double { weightsGB + workingGB }

    /// The default. Keeps the model RC2.1 already runs through WebLLM, and
    /// leaves real headroom rather than spending the whole budget.
    public static let primary = DeviceModelChoice(
        id: "qwen2.5-7b-instruct-4bit", displayName: "Qwen 2.5 7B Instruct (4-bit)",
        weightsGB: 4.2, workingGB: 1.2)

    /// Not a lesser option: the one that runs when the machine is already loaded.
    /// A smaller model that answers beats a larger one that swaps.
    public static let fallback = DeviceModelChoice(
        id: "qwen2.5-3b-instruct-4bit", displayName: "Qwen 2.5 3B Instruct (4-bit)",
        weightsGB: 1.7, workingGB: 0.8)

    public static let all = [primary, fallback]
}

/// What the machine can carry right now.
///
/// On 16 GB of unified memory the failure is not a refusal to load: it is memory
/// pressure, then compression, then swap, which presents as the console going
/// unresponsive mid-sentence in front of the person the Discovery depends on.
/// So this is checked before a model is brought in, and checked again on demand
/// from Settings — days before a demo rather than during one.
public struct MemoryReport: Sendable, Equatable {
    public var physicalGB: Double
    public var availableGB: Double

    public var recommended: DeviceModelChoice? {
        if availableGB >= DeviceModelChoice.primary.totalGB + 1.0 { return .primary }
        if availableGB >= DeviceModelChoice.fallback.totalGB + 0.5 { return .fallback }
        return nil
    }

    public var advice: String {
        switch recommended {
        case .some(let choice) where choice == .primary:
            L("There is room for the full model.")
        case .some:
            L("Tight. The smaller model will run; the full one risks swapping mid-answer.")
        default:
            L("Not enough free memory to run a model locally. Close what you can, or use a keyed rail.")
        }
    }

    public static func current() -> MemoryReport {
        let physical = Double(ProcessInfo.processInfo.physicalMemory) / 1_073_741_824
        return MemoryReport(physicalGB: physical, availableGB: availableMemoryGB() ?? physical * 0.5)
    }

    /// Free plus inactive plus speculative: pages the kernel can hand over
    /// without evicting something somebody is using.
    ///
    /// Counting only genuinely free pages would understate it badly on a Mac
    /// that has been awake a while, and refuse a model that would have run.
    static func availableMemoryGB() -> Double? {
        #if canImport(Darwin)
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return nil }
        let pageSize = Double(vm_kernel_page_size)
        let usable = Double(stats.free_count) + Double(stats.inactive_count)
            + Double(stats.speculative_count)
        return usable * pageSize / 1_073_741_824
        #else
        return nil
        #endif
    }
}

/// The on-device rail.
///
/// Loading is explicit and staged so the console can say where it is: a demo
/// that stalls silently for forty seconds while several gigabytes move into
/// unified memory looks broken, and the fix is to say so rather than to hurry.
@Observable
@MainActor
public final class DeviceModel {

    public enum State: Sendable, Equatable {
        case idle
        case checking
        /// Weights are not on this machine yet.
        case notPresent(DeviceModelChoice)
        case loading(DeviceModelChoice, progress: Double)
        case ready(DeviceModelChoice)
        case failed(String)

        public var isReady: Bool { if case .ready = self { true } else { false } }

        public var label: String {
            switch self {
            case .idle: L("not loaded")
            case .checking: L("checking this machine")
            case .notPresent: L("weights not on this machine")
            case .loading(_, let progress): "\(L("loading")) \(Int(progress * 100))%"
            case .ready(let choice): choice.displayName
            case .failed(let why): why
            }
        }
    }

    public private(set) var state: State = .idle
    public private(set) var memory: MemoryReport = .current()

    /// The engine. Injected so the chat can be exercised without weights, and
    /// so the MLX adapter stays the only thing that has to know about MLX.
    private let engine: LocalEngine

    public init(engine: LocalEngine = .mlx) { self.engine = engine }

    public func refreshMemory() { memory = .current() }

    /// Bring the model in.
    ///
    /// Called at launch rather than at the first message: moving several
    /// gigabytes into unified memory takes seconds, and those seconds must be
    /// spent while somebody is still talking about the architecture, not after
    /// a question has been asked.
    public func load(preferring choice: DeviceModelChoice? = nil) async {
        state = .checking
        refreshMemory()

        guard let pick = choice ?? memory.recommended else {
            state = .failed(memory.advice)
            return
        }
        guard await engine.isPresent(pick) else {
            // Never fetch weights during a session. A four-gigabyte download in
            // front of a client is not recoverable.
            state = .notPresent(pick)
            return
        }
        state = .loading(pick, progress: 0)
        do {
            try await engine.load(pick) { [weak self] progress in
                Task { @MainActor in self?.state = .loading(pick, progress: progress) }
            }
            state = .ready(pick)
        } catch {
            state = .failed(String(describing: error))
        }
    }

    public func answer(_ turns: [Turn], onDelta: @Sendable (String) -> Void) async throws -> String {
        guard case .ready = state else { throw RailError.notReady(state.label) }
        return try await engine.generate(turns, onDelta: onDelta)
    }

    public var choice: DeviceModelChoice? {
        if case .ready(let choice) = state { return choice }
        return nil
    }
}

/// Everything the on-device rail needs from an inference engine.
///
/// Kept deliberately small so that MLX sits behind four functions. The adapter
/// is in `MLXEngine.swift` and is the one file whose API surface has to be
/// checked against the installed MLX version.
public struct LocalEngine: Sendable {
    public var isPresent: @Sendable (DeviceModelChoice) async -> Bool
    public var load: @Sendable (DeviceModelChoice, @escaping @Sendable (Double) -> Void) async throws -> Void
    public var generate: @Sendable ([Turn], @Sendable (String) -> Void) async throws -> String

    public init(isPresent: @escaping @Sendable (DeviceModelChoice) async -> Bool,
                load: @escaping @Sendable (DeviceModelChoice, @escaping @Sendable (Double) -> Void) async throws -> Void,
                generate: @escaping @Sendable ([Turn], @Sendable (String) -> Void) async throws -> String) {
        self.isPresent = isPresent
        self.load = load
        self.generate = generate
    }

    /// An engine that is never present. The default where MLX is not linked, so
    /// the package builds and the console says plainly that there is no local
    /// model rather than pretending there is one.
    public static let unavailable = LocalEngine(
        isPresent: { _ in false },
        load: { _, _ in throw RailError.unavailable(L("No local inference engine is linked into this build.")) },
        generate: { _, _ in throw RailError.unavailable(L("No local inference engine is linked into this build.")) })
}

/// The on-device rail, wrapping `DeviceModel`.
public struct DeviceRail: Rail {
    public let id = "device"
    public var name: String { L("this device") }
    public var modelName: String
    /// The whole point.
    public let leavesDevice = false

    private let model: DeviceModel

    @MainActor
    public init(model: DeviceModel) {
        self.model = model
        self.modelName = model.choice?.displayName ?? L("no model loaded")
    }

    public var isReady: Bool {
        get async { await MainActor.run { model.state.isReady } }
    }

    public func answer(_ turns: [Turn], onDelta: @Sendable (String) -> Void) async throws -> String {
        try await model.answer(turns, onDelta: onDelta)
    }
}
