import SwiftUI

/// Technical Director's dashboard. Stage 1.7 remodel: greeting hero + club
/// composite ring + branch grades grid + watch list + ready-to-grade list +
/// live-match banner. Every block uses the shared design-system primitives.
public struct TDDashboardView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var clubComposite: Double = 0
    @State private var clubGrade: LetterGrade = .c
    @State private var branchSummaries: [BranchSummary] = []
    @State private var watchList: [Athlete] = []
    @State private var readyToGrade: [(Athlete, GradingEligibility)] = []
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
                        subtitleKey: "td.subtitle"
                    )
                }
                if let match = liveMatch {
                    liveMatchBanner(match: match)
                }
                clubCompositeCard
                branchGradesCard
                if isWide {
                    HStack(alignment: .top, spacing: 14) {
                        squadsLink.frame(maxWidth: .infinity)
                        gradingLink.frame(maxWidth: .infinity)
                    }
                } else {
                    squadsLink
                    gradingLink
                }
                watchListCard
                readyToGradeCard
            }
            .padding(.horizontal, isWide ? 20 : 14)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .demoRoleSwitcher()
        .task { await load() }
    }

    private var isWide: Bool { sizeClass == .regular }

    // MARK: - Club composite

    private var clubCompositeCard: some View {
        SectionCard("heading.club_composite", icon: "star.fill") {
            HStack(spacing: 16) {
                GradeBadge(grade: clubGrade, size: 64)
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: String(format: "%.0f", clubComposite))
                        .scaledFont(size: 40, weight: .bold, design: .rounded, monospacedDigit: true)
                        .environment(\.layoutDirection, .leftToRight)
                    Text("heading.club_composite_caption")
                        .scaledFont(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                VStack(alignment: .trailing, spacing: 4) {
                    Text(verbatim: "\(branchSummaries.count)")
                        .scaledFont(.title3, weight: .bold, monospacedDigit: true)
                        .environment(\.layoutDirection, .leftToRight)
                    Text("kpi.branches")
                        .scaledFont(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Live match

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
                    Text("match.live")
                        .scaledFont(.caption, weight: .bold)
                        .foregroundStyle(.red)
                        .textCase(.uppercase)
                    Text(verbatim: match.tournamentName)
                        .scaledFont(.subheadline, weight: .semibold)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                Text(verbatim: "\(match.ourScore) – \(match.opponentScore)")
                    .scaledFont(.title2, weight: .bold, monospacedDigit: true)
                    .environment(\.layoutDirection, .leftToRight)
            }
        }
    }

    // MARK: - Branch grades

    private var branchGradesCard: some View {
        SectionCard("heading.branch_grades", icon: "building.2.fill") {
            if branchSummaries.isEmpty {
                EmptyStateCard(
                    icon: "building.2",
                    titleKey: "td.branches.empty.title",
                    messageKey: nil
                )
            } else {
                let cols = Array(repeating: GridItem(.flexible(), spacing: 10), count: isWide ? 4 : 2)
                LazyVGrid(columns: cols, spacing: 10) {
                    ForEach(branchSummaries.sorted { $0.composite > $1.composite }) { s in
                        NavigationLink(destination: BranchProfileView(branchID: s.branch.id)) {
                            branchGradeTile(s)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func branchGradeTile(_ s: BranchSummary) -> some View {
        HStack(spacing: 10) {
            GradeBadge(grade: s.grade, size: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: s.branch.name)
                    .scaledFont(.caption, weight: .semibold)
                    .lineLimit(1)
                Text(verbatim: String(format: "%.0f", s.composite))
                    .scaledFont(.caption2, monospacedDigit: true)
                    .foregroundStyle(.secondary)
                    .environment(\.layoutDirection, .leftToRight)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Quick links

    private var squadsLink: some View {
        NavigationLink(destination: SquadListView()) {
            linkRow(icon: "person.3.sequence.fill", labelKey: "squad.title")
        }
        .buttonStyle(.plain)
    }

    private var gradingLink: some View {
        NavigationLink(destination: GradingDashboardView()) {
            linkRow(icon: "rosette", labelKey: "grading.dashboard")
        }
        .buttonStyle(.plain)
    }

    private func linkRow(icon: String, labelKey: LocalizedStringKey) -> some View {
        SectionCard {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.accentColor.opacity(0.14))
                    Image(systemName: icon)
                        .scaledFont(.subheadline, weight: .semibold)
                        .foregroundStyle(.tint)
                }
                .frame(width: 38, height: 38)
                Text(labelKey)
                    .scaledFont(.subheadline, weight: .semibold)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .scaledFont(.caption, weight: .semibold)
                    .foregroundStyle(.secondary)
                    .flipsForRightToLeftLayoutDirection(true)
            }
        }
    }

    // MARK: - Watch list

    private var watchListCard: some View {
        SectionCard("heading.watch_list", icon: "eye.fill") {
            if watchList.isEmpty {
                EmptyStateCard(
                    icon: "checkmark.circle",
                    titleKey: "empty.no_athletes_flagged",
                    messageKey: nil
                )
            } else {
                VStack(spacing: 0) {
                    ForEach(watchList) { athlete in
                        NavigationLink(destination: AthleteDetailView(athlete: athlete)) {
                            athleteRow(athlete: athlete, trailing: .status(athlete.status))
                        }
                        .buttonStyle(.plain)
                        if athlete.id != watchList.last?.id {
                            Divider().opacity(0.3)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Ready to grade

    private var readyToGradeCard: some View {
        SectionCard("heading.ready_to_grade", icon: "circle.hexagongrid.fill") {
            if readyToGrade.isEmpty {
                EmptyStateCard(
                    icon: "rosette",
                    titleKey: "empty.nobody_to_grade",
                    messageKey: nil
                )
            } else {
                VStack(spacing: 0) {
                    ForEach(readyToGrade, id: \.0.id) { athlete, elig in
                        NavigationLink(destination: AthleteDetailView(athlete: athlete)) {
                            athleteRow(athlete: athlete, trailing: .beltJump(elig.currentBelt, elig.targetBelt))
                        }
                        .buttonStyle(.plain)
                        if athlete.id != readyToGrade.last?.0.id {
                            Divider().opacity(0.3)
                        }
                    }
                }
            }
        }
    }

    private enum AthleteRowTrailing {
        case status(AthleteStatus)
        case beltJump(Belt, Belt)
    }

    private func athleteRow(athlete: Athlete, trailing: AthleteRowTrailing) -> some View {
        HStack(spacing: 12) {
            Avatar(seed: athlete.avatarSeed, label: athlete.initials, size: 36, urlString: athlete.avatarURL)
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: athlete.fullName)
                    .scaledFont(.subheadline, weight: .semibold)
                    .lineLimit(1)
                Text(localizedKey: athlete.currentBelt.label)
                    .scaledFont(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            switch trailing {
            case .status(let s):
                StatusPill(status: s)
            case .beltJump(let from, let to):
                HStack(spacing: 4) {
                    Text(localizedKey: from.label)
                        .scaledFont(.caption2, weight: .medium)
                    Image(systemName: "arrow.right")
                        .scaledFont(.caption2, weight: .semibold)
                        .flipsForRightToLeftLayoutDirection(true)
                    Text(localizedKey: to.label)
                        .scaledFont(.caption2, weight: .bold)
                        .foregroundStyle(.green)
                }
            }
            Image(systemName: "chevron.right")
                .scaledFont(.caption, weight: .semibold)
                .foregroundStyle(.secondary)
                .flipsForRightToLeftLayoutDirection(true)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }

    // MARK: - Load

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
