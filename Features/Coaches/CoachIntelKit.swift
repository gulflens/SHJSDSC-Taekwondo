import SwiftUI

// MARK: - Coach intelligence kit
//
// Stage 1.14 — Coaches module remodel. The `CoachIntel` view-model plus the
// rings, chips and small primitives the coaches dashboard is built from.
// Executive cards reuse `ExecutiveAnalyticsCard` / `MiniSparkline` /
// `TrendIndicator` from `BranchOverviewKit`.

/// The six coaching-competency axes shown on the preview-panel radar and as
/// the coach's performance breakdown. Derived from the `Coach` dossier.
public enum CoachMetricKind: String, CaseIterable, Sendable, Hashable {
    case teaching, leadership, performance, technical, discipline, attendance

    public var labelKey: String { "coach.metric.\(rawValue)" }

    public var tint: Color {
        switch self {
        case .teaching:    .accentColor
        case .leadership:  .purple
        case .performance: .pink
        case .technical:   .orange
        case .discipline:  .indigo
        case .attendance:  .secondaryAccent
        }
    }
}

public struct CoachMetricScore: Identifiable, Sendable, Hashable {
    public let kind: CoachMetricKind
    public var score: Double          // 0–100
    public var id: String { kind.rawValue }
}

/// One row in a coach's recent-activity feed.
public struct CoachActivity: Identifiable, Sendable, Hashable {
    public enum Kind: String, Sendable, Hashable {
        case session, assessment, review, certification
        public var labelKey: String { "coach.activity.\(rawValue)" }
        public var systemIcon: String {
            switch self {
            case .session:       "figure.taekwondo"
            case .assessment:    "checklist"
            case .review:        "trophy.fill"
            case .certification: "checkmark.seal.fill"
            }
        }
    }
    public let id: EntityID
    public var kind: Kind
    public var dateText: String
}

// MARK: - Coach intel view-model

/// Everything a coach card + preview panel need. Dan rank, experience,
/// certifications and the discipline competencies are real `Coach` data; the
/// six radar axes, the squad/session counts and the activity feed are
/// demo-derived deterministically from a stable per-coach seed — the same
/// approach as the Stage 1.11 branch dashboard.
public struct CoachIntel: Identifiable, Sendable, Hashable {
    public let coach: Coach
    public let branchName: String
    public var id: EntityID { coach.id }
    public var composite: Double
    public var grade: LetterGrade
    public var isElite: Bool
    public var isHeadCoach: Bool
    public var onLeave: Bool
    public var athleteCount: Int
    public var sessionsPerWeek: Int
    public var attendancePct: Double
    public var radar: [CoachMetricScore]
    public var recentActivity: [CoachActivity]

    public var experienceYears: Int { coach.yearsOfExperience }

    public func metric(_ kind: CoachMetricKind) -> Double {
        radar.first { $0.kind == kind }?.score ?? 0
    }

    /// Builds the intel from a coach, their branch name and assigned-athlete
    /// count (counted from the repository in the dashboard).
    public static func make(coach: Coach, branchName: String, athleteCount: Int) -> CoachIntel {
        let seed = CoachIntel.seed(coach.avatarSeed)
        func level(_ v: Int?) -> Double { Double(min(5, max(1, v ?? 3))) }
        func wobble(_ k: Double) -> Double { sin(seed * 6.28 + k) * 6 }

        let technical  = (level(coach.technicalLevel) + level(coach.poomsaeLevel)) / 2 * 20
        let performance = level(coach.sparringLevel) * 16 + 14 + wobble(1)
        let teaching   = (coach.peerReviewAvg ?? (3.6 + seed)) / 5 * 100
        let leadership = 46 + Double(coach.danRank) * 7
            + (coach.coachLevel == .head ? 12 : 0) + wobble(2)
        let discipline = 70 + seed * 24 + wobble(3)
        let attendance = 82 + seed * 15 + wobble(4)

        let pairs: [(CoachMetricKind, Double)] = [
            (.teaching,    clamp(teaching)),
            (.leadership,  clamp(leadership)),
            (.performance, clamp(performance)),
            (.technical,   clamp(technical)),
            (.discipline,  clamp(discipline)),
            (.attendance,  clamp(attendance)),
        ]
        let composite = pairs.reduce(0.0) { $0 + $1.1 } / Double(pairs.count)

        let sessions = coach.weeklyHoursTarget.map { max(6, Int(Double($0) / 1.5)) }
            ?? (11 + Int(seed * 10))

        let isElite = coach.coachLevel == .national || coach.coachLevel == .international
            || coach.olympicProgramStatus != .none || coach.nationalTeamStatus == .leadStaff
            || composite >= 90

        let activityKinds: [CoachActivity.Kind] = [.session, .assessment, .review]
        let dateKeys = ["coach.activity.today", "coach.activity.yesterday", "coach.activity.days_ago"]
        let activity = activityKinds.enumerated().map { idx, kind -> CoachActivity in
            let date = idx < 2
                ? NSLocalizedString(dateKeys[idx], comment: "")
                : String(format: NSLocalizedString(dateKeys[idx], comment: ""), idx * 2 + 1)
            return CoachActivity(id: UUID(), kind: kind, dateText: date)
        }

        return CoachIntel(
            coach: coach, branchName: branchName,
            composite: composite, grade: LetterGrade.from(score: composite),
            isElite: isElite,
            isHeadCoach: coach.coachLevel == .head,
            onLeave: coach.employmentStatus == .leave,
            athleteCount: athleteCount, sessionsPerWeek: sessions,
            attendancePct: clamp(attendance),
            radar: pairs.map { CoachMetricScore(kind: $0.0, score: $0.1) },
            recentActivity: activity)
    }

    private static func clamp(_ v: Double) -> Double { min(99, max(40, v)) }

    private static func seed(_ s: String) -> Double {
        var h: UInt64 = 0xcbf29ce484222325
        for b in s.utf8 { h ^= UInt64(b); h = h &* 0x100000001b3 }
        return Double(h % 1000) / 1000.0
    }
}

// MARK: - Grade ring

/// Coach overall-score ring — letter grade + score + caption. Apple-Fitness
/// inspired: a trimmed gradient ring over a faint track.
public struct CoachGradeRing: View {
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
                Text("coach.overall_score")
                    .scaledFont(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

// MARK: - Status chip

/// Pastel coach chip — Head Coach / Assistant / On Leave / Elite, etc.
public struct CoachStatusChip: View {
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

// MARK: - Metric block

/// Compact labelled metric block for a coach card — value over a caption.
public struct CoachMetricBlock: View {
    private let value: String
    private let labelKey: String
    private let tint: Color

    public init(value: String, labelKey: String, tint: Color = .primary) {
        self.value = value
        self.labelKey = labelKey
        self.tint = tint
    }

    public var body: some View {
        VStack(spacing: 2) {
            Text(verbatim: value)
                .scaledFont(.subheadline, weight: .bold, monospacedDigit: true)
                .foregroundStyle(tint)
                .environment(\.layoutDirection, .leftToRight)
            Text(localizedKey: labelKey)
                .scaledFont(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.secondary.opacity(0.06),
                    in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

// MARK: - Insight card

/// Soft colored coach-intelligence card — used for the smart insights strip.
public struct CoachInsightCard: View {
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

/// Rounded glass-material search field for the coaches header.
public struct SearchCoachField: View {
    @Binding private var text: String

    public init(text: Binding<String>) { _text = text }

    public var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "magnifyingglass")
                .scaledFont(.footnote, weight: .medium)
                .foregroundStyle(.secondary)
            TextField(text: $text) { Text("coach.search") }
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
