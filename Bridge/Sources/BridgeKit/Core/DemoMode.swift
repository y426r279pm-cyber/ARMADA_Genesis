import Foundation

/// What a client may see.
///
/// Daniel's section 7 forbids node counts, model names, bills of materials and
/// prices before a signed discovery agreement. RC1 broke four of those rules and
/// RC2 answers with a demo mode.
///
/// A demo mode implemented as a runtime toggle is one flag away from a screen
/// and one mistake away from a room — and the figures sit in the binary either
/// way, where a screenshot, a crash log or a curious person can reach them. So
/// this is a build, not a switch:
///
///   * `CLIENT_DEMO` is a compile-time flag, so `isClientBuild` is a constant
///     the optimiser folds and the forbidden branches are not in the binary;
///   * the seed is swapped for `Seed.client.json`, in which the model names are
///     absent rather than hidden;
///   * `DemoModeTests` fails if a forbidden string survives either step.
///
/// `tools/make_client_build.sh` does both and archives the result.
public enum DemoMode {

    #if CLIENT_DEMO
    /// This binary is the client build.
    public static let isClientBuild = true
    #else
    public static let isClientBuild = false
    #endif

    /// The seed resource this build loads.
    public static var seedResource: String { isClientBuild ? "Seed.client" : "Seed" }

    // MARK: The four rules

    /// No node counts. "17 nodes" becomes "the rack".
    ///
    /// Not "some nodes" or a blurred number: a vaguer count is still a count,
    /// and a client who is told "around twenty" has been told.
    public static func nodeCount(_ count: Int, of total: Int? = nil) -> String {
        guard isClientBuild else {
            return total.map { "\(count)/\($0)" } ?? "\(count)"
        }
        return L("the rack")
    }

    /// No model names. The brief names the two replacements.
    public static func modelName(_ name: String) -> String {
        guard isClientBuild else { return name }
        return looksLikeEscalation(name) ? L("escalation model") : L("routine model")
    }

    /// A node's role, which in the internal build carries a model family.
    public static func nodeRole(_ role: String) -> String {
        guard isClientBuild else { return role }
        if role.range(of: "admin", options: .caseInsensitive) != nil { return L("admin + spare") }
        if role.range(of: "replica", options: .caseInsensitive) != nil { return L("replica") }
        return modelName(role)
    }

    /// No bill of materials and no prices. Configuration is not shown at all in
    /// a client build — the planner stays for internal use.
    public static var showsConfiguration: Bool { !isClientBuild }

    /// The model catalogue is hidden too: a list of what could be installed is
    /// a list of model names.
    public static var showsModelCatalogue: Bool { !isClientBuild }

    /// No collections or compliance result before one is measured. Every seeded
    /// figure carries its label in both builds; the client build says it louder.
    public static var labelsEveryFigureAsSample: Bool { true }

    /// Screens a client build does not route to at all.
    ///
    /// Hidden rather than emptied: an empty Configuration screen invites the
    /// question of what was removed.
    public static let hiddenScreens: Set<Screen> = [.configuracion, .catalogo, .installer]

    public static func canShow(_ screen: Screen) -> Bool {
        !isClientBuild || !hiddenScreens.contains(screen)
    }

    /// A rough family test, used only to choose which of the two neutral names
    /// to show. Wrong in either direction costs nothing: both are neutral.
    static func looksLikeEscalation(_ name: String) -> Bool {
        ["kimi", "k2", "k3", "escalation", "escalación", "opus", "thinking"]
            .contains { name.range(of: $0, options: .caseInsensitive) != nil }
    }

    /// Strings that must never reach a client build, for the audit to check.
    ///
    /// Kept here rather than in the test so that the list is part of the product
    /// and reads as a rule, not as a test fixture.
    public static let forbiddenInClientBuild = [
        "Kimi", "Llama", "Qwen", "DeepSeek", "Mistral", "Moonshot",
    ]
}
