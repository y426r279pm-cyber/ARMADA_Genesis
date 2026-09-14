import Foundation

/// The rails that need a key and send the conversation somewhere else.
///
/// Every one of these is `leavesDevice = true`. That is not a judgement about
/// the provider; it is the answer to the only question the label asks, which is
/// whether this text left this machine.
public struct KeyedRail: Rail {
    public enum Flavour: String, Sendable, CaseIterable, Identifiable {
        case openai, anthropic, gemini, groq
        public var id: String { rawValue }

        public var displayName: String {
            switch self {
            case .openai: "OpenAI"
            case .anthropic: "Anthropic"
            case .gemini: "Google Gemini"
            case .groq: "Groq"
            }
        }

        public var defaultModel: String {
            switch self {
            case .openai: "gpt-4.1-mini"
            case .anthropic: "claude-haiku-4-5"
            case .gemini: "gemini-2.5-flash"
            case .groq: "openai/gpt-oss-120b"
            }
        }

        /// The Keychain account this rail's key is stored under.
        public var keychainAccount: String { "rail.\(rawValue).key" }
    }

    public var flavour: Flavour
    public var modelName: String
    public var timeout: TimeInterval = 20

    public var id: String { flavour.rawValue }
    public var name: String { flavour.displayName }
    public let leavesDevice = true

    public init(flavour: Flavour, modelName: String? = nil, timeout: TimeInterval = 20) {
        self.flavour = flavour
        self.modelName = modelName ?? flavour.defaultModel
        self.timeout = timeout
    }

    public var isReady: Bool {
        get async { Keychain.has(flavour.keychainAccount) }
    }

    public func answer(_ turns: [Turn], onDelta: @Sendable (String) -> Void) async throws -> String {
        guard let key = Keychain.get(flavour.keychainAccount), !key.isEmpty else {
            throw RailError.notConfigured(flavour.displayName)
        }
        switch flavour {
        case .openai:
            return try await openAICompatible(
                url: URL(string: "https://api.openai.com/v1/chat/completions")!,
                headers: ["Authorization": "Bearer \(key)"], turns: turns, onDelta: onDelta)
        case .groq:
            return try await openAICompatible(
                url: URL(string: "https://api.groq.com/openai/v1/chat/completions")!,
                headers: ["Authorization": "Bearer \(key)"], turns: turns, onDelta: onDelta)
        case .anthropic:
            return try await anthropic(key: key, turns: turns, onDelta: onDelta)
        case .gemini:
            return try await gemini(key: key, turns: turns, onDelta: onDelta)
        }
    }

    // MARK: Transports

    /// The OpenAI chat-completions shape, which Groq also speaks.
    func openAICompatible(url: URL, headers: [String: String], turns: [Turn],
                          onDelta: @Sendable (String) -> Void) async throws -> String {
        var request = URLRequest(url: url, timeoutInterval: timeout)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        for (field, value) in headers { request.setValue(value, forHTTPHeaderField: field) }
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "model": modelName,
            "stream": true,
            "temperature": 0.6,
            "messages": turns.map {
                ["role": $0.who == .person ? "user" : $0.who == .taylor ? "assistant" : "system",
                 "content": $0.text]
            },
        ])
        return try await streamSSE(request) { json in
            ((json["choices"] as? [[String: Any]])?.first?["delta"] as? [String: Any])?["content"] as? String
        } onDelta: { onDelta($0) }
    }

    func anthropic(key: String, turns: [Turn],
                   onDelta: @Sendable (String) -> Void) async throws -> String {
        var request = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!,
                                 timeoutInterval: timeout)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(key, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        // System turns are a top-level field here, not a message.
        let system = turns.filter { $0.who == .system }.map(\.text).joined(separator: "\n\n")
        var body: [String: Any] = [
            "model": modelName,
            "max_tokens": 1024,
            "stream": true,
            "messages": turns.filter { $0.who != .system }.map {
                ["role": $0.who == .person ? "user" : "assistant", "content": $0.text]
            },
        ]
        if !system.isEmpty { body["system"] = system }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return try await streamSSE(request) { json in
            guard json["type"] as? String == "content_block_delta" else { return nil }
            return (json["delta"] as? [String: Any])?["text"] as? String
        } onDelta: { onDelta($0) }
    }

    /// Gemini streams JSON array chunks rather than SSE `data:` lines, so it is
    /// read whole rather than pretending to stream.
    func gemini(key: String, turns: [Turn],
                onDelta: @Sendable (String) -> Void) async throws -> String {
        let path = "https://generativelanguage.googleapis.com/v1beta/models/\(modelName):generateContent"
        var request = URLRequest(url: URL(string: path)!, timeoutInterval: timeout)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(key, forHTTPHeaderField: "x-goog-api-key")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "contents": turns.filter { $0.who != .system }.map {
                ["role": $0.who == .person ? "user" : "model",
                 "parts": [["text": $0.text]]]
            },
        ])
        let (data, response) = try await URLSession.shared.data(for: request)
        try check(response)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let text = ((((json?["candidates"] as? [[String: Any]])?.first)?["content"]
                     as? [String: Any])?["parts"] as? [[String: Any]])?
            .compactMap { $0["text"] as? String }.joined() ?? ""
        guard !text.isEmpty else { throw RailError.emptyReply }
        onDelta(text)
        return text
    }

    // MARK: Plumbing

    /// Read a `text/event-stream` body, extracting each delta with `pick`.
    func streamSSE(_ request: URLRequest,
                   pick: ([String: Any]) -> String?,
                   onDelta: @Sendable (String) -> Void) async throws -> String {
        let (bytes, response) = try await URLSession.shared.bytes(for: request)
        try check(response)
        var text = ""
        for try await line in bytes.lines {
            guard line.hasPrefix("data:") else { continue }
            let payload = line.dropFirst(5).trimmingCharacters(in: .whitespaces)
            if payload == "[DONE]" { break }
            guard let data = payload.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let piece = pick(json) else { continue }
            text += piece
            onDelta(piece)
        }
        guard !text.isEmpty else { throw RailError.emptyReply }
        return text
    }

    func check(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200..<300).contains(http.statusCode) else {
            throw RailError.http(http.statusCode)
        }
    }
}
