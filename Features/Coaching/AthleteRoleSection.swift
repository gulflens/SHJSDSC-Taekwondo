import SwiftUI

/// Roles section for the athlete profile. Always shows the athlete's program
/// roles as pastel chips; when the athlete also serves as an assistant coach
/// it expands with the full `CoachingDevelopmentCard` dossier.
///
/// Self-contained: performs a read-once load of the supervising coach name and
/// branch names so the host tab does not need to thread that data through.
public struct AthleteRoleSection: View {
    @Environment(AppSession.self) private var session

    public let athlete: Athlete

    @State private var supervisingCoachName: String?
    @State private var primaryBranchName: String?
    @State private var supportBranchNames: [String] = []

    public init(athlete: Athlete) {
        self.athlete = athlete
    }

    public var body: some View {
        VStack(spacing: 14) {
            rolesCard
            if let dossier = athlete.assistantCoach {
                CoachingDevelopmentCard(
                    dossier: dossier,
                    supervisingCoachName: supervisingCoachName,
                    primaryBranchName: primaryBranchName,
                    supportBranchNames: supportBranchNames
                )
            }
        }
        .task(id: athlete.id) { await load() }
    }

    private var rolesCard: some View {
        SectionCard("athlete.roles", icon: "person.crop.rectangle.stack.fill") {
            VStack(alignment: .leading, spacing: 10) {
                FlowChipRow {
                    ForEach(ProgramRole.ordered(athlete.programRoles)) { role in
                        RoleChipView(role: role, emphasised: role == .assistantCoach)
                    }
                }
                Text("athlete.roles.caption")
                    .scaledFont(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func load() async {
        guard let dossier = athlete.assistantCoach else { return }
        do {
            if let coachID = dossier.supervisingCoachID,
               let coach = try await session.repository.coach(id: coachID) {
                supervisingCoachName = coach.fullName
            }
            let branches = try await session.repository.branches()
            primaryBranchName = branches.first { $0.id == dossier.primaryBranchID }?.name
            supportBranchNames = dossier.supportBranchIDs.compactMap { id in
                branches.first { $0.id == id }?.name
            }
        } catch {
            print("AthleteRoleSection.load:", error)
        }
    }
}
