import SwiftUI

// Coaching-development design kit (Stage 1.15).
//
// Colour tints + shared chips for the assistant-coach / coaching-development
// surfaces. Tints live here (not on the Core model) so `Core/` stays free of
// SwiftUI — mirroring `DrillCategory.tint` in `DrillKit`. Every primitive
// reuses the Stage 1.6 card tokens; no new design tokens are introduced.

// MARK: - Tints

public extension ProgramRole {
    /// Pastel-chip accent. Each program role reads as a distinct, calm hue.
    var tint: Color {
        switch self {
        case .athlete:         .accentColor
        case .assistantCoach:  .secondaryAccent
        case .competitionTeam: .orange
        case .eliteSquad:      Color(red: 0.55, green: 0.36, blue: 0.96)
        case .demoTeam:        .pink
        }
    }
}

public extension DevelopmentLevel {
    /// Pipeline-stage hue — cool at the athlete end, warm at the top.
    var tint: Color {
        switch self {
        case .athlete:           .secondary
        case .assistantCoach:    .secondaryAccent
        case .juniorCoach:       .accentColor
        case .coach:             .indigo
        case .headCoach:         .orange
        case .technicalDirector: Color(red: 0.55, green: 0.36, blue: 0.96)
        }
    }
}

public extension CoachingPermission {
    /// Allowed actions read emerald; restricted (senior-only) actions read red.
    var tint: Color { isRestricted ? .red : .secondaryAccent }
}

// MARK: - Role chip

/// Rounded pastel chip for a single `ProgramRole`. Apple-style: tinted fill,
/// icon + label, auto-mirrors under RTL because it's an `HStack`.
public struct RoleChipView: View {
    public let role: ProgramRole
    public let emphasised: Bool

    public init(role: ProgramRole, emphasised: Bool = false) {
        self.role = role
        self.emphasised = emphasised
    }

    public var body: some View {
        HStack(spacing: 5) {
            Image(systemName: role.systemIcon)
                .scaledFont(.caption2, weight: .semibold)
            Text(localizedKey: role.labelKey)
                .scaledFont(.caption, weight: .semibold)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .foregroundStyle(emphasised ? Color.white : role.tint)
        .background(
            emphasised ? AnyShapeStyle(role.tint) : AnyShapeStyle(role.tint.opacity(0.14)),
            in: Capsule()
        )
    }
}

// MARK: - Branch assignment chip

/// Pastel chip describing how an assistant coach is attached to a branch.
public struct BranchAssignmentChip: View {
    public enum Kind {
        case primary, support, tournament

        var labelKey: String { "branchAssignment.\(self)" }
        var icon: String {
            switch self {
            case .primary:    "house.fill"
            case .support:    "arrow.triangle.branch"
            case .tournament: "trophy.fill"
            }
        }
        var tint: Color {
            switch self {
            case .primary:    .accentColor
            case .support:    .secondaryAccent
            case .tournament: .orange
            }
        }
    }

    public let kind: Kind
    public let branchName: String

    public init(kind: Kind, branchName: String) {
        self.kind = kind
        self.branchName = branchName
    }

    public var body: some View {
        HStack(spacing: 6) {
            Image(systemName: kind.icon)
                .scaledFont(.caption2, weight: .semibold)
                .foregroundStyle(kind.tint)
            Text(verbatim: branchName)
                .scaledFont(.caption, weight: .medium)
                .foregroundStyle(.primary)
                .lineLimit(1)
            Text(localizedKey: kind.labelKey)
                .scaledFont(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.secondary.opacity(0.10), in: Capsule())
    }
}

// MARK: - Development-level badge

/// Pill marking a person's rung on the coaching-development pipeline.
public struct DevelopmentLevelBadge: View {
    public let level: DevelopmentLevel

    public init(level: DevelopmentLevel) {
        self.level = level
    }

    public var body: some View {
        HStack(spacing: 5) {
            Image(systemName: level.systemIcon)
                .scaledFont(.caption2, weight: .semibold)
            Text(localizedKey: level.labelKey)
                .scaledFont(.caption, weight: .semibold)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(level.tint, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

// MARK: - Readiness meter

/// Slim labelled progress bar, 0...1 — used for promotion readiness. Tone
/// shifts green → blue → orange as readiness drops.
public struct ReadinessMeter: View {
    public let value: Double
    public let titleKey: LocalizedStringKey

    public init(value: Double, titleKey: LocalizedStringKey = "coaching.promotion_readiness") {
        self.value = max(0, min(1, value))
        self.titleKey = titleKey
    }

    public var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(titleKey)
                    .scaledFont(.caption)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
                Text(verbatim: "\(Int((value * 100).rounded()))%")
                    .scaledFont(.caption, weight: .semibold, monospacedDigit: true)
                    .foregroundStyle(tone)
                    .environment(\.layoutDirection, .leftToRight)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.secondary.opacity(0.14))
                    Capsule()
                        .fill(tone)
                        .frame(width: max(4, geo.size.width * value))
                }
            }
            .frame(height: 7)
        }
    }

    private var tone: Color {
        switch value {
        case 0.8...:      return .green
        case 0.55..<0.8:  return .accentColor
        default:          return .orange
        }
    }
}

// MARK: - Evaluation stars

/// Five-segment rating row for coaching-evaluation scores (0...5).
public struct EvaluationStars: View {
    public let score: Double
    public let labelKey: LocalizedStringKey?

    public init(score: Double, labelKey: LocalizedStringKey? = nil) {
        self.score = max(0, min(5, score))
        self.labelKey = labelKey
    }

    public var body: some View {
        HStack(spacing: 8) {
            if let labelKey {
                Text(labelKey)
                    .scaledFont(.caption)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
            }
            HStack(spacing: 3) {
                ForEach(0..<5, id: \.self) { i in
                    Image(systemName: symbol(for: i))
                        .scaledFont(.caption2)
                        .foregroundStyle(Color.orange)
                }
            }
            Text(verbatim: String(format: "%.1f", score))
                .scaledFont(.caption, weight: .semibold, monospacedDigit: true)
                .foregroundStyle(.primary)
                .environment(\.layoutDirection, .leftToRight)
        }
    }

    private func symbol(for index: Int) -> String {
        let position = Double(index)
        if score >= position + 1 { return "star.fill" }
        if score >= position + 0.5 { return "star.leadinghalf.filled" }
        return "star"
    }
}

// MARK: - Pipeline stage node

/// One rung in the horizontal coaching-development pipeline strip.
public struct PipelineStageNode: View {
    public let level: DevelopmentLevel
    public let count: Int
    public let isCurrent: Bool

    public init(level: DevelopmentLevel, count: Int, isCurrent: Bool = false) {
        self.level = level
        self.count = count
        self.isCurrent = isCurrent
    }

    public var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(level.tint.opacity(isCurrent ? 1 : 0.16))
                Image(systemName: level.systemIcon)
                    .scaledFont(.subheadline, weight: .semibold)
                    .foregroundStyle(isCurrent ? Color.white : level.tint)
            }
            .frame(width: 44, height: 44)
            .overlay(
                Circle().stroke(level.tint, lineWidth: isCurrent ? 0 : 1.5)
            )
            Text(verbatim: "\(count)")
                .scaledFont(.headline, weight: .bold, monospacedDigit: true)
                .foregroundStyle(.primary)
                .environment(\.layoutDirection, .leftToRight)
            Text(localizedKey: level.labelKey)
                .scaledFont(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
    }
}
