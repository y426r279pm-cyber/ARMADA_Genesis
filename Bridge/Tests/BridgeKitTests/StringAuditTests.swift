import XCTest
@testable import BridgeKit

/// The wording audit, as a test that fails the build.
///
/// The RC2 brief, section 9, sets rules about what Bridge may and may not claim.
/// Two of them are about language rather than behaviour:
///
///   * the seal witnesses the stamp; it never confers fiscal validity;
///   * nothing claims the layer remediates a control.
///
/// In the browser that audit was a script someone had to remember to run. Here
/// it runs on every build, over every string the app ships, in both languages.
///
/// Matching is on whole words, not substrings. That is not fussiness: matching
/// substrings flags "Rotating invalidates the previous token at once. Sealed." —
/// a true sentence about API tokens that contains "valid" inside "invalidates".
/// A test that fails on day one for a reason nobody believes gets disabled, and
/// then it is not there on the day it would have caught something real.
final class StringAuditTests: XCTestCase {

    /// Claims about validity. Note what is absent: `invalid` and `inválido` say
    /// the opposite and are not claims of validity.
    static let validityClaims: Set<String> = [
        "valid", "validity", "validate", "validates", "validated",
        "valido", "valida", "validas", "validez", "validado", "validar",
    ]

    /// Words about the seal and the chain.
    static let sealWords: Set<String> = [
        "seal", "seals", "sealed", "sealing", "chain",
        "sello", "sellos", "sellado", "sellada", "sellados", "selladas", "sellar", "cadena",
    ]

    /// Claims that a control is fixed rather than witnessed.
    static let remediationClaims: Set<String> = [
        "remediate", "remediates", "remediated", "remediation",
        "remedia", "remediacion", "subsana", "subsanar",
    ]

    /// Lowercased, accent-folded words. Folding lets one list cover both
    /// languages: `válido` and `valido` are the same word for this purpose.
    static func words(in string: String) -> Set<String> {
        let folded = string.folding(options: [.diacriticInsensitive, .caseInsensitive],
                                    locale: Locale(identifier: "en_US_POSIX"))
        return Set(folded.split { !$0.isLetter }.map(String.init))
    }

    /// Every string the app ships, English and Spanish both.
    func allStrings() -> [String] {
        var strings = AuditableStrings.all
        for key in Key.allCases { strings.append(key.string) }
        return strings
    }

    /// A validity word must not appear beside a seal word. Sealing something does
    /// not make it fiscally valid, and a string that puts the two together will
    /// be read as saying it does.
    func testNoStringClaimsSealingConfersValidity() {
        let offenders = allStrings().filter { string in
            let words = Self.words(in: string)
            return !words.isDisjoint(with: Self.validityClaims)
                && !words.isDisjoint(with: Self.sealWords)
        }
        XCTAssertTrue(offenders.isEmpty, """
            \(offenders.count) string(s) put a validity claim beside the seal. The seal \
            witnesses that what was recorded was not altered; it confers no fiscal \
            validity. Rephrase the string rather than widening this test.
            \(offenders.map { "  · \($0)" }.joined(separator: "\n"))
            """)
    }

    /// Nothing claims Bridge remediates a control. It produces evidence about
    /// what was recorded; whether a control is effective is not its finding.
    func testNoStringClaimsControlRemediation() {
        let offenders = allStrings().filter {
            !Self.words(in: $0).isDisjoint(with: Self.remediationClaims)
        }
        XCTAssertTrue(offenders.isEmpty, """
            \(offenders.count) string(s) claim the layer remediates a control.
            \(offenders.map { "  · \($0)" }.joined(separator: "\n"))
            """)
    }

    /// The audit must still catch what it is for. Without this, a later
    /// refactor could neuter the matching and every audit would pass silently.
    func testAuditCatchesAGenuineViolation() {
        for probe in ["This CFDI is valid and sealed to the chain.",
                      "Este CFDI es válido y sellado en la cadena."] {
            let words = Self.words(in: probe)
            XCTAssertFalse(words.isDisjoint(with: Self.validityClaims), "missed: \(probe)")
            XCTAssertFalse(words.isDisjoint(with: Self.sealWords), "missed: \(probe)")
        }
    }

    /// And must not catch what it is not for.
    func testAuditIgnoresInvalidates() {
        let words = Self.words(in: "Rotating invalidates the previous token at once. Sealed.")
        XCTAssertTrue(words.isDisjoint(with: Self.validityClaims),
                      "'invalidates' is not a claim of validity")
    }

    /// The catalog must carry every dictionary key, or the loud marker would
    /// ship. The prototype chose that marker over a silent fallback for exactly
    /// this reason; the test makes it unnecessary.
    func testEveryDictionaryKeyResolves() {
        let missing = Key.allCases.filter { $0.string.hasPrefix("\u{27E6}") }
        XCTAssertTrue(missing.isEmpty,
                      "keys missing from the catalog: \(missing.map(\.rawValue).joined(separator: ", "))")
    }

    /// Every screen in the sidebar has a name to show.
    func testEverySidebarScreenHasALabel() {
        var missing: [String] = []
        for role in Role.allCases {
            for screen in role.screens where Key(rawValue: "nav_\(screen.rawValue)") == nil {
                missing.append(screen.rawValue)
            }
        }
        XCTAssertTrue(missing.isEmpty,
                      "screens with no nav_ label: \(Set(missing).sorted().joined(separator: ", "))")
    }
}
