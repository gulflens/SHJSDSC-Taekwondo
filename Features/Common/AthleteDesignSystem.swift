import SwiftUI

// Design-system primitives for the federation-grade athlete profile redesign.
//
// Style tokens used here:
//   - Surface       Color.cardBackground (auto-generated from Assets.xcassets)
//   - Hairline      Color.secondary.opacity(0.18)
//   - Soft shadow   .shadow(color: .black.opacity(0.04), radius: 14, y: 6)
//   - Corner radius 16 (cards) / 10 (chips) / 8 (status pills)
//   - Body font     .system size via SF Pro (default), tabular-numeric on stats
//   - Accent        Color.tint (semantic alias for accentColor)
//   - Progress good Color.green; warning .orange; critical .red
//
// Every public type is reusable beyond the athlete module. All user-facing
// strings flow through `LocalizedStringKey` so the xcstrings catalogue stays
// authoritative.

// MARK: - Cards

/// White, rounded, soft-shadow surface used for every block on the redesigned
/// athlete profile. Provides an optional title bar with a trailing action
/// (typically "View All").
public struct SectionCard<Content: View, Trailing: View>: View {
    private let titleKey: LocalizedStringKey?
    private let icon: String?
    private let trailing: Trailing
    private let content: Content

    public init(
        _ titleKey: LocalizedStringKey? = nil,
        icon: String? = nil,
        @ViewBuilder trailing: () -> Trailing,
        @ViewBuilder content: () -> Content
    ) {
        self.titleKey = titleKey
        self.icon = icon
        self.trailing = trailing()
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if titleKey != nil || icon != nil {
                HStack(spacing: 8) {
                    if let icon {
                        Image(systemName: icon)
                            .scaledFont(.subheadline, weight: .semibold)
                            .foregroundStyle(.tint)
                    }
                    if let titleKey {
                        Text(titleKey)
                            .scaledFont(.subheadline, weight: .semibold)
                            .foregroundStyle(.primary)
                    }
                    Spacer(minLength: 0)
                    trailing
                }
            }
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 14, y: 6)
    }
}

public extension SectionCard where Trailing == EmptyView {
    init(
        _ titleKey: LocalizedStringKey? = nil,
        icon: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.init(titleKey, icon: icon, trailing: { EmptyView() }, content: content)
    }
}

/// "View All" chevron button used in the trailing slot of `SectionCard`.
public struct ViewAllButton: View {
    private let action: () -> Void

    public init(action: @escaping () -> Void = {}) {
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 2) {
                Text("action.view_all")
                Image(systemName: "chevron.right")
                    .scaledFont(.caption2, weight: .semibold)
                    .flipsForRightToLeftLayoutDirection(true)
            }
            .scaledFont(.caption, weight: .semibold)
            .foregroundStyle(.tint)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Identity chips

/// Subtle two-line ID chip: top caption ("UAE Federation ID") + bottom value
/// rendered in monospaced digits so number-heavy strings stay visually stable.
/// Used in the athlete profile header.
public struct IDChip: View {
    public let labelKey: LocalizedStringKey
    public let value: String
    public let systemIcon: String?

    public init(_ labelKey: LocalizedStringKey, value: String, icon: String? = nil) {
        self.labelKey = labelKey
        self.value = value
        self.systemIcon = icon
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                if let systemIcon {
                    Image(systemName: systemIcon)
                        .scaledFont(.caption2)
                        .foregroundStyle(.secondary)
                }
                Text(labelKey)
                    .scaledFont(.caption2)
                    .foregroundStyle(.secondary)
            }
            Text(verbatim: value.isEmpty ? "—" : value)
                .scaledFont(.footnote, weight: .semibold, monospacedDigit: true)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .environment(\.layoutDirection, .leftToRight)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Compact metadata chip used for Gender / Age / Nationality in the header.
public struct MetaChip: View {
    public let labelKey: LocalizedStringKey
    public let value: String
    public let systemIcon: String

    public init(_ labelKey: LocalizedStringKey, value: String, icon: String) {
        self.labelKey = labelKey
        self.value = value
        self.systemIcon = icon
    }

    public var body: some View {
        HStack(spacing: 5) {
            Image(systemName: systemIcon)
                .scaledFont(.caption2)
                .foregroundStyle(.tint)
            Text(verbatim: value)
                .scaledFont(.caption, weight: .medium)
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(Color.accentColor.opacity(0.10), in: Capsule())
        .accessibilityLabel(Text(labelKey))
        .accessibilityValue(Text(verbatim: value))
    }
}

/// Tiny blue verified-checkmark badge rendered to the right of the athlete
/// name when the profile has all federation IDs + an uploaded photo.
public struct VerificationBadge: View {
    public init() {}

    public var body: some View {
        Image(systemName: "checkmark.seal.fill")
            .scaledFont(.title3)
            .foregroundStyle(Color.tint)
            .accessibilityLabel(Text("athlete.profile.verified"))
    }
}

/// Pill used for Squad / Weight Category / Belt context badges under the
/// athlete name. Colour adapts to the semantic tone of the value.
public struct CategoryBadge: View {
    public enum Tone {
        case elite, neutral, dark, warning, success

        var foreground: Color {
            switch self {
            case .elite: .white
            case .neutral: .primary
            case .dark: .white
            case .warning: .orange
            case .success: .green
            }
        }

        var background: Color {
            switch self {
            case .elite: Color.tint
            case .neutral: Color.secondary.opacity(0.14)
            case .dark: Color(white: 0.18)
            case .warning: Color.orange.opacity(0.18)
            case .success: Color.green.opacity(0.18)
            }
        }
    }

    public let labelKey: LocalizedStringKey?
    public let value: String
    public let tone: Tone
    public let systemIcon: String?

    public init(
        _ labelKey: LocalizedStringKey? = nil,
        value: String,
        tone: Tone = .neutral,
        icon: String? = nil
    ) {
        self.labelKey = labelKey
        self.value = value
        self.tone = tone
        self.systemIcon = icon
    }

    public var body: some View {
        HStack(spacing: 6) {
            if let systemIcon {
                Image(systemName: systemIcon)
                    .scaledFont(.caption2, weight: .semibold)
            }
            if let labelKey {
                Text(labelKey)
                    .scaledFont(.caption2)
                    .opacity(0.75)
            }
            Text(verbatim: value)
                .scaledFont(.caption, weight: .semibold)
        }
        .foregroundStyle(tone.foreground)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(tone.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

// MARK: - Progress ring

/// Circular progress ring used for the Overview tab's overall-progress metric.
/// `value` clamped 0...1; `delta` is rendered as a green "+N% vs last month"
/// or red "-N% vs last month" caption when non-nil.
public struct ProgressRing: View {
    public let value: Double
    public let size: CGFloat
    public let trackWidth: CGFloat
    public let centerLabelKey: LocalizedStringKey
    public let delta: Double?
    @Environment(\.uiScale) private var uiScale

    public init(
        value: Double,
        size: CGFloat = 132,
        trackWidth: CGFloat = 12,
        centerLabelKey: LocalizedStringKey = "athlete.overall_progress",
        delta: Double? = nil
    ) {
        self.value = max(0, min(1, value))
        self.size = size
        self.trackWidth = trackWidth
        self.centerLabelKey = centerLabelKey
        self.delta = delta
    }

    /// Caller-provided size + track width scaled by the UI Zoom factor. The
    /// inner percentage font is derived from this so the ring, its stroke,
    /// and the centred number all grow together.
    private var renderSize: CGFloat { size * uiScale }
    private var renderTrackWidth: CGFloat { trackWidth * uiScale }

    public var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.15), lineWidth: renderTrackWidth)
                Circle()
                    .trim(from: 0, to: value)
                    .stroke(
                        LinearGradient(
                            colors: [Color.green, Color.green.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        style: StrokeStyle(lineWidth: renderTrackWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.6), value: value)
                VStack(spacing: 2) {
                    Text(verbatim: "\(Int((value * 100).rounded()))%")
                        .font(.system(size: renderSize * 0.22, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .environment(\.layoutDirection, .leftToRight)
                    Text(centerLabelKey)
                        .scaledFont(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(width: renderSize, height: renderSize)
            if let delta {
                HStack(spacing: 4) {
                    Image(systemName: delta >= 0 ? "arrow.up.right" : "arrow.down.right")
                    Text(verbatim: String(format: "%+.0f%%", delta * 100))
                        .environment(\.layoutDirection, .leftToRight)
                    Text("athlete.vs_last_month")
                }
                .scaledFont(.caption, weight: .semibold)
                .foregroundStyle(delta >= 0 ? .green : .red)
            }
        }
    }
}

// MARK: - Summary rows

/// Row used inside the Athlete Summary card: small mono icon → label → value.
public struct AthleteSummaryRow: View {
    public let icon: String
    public let labelKey: LocalizedStringKey
    public let value: String
    public let valueColor: Color

    public init(icon: String, labelKey: LocalizedStringKey, value: String, valueColor: Color = .primary) {
        self.icon = icon
        self.labelKey = labelKey
        self.value = value
        self.valueColor = valueColor
    }

    public var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .scaledFont(.footnote)
                .foregroundStyle(.tint)
                .frame(width: 18)
            Text(labelKey)
                .scaledFont(.footnote)
                .foregroundStyle(.secondary)
            Spacer(minLength: 8)
            Text(verbatim: value)
                .scaledFont(.footnote, weight: .semibold)
                .foregroundStyle(valueColor)
                .lineLimit(1)
        }
        .padding(.vertical, 2)
    }
}

/// Two-line metric row used by Training This Week: label on top, value /
/// target underneath with a slim progress bar to the right of the value.
public struct TrainingStatRow: View {
    public let icon: String
    public let labelKey: LocalizedStringKey
    public let value: Double
    public let target: Double
    public let unitSuffix: String

    public init(icon: String, labelKey: LocalizedStringKey, value: Double, target: Double, unitSuffix: String = "") {
        self.icon = icon
        self.labelKey = labelKey
        self.value = value
        self.target = target
        self.unitSuffix = unitSuffix
    }

    public var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .scaledFont(.subheadline)
                .foregroundStyle(.tint)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(labelKey)
                        .scaledFont(.caption)
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 0)
                    Text(verbatim: formattedValue)
                        .scaledFont(.caption, weight: .semibold, monospacedDigit: true)
                        .foregroundStyle(.primary)
                        .environment(\.layoutDirection, .leftToRight)
                }
                progressBar
            }
        }
    }

    private var formattedValue: String {
        let v = value.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(value))
            : String(format: "%.1f", value)
        let t = target.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(target))
            : String(format: "%.1f", target)
        let suffix = unitSuffix.isEmpty ? "" : unitSuffix
        if target > 0 {
            return "\(v)/\(t)\(suffix)"
        } else {
            return "\(v)\(suffix)"
        }
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.secondary.opacity(0.15))
                RoundedRectangle(cornerRadius: 2)
                    .fill(barColor)
                    .frame(width: max(2, geo.size.width * clampedRatio))
            }
        }
        .frame(height: 4)
    }

    private var clampedRatio: Double {
        guard target > 0 else { return value > 0 ? 1 : 0 }
        return max(0, min(1, value / target))
    }

    private var barColor: Color {
        switch clampedRatio {
        case 0.85...: return .green
        case 0.5..<0.85: return .tint
        default: return .orange
        }
    }
}

/// "Speed 81/100" row used in Latest Performance — label + filled bar +
/// numeric value, with the value rendered LTR.
public struct RatingBarRow: View {
    public let icon: String
    public let labelKey: LocalizedStringKey
    public let value: Double
    public let maxValue: Double

    public init(icon: String, labelKey: LocalizedStringKey, value: Double, maxValue: Double = 100) {
        self.icon = icon
        self.labelKey = labelKey
        self.value = value
        self.maxValue = maxValue
    }

    public var body: some View {
        VStack(spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .scaledFont(.caption)
                    .foregroundStyle(.tint)
                    .frame(width: 16)
                Text(labelKey)
                    .scaledFont(.caption)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
                Text(verbatim: "\(Int(value.rounded()))/\(Int(maxValue))")
                    .scaledFont(.caption, weight: .semibold, monospacedDigit: true)
                    .foregroundStyle(.primary)
                    .environment(\.layoutDirection, .leftToRight)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.secondary.opacity(0.12))
                    RoundedRectangle(cornerRadius: 3)
                        .fill(barColor)
                        .frame(width: max(3, geo.size.width * clampedRatio))
                }
            }
            .frame(height: 6)
        }
    }

    private var clampedRatio: Double {
        guard maxValue > 0 else { return 0 }
        return max(0, min(1, value / maxValue))
    }

    private var barColor: Color {
        switch clampedRatio {
        case 0.8...: return .green
        case 0.5..<0.8: return .tint
        case 0.3..<0.5: return .orange
        default: return .red
        }
    }
}

// MARK: - Ranking + Achievements

public struct RankingRow: View {
    public let labelKey: LocalizedStringKey
    public let systemIcon: String
    /// Rank value — nil renders as "N/A".
    public let rank: Int?
    /// Optional descriptive suffix, e.g. "of 24" — appears small + dim under the rank.
    public let totalKey: LocalizedStringKey?

    public init(labelKey: LocalizedStringKey, icon: String, rank: Int?, totalKey: LocalizedStringKey? = nil) {
        self.labelKey = labelKey
        self.systemIcon = icon
        self.rank = rank
        self.totalKey = totalKey
    }

    public var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemIcon)
                .scaledFont(.subheadline)
                .foregroundStyle(.tint)
                .frame(width: 22)
            Text(labelKey)
                .scaledFont(.footnote)
                .foregroundStyle(.primary)
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 1) {
                Text(verbatim: rank.map { "#\($0)" } ?? "N/A")
                    .scaledFont(.footnote, weight: .bold, monospacedDigit: true)
                    .foregroundStyle(rank == nil ? .secondary : .primary)
                    .environment(\.layoutDirection, .leftToRight)
                if let totalKey {
                    Text(totalKey)
                        .scaledFont(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

/// Single medal achievement card used in the Recent Achievements row.
public struct AchievementMedalCard: View {
    public let medal: MedalType
    public let tournamentName: String
    public let date: Date
    public let categoryDescription: String?

    public init(medal: MedalType, tournamentName: String, date: Date, categoryDescription: String? = nil) {
        self.medal = medal
        self.tournamentName = tournamentName
        self.date = date
        self.categoryDescription = categoryDescription
    }

    public var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(medalColor.opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: "medal.fill")
                    .scaledFont(.title2)
                    .foregroundStyle(medalColor)
            }
            Text(localizedKey: medal.labelKey)
                .scaledFont(.caption, weight: .bold)
                .foregroundStyle(medalColor)
            Text(verbatim: tournamentName)
                .scaledFont(.caption2, weight: .semibold)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .foregroundStyle(.primary)
            Text(date, format: .dateTime.month(.abbreviated).year())
                .scaledFont(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var medalColor: Color {
        switch medal {
        case .gold: Color(red: 0.86, green: 0.65, blue: 0.13)
        case .silver: Color(white: 0.55)
        case .bronze: Color(red: 0.72, green: 0.45, blue: 0.20)
        case .none: .secondary
        }
    }
}

/// Calendar-style date stamp + event details row used in the Upcoming Event card.
public struct UpcomingEventCard: View {
    public let date: Date
    public let title: String
    public let subtitle: String?
    public let footnoteKey: LocalizedStringKey?

    public init(date: Date, title: String, subtitle: String? = nil, footnoteKey: LocalizedStringKey? = nil) {
        self.date = date
        self.title = title
        self.subtitle = subtitle
        self.footnoteKey = footnoteKey
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 12) {
            dateStamp
            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: title)
                    .scaledFont(.subheadline, weight: .semibold)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                if let subtitle {
                    Text(verbatim: subtitle)
                        .scaledFont(.caption)
                        .foregroundStyle(.secondary)
                }
                if let footnoteKey {
                    Text(footnoteKey)
                        .scaledFont(.caption2)
                        .foregroundStyle(.tint)
                }
            }
            Spacer(minLength: 0)
        }
    }

    private var dateStamp: some View {
        VStack(spacing: 0) {
            Text(date, format: .dateTime.month(.abbreviated))
                .scaledFont(.caption, weight: .bold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 3)
                .background(Color.red.opacity(0.85))
            Text(date, format: .dateTime.day())
                .scaledFont(.title2, weight: .bold, monospacedDigit: true)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
                .environment(\.layoutDirection, .leftToRight)
        }
        .frame(width: 58)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.secondary.opacity(0.18), lineWidth: 1)
        )
    }
}

// MARK: - Segmented tab bar

/// Horizontally scrollable segmented tab bar — animated underline indicator,
/// auto-mirrors under RTL because it's built with HStack + ScrollView.
public struct SegmentedTabBar<Tab: Hashable & Identifiable>: View {
    @Binding private var selection: Tab
    private let tabs: [Tab]
    /// Pre-resolved title (call `NSLocalizedString` at the call site). Using a
    /// String here avoids SwiftUI's `LocalizedStringKey(runtime-interpolated)`
    /// lookup quirk that left dotted keys visible in earlier builds.
    private let title: (Tab) -> String
    private let systemIcon: ((Tab) -> String?)?

    @Namespace private var indicator

    public init(
        selection: Binding<Tab>,
        tabs: [Tab],
        title: @escaping (Tab) -> String,
        icon: ((Tab) -> String?)? = nil
    ) {
        _selection = selection
        self.tabs = tabs
        self.title = title
        self.systemIcon = icon
    }

    public var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(tabs) { tab in
                        tabButton(tab)
                            .id(tab.id)
                    }
                }
                .padding(.horizontal, 4)
            }
            .onChange(of: selection) { _, newValue in
                withAnimation(.easeInOut(duration: 0.25)) {
                    proxy.scrollTo(newValue.id, anchor: .center)
                }
            }
        }
    }

    @ViewBuilder
    private func tabButton(_ tab: Tab) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.22)) {
                selection = tab
            }
        } label: {
            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    if let icon = systemIcon?(tab) {
                        Image(systemName: icon)
                            .scaledFont(.caption, weight: .semibold)
                    }
                    Text(verbatim: title(tab))
                        .scaledFont(.subheadline, weight: selection == tab ? .semibold : .medium)
                }
                .foregroundStyle(selection == tab ? Color.accentColor : .secondary)
                .padding(.horizontal, 12)
                .padding(.top, 8)
                if selection == tab {
                    Capsule()
                        .fill(Color.accentColor)
                        .frame(height: 3)
                        .matchedGeometryEffect(id: "underline", in: indicator)
                        .padding(.horizontal, 8)
                } else {
                    Color.clear.frame(height: 3)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Document + Coach Note rows

public struct DocumentRow: View {
    public let document: AthleteDocument
    public let now: Date

    public init(document: AthleteDocument, now: Date = Date()) {
        self.document = document
        self.now = now
    }

    public var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.accentColor.opacity(0.12))
                Image(systemName: document.kind.systemIcon)
                    .scaledFont(.subheadline)
                    .foregroundStyle(.tint)
            }
            .frame(width: 38, height: 38)
            VStack(alignment: .leading, spacing: 2) {
                Group {
                    if let label = document.label, !label.isEmpty {
                        // User-entered free text — render verbatim, not as a localization key.
                        Text(verbatim: label)
                    } else {
                        Text(localizedKey: document.kind.labelKey)
                    }
                }
                    .scaledFont(.subheadline, weight: .semibold)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    if let expiry = document.expiresAt {
                        Image(systemName: "calendar")
                            .scaledFont(.caption2)
                        Text("doc.expires_label")
                            .scaledFont(.caption2)
                        Text(expiry, format: .dateTime.day().month(.abbreviated).year())
                            .scaledFont(.caption2, monospacedDigit: true)
                            .environment(\.layoutDirection, .leftToRight)
                    } else {
                        Text("doc.no_expiry")
                            .scaledFont(.caption2)
                    }
                }
                .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            statusBadge
        }
        .padding(.vertical, 4)
    }

    private var statusBadge: some View {
        let derived = document.derivedStatus(asOf: now)
        let (tone, icon): (CategoryBadge.Tone, String) = switch derived {
        case .valid: (.success, "checkmark.circle.fill")
        case .expiringSoon: (.warning, "exclamationmark.circle.fill")
        case .expired: (.warning, "xmark.circle.fill")
        case .missing: (.neutral, "questionmark.circle")
        case .pending: (.neutral, "clock")
        }
        return CategoryBadge(
            value: NSLocalizedString(derived.labelKey, comment: ""),
            tone: tone,
            icon: icon
        )
    }
}

public struct CoachNoteCard: View {
    public let note: CoachNote

    public init(note: CoachNote) {
        self.note = note
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Avatar(seed: note.authorName, label: initials(note.authorName), size: 32)
                VStack(alignment: .leading, spacing: 1) {
                    Text(verbatim: note.authorName)
                        .scaledFont(.footnote, weight: .semibold)
                    Text(note.date, format: .dateTime.day().month(.abbreviated).year())
                        .scaledFont(.caption2)
                        .foregroundStyle(.secondary)
                        .environment(\.layoutDirection, .leftToRight)
                }
                Spacer(minLength: 0)
                CategoryBadge(
                    value: NSLocalizedString(note.category.labelKey, comment: ""),
                    tone: .neutral,
                    icon: note.category.systemIcon
                )
                if note.isPinned {
                    Image(systemName: "pin.fill")
                        .scaledFont(.caption)
                        .foregroundStyle(.orange)
                        .accessibilityLabel(Text("coach_note.pinned"))
                }
            }
            Text(verbatim: note.body)
                .scaledFont(.subheadline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.secondary.opacity(0.12), lineWidth: 1)
        )
    }

    private func initials(_ name: String) -> String {
        name.split(separator: " ").prefix(2).map { String($0.prefix(1)) }.joined().uppercased()
    }
}

// MARK: - Greeting hero

/// Premium greeting card used as the first element on every role's home
/// dashboard. Adapts the greeting to the time of day, surfaces the user's
/// bilingual name, and renders a role chip + ambient icon on the trailing
/// edge.
public struct GreetingHero: View {
    public let fullName: String
    public let fullNameAr: String
    /// Pre-resolved role label (e.g. "Coach", "Technical Director"). Pass a
    /// raw NSLocalizedString result here — building a LocalizedStringKey from
    /// a runtime-interpolated string doesn't reliably look up in xcstrings.
    public let roleLabel: String?
    public let subtitleKey: LocalizedStringKey?
    public let now: Date

    public init(
        fullName: String,
        fullNameAr: String,
        roleLabel: String? = nil,
        subtitleKey: LocalizedStringKey? = nil,
        now: Date = Date()
    ) {
        self.fullName = fullName
        self.fullNameAr = fullNameAr
        self.roleLabel = roleLabel
        self.subtitleKey = subtitleKey
        self.now = now
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(localizedKey: greetingKey)
                    .scaledFont(.caption, weight: .semibold)
                    .foregroundStyle(.white.opacity(0.85))
                    .textCase(.uppercase)
                Text(verbatim: fullName)
                    .scaledFont(.title2, weight: .bold)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(verbatim: fullNameAr)
                    .scaledFont(.subheadline)
                    .foregroundStyle(.white.opacity(0.78))
                    .environment(\.layoutDirection, .rightToLeft)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    if let roleLabel, !roleLabel.isEmpty {
                        roleChip(roleLabel)
                    }
                    if let subtitleKey {
                        Text(subtitleKey)
                            .scaledFont(.caption, weight: .medium)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }
                .padding(.top, 2)
            }
            Spacer(minLength: 0)
            timeIcon
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [
                    Color.accentColor,
                    Color.accentColor.opacity(0.78)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: Color.accentColor.opacity(0.25), radius: 16, y: 8)
    }

    private func roleChip(_ label: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "person.fill")
                .scaledFont(.caption2, weight: .semibold)
            Text(verbatim: label)
                .scaledFont(.caption, weight: .semibold)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Color.white.opacity(0.22), in: Capsule())
        .foregroundStyle(.white)
    }

    private var timeIcon: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.18))
                .frame(width: 56, height: 56)
            Image(systemName: timeIconName)
                .scaledFont(.title2)
                .foregroundStyle(.white)
        }
    }

    private var hour: Int {
        Calendar.current.component(.hour, from: now)
    }

    private var greetingKey: String {
        switch hour {
        case 5..<12: "greeting.morning"
        case 12..<17: "greeting.afternoon"
        case 17..<22: "greeting.evening"
        default: "greeting.night"
        }
    }

    private var timeIconName: String {
        switch hour {
        case 5..<8: "sunrise.fill"
        case 8..<17: "sun.max.fill"
        case 17..<19: "sunset.fill"
        case 19..<22: "moon.stars.fill"
        default: "moon.fill"
        }
    }
}

// MARK: - Empty state

public struct EmptyStateCard: View {
    public let icon: String
    public let titleKey: LocalizedStringKey
    public let messageKey: LocalizedStringKey?

    public init(icon: String, titleKey: LocalizedStringKey, messageKey: LocalizedStringKey? = nil) {
        self.icon = icon
        self.titleKey = titleKey
        self.messageKey = messageKey
    }

    public var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .scaledFont(.title)
                .foregroundStyle(.secondary)
            Text(titleKey)
                .scaledFont(.subheadline, weight: .semibold)
                .multilineTextAlignment(.center)
            if let messageKey {
                Text(messageKey)
                    .scaledFont(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 16)
    }
}
