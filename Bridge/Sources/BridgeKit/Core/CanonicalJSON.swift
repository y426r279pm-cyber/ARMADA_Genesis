import Foundation

/// JSON written the way `JSON.stringify` writes it.
///
/// This exists for exactly one caller — the sealed chain — and must never be
/// swapped for `JSONEncoder`. The prototype seals with:
///
///     payload = JSON.stringify({ es, en, actor, ...extra })
///     hash    = sha256((prev?.hash ?? "genesis") + at + actor + payload)
///
/// `JSON.stringify` emits keys in *insertion order*. `JSONEncoder` emits them
/// sorted or in declaration order, and formats numbers differently. Feed a
/// ledger entry through the wrong one and the digest changes, so a chain sealed
/// in the browser fails to verify here — and the failure presents as tampering,
/// which is the worst possible way to be wrong about an audit log.
///
/// `tools/verify_chain.py` demonstrates both outcomes against the real seeded
/// ledger: insertion order verifies, sorted keys break at seq 1.
public enum CanonicalJSON {

    /// A JSON value, in the order it was written.
    ///
    /// An ordered array of pairs rather than a dictionary, because a dictionary
    /// would discard the one property the hash depends on.
    public indirect enum Value: Sendable, Equatable {
        case string(String)
        case number(Double)
        case integer(Int)
        case bool(Bool)
        case null
        case array([Value])
        case object([(key: String, value: Value)])

        public static func == (a: Value, b: Value) -> Bool {
            switch (a, b) {
            case let (.string(x), .string(y)): x == y
            case let (.number(x), .number(y)): x == y
            case let (.integer(x), .integer(y)): x == y
            case let (.bool(x), .bool(y)): x == y
            case (.null, .null): true
            case let (.array(x), .array(y)): x == y
            case let (.object(x), .object(y)):
                x.count == y.count && zip(x, y).allSatisfy { $0.key == $1.key && $0.value == $1.value }
            default: false
            }
        }
    }

    /// Serialise exactly as `JSON.stringify` would: no whitespace, insertion
    /// order preserved, JavaScript number formatting.
    public static func stringify(_ value: Value) -> String {
        switch value {
        case .null: "null"
        case .bool(let b): b ? "true" : "false"
        case .integer(let i): String(i)
        case .number(let d): number(d)
        case .string(let s): quote(s)
        case .array(let items): "[" + items.map(stringify).joined(separator: ",") + "]"
        case .object(let pairs):
            "{" + pairs.map { "\(quote($0.key)):\(stringify($0.value))" }.joined(separator: ",") + "}"
        }
    }

    /// JavaScript prints an integral double without a fractional part: `12000`,
    /// never `12000.0`. Swift's default description does the opposite.
    static func number(_ d: Double) -> String {
        if d.isNaN || d.isInfinite { return "null" }          // JSON.stringify's behaviour
        if d == d.rounded(), abs(d) < 9_007_199_254_740_992 {
            return String(Int64(d))
        }
        var text = "\(d)"
        if text.hasSuffix(".0") { text.removeLast(2) }
        return text
    }

    /// String escaping to match `JSON.stringify`.
    ///
    /// Note what is *not* escaped: non-ASCII characters pass through as UTF-8.
    /// `sellado (emisión)` is sealed with its accent intact, so escaping it to
    /// `ó` here would change every hash in the Spanish half of the ledger.
    static func quote(_ s: String) -> String {
        var out = "\""
        for scalar in s.unicodeScalars {
            switch scalar {
            case "\"": out += "\\\""
            case "\\": out += "\\\\"
            case "\n": out += "\\n"
            case "\r": out += "\\r"
            case "\t": out += "\\t"
            case "\u{08}": out += "\\b"
            case "\u{0C}": out += "\\f"
            default:
                if scalar.value < 0x20 {
                    out += String(format: "\\u%04x", scalar.value)
                } else {
                    out.unicodeScalars.append(scalar)
                }
            }
        }
        return out + "\""
    }
}

extension CanonicalJSON {

    /// Parse JSON while preserving key order.
    ///
    /// `JSONSerialization` returns dictionaries, which discard order — and order
    /// is the one property the sealed payload depends on, at every depth. A
    /// nested `{"po":"PO-1","delta":0}` re-serialised alphabetically is a
    /// different byte sequence and a different hash.
    ///
    /// Needed wherever a browser-written payload is read back: verifying an
    /// imported chain, and the export round-trip that keeps the two builds
    /// honest about each other.
    public static func parse(_ text: String) throws -> Value {
        var scanner = Scanner(text)
        let value = try scanner.value()
        scanner.skipWhitespace()
        guard scanner.atEnd else { throw ParseError.trailingCharacters(at: scanner.offset) }
        return value
    }

    public enum ParseError: Error, Equatable {
        case unexpectedCharacter(Character, at: Int)
        case unexpectedEnd
        case invalidNumber(String, at: Int)
        case invalidEscape(at: Int)
        case trailingCharacters(at: Int)
    }

    struct Scanner {
        let characters: [Character]
        var index = 0

        init(_ text: String) { characters = Array(text) }
        var atEnd: Bool { index >= characters.count }
        var offset: Int { index }

        mutating func skipWhitespace() {
            while index < characters.count, characters[index] == " " || characters[index] == "\n"
                    || characters[index] == "\t" || characters[index] == "\r" { index += 1 }
        }

        mutating func value() throws -> Value {
            skipWhitespace()
            guard index < characters.count else { throw ParseError.unexpectedEnd }
            switch characters[index] {
            case "{": return try object()
            case "[": return try array()
            case "\"": return .string(try string())
            case "t": try literal("true"); return .bool(true)
            case "f": try literal("false"); return .bool(false)
            case "n": try literal("null"); return .null
            default: return try number()
            }
        }

        mutating func literal(_ word: String) throws {
            for expected in word {
                guard index < characters.count, characters[index] == expected else {
                    throw ParseError.unexpectedCharacter(characters[min(index, characters.count - 1)], at: index)
                }
                index += 1
            }
        }

        mutating func object() throws -> Value {
            index += 1                                  // past {
            var pairs: [(key: String, value: Value)] = []
            skipWhitespace()
            if index < characters.count, characters[index] == "}" { index += 1; return .object(pairs) }
            while true {
                skipWhitespace()
                let key = try string()
                skipWhitespace()
                guard index < characters.count, characters[index] == ":" else {
                    throw ParseError.unexpectedCharacter(characters[min(index, characters.count - 1)], at: index)
                }
                index += 1
                pairs.append((key, try value()))
                skipWhitespace()
                guard index < characters.count else { throw ParseError.unexpectedEnd }
                if characters[index] == "," { index += 1; continue }
                if characters[index] == "}" { index += 1; return .object(pairs) }
                throw ParseError.unexpectedCharacter(characters[index], at: index)
            }
        }

        mutating func array() throws -> Value {
            index += 1                                  // past [
            var items: [Value] = []
            skipWhitespace()
            if index < characters.count, characters[index] == "]" { index += 1; return .array(items) }
            while true {
                items.append(try value())
                skipWhitespace()
                guard index < characters.count else { throw ParseError.unexpectedEnd }
                if characters[index] == "," { index += 1; continue }
                if characters[index] == "]" { index += 1; return .array(items) }
                throw ParseError.unexpectedCharacter(characters[index], at: index)
            }
        }

        mutating func string() throws -> String {
            guard index < characters.count, characters[index] == "\"" else {
                throw ParseError.unexpectedCharacter(characters[min(index, characters.count - 1)], at: index)
            }
            index += 1
            var out = ""
            while index < characters.count {
                let c = characters[index]
                if c == "\"" { index += 1; return out }
                if c != "\\" { out.append(c); index += 1; continue }
                index += 1
                guard index < characters.count else { throw ParseError.unexpectedEnd }
                switch characters[index] {
                case "\"": out.append("\"")
                case "\\": out.append("\\")
                case "/": out.append("/")
                case "n": out.append("\n")
                case "r": out.append("\r")
                case "t": out.append("\t")
                case "b": out.append("\u{08}")
                case "f": out.append("\u{0C}")
                case "u":
                    let start = index + 1
                    guard start + 4 <= characters.count,
                          let code = UInt32(String(characters[start..<(start + 4)]), radix: 16)
                    else { throw ParseError.invalidEscape(at: index) }
                    index += 4
                    if code >= 0xD800, code <= 0xDBFF,                    // surrogate pair
                       index + 6 < characters.count, characters[index + 1] == "\\",
                       characters[index + 2] == "u",
                       let low = UInt32(String(characters[(index + 3)..<(index + 7)]), radix: 16),
                       low >= 0xDC00, low <= 0xDFFF {
                        let combined = 0x10000 + ((code - 0xD800) << 10) + (low - 0xDC00)
                        out.unicodeScalars.append(Unicode.Scalar(combined)!)
                        index += 6
                    } else if let scalar = Unicode.Scalar(code) {
                        out.unicodeScalars.append(scalar)
                    } else {
                        throw ParseError.invalidEscape(at: index)
                    }
                default: throw ParseError.invalidEscape(at: index)
                }
                index += 1
            }
            throw ParseError.unexpectedEnd
        }

        mutating func number() throws -> Value {
            let start = index
            if index < characters.count, characters[index] == "-" { index += 1 }
            var isInteger = true
            while index < characters.count {
                let c = characters[index]
                if c.isNumber { index += 1 }
                else if c == "." || c == "e" || c == "E" || c == "+" || c == "-" { isInteger = false; index += 1 }
                else { break }
            }
            let text = String(characters[start..<index])
            guard !text.isEmpty else {
                throw ParseError.unexpectedCharacter(characters[min(start, characters.count - 1)], at: start)
            }
            if isInteger, let i = Int(text) { return .integer(i) }
            guard let d = Double(text) else { throw ParseError.invalidNumber(text, at: start) }
            return .number(d)
        }
    }
}
