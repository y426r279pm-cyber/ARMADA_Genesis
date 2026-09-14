import Foundation

//  MLX adapter
//  ───────────
//  This is the one file in BridgeKit whose API surface was written without a
//  compiler to check it against. Everything else here is Foundation, SwiftUI or
//  our own types; this talks to MLX, whose module names and signatures move
//  between versions.
//
//  It is deliberately four functions wide. `LocalEngine` is the seam, and if the
//  calls below need adjusting for the MLX version actually installed, nothing
//  outside this file changes.
//
//  To enable: add the package dependency (see Package.swift, where it is
//  commented with the same warning) and build. Without it the whole file
//  compiles to `LocalEngine.unavailable`, the console says there is no local
//  model, and every other rail still works.
//
//  Verify when enabling:
//    · the module names in the import below;
//    · how a model container is loaded, and what its progress callback reports;
//    · how a chat-shaped prompt is passed (a role/content list, or a template);
//    · how generation streams tokens back.

#if canImport(MLXLLM) && canImport(MLXLMCommon)
import MLXLLM
import MLXLMCommon

extension LocalEngine {
    /// MLX on Apple silicon.
    public static let mlx = LocalEngine(
        isPresent: { choice in
            // Weights are never fetched mid-session, so presence is a question
            // about the local cache and nothing else.
            MLXWeights.isCached(choice)
        },
        load: { choice, onProgress in
            try await MLXWeights.load(choice, onProgress: onProgress)
        },
        generate: { turns, onDelta in
            try await MLXWeights.generate(turns, onDelta: onDelta)
        })
}

/// Holds the loaded container between calls, so a second question does not pay
/// the load cost again.
actor MLXWeights {
    private static var container: ModelContainer?
    private static var loaded: DeviceModelChoice?

    static func isCached(_ choice: DeviceModelChoice) -> Bool {
        // The Hub cache location MLX reads from. Presence of the directory is
        // enough: a partial download fails at load and is reported there.
        let hub = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            .first?.appendingPathComponent("huggingface/models/mlx-community/\(choice.id)")
        guard let hub else { return false }
        return FileManager.default.fileExists(atPath: hub.path)
    }

    static func load(_ choice: DeviceModelChoice,
                     onProgress: @escaping @Sendable (Double) -> Void) async throws {
        if loaded == choice, container != nil { return }
        let configuration = ModelConfiguration(id: "mlx-community/\(choice.id)")
        container = try await LLMModelFactory.shared.loadContainer(configuration: configuration) {
            progress in onProgress(progress.fractionCompleted)
        }
        loaded = choice
    }

    static func generate(_ turns: [Turn],
                         onDelta: @Sendable (String) -> Void) async throws -> String {
        guard let container else { throw RailError.notReady("no container") }
        let messages: [[String: String]] = turns.map { turn in
            ["role": turn.who == .person ? "user" : turn.who == .taylor ? "assistant" : "system",
             "content": turn.text]
        }
        return try await container.perform { context in
            let input = try await context.processor.prepare(input: .init(messages: messages))
            var text = ""
            let result = try MLXLMCommon.generate(
                input: input,
                parameters: GenerateParameters(temperature: 0.6),
                context: context
            ) { tokens in
                let piece = context.tokenizer.decode(tokens: tokens)
                if piece.count > text.count {
                    onDelta(String(piece.dropFirst(text.count)))
                    text = piece
                }
                return .more
            }
            return result.output.isEmpty ? text : result.output
        }
    }
}

#else

extension LocalEngine {
    /// MLX is not linked into this build.
    ///
    /// Not an error and not hidden: the console says there is no local model,
    /// which is true, and the keyed rails still answer.
    public static let mlx = LocalEngine.unavailable
}

#endif
