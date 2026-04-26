import SwiftUI

public struct TDDashboardView: View {
    @Environment(AppSession.self) private var session
    @State private var clubComposite: Double = 0
    @State private var clubGrade: LetterGrade = .c
    @State private var branchSummaries: [BranchSummary] = []
    @State private var watchList: [Athlete] = []
    @State private var readyToGrade: [(Athlete, GradingEligibility)] = []
    @State private var liveMatch: Match?

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headline
                    if let match = liveMatch {
                        liveMatchBanner(match: match)
                    }
                    branchGrades
                    gradingLink
                    watchSection
                    readySection
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
                    .environment(\.layoutDirection, .leftToRight)
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
                                .environment(\.layoutDirection, .leftToRight)
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

    private func liveMatchBanner(match: Match) -> some View {
        HStack(spacing: 10) {
            Circle().fill(Color.red).frame(width: 8, height: 8)
                .overlay(
                    Circle().stroke(Color.red.opacity(0.4), lineWidth: 4)
                )
            VStack(alignment: .leading, spacing: 2) {
                Text("match.live").font(.subheadline.bold())
                Text(verbatim: "\(match.tournamentName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(verbatim: "\(match.ourScore) — \(match.opponentScore)")
                .font(.headline.monospacedDigit())
                .environment(\.layoutDirection, .leftToRight)
        }
        .padding(12)
        .background(Color.red.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var gradingLink: some View {
        NavigationLink(destination: GradingDashboardView()) {
            HStack {
                Image(systemName: "rosette").foregroundStyle(.tint)
                Text("grading.dashboard").font(.subheadline.bold()).foregroundStyle(.primary)
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.secondary)
            }
            .padding(12)
            .background(Color.secondary.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    private var watchSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("heading.watch_list").font(.headline)
            if watchList.isEmpty {
                Text("empty.no_athletes_flagged").foregroundStyle(.secondary)
            } else {
                ForEach(watchList) { a in
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

    private var readySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("heading.ready_to_grade").font(.headline)
            if readyToGrade.isEmpty {
                Text("empty.nobody_to_grade").foregroundStyle(.secondary)
            } else {
                ForEach(readyToGrade, id: \.0.id) { a, elig in
                    NavigationLink(destination: AthleteDetailView(athlete: a)) {
                        HStack(spacing: 10) {
                            Avatar(seed: a.avatarSeed, label: a.initials, size: 32)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(verbatim: a.fullName).foregroundStyle(.primary)
                                HStack(spacing: 4) {
                                    Text(LocalizedStringKey(elig.currentBelt.label))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    Text(verbatim: "→")
                                    Text(LocalizedStringKey(elig.targetBelt.label))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Image(systemName: "checkmark.seal.fill").foregroundStyle(.green)
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

            let allAthletes = try await session.repository.athletes()

            // Watch list: status == .watch OR latest composite dropped >10 from previous month
            var watch: [Athlete] = []
            for a in allAthletes {
                if a.status == .watch {
                    watch.append(a); continue
                }
                let history = try await session.repository.scoreHistory(athleteID: a.id)
                guard history.count >= 2 else { continue }
                let weights: ScoreWeights = a.status == .competitionTeam
                    ? .competitionTeam
                    : (a.ageGroup == .cubs ? .cubs : .standard)
                let latest = ScoreEngine.composite(history[0], weights: weights)
                let previous = ScoreEngine.composite(history[1], weights: weights)
                if latest - previous < -10 { watch.append(a) }
            }
            watchList = watch

            // Ready to grade via real eligibility engine
            var ready: [(Athlete, GradingEligibility)] = []
            for a in allAthletes {
                let target = GradingEngine.nextBelt(after: a.currentBelt)
                let elig = try await session.repository.eligibility(athleteID: a.id, targetBelt: target)
                if elig.isEligible {
                    ready.append((a, elig))
                }
            }
            readyToGrade = ready

            liveMatch = try await session.repository.activeMatch()
        } catch {
            print("TDDashboardView.load:", error)
        }
    }
}
