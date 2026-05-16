import SwiftUI

/// Federation-level HQ dashboard (Admin + Developer). Greeting hero + KPI
/// strip + branch performance table + recent activity placeholder.
public struct HQDashboardView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var branchSummaries: [BranchSummary] = []
    @State private var athleteCount: Int = 0
    @State private var coachCount: Int = 0
    @State private var medalsYTD: Int = 0
    @State private var clubComposite: Double = 0
    @State private var liveMatch: Match?

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                if let user = session.currentUser {
                    GreetingHero(
                        fullName: user.fullName,
                        fullNameAr: user.fullNameAr,
                        roleLabel: NSLocalizedString("role.\(user.role.rawValue)", comment: ""),
                        subtitleKey: "hq.subtitle"
                    )
                }
                if let match = liveMatch {
                    liveMatchBanner(match: match)
                }
                kpiStrip
                branchTable
            }
            .padding(.horizontal, isWide ? 20 : 14)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .demoRoleSwitcher()
        .toolbar {
            if let role = session.currentUser?.role,
               PermissionMatrix.allowed(role: role, permission: .exportReports),
               !branchSummaries.isEmpty {
                ToolbarItem(placement: .primaryAction) {
                    ExportButton(
                        baseFilename: "branch-performance",
                        csvProvider: {
                            let branches = branchSummaries.map { $0.branch }
                            return CSVReportExporter().exportBranchPerformance(
                                branches: branches,
                                summaries: branchSummaries,
                                format: .csv
                            )
                        }
                    )
                }
            }
        }
        .task { await load() }
    }

    private var isWide: Bool { sizeClass == .regular }

    private var kpiStrip: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: isWide ? 5 : 2),
            spacing: 12
        ) {
            KPITile(title: "kpi.active_athletes", value: "\(athleteCount)", icon: "person.3.fill")
            KPITile(title: "kpi.coaches", value: "\(coachCount)", icon: "graduationcap.fill")
            KPITile(title: "kpi.branches", value: "\(branchSummaries.count)", icon: "building.2.fill")
            KPITile(title: "kpi.medals", value: "\(medalsYTD)", icon: "medal.fill")
            KPITile(title: "kpi.composite", value: String(format: "%.0f", clubComposite), icon: "star.fill")
        }
    }

    private func liveMatchBanner(match: Match) -> some View {
        SectionCard {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.18))
                        .frame(width: 44, height: 44)
                    Circle()
                        .fill(Color.red)
                        .frame(width: 12, height: 12)
                }
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("match.live")
                            .scaledFont(.caption, weight: .bold)
                            .foregroundStyle(.red)
                            .textCase(.uppercase)
                        Spacer(minLength: 0)
                    }
                    Text(verbatim: match.tournamentName)
                        .scaledFont(.subheadline, weight: .semibold)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                Text(verbatim: "\(match.ourScore) – \(match.opponentScore)")
                    .scaledFont(.title2, weight: .bold, monospacedDigit: true)
                    .foregroundStyle(.primary)
                    .environment(\.layoutDirection, .leftToRight)
            }
        }
    }

    private var branchTable: some View {
        SectionCard("heading.branches", icon: "building.2.fill") {
            if branchSummaries.isEmpty {
                EmptyStateCard(
                    icon: "building.2",
                    titleKey: "hq.branches.empty.title",
                    messageKey: nil
                )
            } else {
                let sorted = branchSummaries.sorted { lhs, rhs in
                    if lhs.branch.isMain != rhs.branch.isMain { return lhs.branch.isMain }
                    return lhs.composite > rhs.composite
                }
                VStack(spacing: 0) {
                    ForEach(sorted) { summary in
                        NavigationLink(destination: BranchProfileView(branchID: summary.branch.id)) {
                            branchRow(summary)
                        }
                        .buttonStyle(.plain)
                        if summary.id != sorted.last?.id {
                            Divider().opacity(0.3)
                        }
                    }
                }
            }
        }
    }

    private func branchRow(_ summary: BranchSummary) -> some View {
        HStack(spacing: 12) {
            GradeBadge(grade: summary.grade, size: 40)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(verbatim: summary.branch.name)
                        .scaledFont(.subheadline, weight: .semibold)
                        .lineLimit(1)
                    if summary.branch.isMain {
                        Image(systemName: "crown.fill")
                            .scaledFont(.caption2)
                            .foregroundStyle(Color(red: 0.86, green: 0.65, blue: 0.13))
                    }
                }
                HStack(spacing: 6) {
                    Text(verbatim: "\(summary.athleteCount)")
                        .scaledFont(.caption2, monospacedDigit: true)
                        .environment(\.layoutDirection, .leftToRight)
                    Text("kpi.active_athletes")
                        .scaledFont(.caption2)
                    Text(verbatim: "·")
                        .scaledFont(.caption2)
                    Text(verbatim: String(format: "%.0f%%", summary.utilisation * 100))
                        .scaledFont(.caption2, monospacedDigit: true)
                        .environment(\.layoutDirection, .leftToRight)
                    Text("branch.card.utilization")
                        .scaledFont(.caption2)
                }
                .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: 2) {
                Text(verbatim: String(format: "%.0f", summary.composite))
                    .scaledFont(.subheadline, weight: .bold, monospacedDigit: true)
                    .environment(\.layoutDirection, .leftToRight)
                Text("kpi.composite")
                    .scaledFont(.caption2)
                    .foregroundStyle(.secondary)
            }
            Image(systemName: "chevron.right")
                .scaledFont(.caption, weight: .semibold)
                .foregroundStyle(.secondary)
                .flipsForRightToLeftLayoutDirection(true)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }

    private func load() async {
        do {
            let branches = try await session.repository.branches()
            var summaries: [BranchSummary] = []
            var totalAthletes = 0
            var totalCoaches = 0
            var totalMedals = 0
            for b in branches {
                let athletes = try await session.repository.athletes(branchID: b.id)
                let scores = try await session.repository.scores(branchID: b.id)
                let coaches = try await session.repository.coaches(branchID: b.id)
                let comp = ScoreEngine.branchComposite(scores)
                let util = b.capacity > 0 ? Double(athletes.count) / Double(b.capacity) : 0
                summaries.append(BranchSummary(
                    id: b.id, branch: b, composite: comp,
                    grade: LetterGrade.from(score: comp),
                    athleteCount: athletes.count,
                    utilisation: min(1.0, util)
                ))
                totalAthletes += athletes.count
                totalCoaches += coaches.count
                let matches = try await session.repository.matches(branchID: b.id)
                totalMedals += matches.filter { $0.medal != .none }.count
            }
            branchSummaries = summaries
            athleteCount = totalAthletes
            coachCount = totalCoaches
            medalsYTD = totalMedals
            let allScores = try await session.repository.allScores()
            clubComposite = ScoreEngine.branchComposite(allScores)
            liveMatch = try await session.repository.activeMatch()
        } catch {
            print("HQDashboardView.load:", error)
        }
    }
}
