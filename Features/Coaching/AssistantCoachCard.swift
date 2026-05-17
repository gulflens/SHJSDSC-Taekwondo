import SwiftUI

/// Premium card for a single assistant coach — a promoted athlete on the
/// coaching pathway. Shows the athlete identity, development-pipeline rung,
/// branch assignment, promotion readiness, and coaching activity. Used in the
/// coach profile's Assistant Coaches section, the coaching hierarchy, and the
/// Technical Director's development dashboard.
///
/// Callers wrap this in a `NavigationLink` to `AthleteDetailView` — the card
/// itself is pure presentation.
public struct AssistantCoachCard: View {
    public let athlete: Athlete
    public let primaryBranchName: String?
    public let supportBranchNames: [String]
    public let supervisingCoachName: String?
    public let showsSupervisor: Bool

    public init(
        athlete: Athlete,
        primaryBranchName: String? = nil,
        supportBranchNames: [String] = [],
        supervisingCoachName: String? = nil,
        showsSupervisor: Bool = false
    ) {
        self.athlete = athlete
        self.primaryBranchName = primaryBranchName
        self.supportBranchNames = supportBranchNames
        self.supervisingCoachName = supervisingCoachName
        self.showsSupervisor = showsSupervisor
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            if let dossier = athlete.assistantCoach {
                branchRow(dossier)
                ReadinessMeter(value: dossier.promotionReadiness)
                statRow(dossier)
                if showsSupervisor, let supervisingCoachName {
                    supervisorRow(supervisingCoachName)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.secondary.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 12, y: 5)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            Avatar(
                seed: athlete.avatarSeed,
                label: athlete.initials,
                size: 52,
                urlString: athlete.avatarURL
            )
            VStack(alignment: .leading, spacing: 3) {
                Text(verbatim: athlete.fullName)
                    .scaledFont(.subheadline, weight: .semibold)
                    .lineLimit(1)
                Text(verbatim: athlete.fullNameAr)
                    .scaledFont(.caption2)
                    .foregroundStyle(.secondary)
                    .environment(\.layoutDirection, .rightToLeft)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(localizedKey: athlete.currentBelt.color.labelKey)
                        .scaledFont(.caption2)
                        .foregroundStyle(.secondary)
                    Text(verbatim: "·")
                        .scaledFont(.caption2)
                        .foregroundStyle(.secondary)
                    Text(localizedKey: athlete.ageGroup.labelKey)
                        .scaledFont(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
            if let dossier = athlete.assistantCoach {
                DevelopmentLevelBadge(level: dossier.developmentLevel)
            }
        }
    }

    // MARK: - Branch row

    @ViewBuilder
    private func branchRow(_ dossier: AssistantCoachProfile) -> some View {
        let primary = primaryBranchName ?? "—"
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                BranchAssignmentChip(kind: .primary, branchName: primary)
                ForEach(supportBranchNames, id: \.self) { name in
                    BranchAssignmentChip(kind: .support, branchName: name)
                }
            }
            .padding(.horizontal, 1)
        }
    }

    // MARK: - Stats

    private func statRow(_ dossier: AssistantCoachProfile) -> some View {
        HStack(spacing: 0) {
            stat(
                icon: "checklist",
                value: "\(dossier.assistedSessionCount)",
                labelKey: "coaching.stat.assisted_sessions"
            )
            Divider().frame(height: 28)
            stat(
                icon: "star.fill",
                value: dossier.coachEvaluationScore.map { String(format: "%.1f", $0) } ?? "—",
                labelKey: "coaching.stat.evaluation"
            )
            Divider().frame(height: 28)
            stat(
                icon: "calendar",
                value: "\(dossier.monthsCoaching)",
                labelKey: "coaching.stat.months_coaching"
            )
        }
    }

    private func stat(icon: String, value: String, labelKey: LocalizedStringKey) -> some View {
        VStack(spacing: 3) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .scaledFont(.caption2)
                    .foregroundStyle(.tint)
                Text(verbatim: value)
                    .scaledFont(.subheadline, weight: .bold, monospacedDigit: true)
                    .environment(\.layoutDirection, .leftToRight)
            }
            Text(labelKey)
                .scaledFont(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Supervisor

    private func supervisorRow(_ name: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "person.fill.checkmark")
                .scaledFont(.caption2)
                .foregroundStyle(.secondaryAccent)
            Text("coaching.mentored_by")
                .scaledFont(.caption2)
                .foregroundStyle(.secondary)
            Text(verbatim: name)
                .scaledFont(.caption, weight: .semibold)
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
    }
}
