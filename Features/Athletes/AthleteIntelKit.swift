import SwiftUI

// MARK: - Athlete intelligence kit
//
// Stage 1.12 — Athletes module remodel. The `AthleteIntel` view-model plus
// the cards, rings and chips the dashboard is built from. Executive cards
// reuse `ExecutiveAnalyticsCard` / `MiniSparkline` / `TrendIndicator` from
// `BranchOverviewKit`.

/// The five compact performance metrics shown as mini rings on an athlete
/// card. Derived from `PerformanceScore`.
public enum AthleteMetricKind: String, CaseIterable, Sendable, Hashable {
    case attendance, progress, discipline, fitness, competition

    public var labelKey: String { "athlete.metric.\(rawValue)" }

    public var tint: Color {
        switch self {
        case .attendance:  .accentColor
        case .progress:    .secondaryAccent
        case .discipline:  .purple
        case .fitness:     .orange
        case .competition: .pink
        }
    }
}

public extension AthleteStatus {
    /// Pastel chip accent.
    var tint: Color {
        switch self {
        case .active:          .accentColor
        case .readyToGrade:    .secondaryAccent
        case .competitionTeam: .red
        case .watch:           .orange
        case .rest:            .secondary
        }
    }

    var systemIcon: String {
        switch self {
        case .active:          "bolt.fill"
        case .readyToGrade:    "checkmark.seal.fill"
        case .competitionTeam: "flag.fill"
        case .watch:           "eye.fill"
        case .rest:            "moon.fill"
        }
    }
}

public struct AthleteMetricScore: Identifiable, Sendable, Hashable {
    public let kind: AthleteMetricKind
    public var score: Double
    public var id: String { kind.rawValue }
}

/// One row in an athlete's "Recent Activity" feed.
public struct AthleteActivity: Identifiable, Sendable, Hashable {
    public enum Kind: String, Sendable, Hashable {
        case training, sparring, fitnessTest, grading
        public var labelKey: String { "athlete.activity.\(rawValue)" }
        public var systemIcon: String {
            switch self {
            case .training:    "figure.taekwondo"
            case .sparring:    "figure.kickboxing"
            case .fitnessTest: "heart.fill"
            case .grading:     "medal.fill"
            }
        }
    }
    public let id: EntityID
    public var kind: Kind
    public var dateText: String
    public var done: Bool
}

// MARK: - Athlete intel view-model

/// Everything an athlete card + preview panel need. Composite / grade / the
/// five metrics are real (from the athlete's `PerformanceScore`); the 12-week
/// trend and recent activity are demo-derived deterministically.
public struct AthleteIntel: Identifiable, Sendable, Hashable {
    public let athlete: Athlete
    public let branchName: String
    public var id: EntityID { athlete.id }
    public var composite: Double
    public var grade: LetterGrade
    public var isElite: Bool
    public var age: Int
    public var ageGroup: AgeGroup
    public var metrics: [AthleteMetricScore]
    public var perfTrend: [Double]
    public var recentActivity: [AthleteActivity]

    public func metric(_ kind: AthleteMetricKind) -> Double {
        metrics.first { $0.kind == kind }?.score ?? 0
    }

    /// Builds the intel from an athlete and their (optional) performance score.
    public static func make(athlete: Athlete, score: PerformanceScore?, branchName: String) -> AthleteIntel {
        let composite = score.map { ScoreEngine.composite($0) } ?? 0
        let metricPairs: [(AthleteMetricKind, Double)] = [
            (.attendance,  score?.adherence ?? 0),
            (.progress,    score?.beltProgression ?? 0),
            (.discipline,  score?.character ?? 0),
            (.fitness,     score?.physical ?? 0),
            (.competition, score?.competition ?? 0),
        ]
        let age = Calendar.current.dateComponents([.year], from: athlete.dateOfBirth, to: Date()).year ?? 0
        let seed = AthleteIntel.seed(athlete.avatarSeed)
        let trend = (0..<12).map { week -> Double in
            let t = Double(week) / 11.0
            let rise = (composite - 60) / 4 * t
            let wobble = sin(Double(week) * 1.6 + seed * 6) * 6
            return min(100, max(45, composite - 14 + rise + wobble))
        }
        let labels: [AthleteActivity.Kind] = [.training, .sparring, .fitnessTest, .grading]
        let dateKeys = ["athlete.activity.today", "athlete.activity.yesterday",
                        "athlete.activity.days_ago", "athlete.activity.days_ago"]
        let activity = labels.enumerated().map { idx, kind -> AthleteActivity in
            let date: String
            if idx < 2 {
                date = NSLocalizedString(dateKeys[idx], comment: "")
            } else {
                date = String(format: NSLocalizedString(dateKeys[idx], comment: ""), idx * 3 + 2)
            }
            return AthleteActivity(id: UUID(), kind: kind, dateText: date, done: idx < 3)
        }
        return AthleteIntel(
            athlete: athlete, branchName: branchName,
            composite: composite, grade: LetterGrade.from(score: composite),
            isElite: composite >= 88,
            age: age, ageGroup: AgeGroup.from(age: age),
            metrics: metricPairs.map { AthleteMetricScore(kind: $0.0, score: $0.1) },
            perfTrend: trend, recentActivity: activity
        )
    }

    private static func seed(_ s: String) -> Double {
        var h: UInt64 = 0xcbf29ce484222325
        for b in s.utf8 { h ^= UInt64(b); h = h &* 0x100000001b3 }
        return Double(h % 1000) / 1000.0
    }
}

// MARK: - Grade ring

/// Athlete overall-score ring — letter grade + score + caption.
public struct AthleteGradeRing: View {
    private let grade: LetterGrade
    private let score: Double
    private let size: CGFloat
    private let showsCaption: Bool

    public init(grade: LetterGrade, score: Double, size: CGFloat = 64, showsCaption: Bool = true) {
        self.grade = grade
        self.score = score
        self.size = size
        self.showsCaption = showsCaption
    }

    public var body: some View {
        VStack(spacing: 3) {
            ZStack {
                Circle().stroke(grade.branchTint.opacity(0.15), lineWidth: size * 0.11)
                Circle()
                    .trim(from: 0, to: min(1, max(0, score / 100)))
                    .stroke(
                        LinearGradient(colors: [grade.branchTint, grade.branchTint.opacity(0.65)],
                                       startPoint: .top, endPoint: .bottom),
                        style: StrokeStyle(lineWidth: size * 0.11, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .shadow(color: grade.branchTint.opacity(0.3), radius: 4)
                    .animation(.easeInOut(duration: 0.5), value: score)
                VStack(spacing: 0) {
                    Text(verbatim: grade.label)
                        .font(.system(size: size * 0.34, weight: .bold, design: .rounded))
                        .foregroundStyle(grade.branchTint)
                    Text(verbatim: String(format: "%.1f", score))
                        .scaledFont(.caption2, weight: .semibold, monospacedDigit: true)
                        .foregroundStyle(.secondary)
                        .environment(\.layoutDirection, .leftToRight)
                }
            }
            .frame(width: size, height: size)
            if showsCaption {
                Text("athlete.overall_score")
                    .scaledFont(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

// MARK: - Mini metric ring

/// Small radial metric ring — score inside, metric label below.
public struct MiniMetricRing: View {
    private let kind: AthleteMetricKind
    private let score: Double

    public init(kind: AthleteMetricKind, score: Double) {
        self.kind = kind
        self.score = score
    }

    public var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle().stroke(kind.tint.opacity(0.16), lineWidth: 3.5)
                Circle()
                    .trim(from: 0, to: min(1, max(0, score / 100)))
                    .stroke(kind.tint, style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text(verbatim: "\(Int(score.rounded()))")
                    .scaledFont(.caption2, weight: .bold, monospacedDigit: true)
                    .environment(\.layoutDirection, .leftToRight)
            }
            .frame(width: 40, height: 40)
            Text(localizedKey: kind.labelKey)
                .scaledFont(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }
}

// MARK: - Status chip

/// Generic pastel athlete chip — status, "Elite", age group, etc.
public struct AthleteTagChip: View {
    private let titleKey: String
    private let tint: Color
    private let systemIcon: String?

    public init(titleKey: String, tint: Color, systemIcon: String? = nil) {
        self.titleKey = titleKey
        self.tint = tint
        self.systemIcon = systemIcon
    }

    public var body: some View {
        HStack(spacing: 4) {
            if let systemIcon {
                Image(systemName: systemIcon).scaledFont(.caption2, weight: .bold)
            }
            Text(localizedKey: titleKey).scaledFont(.caption2, weight: .semibold)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(tint.opacity(0.15), in: Capsule())
        .foregroundStyle(tint)
    }
}

// MARK: - Insight card

/// Soft colored athlete-intelligence card.
public struct AthleteInsightCard: View {
    private let systemIcon: String
    private let tint: Color
    private let text: AttributedString

    public init(systemIcon: String, tint: Color, text: AttributedString) {
        self.systemIcon = systemIcon
        self.tint = tint
        self.text = text
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemIcon)
                .scaledFont(.footnote, weight: .semibold)
                .foregroundStyle(tint)
                .frame(width: 28, height: 28)
                .background(tint.opacity(0.16),
                            in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            Text(text)
                .scaledFont(.caption)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.08),
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Search field

/// Rounded glass-material search field for the athletes header.
public struct SearchAthleteField: View {
    @Binding private var text: String

    public init(text: Binding<String>) {
        _text = text
    }

    public var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "magnifyingglass")
                .scaledFont(.footnote, weight: .medium)
                .foregroundStyle(.secondary)
            TextField(text: $text) { Text("athlete.search") }
                .textFieldStyle(.plain)
                #if os(iOS)
                .textInputAutocapitalization(.never)
                #endif
                .autocorrectionDisabled()
            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .scaledFont(.footnote)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(.thinMaterial, in: Capsule())
        .overlay(Capsule().stroke(Color.secondary.opacity(0.14), lineWidth: 1))
    }
}
