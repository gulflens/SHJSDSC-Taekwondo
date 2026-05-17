import SwiftUI

/// "Assistant Coaches" section for a coach profile. Lists the assistant
/// coaches this coach mentors — promoted athletes carrying a coaching dossier
/// whose `supervisingCoachID` points at this coach. Each card pushes the full
/// athlete profile.
///
/// Self-contained: loads the assistant-coach roster and branch names directly
/// (a read-once detail load), so the host coach tab needs no extra plumbing.
public struct CoachSupervisionPanel: View {
    @Environment(AppSession.self) private var session

    public let coach: Coach
    public let isWide: Bool

    @State private var assistantCoaches: [Athlete] = []
    @State private var branchLookup: [EntityID: String] = [:]
    @State private var loaded = false

    public init(coach: Coach, isWide: Bool) {
        self.coach = coach
        self.isWide = isWide
    }

    public var body: some View {
        SectionCard(
            "coach.assistant_coaches",
            icon: "figure.taekwondo",
            trailing: { countBadge }
        ) {
            content
        }
        .task(id: coach.id) { await load() }
    }

    @ViewBuilder
    private var countBadge: some View {
        if loaded, !assistantCoaches.isEmpty {
            Text(verbatim: "\(assistantCoaches.count)")
                .scaledFont(.caption, weight: .bold, monospacedDigit: true)
                .foregroundStyle(.secondaryAccent)
                .padding(.horizontal, 9)
                .padding(.vertical, 3)
                .background(Color.secondaryAccent.opacity(0.14), in: Capsule())
                .environment(\.layoutDirection, .leftToRight)
        }
    }

    @ViewBuilder
    private var content: some View {
        if !loaded {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
        } else if assistantCoaches.isEmpty {
            EmptyStateCard(
                icon: "figure.taekwondo",
                titleKey: "coach.assistant_coaches.empty.title",
                messageKey: "coach.assistant_coaches.empty.message"
            )
        } else {
            VStack(alignment: .leading, spacing: 12) {
                Text("coach.assistant_coaches.caption")
                    .scaledFont(.caption2)
                    .foregroundStyle(.secondary)
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: isWide ? 2 : 1),
                    spacing: 12
                ) {
                    ForEach(assistantCoaches) { athlete in
                        NavigationLink {
                            AthleteDetailView(athlete: athlete)
                        } label: {
                            AssistantCoachCard(
                                athlete: athlete,
                                primaryBranchName: primaryBranchName(for: athlete),
                                supportBranchNames: supportBranchNames(for: athlete)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func primaryBranchName(for athlete: Athlete) -> String? {
        guard let id = athlete.assistantCoach?.primaryBranchID else { return nil }
        return branchLookup[id]
    }

    private func supportBranchNames(for athlete: Athlete) -> [String] {
        (athlete.assistantCoach?.supportBranchIDs ?? []).compactMap { branchLookup[$0] }
    }

    private func load() async {
        do {
            let allAthletes = try await session.repository.athletes()
            assistantCoaches = allAthletes
                .filter { $0.assistantCoach?.supervisingCoachID == coach.id }
                .sorted { lhs, rhs in
                    let l = lhs.assistantCoach?.developmentLevel.stageIndex ?? 0
                    let r = rhs.assistantCoach?.developmentLevel.stageIndex ?? 0
                    if l != r { return l > r }
                    return lhs.fullName < rhs.fullName
                }
            let branches = try await session.repository.branches()
            branchLookup = Dictionary(uniqueKeysWithValues: branches.map { ($0.id, $0.name) })
            loaded = true
        } catch {
            print("CoachSupervisionPanel.load:", error)
            loaded = true
        }
    }
}
