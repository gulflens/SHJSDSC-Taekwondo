import SwiftUI

public struct HQDashboardView: View {
    @Environment(AppSession.self) private var session
    @State private var branchSummaries: [BranchSummary] = []
    @State private var athleteCount: Int = 0
    @State private var medalsYTD: Int = 0
    @State private var clubComposite: Double = 0

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(Date(), style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        KPITile(title: "kpi.active_athletes", value: "\(athleteCount)", icon: "figure.martial.arts")
                        KPITile(title: "kpi.branches", value: "\(branchSummaries.count)", icon: "building.2")
                        KPITile(title: "kpi.medals", value: "\(medalsYTD)", icon: "medal.fill")
                        KPITile(title: "kpi.composite", value: String(format: "%.0f", clubComposite), icon: "star.fill")
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("heading.branches").font(.headline)
                        ForEach(branchSummaries) { s in
                            BranchUtilRow(summary: s)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(Text("tab.overview"))
            .demoRoleSwitcher()
        }
        .task { await load() }
    }

    private func load() async {
        do {
            let branches = try await session.repository.branches()
            var summaries: [BranchSummary] = []
            var totalAthletes = 0
            var totalMedals = 0
            for b in branches {
                let athletes = try await session.repository.athletes(branchID: b.id)
                let scores = try await session.repository.scores(branchID: b.id)
                let comp = ScoreEngine.branchComposite(scores)
                let util = b.capacity > 0 ? Double(athletes.count) / Double(b.capacity) : 0
                summaries.append(BranchSummary(
                    id: b.id, branch: b, composite: comp,
                    grade: LetterGrade.from(score: comp),
                    athleteCount: athletes.count,
                    utilisation: min(1.0, util)
                ))
                totalAthletes += athletes.count
                let matches = try await session.repository.matches(branchID: b.id)
                totalMedals += matches.filter { $0.medal != .none }.count
            }
            branchSummaries = summaries
            athleteCount = totalAthletes
            medalsYTD = totalMedals
            let allScores = try await session.repository.allScores()
            clubComposite = ScoreEngine.branchComposite(allScores)
        } catch {
            print("HQDashboardView.load:", error)
        }
    }
}

private struct BranchUtilRow: View {
    let summary: BranchSummary

    var body: some View {
        HStack(spacing: 12) {
            GradeBadge(grade: summary.grade, size: 36)
            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: summary.branch.name).font(.subheadline.bold())
                ProgressView(value: summary.utilisation)
                Text(String(format: "%.0f%%", summary.utilisation * 100))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
