import SwiftUI

/// Federation-grade Branches index screen. Replaces the basic BranchListView
/// for HQ/admin roles. Adapts between iPhone (hero card + main branch card +
/// secondary grid) and iPad landscape (top analytics row + hierarchy +
/// analytics cards + upcoming events).
public struct BranchesOverviewView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.horizontalSizeClass) private var sizeClass

    @State private var branches: [Branch] = []
    @State private var athletesByBranch: [EntityID: [Athlete]] = [:]
    @State private var coachesByBranch: [EntityID: [Coach]] = [:]
    @State private var sessionsThisWeekByBranch: [EntityID: Int] = [:]
    @State private var upcomingTournaments: [Tournament] = []

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                heroCard
                if isWide {
                    BranchHierarchyView(
                        branches: branches,
                        athletesByBranch: athletesByBranch,
                        coachesByBranch: coachesByBranch,
                        sessionsByBranch: sessionsThisWeekByBranch
                    )
                }
                mainBranchSection
                secondaryBranchesSection
                if isWide {
                    HStack(alignment: .top, spacing: 14) {
                        BranchAthleteDistributionCard(
                            branches: branches,
                            athletesByBranch: athletesByBranch
                        )
                        .frame(maxWidth: .infinity)
                        BranchSessionsBarCard(
                            branches: branches,
                            sessionsByBranch: sessionsThisWeekByBranch
                        )
                        .frame(maxWidth: .infinity)
                    }
                    BranchPerformanceTableCard(
                        branches: branches,
                        athletesByBranch: athletesByBranch,
                        coachesByBranch: coachesByBranch,
                        sessionsByBranch: sessionsThisWeekByBranch
                    )
                }
                upcomingEventsSection
            }
            .padding(.horizontal, isWide ? 20 : 14)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle(Text("branches.title"))
        .task { await load() }
    }

    // MARK: - Hero

    private var heroCard: some View {
        let gradient = LinearGradient(
            colors: [
                Color(red: 0.12, green: 0.34, blue: 0.78),
                Color(red: 0.22, green: 0.52, blue: 0.92)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        return VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("branches.hero.title")
                    .scaledFont(.title2, weight: .bold)
                    .foregroundStyle(.white)
                Text("branches.hero.subtitle")
                    .scaledFont(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
            }
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: isWide ? 7 : 2),
                spacing: 14
            ) {
                heroStat(value: "\(branches.count)", labelKey: "branches.stat.total")
                heroStat(value: "\(branches.filter(\.isMain).count)", labelKey: "branches.stat.main")
                heroStat(value: "\(branches.filter { !$0.isMain }.count)", labelKey: "branches.stat.secondary")
                heroStat(value: "\(totalAthletes)", labelKey: "branches.stat.athletes")
                heroStat(value: "\(totalCoaches)", labelKey: "branches.stat.coaches")
                heroStat(value: "\(totalSessions)", labelKey: "branches.stat.sessions_week")
                heroStat(value: "\(upcomingTournaments.count)", labelKey: "branches.stat.events_month")
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(gradient, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: Color(red: 0.12, green: 0.34, blue: 0.78).opacity(0.30), radius: 18, y: 10)
    }

    private func heroStat(value: String, labelKey: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(verbatim: value)
                .scaledFont(.title, weight: .bold, monospacedDigit: true)
                .foregroundStyle(.white)
                .environment(\.layoutDirection, .leftToRight)
            Text(labelKey)
                .scaledFont(.caption2)
                .foregroundStyle(.white.opacity(0.85))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Main + Secondary

    @ViewBuilder
    private var mainBranchSection: some View {
        if let main = branches.first(where: { $0.isMain }) {
            BranchCard(
                branch: main,
                athleteCount: athletesByBranch[main.id]?.count ?? 0,
                coachCount: coachesByBranch[main.id]?.count ?? 0,
                sessionsPerWeek: sessionsThisWeekByBranch[main.id] ?? 0,
                isDominant: true,
                isWide: isWide
            )
        }
    }

    @ViewBuilder
    private var secondaryBranchesSection: some View {
        let secondaries = branches.filter { !$0.isMain }
        if !secondaries.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "building.2")
                        .scaledFont(.subheadline, weight: .semibold)
                        .foregroundStyle(.tint)
                    Text("branches.section.secondary")
                        .scaledFont(.subheadline, weight: .semibold)
                    Spacer(minLength: 0)
                    Text(verbatim: "\(secondaries.count)")
                        .scaledFont(.caption, weight: .semibold, monospacedDigit: true)
                        .foregroundStyle(.secondary)
                        .environment(\.layoutDirection, .leftToRight)
                }
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: isWide ? 3 : 1),
                    spacing: 14
                ) {
                    ForEach(secondaries) { branch in
                        BranchCard(
                            branch: branch,
                            athleteCount: athletesByBranch[branch.id]?.count ?? 0,
                            coachCount: coachesByBranch[branch.id]?.count ?? 0,
                            sessionsPerWeek: sessionsThisWeekByBranch[branch.id] ?? 0,
                            isDominant: false,
                            isWide: isWide
                        )
                    }
                }
            }
        }
    }

    // MARK: - Upcoming events

    @ViewBuilder
    private var upcomingEventsSection: some View {
        if !upcomingTournaments.isEmpty {
            SectionCard("branches.upcoming_events", icon: "calendar.badge.clock") {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: isWide ? 3 : 1),
                    spacing: 12
                ) {
                    ForEach(upcomingTournaments.prefix(6)) { tournament in
                        eventCard(tournament)
                    }
                }
            }
        }
    }

    private func eventCard(_ tournament: Tournament) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 0) {
                Text(tournament.startsAt, format: .dateTime.month(.abbreviated))
                    .scaledFont(.caption, weight: .bold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 3)
                    .background(eventTypeColor(tournament))
                Text(tournament.startsAt, format: .dateTime.day())
                    .scaledFont(.title3, weight: .bold, monospacedDigit: true)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                    .environment(\.layoutDirection, .leftToRight)
            }
            .frame(width: 54)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.secondary.opacity(0.18), lineWidth: 1)
            )
            VStack(alignment: .leading, spacing: 3) {
                Text(verbatim: tournament.name)
                    .scaledFont(.subheadline, weight: .semibold)
                    .lineLimit(2)
                Text(verbatim: tournament.location)
                    .scaledFont(.caption2)
                    .foregroundStyle(.secondary)
                CategoryBadge(
                    value: NSLocalizedString(tournament.hostingFederation.labelKey, comment: ""),
                    tone: .neutral,
                    icon: "rosette"
                )
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func eventTypeColor(_ tournament: Tournament) -> Color {
        switch tournament.hostingFederation {
        case .uae: Color.red
        case .gcc: Color(red: 0.95, green: 0.55, blue: 0.20)
        case .wtf: Color(red: 0.12, green: 0.34, blue: 0.78)
        case .clubInternal: Color.gray
        }
    }

    // MARK: - Helpers

    private var isWide: Bool { sizeClass == .regular }

    private var totalAthletes: Int {
        athletesByBranch.values.reduce(0) { $0 + $1.count }
    }

    private var totalCoaches: Int {
        coachesByBranch.values.reduce(0) { $0 + $1.count }
    }

    private var totalSessions: Int {
        sessionsThisWeekByBranch.values.reduce(0, +)
    }

    // MARK: - Data load

    private func load() async {
        do {
            let allBranches = try await session.repository.branches()
            branches = allBranches.sorted { lhs, rhs in
                if lhs.isMain != rhs.isMain { return lhs.isMain }
                return lhs.name < rhs.name
            }
            for branch in allBranches {
                async let athletesTask = session.repository.athletes(branchID: branch.id)
                async let coachesTask = session.repository.coaches(branchID: branch.id)
                let athletes = (try? await athletesTask) ?? []
                let coaches = (try? await coachesTask) ?? []
                athletesByBranch[branch.id] = athletes
                coachesByBranch[branch.id] = coaches

                // Sessions this week
                let cal = Calendar.current
                let now = Date()
                let weekStart = cal.date(byAdding: .day, value: -7, to: now) ?? now
                var count = 0
                var day = weekStart
                while day <= now {
                    let sessions = (try? await session.repository.sessions(branchID: branch.id, on: day)) ?? []
                    count += sessions.count
                    guard let next = cal.date(byAdding: .day, value: 1, to: day) else { break }
                    day = next
                }
                sessionsThisWeekByBranch[branch.id] = count
            }
            let tournaments = try await session.repository.tournaments()
            let now = Date()
            upcomingTournaments = tournaments
                .filter { $0.startsAt > now }
                .sorted { $0.startsAt < $1.startsAt }
        } catch {
            print("BranchesOverviewView.load:", error)
        }
    }
}
