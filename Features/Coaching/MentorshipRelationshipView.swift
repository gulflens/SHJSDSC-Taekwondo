import SwiftUI

/// One mentorship unit: a supervising coach and the assistant coaches they
/// mentor, connected by a tree spine. This is a *mentorship* relationship —
/// coaching development — not an HR reporting line. Used as the repeating
/// building block of `CoachHierarchyView`.
public struct MentorshipRelationshipView: View {
    public let coach: Coach
    public let coachBranchName: String?
    public let assistantCoaches: [Athlete]
    public let branchLookup: [EntityID: String]

    public init(
        coach: Coach,
        coachBranchName: String? = nil,
        assistantCoaches: [Athlete],
        branchLookup: [EntityID: String] = [:]
    ) {
        self.coach = coach
        self.coachBranchName = coachBranchName
        self.assistantCoaches = assistantCoaches
        self.branchLookup = branchLookup
    }

    private var spineColor: Color { Color.secondaryAccent.opacity(0.35) }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            NavigationLink {
                CoachDetailView(coach: coach)
            } label: {
                coachRow
            }
            .buttonStyle(.plain)

            if assistantCoaches.isEmpty {
                emptyHint
            } else {
                HStack(alignment: .top, spacing: 0) {
                    Rectangle()
                        .fill(spineColor)
                        .frame(width: 2)
                        .padding(.leading, 22)
                    VStack(spacing: 8) {
                        ForEach(assistantCoaches) { athlete in
                            assistantRow(athlete)
                        }
                    }
                    .padding(.leading, 6)
                    .padding(.vertical, 8)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.secondary.opacity(0.12), lineWidth: 1)
        )
    }

    // MARK: - Coach row

    private var coachRow: some View {
        HStack(spacing: 12) {
            Avatar(seed: coach.avatarSeed, label: initials(coach.fullName), size: 46, urlString: coach.avatarURL)
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: coach.fullName)
                    .scaledFont(.subheadline, weight: .semibold)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text("coaching.role.coach")
                        .scaledFont(.caption2, weight: .semibold)
                        .foregroundStyle(.secondaryAccent)
                    if let coachBranchName {
                        Text(verbatim: "·")
                            .scaledFont(.caption2)
                            .foregroundStyle(.secondary)
                        Text(verbatim: coachBranchName)
                            .scaledFont(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            Spacer(minLength: 0)
            mentorCountPill
        }
    }

    private var mentorCountPill: some View {
        HStack(spacing: 4) {
            Image(systemName: "figure.taekwondo")
                .scaledFont(.caption2, weight: .semibold)
            Text(verbatim: "\(assistantCoaches.count)")
                .scaledFont(.caption, weight: .bold, monospacedDigit: true)
                .environment(\.layoutDirection, .leftToRight)
        }
        .foregroundStyle(.secondaryAccent)
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(Color.secondaryAccent.opacity(0.14), in: Capsule())
    }

    // MARK: - Assistant rows

    private func assistantRow(_ athlete: Athlete) -> some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(spineColor)
                .frame(width: 12, height: 2)
            NavigationLink {
                AthleteDetailView(athlete: athlete)
            } label: {
                assistantContent(athlete)
            }
            .buttonStyle(.plain)
        }
    }

    private func assistantContent(_ athlete: Athlete) -> some View {
        HStack(spacing: 10) {
            Avatar(seed: athlete.avatarSeed, label: athlete.initials, size: 34, urlString: athlete.avatarURL)
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: athlete.fullName)
                    .scaledFont(.footnote, weight: .semibold)
                    .lineLimit(1)
                if let dossier = athlete.assistantCoach {
                    Text(localizedKey: dossier.developmentLevel.labelKey)
                        .scaledFont(.caption2)
                        .foregroundStyle(dossier.developmentLevel.tint)
                }
            }
            Spacer(minLength: 0)
            if let dossier = athlete.assistantCoach {
                Text(verbatim: "\(Int((dossier.promotionReadiness * 100).rounded()))%")
                    .scaledFont(.caption, weight: .bold, monospacedDigit: true)
                    .foregroundStyle(.secondary)
                    .environment(\.layoutDirection, .leftToRight)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity)
        .background(Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var emptyHint: some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.turn.down.right")
                .scaledFont(.caption2)
                .foregroundStyle(.secondary)
            Text("coaching.no_assistant_coaches")
                .scaledFont(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.leading, 22)
        .padding(.top, 8)
    }

    private func initials(_ name: String) -> String {
        name.split(separator: " ").prefix(2).map { String($0.prefix(1)) }.joined().uppercased()
    }
}
