import SwiftUI

public struct TDDashboardView: View {
    @Environment(AppSession.self) private var session
    @State private var clubComposite: Double = 0
    @State private var clubGrade: LetterGrade = .c
    @State private var branchSummaries: [BranchSummary] = []
    @State private var watchList: [Athlete] = []
    @State private var readyToGrade: [Athlete] = []
    @State private var scoreByAthlete: [EntityID: PerformanceScore] = [:]

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headline
                    branchGrades
                    section(title: "heading.watch_list", athletes: watchList, empty: "empty.no_athletes_flagged")
                    section(title: "heading.ready_to_grade", athletes: readyToGrade, empty: "empty.nobody_to_grade")
                }
                .padding()
            }
            .navigationTitle(Text("tab.overview"))
            .demoRoleSwitcher()
        }
        .task { await load() }
    }

    private var headline: some View {
        HStack(spacing: 16) {
            GradeBadge(grade: clubGrade, size: 64)
            VStack(alignment: .leading, spacing: 4) {
                Text("heading.club_composite").font(.caption).foregroundStyle(.secondary)
                Text(verbatim: String(format: "%.0f", clubComposite))
                    .font(.system(size: 44, weight: .bold, design: .rounded))
            }
            Spacer()
        }
    }

    private var branchGrades: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("heading.branch_grades").font(.headline)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(branchSummaries) { s in
                    HStack(spacing: 10) {
                        GradeBadge(grade: s.grade, size: 36)
                        VStack(alignment: .leading) {
                            Text(verbatim: s.branch.name).font(.subheadline.bold())
                            Text(verbatim: String(format: "%.0f", s.composite))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(10)
                    .background(Color.secondary.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }

    @ViewBuilder
    private func section(title: LocalizedStringKey, athletes: [Athlete], empty: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            if athletes.isEmpty {
                Text(empty).foregroundStyle(.secondary)
            } else {
                ForEach(athletes) { a in
                    NavigationLink(destination: AthleteDetailView(athlete: a)) {
                        HStack(spacing: 10) {
                            Avatar(seed: a.avatarSeed, label: a.initials, size: 32)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(verbatim: a.fullName).foregroundStyle(.primary)
                                Text(LocalizedStringKey(a.currentBelt.label))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            StatusPill(status: a.status)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func load() async {
        do {
            let branches = try await session.repository.branches()
            var summaries: [BranchSummary] = []
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
            }
            branchSummaries = summaries

            let allScores = try await session.repository.allScores()
            clubComposite = ScoreEngine.branchComposite(allScores)
            clubGrade = LetterGrade.from(score: clubComposite)
            scoreByAthlete = Dictionary(uniqueKeysWithValues: allScores.map { ($0.athleteID, $0) })

            let allAthletes = try await session.repository.athletes()
            watchList = allAthletes.filter { $0.status == .watch }
            readyToGrade = allAthletes.filter { $0.status == .readyToGrade }
        } catch {
            print("TDDashboardView.load:", error)
        }
    }
}
