import SwiftUI

/// Technical Director's coaching-development dashboard. Surfaces the full
/// coaching pathway at a federation-operations level: pipeline headcount,
/// coaching quality, branch coverage, the mentorship hierarchy, and every
/// assistant coach in the federation. Routed from the "development" sidebar
/// item — a top-level root view, so no subview chrome.
public struct CoachingDevelopmentView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.horizontalSizeClass) private var sizeClass

    @State private var coaches: [Coach] = []
    @State private var athletes: [Athlete] = []
    @State private var branches: [Branch] = []
    @State private var director: User?
    @State private var loaded = false

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                header
                if !loaded {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                } else {
                    kpiGrid
                    CoachingPipelineView(counts: pipelineCounts)
                    CoachHierarchyView(
                        director: director,
                        coaches: coaches,
                        assistantCoachesByCoach: assistantCoachesByCoach,
                        coachBranchNames: coachBranchNames,
                        branchLookup: branchLookup,
                        isWide: isWide
                    )
                    branchCoverageCard
                    allAssistantCoachesCard
                }
            }
            .padding(.horizontal, isWide ? 20 : 14)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .task { await load() }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("coaching.development.title")
                .scaledFont(.title2, weight: .bold)
            Text("coaching.development.subtitle")
                .scaledFont(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - KPI grid

    private var kpiGrid: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: isWide ? 3 : 2),
            spacing: 12
        ) {
            KPITile(title: "coaching.kpi.coaches", value: "\(coaches.count)", icon: "person.crop.rectangle.stack.fill")
            KPITile(title: "coaching.kpi.assistant_coaches", value: "\(assistantCoaches.count)", icon: "figure.taekwondo")
            KPITile(title: "coaching.kpi.promotion_ready", value: "\(promotionReadyCount)", icon: "arrow.up.circle.fill")
            KPITile(title: "coaching.kpi.avg_readiness", value: percentString(avgReadiness), icon: "gauge.with.dots.needle.67percent")
            KPITile(title: "coaching.kpi.coaching_quality", value: qualityString, icon: "star.fill")
            KPITile(title: "coaching.kpi.branch_coverage", value: "\(coveredBranchCount)/\(branches.count)", icon: "building.2.fill")
        }
    }

    // MARK: - Branch coverage

    private var branchCoverageCard: some View {
        SectionCard("coaching.branch_coverage", icon: "building.2.fill") {
            VStack(spacing: 8) {
                if branches.isEmpty {
                    EmptyStateCard(icon: "building.2", titleKey: "coaching.branch_coverage.empty")
                } else {
                    ForEach(branches) { branch in
                        branchCoverageRow(branch)
                        if branch.id != branches.last?.id {
                            Divider().opacity(0.35)
                        }
                    }
                }
            }
        }
    }

    private func branchCoverageRow(_ branch: Branch) -> some View {
        let count = assistantCoaches.filter { $0.assistantCoach?.primaryBranchID == branch.id }.count
        return HStack(spacing: 10) {
            Image(systemName: branch.isMain ? "building.columns.fill" : "building.2.fill")
                .scaledFont(.footnote)
                .foregroundStyle(.tint)
                .frame(width: 20)
            Text(verbatim: branch.name)
                .scaledFont(.footnote, weight: .medium)
            Spacer(minLength: 8)
            if count == 0 {
                Text("coaching.branch_coverage.none")
                    .scaledFont(.caption2, weight: .semibold)
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.orange.opacity(0.14), in: Capsule())
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "figure.taekwondo")
                        .scaledFont(.caption2, weight: .semibold)
                    Text(verbatim: "\(count)")
                        .scaledFont(.caption, weight: .bold, monospacedDigit: true)
                        .environment(\.layoutDirection, .leftToRight)
                }
                .foregroundStyle(.secondaryAccent)
                .padding(.horizontal, 9)
                .padding(.vertical, 3)
                .background(Color.secondaryAccent.opacity(0.14), in: Capsule())
            }
        }
        .padding(.vertical, 3)
    }

    // MARK: - All assistant coaches

    private var allAssistantCoachesCard: some View {
        SectionCard("coaching.all_assistant_coaches", icon: "figure.taekwondo") {
            if assistantCoaches.isEmpty {
                EmptyStateCard(
                    icon: "figure.taekwondo",
                    titleKey: "coach.assistant_coaches.empty.title",
                    messageKey: "coach.assistant_coaches.empty.message"
                )
            } else {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: isWide ? 2 : 1),
                    spacing: 12
                ) {
                    ForEach(sortedAssistantCoaches) { athlete in
                        NavigationLink {
                            AthleteDetailView(athlete: athlete)
                        } label: {
                            AssistantCoachCard(
                                athlete: athlete,
                                primaryBranchName: athlete.assistantCoach.flatMap { branchLookup[$0.primaryBranchID] },
                                supportBranchNames: (athlete.assistantCoach?.supportBranchIDs ?? []).compactMap { branchLookup[$0] },
                                supervisingCoachName: athlete.assistantCoach?.supervisingCoachID.flatMap { coachNameLookup[$0] },
                                showsSupervisor: true
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Derived data

    private var isWide: Bool { sizeClass == .regular }

    private var assistantCoaches: [Athlete] {
        athletes.filter { $0.assistantCoach != nil }
    }

    private var sortedAssistantCoaches: [Athlete] {
        assistantCoaches.sorted { lhs, rhs in
            let l = lhs.assistantCoach?.promotionReadiness ?? 0
            let r = rhs.assistantCoach?.promotionReadiness ?? 0
            return l > r
        }
    }

    private var assistantCoachesByCoach: [EntityID: [Athlete]] {
        var map: [EntityID: [Athlete]] = [:]
        for athlete in assistantCoaches {
            guard let supervisor = athlete.assistantCoach?.supervisingCoachID else { continue }
            map[supervisor, default: []].append(athlete)
        }
        return map
    }

    private var pipelineCounts: [DevelopmentLevel: Int] {
        var counts: [DevelopmentLevel: Int] = [:]
        counts[.athlete] = athletes.filter { $0.assistantCoach == nil }.count
        counts[.assistantCoach] = assistantCoaches.filter { $0.assistantCoach?.developmentLevel == .assistantCoach }.count
        counts[.juniorCoach] = assistantCoaches.filter { $0.assistantCoach?.developmentLevel == .juniorCoach }.count
        counts[.coach] = coaches.count
        counts[.headCoach] = coaches.filter { $0.coachLevel == .head }.count
        counts[.technicalDirector] = director == nil ? 0 : 1
        return counts
    }

    private var branchLookup: [EntityID: String] {
        Dictionary(uniqueKeysWithValues: branches.map { ($0.id, $0.name) })
    }

    private var coachNameLookup: [EntityID: String] {
        Dictionary(uniqueKeysWithValues: coaches.map { ($0.id, $0.fullName) })
    }

    private var coachBranchNames: [EntityID: String] {
        Dictionary(uniqueKeysWithValues: coaches.compactMap { coach -> (EntityID, String)? in
            guard let name = branchLookup[coach.primaryBranchID] else { return nil }
            return (coach.id, name)
        })
    }

    private var promotionReadyCount: Int {
        assistantCoaches.filter { ($0.assistantCoach?.promotionReadiness ?? 0) >= 0.8 }.count
    }

    private var avgReadiness: Double {
        let values = assistantCoaches.compactMap { $0.assistantCoach?.promotionReadiness }
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }

    private var qualityString: String {
        let values = assistantCoaches.compactMap { $0.assistantCoach?.coachEvaluationScore }
        guard !values.isEmpty else { return "—" }
        return String(format: "%.1f", values.reduce(0, +) / Double(values.count))
    }

    private var coveredBranchCount: Int {
        let covered = Set(assistantCoaches.compactMap { $0.assistantCoach?.primaryBranchID })
        return branches.filter { covered.contains($0.id) }.count
    }

    private func percentString(_ value: Double) -> String {
        "\(Int((value * 100).rounded()))%"
    }

    // MARK: - Load

    private func load() async {
        do {
            async let coachesTask = session.repository.coaches()
            async let athletesTask = session.repository.athletes()
            async let branchesTask = session.repository.branches()
            async let directorsTask = session.repository.users(role: .technicalDirector)

            coaches = try await coachesTask.sorted { $0.fullName < $1.fullName }
            athletes = try await athletesTask
            branches = try await branchesTask
            director = try await directorsTask.first
            loaded = true
        } catch {
            print("CoachingDevelopmentView.load:", error)
            loaded = true
        }
    }
}
