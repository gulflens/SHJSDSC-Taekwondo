import SwiftUI

/// The SSDC coaching structure as a development tree — Technical Director /
/// Head Coach on top, coaches beneath, assistant coaches mentored under each.
/// This is a sports-development pathway, not a corporate org chart: every
/// edge is a mentorship relationship.
public struct CoachHierarchyView: View {
    public let director: User?
    public let coaches: [Coach]
    public let assistantCoachesByCoach: [EntityID: [Athlete]]
    public let coachBranchNames: [EntityID: String]
    public let branchLookup: [EntityID: String]
    public let isWide: Bool

    public init(
        director: User?,
        coaches: [Coach],
        assistantCoachesByCoach: [EntityID: [Athlete]],
        coachBranchNames: [EntityID: String] = [:],
        branchLookup: [EntityID: String] = [:],
        isWide: Bool
    ) {
        self.director = director
        self.coaches = coaches
        self.assistantCoachesByCoach = assistantCoachesByCoach
        self.coachBranchNames = coachBranchNames
        self.branchLookup = branchLookup
        self.isWide = isWide
    }

    public var body: some View {
        SectionCard("coaching.hierarchy", icon: "point.3.connected.trianglepath.dotted") {
            VStack(spacing: 0) {
                directorCard
                Rectangle()
                    .fill(Color.secondaryAccent.opacity(0.35))
                    .frame(width: 2, height: 18)
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 12, alignment: .top),
                                   count: isWide ? 2 : 1),
                    spacing: 12
                ) {
                    ForEach(coaches) { coach in
                        MentorshipRelationshipView(
                            coach: coach,
                            coachBranchName: coachBranchNames[coach.id],
                            assistantCoaches: assistantCoachesByCoach[coach.id] ?? [],
                            branchLookup: branchLookup
                        )
                    }
                }
            }
        }
    }

    // MARK: - Director card

    private var directorCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                if let director {
                    Text(verbatim: initials(director.fullName))
                        .scaledFont(.headline, weight: .bold)
                        .foregroundStyle(.white)
                } else {
                    Image(systemName: "checkmark.seal.fill")
                        .scaledFont(.title3)
                        .foregroundStyle(.white)
                }
            }
            .frame(width: 54, height: 54)
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: director?.fullName ?? NSLocalizedString("coaching.role.technical_director", comment: ""))
                    .scaledFont(.subheadline, weight: .bold)
                    .lineLimit(1)
                Text("coaching.role.technical_director_head")
                    .scaledFont(.caption2, weight: .semibold)
                    .foregroundStyle(.tint)
                Text("coaching.hierarchy.director_scope")
                    .scaledFont(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Image(systemName: "checkmark.seal.fill")
                .scaledFont(.title3)
                .foregroundStyle(.tint)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.accentColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.accentColor.opacity(0.25), lineWidth: 1)
        )
    }

    private func initials(_ name: String) -> String {
        name.split(separator: " ").prefix(2).map { String($0.prefix(1)) }.joined().uppercased()
    }
}
