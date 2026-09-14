import SwiftUI

/// The pieces every screen is built from.
///
/// The prototype has a small vocabulary — card, stat card, chip, status pill,
/// bar, table — used everywhere. Keeping the same vocabulary here is what makes
/// the port read as the same product rather than a similar one.
///
/// Sizes come from `Theme`, which comes from the prototype's token block. Type
/// uses Dynamic Type styles rather than the prototype's fixed 15px: an auditor
/// reading a ledger is exactly the person who will enlarge it.

// MARK: Card

struct Card<Content: View>: View {
    var title: String?
    var trailing: String?
    @ViewBuilder var content: Content

    init(_ title: String? = nil, trailing: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.trailing = trailing
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if title != nil || trailing != nil {
                HStack(alignment: .firstTextBaseline) {
                    if let title {
                        Text(title).font(.headline).foregroundStyle(Theme.text)
                    }
                    Spacer(minLength: 12)
                    if let trailing {
                        Text(trailing).font(.caption).foregroundStyle(Theme.muted)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.radiusCard))
        .overlay(RoundedRectangle(cornerRadius: Theme.radiusCard).stroke(Theme.line, lineWidth: 1))
    }
}

// MARK: Screen header

/// A screen's title and one line saying what it is for.
///
/// Detail screens inherit their parent's icon, which is the RC2.1 forensic
/// audit's rule: every header carries an icon, and a detail screen carries the
/// icon of the screen it came from.
struct ScreenHeader: View {
    var screen: Screen
    var title: String
    var subtitle: String?
    var iconScreen: Screen?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            BridgeIcon(iconScreen ?? screen, size: 40)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.largeTitle.weight(.semibold))
                    .foregroundStyle(Theme.text)
                if let subtitle {
                    Text(subtitle).font(.subheadline).foregroundStyle(Theme.text2)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.bottom, 4)
    }
}

// MARK: Stat card

/// A number, a label, and the icon that names it.
///
/// Every stat card carries an icon — the RC2.1 audit made that a rule — and a
/// tappable one shows a chevron so the affordance is visible rather than learnt.
struct StatCard: View {
    var value: String
    var label: String
    var tint: Color?
    var icon: AnyView?
    var action: (() -> Void)?
    var selected: Bool = false

    var body: some View {
        let content = HStack(spacing: 10) {
            if let icon { icon }
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(.title, design: .default).weight(.semibold))
                    .foregroundStyle(tint ?? Theme.text)
                Text(label).font(.caption).foregroundStyle(Theme.text2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            if action != nil {
                Image(systemName: "chevron.right").font(.caption2).foregroundStyle(Theme.muted)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.radiusCard))
        .overlay(RoundedRectangle(cornerRadius: Theme.radiusCard)
            .stroke(selected ? Theme.led : Theme.line, lineWidth: selected ? 2 : 1))

        if let action {
            Button(action: action) { content }.buttonStyle(.plain)
        } else {
            content
        }
    }
}

// MARK: Status

enum StatusKind {
    case ok, warn, crit, info, muted

    var color: Color {
        switch self {
        case .ok: Theme.led
        case .warn: Theme.warn
        case .crit: Theme.crit
        case .info: Theme.info
        case .muted: Theme.muted
        }
    }
}

/// A status pill. Never colour alone: the text carries the meaning, so it still
/// reads without colour vision.
struct StatusPill: View {
    var kind: StatusKind
    var text: String

    var body: some View {
        HStack(spacing: 5) {
            Circle().fill(kind.color).frame(width: 7, height: 7)
            Text(text).font(.caption).foregroundStyle(Theme.text2)
        }
        .padding(.horizontal, 9).padding(.vertical, 4)
        .background(Theme.surface2, in: Capsule())
        .accessibilityElement(children: .combine)
    }
}

/// A chip. Informational by default; tappable ones show a chevron, which the
/// RC2.1 audit made a rule so that a chip's behaviour is visible before it is
/// tried.
struct Chip: View {
    var text: String
    var dot: Color?
    var action: (() -> Void)?

    var body: some View {
        let content = HStack(spacing: 6) {
            if let dot { Circle().fill(dot).frame(width: 7, height: 7) }
            Text(text).font(.caption).foregroundStyle(Theme.text2)
            if action != nil {
                Image(systemName: "chevron.right").font(.system(size: 8)).foregroundStyle(Theme.muted)
            }
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(Theme.surface2, in: Capsule())

        if let action {
            Button(action: action) { content }.buttonStyle(.plain)
        } else {
            content
        }
    }
}

// MARK: Bar

/// A progress bar, used for the REP clock and the measures.
struct MeterBar: View {
    var share: Double
    var color: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.surface2)
                Capsule().fill(color)
                    .frame(width: max(0, min(1, share)) * geo.size.width)
            }
        }
        .frame(height: 8)
        .accessibilityHidden(true)
    }
}

// MARK: Key/value

/// A labelled value, the shape every detail screen repeats.
struct KeyValue: View {
    var label: String
    var value: String
    var monospaced: Bool = false
    var tint: Color?

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label).font(.caption).foregroundStyle(Theme.muted)
            Text(value)
                .font(monospaced ? Theme.mono : .body)
                .foregroundStyle(tint ?? Theme.text)
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: Read-only banner

/// Shown to roles that may inspect but not change.
///
/// The prototype states this plainly rather than silently disabling controls,
/// because a person who cannot tell whether a control is broken or forbidden
/// will assume broken.
struct ReadOnlyBanner: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "eye").foregroundStyle(Theme.warn)
            Text(Key.readonly.string).font(.footnote).foregroundStyle(Theme.text2)
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface2, in: RoundedRectangle(cornerRadius: Theme.radiusCtl))
    }
}

// MARK: Sample-data label

/// Marks a figure that came from seeded data rather than measurement.
///
/// The RC2 brief forbids showing a collections or compliance result before one
/// has been measured. Rather than hide the seeded figures, every one of them
/// says what it is.
struct SampleBadge: View {
    /// Already localized. Callers pass `L("...")` or a literal marker such as
    /// "EST", so this never builds a localization key from a runtime value.
    var text: String = L("sample data")

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(Theme.warn)
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(Theme.surface2, in: RoundedRectangle(cornerRadius: 4))
    }
}

// MARK: Screen scaffold

/// The frame every screen sits in: scrolling body, consistent padding.
struct ScreenScaffold<Content: View>: View {
    var maxWidth: CGFloat = 1100
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                content
            }
            .frame(maxWidth: maxWidth, alignment: .leading)
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .background(Theme.bg)
    }
}

/// A responsive grid of cards: as many columns as fit, one on a phone.
struct CardGrid<Content: View>: View {
    var minimum: CGFloat = 210
    @ViewBuilder var content: Content

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: minimum), spacing: 14)],
                  alignment: .leading, spacing: 14) {
            content
        }
    }
}
