import SwiftUI

/// Federation-grade branch profile. Header + 7-tab operational console.
/// Adapts iPhone (single-column) / iPad landscape (multi-column).
///
/// The existing rich public-profile content (programs, hours, pricing, social,
/// milestones) is now surfaced inside the More tab as "Public profile" rows
/// that link into the per-section editors. The Overview tab carries the
/// operational summary that matters day-to-day for HQ / branch managers.
public struct BranchProfileView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var store: BranchProfileStore?
    @State private var selectedTab: BranchTab = .overview
    @State private var athletes: [Athlete] = []
    @State private var matches: [Match] = []
    @State private var tournamentLookup: [EntityID: Tournament] = [:]
    @State private var weekSessions: [ClassSession] = []
    @State private var manager: Coach?
    @State private var showingEdit = false

    public let branchID: EntityID

    public init(branchID: EntityID) {
        self.branchID = branchID
    }

    public enum BranchTab: String, CaseIterable, Identifiable, Hashable {
        case overview, athletes, coaches, sessions, competitions, reports, more

        public var id: String { rawValue }
        public var title: String {
            NSLocalizedString("branch.tab.\(rawValue)", comment: "")
        }
        public var systemIcon: String {
            switch self {
            case .overview: "rectangle.grid.2x2.fill"
            case .athletes: "person.3.fill"
            case .coaches: "graduationcap.fill"
            case .sessions: "calendar.badge.checkmark"
            case .competitions: "trophy.fill"
            case .reports: "doc.text.fill"
            case .more: "ellipsis.circle.fill"
            }
        }
    }

    public var body: some View {
        ScrollView {
            if let store, let branch = store.branch {
                VStack(spacing: 14) {
                    BranchProfileHeader(
                        branch: branch,
                        manager: manager,
                        athleteCount: store.metrics.registeredCount,
                        coachCount: store.metrics.totalCoaches,
                        sessionsPerWeek: store.metrics.sessionsPerWeek,
                        attendancePct: store.metrics.avgAttendancePct,
                        mediaHeroURL: store.media?.heroPhotoURL,
                        isWide: isWide,
                        onEditPhoto: { showingEdit = true }
                    )
                    tabBar
                    Group {
                        switch selectedTab {
                        case .overview:
                            BranchOverviewTabContent(
                                branch: branch,
                                store: store,
                                athletes: athletes,
                                matches: matches,
                                tournamentLookup: tournamentLookup,
                                manager: manager,
                                weekSessions: weekSessions,
                                isWide: isWide
                            )
                        case .athletes:
                            BranchAthletesTabContent(athletes: athletes, isWide: isWide)
                        case .coaches:
                            BranchCoachesTabContent(coaches: store.coaches, manager: manager, isWide: isWide)
                        case .sessions:
                            BranchSessionsTabContent(sessions: weekSessions, isWide: isWide)
                        case .competitions:
                            BranchCompetitionsTabContent(
                                matches: matches,
                                tournaments: tournamentLookup,
                                isWide: isWide
                            )
                        case .reports:
                            BranchReportsTabContent(isWide: isWide)
                        case .more:
                            BranchMoreTabContent(branch: branch, store: store, isWide: isWide)
                        }
                    }
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.18), value: selectedTab)
                }
                .padding(.horizontal, isWide ? 20 : 14)
                .padding(.top, 12)
                .padding(.bottom, 24)
            } else {
                ProgressView().padding(.top, 80)
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle(Text(verbatim: store?.branch?.name ?? ""))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            if let role = session.currentUser?.role,
               PermissionMatrix.allowed(role: role, permission: .editBranchProfile) {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingEdit = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                    .accessibilityLabel(Text("manager.dashboard"))
                    .bareToolbarButton()
                }
            }
        }
        .navigationDestination(isPresented: $showingEdit) {
            BranchEditView(branchID: branchID)
        }
        .task {
            if store == nil { store = BranchProfileStore(repository: session.repository) }
            await store?.load(branchID: branchID)
            await loadAuxiliary()
        }
    }

    private var isWide: Bool { sizeClass == .regular }

    private var tabBar: some View {
        SegmentedTabBar(
            selection: $selectedTab,
            tabs: BranchTab.allCases,
            title: { $0.title },
            icon: { $0.systemIcon }
        )
        .padding(.vertical, 4)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.03), radius: 8, y: 3)
    }

    private func loadAuxiliary() async {
        do {
            athletes = try await session.repository.athletes(branchID: branchID)
            // Pull matches for branch athletes (single-pass loop is fine for demo scale)
            var allMatches: [Match] = []
            var lookup: [EntityID: Tournament] = [:]
            for a in athletes {
                if let athleteMatches = try? await session.repository.matches(athleteID: a.id) {
                    allMatches.append(contentsOf: athleteMatches)
                    for m in athleteMatches {
                        if let tid = m.tournamentID,
                           lookup[tid] == nil,
                           let t = try? await session.repository.tournament(id: tid) {
                            lookup[tid] = t
                        }
                    }
                }
            }
            matches = allMatches
            tournamentLookup = lookup

            // Sessions for this week
            let cal = Calendar.current
            let now = Date()
            let weekStart = cal.date(byAdding: .day, value: -6, to: now) ?? now
            var collected: [ClassSession] = []
            var day = weekStart
            while day <= now.addingTimeInterval(7 * 86400) {
                let s = (try? await session.repository.sessions(branchID: branchID, on: day)) ?? []
                collected.append(contentsOf: s)
                guard let next = cal.date(byAdding: .day, value: 1, to: day) else { break }
                day = next
            }
            weekSessions = collected

            if let store, let managerID = store.branch?.managerID {
                manager = try await session.repository.coach(id: managerID)
            }
        } catch {
            print("BranchProfileView.loadAuxiliary:", error)
        }
    }
}

// MARK: - Overview tab content

private struct BranchOverviewTabContent: View {
    let branch: Branch
    let store: BranchProfileStore
    let athletes: [Athlete]
    let matches: [Match]
    let tournamentLookup: [EntityID: Tournament]
    let manager: Coach?
    let weekSessions: [ClassSession]
    let isWide: Bool

    var body: some View {
        VStack(spacing: 14) {
            kpiStrip
            if isWide {
                HStack(alignment: .top, spacing: 14) {
                    summaryCard.frame(maxWidth: .infinity)
                    performanceCard.frame(maxWidth: .infinity)
                    upcomingSessionsCard.frame(maxWidth: .infinity)
                }
                HStack(alignment: .top, spacing: 14) {
                    athleteGrowthCard.frame(maxWidth: .infinity)
                    coachOverviewCard.frame(maxWidth: .infinity)
                }
            } else {
                summaryCard
                performanceCard
                upcomingSessionsCard
                athleteGrowthCard
                coachOverviewCard
            }
            recentAchievementsCard
        }
    }

    private var kpiStrip: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: isWide ? 4 : 2),
            spacing: 12
        ) {
            KPITile(title: "branch.kpi.attendance", value: String(format: "%.0f%%", store.metrics.avgAttendancePct * 100), icon: "checkmark.circle.fill")
            KPITile(title: "branch.kpi.utilisation", value: String(format: "%.0f%%", store.metrics.utilisationPct * 100), icon: "person.crop.rectangle.stack.fill")
            KPITile(title: "branch.kpi.new_signups", value: "\(store.metrics.newSignups30d)", icon: "person.crop.circle.badge.plus")
            KPITile(title: "branch.kpi.medals", value: "\(medalsCount)", icon: "medal.fill")
        }
    }

    private var summaryCard: some View {
        SectionCard("branch.card.summary", icon: "info.circle.fill") {
            VStack(spacing: 6) {
                AthleteSummaryRow(
                    icon: "building.2.fill",
                    labelKey: "branch.field.code",
                    value: branch.code
                )
                AthleteSummaryRow(
                    icon: "mappin.and.ellipse",
                    labelKey: "branch.field.location",
                    value: branch.area.isEmpty ? branch.emirate : "\(branch.area), \(branch.emirate)"
                )
                AthleteSummaryRow(
                    icon: "person.fill",
                    labelKey: "branch.field.manager",
                    value: manager?.fullName ?? "—"
                )
                AthleteSummaryRow(
                    icon: "phone.fill",
                    labelKey: "branch.field.phone",
                    value: branch.phone.isEmpty ? "—" : branch.phone
                )
                AthleteSummaryRow(
                    icon: "envelope.fill",
                    labelKey: "branch.field.email",
                    value: branch.email.isEmpty ? "—" : branch.email
                )
                AthleteSummaryRow(
                    icon: "calendar",
                    labelKey: "branch.field.founded",
                    value: dateString(branch.foundedAt)
                )
                AthleteSummaryRow(
                    icon: "person.3.sequence.fill",
                    labelKey: "branch.field.capacity",
                    value: "\(branch.capacity)"
                )
            }
        }
    }

    private var performanceCard: some View {
        SectionCard("branch.card.performance", icon: "chart.line.uptrend.xyaxis") {
            VStack(spacing: 12) {
                RatingBarRow(
                    icon: "checkmark.circle.fill",
                    labelKey: "branch.metric.attendance",
                    value: store.metrics.avgAttendancePct * 100
                )
                RatingBarRow(
                    icon: "person.crop.rectangle.stack.fill",
                    labelKey: "branch.metric.utilisation",
                    value: store.metrics.utilisationPct * 100
                )
                RatingBarRow(
                    icon: "arrow.up.right.circle.fill",
                    labelKey: "branch.metric.retention",
                    value: store.metrics.retentionPct90d * 100
                )
                RatingBarRow(
                    icon: "shield.fill",
                    labelKey: "branch.metric.safeguarding",
                    value: store.metrics.coachesWithCurrentSafeguardingPct * 100
                )
            }
        }
    }

    private var upcomingSessionsCard: some View {
        SectionCard("branch.card.upcoming_sessions", icon: "calendar.badge.clock") {
            let upcoming = weekSessions
                .filter { $0.startsAt > Date() }
                .sorted { $0.startsAt < $1.startsAt }
                .prefix(5)
            if upcoming.isEmpty {
                EmptyStateCard(
                    icon: "calendar",
                    titleKey: "branch.sessions.empty.title",
                    messageKey: "branch.sessions.empty.message"
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(upcoming)) { session in
                        sessionRow(session)
                        if session.id != upcoming.last?.id {
                            Divider().opacity(0.4)
                        }
                    }
                }
            }
        }
    }

    private func sessionRow(_ session: ClassSession) -> some View {
        HStack(spacing: 12) {
            VStack(spacing: 0) {
                Text(session.startsAt, format: .dateTime.month(.abbreviated))
                    .scaledFont(.caption2, weight: .bold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 2)
                    .background(Color.accentColor)
                Text(session.startsAt, format: .dateTime.day())
                    .scaledFont(.subheadline, weight: .bold, monospacedDigit: true)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 3)
                    .environment(\.layoutDirection, .leftToRight)
            }
            .frame(width: 46)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.secondary.opacity(0.18), lineWidth: 1)
            )
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: session.title)
                    .scaledFont(.footnote, weight: .semibold)
                    .lineLimit(1)
                Text(verbatim: session.startsAt.formatted(.dateTime.hour().minute()))
                    .scaledFont(.caption2)
                    .foregroundStyle(.secondary)
                    .environment(\.layoutDirection, .leftToRight)
            }
            Spacer(minLength: 0)
            Text(verbatim: "\(session.enrolledAthleteIDs.count)/\(session.capacity)")
                .scaledFont(.caption, monospacedDigit: true)
                .foregroundStyle(.secondary)
                .environment(\.layoutDirection, .leftToRight)
        }
    }

    private var athleteGrowthCard: some View {
        SectionCard("branch.card.athlete_growth", icon: "chart.bar.fill") {
            VStack(spacing: 8) {
                growthRow(icon: "person.crop.circle.badge.plus", labelKey: "branch.metric.new_30d", value: store.metrics.newSignups30d, accent: .green)
                growthRow(icon: "person.crop.circle.badge.minus", labelKey: "branch.metric.churn_30d", value: store.metrics.churn30d, accent: .red)
                Divider().padding(.vertical, 2)
                AthleteSummaryRow(
                    icon: "flame.fill",
                    labelKey: "branch.metric.competition_team",
                    value: "\(store.metrics.competitionTeamCount)"
                )
                AthleteSummaryRow(
                    icon: "checkmark.seal.fill",
                    labelKey: "branch.metric.ready_to_grade",
                    value: "\(store.metrics.readyToGradeCount)"
                )
                AthleteSummaryRow(
                    icon: "eye.fill",
                    labelKey: "branch.metric.watch",
                    value: "\(store.metrics.watchListCount)"
                )
                AthleteSummaryRow(
                    icon: "moon.zzz.fill",
                    labelKey: "branch.metric.rest",
                    value: "\(store.metrics.restCount)"
                )
            }
        }
    }

    private func growthRow(icon: String, labelKey: LocalizedStringKey, value: Int, accent: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .scaledFont(.footnote)
                .foregroundStyle(accent)
                .frame(width: 18)
            Text(labelKey)
                .scaledFont(.footnote)
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
            Text(verbatim: "\(value)")
                .scaledFont(.footnote, weight: .bold, monospacedDigit: true)
                .foregroundStyle(accent)
                .environment(\.layoutDirection, .leftToRight)
        }
        .padding(.vertical, 2)
    }

    private var coachOverviewCard: some View {
        SectionCard("branch.card.coach_overview", icon: "graduationcap.fill") {
            VStack(spacing: 8) {
                AthleteSummaryRow(
                    icon: "person.fill",
                    labelKey: "branch.coach.total",
                    value: "\(store.metrics.totalCoaches)"
                )
                AthleteSummaryRow(
                    icon: "shield.fill",
                    labelKey: "branch.coach.safeguarding_current",
                    value: String(format: "%.0f%%", store.metrics.coachesWithCurrentSafeguardingPct * 100),
                    valueColor: store.metrics.coachesWithCurrentSafeguardingPct >= 0.8 ? .green : .orange
                )
                if let manager {
                    Divider().padding(.vertical, 2)
                    HStack(spacing: 10) {
                        Avatar(seed: manager.avatarSeed, label: manager.initials, size: 32, urlString: manager.avatarURL)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(verbatim: manager.fullName)
                                .scaledFont(.footnote, weight: .semibold)
                            Text("branch.coach.manager")
                                .scaledFont(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 0)
                    }
                }
            }
        }
    }

    private var recentAchievementsCard: some View {
        let medals = matches.filter { $0.medal != .none }
            .sorted { $0.date > $1.date }
            .prefix(6)
        return SectionCard("branch.card.recent_achievements", icon: "medal.fill") {
            if medals.isEmpty {
                EmptyStateCard(
                    icon: "medal",
                    titleKey: "branch.achievements.empty.title",
                    messageKey: "branch.achievements.empty.message"
                )
            } else {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: isWide ? 6 : 3),
                    spacing: 12
                ) {
                    ForEach(Array(medals)) { match in
                        AchievementMedalCard(
                            medal: match.medal,
                            tournamentName: match.tournamentName,
                            date: match.date
                        )
                    }
                }
            }
        }
    }

    private var medalsCount: Int { matches.filter { $0.medal != .none }.count }

    private func dateString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }
}

// MARK: - Athletes tab

private struct BranchAthletesTabContent: View {
    let athletes: [Athlete]
    let isWide: Bool

    var body: some View {
        SectionCard("branch.athletes.roster", icon: "person.3.fill") {
            if athletes.isEmpty {
                EmptyStateCard(
                    icon: "person.crop.circle.badge.questionmark",
                    titleKey: "branch.athletes.empty.title",
                    messageKey: "branch.athletes.empty.message"
                )
            } else {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: isWide ? 3 : 1),
                    spacing: 12
                ) {
                    ForEach(athletes) { athlete in
                        NavigationLink {
                            AthleteDetailView(athlete: athlete)
                        } label: {
                            athleteRow(athlete)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func athleteRow(_ athlete: Athlete) -> some View {
        HStack(spacing: 12) {
            Avatar(seed: athlete.avatarSeed, label: athlete.initials, size: 40, urlString: athlete.avatarURL)
            VStack(alignment: .leading, spacing: 3) {
                Text(verbatim: athlete.fullName)
                    .scaledFont(.subheadline, weight: .semibold)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(localizedKey: athlete.ageGroup.labelKey)
                        .scaledFont(.caption2)
                    Text(verbatim: "·")
                    Text(verbatim: String(format: "%.0fkg", athlete.weightKg))
                        .scaledFont(.caption2, monospacedDigit: true)
                        .environment(\.layoutDirection, .leftToRight)
                }
                .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            StatusPill(status: athlete.status)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Coaches tab

private struct BranchCoachesTabContent: View {
    let coaches: [Coach]
    let manager: Coach?
    let isWide: Bool

    var body: some View {
        SectionCard("branch.coaches.roster", icon: "graduationcap.fill") {
            if coaches.isEmpty {
                EmptyStateCard(
                    icon: "graduationcap",
                    titleKey: "branch.coaches.empty.title",
                    messageKey: "branch.coaches.empty.message"
                )
            } else {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: isWide ? 3 : 1),
                    spacing: 12
                ) {
                    ForEach(coaches) { coach in
                        NavigationLink {
                            CoachDetailView(coach: coach)
                        } label: {
                            coachRow(coach, isManager: coach.id == manager?.id)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func coachRow(_ coach: Coach, isManager: Bool) -> some View {
        HStack(spacing: 12) {
            Avatar(seed: coach.avatarSeed, label: coach.initials, size: 40, urlString: coach.avatarURL)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(verbatim: coach.fullName)
                        .scaledFont(.subheadline, weight: .semibold)
                        .lineLimit(1)
                    if isManager {
                        Image(systemName: "crown.fill")
                            .scaledFont(.caption2)
                            .foregroundStyle(Color(red: 0.86, green: 0.65, blue: 0.13))
                    }
                }
                HStack(spacing: 6) {
                    Text(verbatim: "\(coach.danRank) Dan")
                        .scaledFont(.caption2, monospacedDigit: true)
                        .environment(\.layoutDirection, .leftToRight)
                    if let spec = coach.specialisation {
                        Text(verbatim: "·")
                        Text(localizedKey: spec.labelKey)
                            .scaledFont(.caption2)
                    }
                }
                .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Sessions tab

private struct BranchSessionsTabContent: View {
    let sessions: [ClassSession]
    let isWide: Bool

    var body: some View {
        VStack(spacing: 14) {
            kpiStrip
            sessionsCard
        }
    }

    private var kpiStrip: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: isWide ? 4 : 2),
            spacing: 12
        ) {
            KPITile(title: "branch.sessions.this_week", value: "\(sessions.count)", icon: "calendar.badge.checkmark")
            KPITile(title: "branch.sessions.upcoming", value: "\(upcomingCount)", icon: "calendar.badge.clock")
            KPITile(title: "branch.sessions.capacity_total", value: "\(totalCapacity)", icon: "person.3.fill")
            KPITile(title: "branch.sessions.enrolled_total", value: "\(totalEnrolled)", icon: "person.crop.circle.fill")
        }
    }

    private var sessionsCard: some View {
        SectionCard("branch.sessions.weekly_schedule", icon: "calendar") {
            if sessions.isEmpty {
                EmptyStateCard(
                    icon: "calendar",
                    titleKey: "branch.sessions.empty.title",
                    messageKey: "branch.sessions.empty.message"
                )
            } else {
                let sorted = sessions.sorted { $0.startsAt < $1.startsAt }
                VStack(spacing: 8) {
                    ForEach(sorted) { session in
                        sessionCard(session)
                        if session.id != sorted.last?.id {
                            Divider().opacity(0.4)
                        }
                    }
                }
            }
        }
    }

    private func sessionCard(_ session: ClassSession) -> some View {
        HStack(spacing: 12) {
            VStack(spacing: 0) {
                Text(session.startsAt, format: .dateTime.weekday(.abbreviated))
                    .scaledFont(.caption2, weight: .bold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 3)
                    .background(disciplineColor(session.discipline))
                Text(session.startsAt, format: .dateTime.day())
                    .scaledFont(.subheadline, weight: .bold, monospacedDigit: true)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 3)
                    .environment(\.layoutDirection, .leftToRight)
            }
            .frame(width: 54)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.secondary.opacity(0.18), lineWidth: 1)
            )
            VStack(alignment: .leading, spacing: 3) {
                Text(verbatim: session.title)
                    .scaledFont(.subheadline, weight: .semibold)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(session.startsAt, format: .dateTime.hour().minute())
                        .environment(\.layoutDirection, .leftToRight)
                    Text(verbatim: "·")
                    Text(localizedKey: session.discipline.labelKey)
                    Text(verbatim: "·")
                    Text(localizedKey: session.ageGroup.labelKey)
                }
                .scaledFont(.caption2)
                .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: 2) {
                Text(verbatim: "\(session.enrolledAthleteIDs.count)/\(session.capacity)")
                    .scaledFont(.caption, weight: .semibold, monospacedDigit: true)
                    .environment(\.layoutDirection, .leftToRight)
                Text("branch.sessions.enrolled")
                    .scaledFont(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }

    private func disciplineColor(_ d: ClassDiscipline) -> Color {
        switch d {
        case .poomsae: .purple
        case .kyorugi: .red
        case .fundamentals: .blue
        case .competition: .orange
        case .fitness: .green
        }
    }

    private var upcomingCount: Int {
        let now = Date()
        return sessions.filter { $0.startsAt > now }.count
    }

    private var totalCapacity: Int {
        sessions.reduce(0) { $0 + $1.capacity }
    }

    private var totalEnrolled: Int {
        sessions.reduce(0) { $0 + $1.enrolledAthleteIDs.count }
    }
}

// MARK: - Competitions tab

private struct BranchCompetitionsTabContent: View {
    let matches: [Match]
    let tournaments: [EntityID: Tournament]
    let isWide: Bool

    var body: some View {
        VStack(spacing: 14) {
            kpiStrip
            recentMatchesCard
        }
    }

    private var kpiStrip: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: isWide ? 5 : 2),
            spacing: 12
        ) {
            KPITile(title: "branch.competition.matches", value: "\(matches.count)", icon: "figure.boxing")
            KPITile(title: "branch.competition.gold", value: "\(medalCount(.gold))", icon: "medal.fill")
            KPITile(title: "branch.competition.silver", value: "\(medalCount(.silver))", icon: "medal.fill")
            KPITile(title: "branch.competition.bronze", value: "\(medalCount(.bronze))", icon: "medal.fill")
            KPITile(title: "branch.competition.win_rate", value: String(format: "%.0f%%", winRate * 100), icon: "chart.bar.fill")
        }
    }

    private var recentMatchesCard: some View {
        SectionCard("branch.competition.recent_matches", icon: "list.bullet.rectangle") {
            if matches.isEmpty {
                EmptyStateCard(
                    icon: "trophy",
                    titleKey: "branch.competition.empty.title",
                    messageKey: "branch.competition.empty.message"
                )
            } else {
                let recent = matches.sorted { $0.date > $1.date }.prefix(12)
                VStack(spacing: 8) {
                    ForEach(Array(recent)) { match in
                        matchRow(match)
                        if match.id != recent.last?.id {
                            Divider().opacity(0.4)
                        }
                    }
                }
            }
        }
    }

    private func matchRow(_ match: Match) -> some View {
        HStack(spacing: 12) {
            outcomeIndicator(match)
            VStack(alignment: .leading, spacing: 3) {
                Text(verbatim: match.tournamentName)
                    .scaledFont(.subheadline, weight: .semibold)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(match.date, format: .dateTime.day().month(.abbreviated).year())
                        .environment(\.layoutDirection, .leftToRight)
                    Text(verbatim: "·")
                    Text(verbatim: String(format: "%.0fkg", match.weightClassKg))
                        .environment(\.layoutDirection, .leftToRight)
                }
                .scaledFont(.caption2)
                .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            if match.medal != .none {
                Image(systemName: "medal.fill")
                    .scaledFont(.subheadline)
                    .foregroundStyle(medalColor(match.medal))
            }
            Text(verbatim: "\(match.ourScore)–\(match.opponentScore)")
                .scaledFont(.caption, weight: .semibold, monospacedDigit: true)
                .foregroundStyle(.secondary)
                .environment(\.layoutDirection, .leftToRight)
        }
        .padding(.vertical, 6)
    }

    private func outcomeIndicator(_ match: Match) -> some View {
        let color: Color = switch match.effectiveOutcome {
        case .win: .green
        case .loss: .red
        case .draw: .gray
        }
        return RoundedRectangle(cornerRadius: 2)
            .fill(color)
            .frame(width: 3, height: 32)
    }

    private func medalColor(_ medal: MedalType) -> Color {
        switch medal {
        case .gold: Color(red: 0.86, green: 0.65, blue: 0.13)
        case .silver: Color(white: 0.55)
        case .bronze: Color(red: 0.72, green: 0.45, blue: 0.20)
        case .none: .secondary
        }
    }

    private func medalCount(_ medal: MedalType) -> Int {
        matches.filter { $0.medal == medal }.count
    }

    private var winRate: Double {
        guard !matches.isEmpty else { return 0 }
        let wins = matches.filter { $0.effectiveOutcome == .win }.count
        return Double(wins) / Double(matches.count)
    }
}

// MARK: - Reports tab

private struct BranchReportsTabContent: View {
    let isWide: Bool

    var body: some View {
        VStack(spacing: 14) {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: isWide ? 4 : 2),
                spacing: 12
            ) {
                KPITile(title: "branch.reports.monthly", value: "0", icon: "doc.text.fill")
                KPITile(title: "branch.reports.federation", value: "0", icon: "rosette")
                KPITile(title: "branch.reports.audit", value: "0", icon: "shield.fill")
                KPITile(title: "branch.reports.compliance", value: "0", icon: "checkmark.shield.fill")
            }
            SectionCard("branch.reports.available", icon: "doc.text.fill") {
                VStack(spacing: 6) {
                    reportRow("branch.reports.type.monthly_summary", icon: "calendar.badge.clock")
                    reportRow("branch.reports.type.utilisation", icon: "chart.pie.fill")
                    reportRow("branch.reports.type.athlete_progression", icon: "chart.line.uptrend.xyaxis")
                    reportRow("branch.reports.type.coach_evaluation", icon: "person.fill.checkmark")
                    reportRow("branch.reports.type.federation_filing", icon: "rosette")
                    reportRow("branch.reports.type.financial_summary", icon: "dollarsign.circle.fill")
                }
            }
            SectionCard("branch.reports.history", icon: "list.bullet.rectangle") {
                EmptyStateCard(
                    icon: "doc.text.magnifyingglass",
                    titleKey: "branch.reports.empty.title",
                    messageKey: "branch.reports.empty.message"
                )
            }
        }
    }

    private func reportRow(_ key: LocalizedStringKey, icon: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.accentColor.opacity(0.12))
                Image(systemName: icon)
                    .scaledFont(.subheadline)
                    .foregroundStyle(.tint)
            }
            .frame(width: 38, height: 38)
            Text(key)
                .scaledFont(.subheadline, weight: .semibold)
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .scaledFont(.caption, weight: .semibold)
                .foregroundStyle(.secondary)
                .flipsForRightToLeftLayoutDirection(true)
        }
        .padding(.vertical, 6)
    }
}

// MARK: - More tab

private struct BranchMoreTabContent: View {
    let branch: Branch
    let store: BranchProfileStore
    let isWide: Bool

    var body: some View {
        VStack(spacing: 14) {
            addressCard
            if !store.programs.isEmpty { programsCard }
            if let hours = store.hours { hoursCard(hours) }
            if let pricing = store.pricing { pricingCard(pricing) }
            if !store.milestones.isEmpty { milestonesCard }
            if let social = store.socialLinks { socialCard(social) }
        }
    }

    private var addressCard: some View {
        SectionCard("branch.more.address", icon: "mappin.and.ellipse") {
            VStack(spacing: 6) {
                AthleteSummaryRow(
                    icon: "location.fill",
                    labelKey: "branch.field.street",
                    value: branch.streetAddress.isEmpty ? "—" : branch.streetAddress
                )
                AthleteSummaryRow(
                    icon: "globe",
                    labelKey: "branch.field.emirate",
                    value: branch.emirate
                )
                if let poBox = branch.poBox, !poBox.isEmpty {
                    AthleteSummaryRow(
                        icon: "envelope.fill",
                        labelKey: "branch.field.po_box",
                        value: poBox
                    )
                }
                AthleteSummaryRow(
                    icon: "phone.fill",
                    labelKey: "branch.field.phone",
                    value: branch.phone.isEmpty ? "—" : branch.phone
                )
                AthleteSummaryRow(
                    icon: "envelope.fill",
                    labelKey: "branch.field.email",
                    value: branch.email.isEmpty ? "—" : branch.email
                )
            }
        }
    }

    private var programsCard: some View {
        SectionCard("branch.more.programs", icon: "list.bullet.rectangle") {
            VStack(spacing: 6) {
                ForEach(store.programs) { program in
                    programRow(program)
                }
            }
        }
    }

    private func programRow(_ program: BranchProgram) -> some View {
        // The custom name is user-entered free text — render verbatim. Only
        // fall back to the localised default when no custom or key name is set.
        let displayName: String = {
            if let custom = program.customName, !custom.isEmpty { return custom }
            if let key = program.nameKey, !key.isEmpty {
                return NSLocalizedString(key, comment: "")
            }
            return NSLocalizedString("branch.program.unnamed", comment: "")
        }()
        return HStack(spacing: 10) {
            Image(systemName: "circle.fill")
                .scaledFont(.caption2)
                .foregroundStyle(.tint)
                .frame(width: 18)
            Text(verbatim: displayName)
                .scaledFont(.footnote)
                .foregroundStyle(.primary)
            Spacer(minLength: 8)
            Text(localizedKey: program.ageGroup.labelKey)
                .scaledFont(.footnote, weight: .semibold)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.vertical, 2)
    }

    private func hoursCard(_ hours: BranchHours) -> some View {
        SectionCard("branch.more.hours", icon: "clock.fill") {
            VStack(spacing: 6) {
                ForEach(hours.regular, id: \.day) { window in
                    HStack {
                        Text(localizedKey: window.day.labelKey)
                            .scaledFont(.footnote)
                        Spacer(minLength: 0)
                        Text(verbatim: window.isOpen
                             ? "\(window.opensAt ?? "—") – \(window.closesAt ?? "—")"
                             : NSLocalizedString("branch.hours.closed", comment: ""))
                            .scaledFont(.footnote, monospacedDigit: true)
                            .foregroundStyle(.secondary)
                            .environment(\.layoutDirection, .leftToRight)
                    }
                }
            }
        }
    }

    private func pricingCard(_ pricing: BranchPricing) -> some View {
        SectionCard("branch.more.pricing", icon: "dollarsign.circle.fill") {
            VStack(spacing: 6) {
                AthleteSummaryRow(
                    icon: "ticket.fill",
                    labelKey: "branch.pricing.trial",
                    value: String(format: "%.0f AED", pricing.trialClassFeeAED)
                )
                AthleteSummaryRow(
                    icon: "calendar",
                    labelKey: "branch.pricing.monthly",
                    value: String(format: "%.0f AED", pricing.baseMonthlyFeeAED)
                )
                AthleteSummaryRow(
                    icon: "person.crop.circle.badge.plus",
                    labelKey: "branch.pricing.registration",
                    value: String(format: "%.0f AED", pricing.registrationFeeAED)
                )
                AthleteSummaryRow(
                    icon: "bag.fill",
                    labelKey: "branch.pricing.equipment",
                    value: String(format: "%.0f AED", pricing.equipmentPackageFeeAED)
                )
            }
        }
    }

    private var milestonesCard: some View {
        SectionCard("branch.more.milestones", icon: "flag.checkered") {
            VStack(spacing: 8) {
                ForEach(store.milestones) { milestone in
                    HStack(spacing: 10) {
                        Image(systemName: "star.fill")
                            .scaledFont(.caption)
                            .foregroundStyle(.tint)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(verbatim: milestone.titleEn)
                                .scaledFont(.footnote, weight: .semibold)
                            Text(milestone.occurredAt, format: .dateTime.day().month(.abbreviated).year())
                                .scaledFont(.caption2)
                                .foregroundStyle(.secondary)
                                .environment(\.layoutDirection, .leftToRight)
                        }
                        Spacer(minLength: 0)
                    }
                }
            }
        }
    }

    private func socialCard(_ links: BranchSocialLinks) -> some View {
        SectionCard("branch.more.social", icon: "network") {
            VStack(spacing: 6) {
                if let ig = links.instagramHandle, !ig.isEmpty {
                    AthleteSummaryRow(icon: "camera.fill", labelKey: "branch.social.instagram", value: "@\(ig)")
                }
                if let tt = links.tiktokHandle, !tt.isEmpty {
                    AthleteSummaryRow(icon: "music.note", labelKey: "branch.social.tiktok", value: "@\(tt)")
                }
                if let yt = links.youtubeChannelURL, !yt.isEmpty {
                    AthleteSummaryRow(icon: "play.rectangle.fill", labelKey: "branch.social.youtube", value: yt)
                }
                if let tg = links.telegramChannelLink, !tg.isEmpty {
                    AthleteSummaryRow(icon: "paperplane.fill", labelKey: "branch.social.telegram", value: tg)
                }
                if let web = links.websiteURL, !web.isEmpty {
                    AthleteSummaryRow(icon: "globe", labelKey: "branch.social.website", value: web)
                }
            }
        }
    }
}
