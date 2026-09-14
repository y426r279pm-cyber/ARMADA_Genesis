import Foundation

/// Guardrails and terms, versioned.
///
/// A policy is not a document that changes; it is a series of documents, each of
/// which some agent was running under. An agent's recommendation carries the
/// guardrails version it was written beneath, so the version has to still exist
/// to be read back — which means a policy edit publishes a new version rather
/// than overwriting one.
public struct PolicyVersion: Sendable, Equatable, Identifiable {
    public var id: String { "\(policyID)@\(version)" }
    public var policyID: String
    public var version: String
    public var text: String
    public var publishedAt: String
    public var publishedBy: String

    public init(policyID: String, version: String, text: String,
                publishedAt: String, publishedBy: String) {
        self.policyID = policyID
        self.version = version
        self.text = text
        self.publishedAt = publishedAt
        self.publishedBy = publishedBy
    }
}

public enum Policies {

    /// `1.4` -> `1.5` for a minor change, `2.0` for a major one.
    ///
    /// Major means the rules an agent operates under changed in a way that would
    /// alter what it does. Minor means wording. The person publishing says which,
    /// because only they know.
    public static func nextVersion(after current: String, major: Bool) -> String {
        let parts = current.split(separator: ".").compactMap { Int($0) }
        let currentMajor = parts.first ?? 1
        let currentMinor = parts.count > 1 ? parts[1] : 0
        return major ? "\(currentMajor + 1).0" : "\(currentMajor).\(currentMinor + 1)"
    }

    /// A clause-level diff between two versions.
    ///
    /// Line-by-line would be noise: reflowing a paragraph would read as a
    /// rewrite of every line in it. Clauses are the unit a person reviews, so
    /// they are the unit compared.
    public struct Change: Sendable, Equatable, Identifiable {
        public enum Kind: Sendable, Equatable { case added, removed, changed, unchanged }
        public var id: Int
        public var kind: Kind
        public var text: String
        public var previous: String?
    }

    public static func diff(_ old: String, _ new: String) -> [Change] {
        let before = clauses(of: old)
        let after = clauses(of: new)
        var changes: [Change] = []
        var index = 0

        for (position, clause) in after.enumerated() {
            if position < before.count {
                let was = before[position]
                if normalise(was) == normalise(clause) {
                    changes.append(Change(id: index, kind: .unchanged, text: clause, previous: nil))
                } else {
                    changes.append(Change(id: index, kind: .changed, text: clause, previous: was))
                }
            } else {
                changes.append(Change(id: index, kind: .added, text: clause, previous: nil))
            }
            index += 1
        }
        for removed in before.dropFirst(after.count) {
            changes.append(Change(id: index, kind: .removed, text: removed, previous: nil))
            index += 1
        }
        return changes
    }

    /// A clause starts at a number, a roman numeral, a heading, or a blank line.
    static func clauses(of text: String) -> [String] {
        var out: [String] = []
        var current = ""
        for line in text.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty {
                if !current.isEmpty { out.append(current); current = "" }
                continue
            }
            if startsAClause(trimmed), !current.isEmpty {
                out.append(current)
                current = ""
            }
            current += current.isEmpty ? trimmed : " " + trimmed
        }
        if !current.isEmpty { out.append(current) }
        return out
    }

    static func startsAClause(_ line: String) -> Bool {
        line.range(of: #"^(\d+[.)]|[IVX]+\.|#|[A-ZÁÉÍÓÚÑ][^:]{2,40}:)"#,
                   options: .regularExpression) != nil
    }

    /// Whitespace and case are not changes worth showing.
    static func normalise(_ text: String) -> String {
        text.lowercased().split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }

    public static func summary(of changes: [Change]) -> String {
        let added = changes.filter { $0.kind == .added }.count
        let removed = changes.filter { $0.kind == .removed }.count
        let changed = changes.filter { $0.kind == .changed }.count
        if added + removed + changed == 0 { return L("No change.") }
        return "\(added) \(L("added")) · \(changed) \(L("changed")) · \(removed) \(L("removed"))"
    }
}
