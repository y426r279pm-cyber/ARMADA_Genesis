import Foundation

/// Where an answer came from, and whether it left the building.
///
/// Provenance is not a label on a reply; it is the reason the product exists. An
/// institution running Génesis is told its work stays on hardware it owns, and
/// the console has to be able to show that for any given answer rather than
/// assert it in a brochure.
///
/// So `leavesDevice` is carried by the rail itself, and every reply records the
/// rail that produced it. A reply with no recorded provenance is a bug, not a
/// missing nicety.
public struct Provenance: Sendable, Equatable, Codable {
    public var railID: String
    public var railName: String
    public var modelName: String
    public var leavesDevice: Bool

    public init(railID: String, railName: String, modelName: String, leavesDevice: Bool) {
        self.railID = railID
        self.railName = railName
        self.modelName = modelName
        self.leavesDevice = leavesDevice
    }

    /// What the chat shows under a reply.
    public var label: String {
        leavesDevice
            ? "\(railName) · \(modelName) · \(L("left this device"))"
            : "\(railName) · \(modelName) · \(L("on this device"))"
    }
}

/// One turn in a conversation.
public struct Turn: Sendable, Equatable, Identifiable, Codable {
    public enum Who: String, Sendable, Codable { case person, taylor, system }

    public var id: String
    public var who: Who
    public var text: String
    public var at: String
    /// Absent on a person's own turn, and on a reply still being written.
    public var provenance: Provenance?

    public init(id: String = UUID().uuidString, who: Who, text: String,
                at: String = ISO8601DateFormatter.bridge.string(from: Date()),
                provenance: Provenance? = nil) {
        self.id = id
        self.who = who
        self.text = text
        self.at = at
        self.provenance = provenance
    }
}

/// Something that can answer.
public protocol Rail: Sendable {
    var id: String { get }
    var name: String { get }
    var modelName: String { get }

    /// Whether an answer from this rail leaves the device.
    ///
    /// Not a preference. A rail that posts to somebody else's server is
    /// `true` even when that server belongs to the institution, because the
    /// question the label answers is "did this text leave this machine".
    var leavesDevice: Bool { get }

    /// Ready to answer right now, without downloading or asking for a key.
    var isReady: Bool { get async }

    /// Answer, streaming deltas as they arrive.
    func answer(_ turns: [Turn], onDelta: @Sendable (String) -> Void) async throws -> String
}

extension Rail {
    public var provenance: Provenance {
        Provenance(railID: id, railName: name, modelName: modelName, leavesDevice: leavesDevice)
    }
}

public enum RailError: Error, Equatable {
    case notConfigured(String)
    case notReady(String)
    case http(Int)
    case emptyReply
    case cancelled
    case timedOut
    case unavailable(String)

    public var message: String {
        switch self {
        case .notConfigured(let what): "\(L("Not configured:")) \(what)"
        case .notReady(let what): "\(L("Not ready:")) \(what)"
        case .http(let code): "HTTP \(code)"
        case .emptyReply: L("The rail returned nothing.")
        case .cancelled: L("Cancelled.")
        case .timedOut: L("The rail did not answer in time.")
        case .unavailable(let why): why
        }
    }
}
