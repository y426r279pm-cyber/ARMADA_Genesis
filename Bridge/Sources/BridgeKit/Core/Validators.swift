import Foundation

/// Field validators, ported from the prototype's integration wizard.
///
/// Worth porting exactly rather than approximating: an RFC or a CLABE that the
/// console accepts and the bank rejects is a failure discovered at the worst
/// moment, and the check digit is cheap to get right and easy to get wrong.
public enum Validator {

    public struct Result: Sendable, Equatable {
        public var isValid: Bool
        public var message: String
        public static let valid = Result(isValid: true, message: "")
        public static func invalid(_ message: String) -> Result {
            Result(isValid: false, message: message)
        }
    }

    /// Required, non-blank.
    public static func text(_ value: String) -> Result {
        value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? .invalid(L("Required.")) : .valid
    }

    public static func url(_ value: String) -> Result {
        guard let url = URL(string: value), let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme), url.host != nil else {
            return .invalid(L("Must be an http or https address."))
        }
        return .valid
    }

    public static func host(_ value: String) -> Result {
        let pattern = #"^(?=.{1,253}$)([A-Za-z0-9]([A-Za-z0-9\-]{0,61}[A-Za-z0-9])?\.)*[A-Za-z0-9]([A-Za-z0-9\-]{0,61}[A-Za-z0-9])?$"#
        return value.range(of: pattern, options: .regularExpression) != nil
            ? .valid : .invalid(L("Not a host name."))
    }

    public static func port(_ value: String) -> Result {
        guard let port = Int(value), port > 0, port < 65536 else {
            return .invalid(L("1 to 65535."))
        }
        return .valid
    }

    /// RFC: twelve characters for a company, thirteen for a person, plus the
    /// homoclave. Shape only — whether the taxpayer exists is the SAT's answer,
    /// not ours, and pretending otherwise would be a validity claim.
    public static func rfc(_ value: String) -> Result {
        let upper = value.uppercased().trimmingCharacters(in: .whitespaces)
        let pattern = #"^[A-ZÑ&]{3,4}[0-9]{6}[A-Z0-9]{3}$"#
        guard upper.range(of: pattern, options: .regularExpression) != nil else {
            return .invalid(L("12 characters for a company, 13 for a person."))
        }
        return .valid
    }

    /// CLABE: eighteen digits, the last one a check digit over weights 3, 7, 1.
    ///
    /// The check digit is the whole point. Eighteen digits that merely *look*
    /// like a CLABE will be accepted by a form and refused by a bank, and the
    /// person who typed them will be told days later.
    public static func clabe(_ value: String) -> Result {
        let digits = value.filter(\.isNumber)
        guard digits.count == 18 else { return .invalid(L("18 digits.")) }
        let weights = [3, 7, 1]
        let numbers = digits.compactMap { $0.wholeNumberValue }
        let sum = numbers.prefix(17).enumerated()
            .reduce(0) { total, pair in total + (pair.element * weights[pair.offset % 3]) % 10 }
        let expected = (10 - (sum % 10)) % 10
        guard numbers[17] == expected else {
            return .invalid(L("The check digit does not match."))
        }
        return .valid
    }

    /// A PEM block. Shape, not trust: whether the key is one we should accept is
    /// a different question, answered elsewhere.
    public static func pem(_ value: String) -> Result {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("-----BEGIN "), trimmed.contains("-----END ") else {
            return .invalid(L("Expected a PEM block beginning with -----BEGIN."))
        }
        return .valid
    }

    /// A secret. Checked for presence and length only, and never echoed.
    public static func secret(_ value: String) -> Result {
        value.count >= 8 ? .valid : .invalid(L("At least 8 characters."))
    }
}
