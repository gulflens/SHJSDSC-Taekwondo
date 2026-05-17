import SwiftUI

/// Coach's home dashboard — Stage 1.13 executive remodel. Greeting hero +
/// executive analytics row + today's classes + a squad performance snapshot
/// (grade ring + averaged metric rings) + promotion readiness + quick actions.
public struct CoachHomeView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var schedule: ScheduleStore?
    @State private var squad: AthletesStore?
    @State private var showingSchedule = false
    @State private var showingSquad = false
    @State private var showingDrills = false
    @State private var showingAnnouncements = false
    @State private var liveSession: ClassSession?

    public init() {}

    public var body: some View {
        Group {
            if let schedule {
                content(schedule: schedule)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .demoRoleSwitcher()
        .toolbar {
            if canSchedule {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingSchedule = true
                    } label: {
                        Image(systemName: "calendar.badge.plus")
                    }
                    .accessibilityLabel(Text("class.add"))
                    .bareToolbarButton()
                }
            }
        }
        .sheet(isPresented: $showingSchedule) {
            NavigationStack {
                ScheduleClassView { _ in
                    Task {
                        guard let coachID = session.currentUser?.id else { return }
                        await schedule?.loadCoachDay(coachID: coachID)
                    }
                }
            }
        }
        .navigationDestination(isPresented: $showingSquad) { SquadListView() }
        .navigationDestination(isPresented: $showingDrills) {
            DrillLibraryView().subviewChrome(Text("coach.home.drills"))
        }
        .navigationDestination(isPresented: $showingAnnouncements) {
            AnnouncementsView().subviewChrome(Text("announcement.dashboard.title"))
        }
        #if os(iOS)
        .fullScreenCover(item: $liveSession) { s in
            LiveClassView(session: s)
        }
        #else
        .sheet(item: $liveSession) { s in
            LiveClassView(session: s)
        }
        #endif
        .task {
            guard let coachID = session.currentUser?.id else { return }
            if schedule == nil { schedule = ScheduleStore(repository: session.repository) }
            if squad == nil { squad = AthletesStore(repository: session.repository) }
            await schedule?.loadCoachDay(coachID: coachID)
            await squad?.loadForCoach(coachID)
        }
    }

    private var isWide: Bool { sizeClass == .regular }

    private var canSchedule: Bool {
        guard let role = session.currentUser?.role else { return false }
        return PermissionMatrix.allowed(role: role, permission: .scheduleSession)
    }

    @ViewBuilder
    private func content(schedule: ScheduleStore) -> some View {
        ScrollView {
            VStack(spacing: 14) {
                if let user = session.currentUser {
                    GreetingHero(
                        fullName: user.fullName,
                        fullNameAr: user.fullNameAr,
                        roleLabel: NSLocalizedString("role.\(user.role.rawValue)", comment: ""),
                        subtitleKey: "coach.home.subtitle"
                    )
                }
                analyticsRow(schedule: schedule)
                todayCard(schedule: schedule)
                squadSnapshotCard
                if let coachID = session.currentUser?.id {
                    PromotionReadinessCard(coachID: coachID)
                }
                quickActionsCard
            }
            .padding(.horizontal, isWide ? 20 : 14)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
    }

    // MARK: - Executive analytics

    private func analyticsRow(schedule: ScheduleStore) -> some View {
        LazyVGrid(columns: homeAnalyticsColumns(isWide: isWide), spacing: 12) {
            ExecutiveAnalyticsCard(titleKey: "coach.home.kpi.classes_today",
                                   systemIcon: "calendar.badge.checkmark", tint: .accentColor,
                                   value: "\(schedule.sessionsToday.count)",
                                   spark: homeSpark(1), deltaPct: 6.0)
            ExecutiveAnalyticsCard(titleKey: "coach.home.kpi.athletes_today",
                                   systemIcon: "person.3.fill", tint: .secondaryAccent,
                                   value: "\(athletesToday(schedule))",
                                   spark: homeSpark(2), deltaPct: 9.5)
            ExecutiveAnalyticsCard(titleKey: "coach.home.kpi.hours",
                                   systemIcon: "clock.fill", tint: .orange,
                                   value: String(format: "%.1fh", hoursToday(schedule)),
                                   spark: homeSpark(3), deltaPct: 4.0)
            ExecutiveAnalyticsCard(titleKey: "coach.home.kpi.squad",
                                   systemIcon: "person.2.badge.gearshape.fill", tint: .purple,
                                   value: "\(squadIntels.count)",
                                   spark: homeSpark(4), deltaPct: 12.0)
            ExecutiveAnalyticsCard(titleKey: "coach.home.kpi.squad_score",
                                   systemIcon: "chart.line.uptrend.xyaxis", tint: .pink,
                                   value: String(format: "%.0f", squadComposite),
                                   spark: homeSpark(5), deltaPct: 5.5)
            ExecutiveAnalyticsCard(titleKey: "coach.home.kpi.attendance",
                                   systemIcon: "shield.lefthalf.filled", tint: .cyan,
                                   value: "\(Int(squadMetricAvg(.attendance).rounded()))%",
                                   spark: homeSpark(6), deltaPct: 3.2)
        }
    }

    // MARK: - Today's classes

    @ViewBuilder
    private func todayCard(schedule: ScheduleStore) -> some View {
        let sorted = schedule.sessionsToday.sorted { $0.startsAt < $1.startsAt }
        SectionCard("heading.today", icon: "calendar", trailing: {
            if let next = nextClass(schedule) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.right.circle.fill")
                        .scaledFont(.caption2, weight: .semibold)
                    Text(verbatim: String(
                        format: NSLocalizedString("coach.home.next_at.fmt", comment: ""),
                        next.startsAt.formatted(.dateTime.hour().minute())))
                        .scaledFont(.caption2, weight: .semibold)
                        .environment(\.layoutDirection, .leftToRight)
                }
                .foregroundStyle(Color.accentColor)
                .padding(.horizontal, 9).padding(.vertical, 4)
                .background(Color.accentColor.opacity(0.12), in: Capsule())
            }
        }, content: {
            if sorted.isEmpty {
                EmptyStateCard(icon: "calendar",
                               titleKey: "empty.no_classes_today",
                               messageKey: "coach.home.no_classes.message")
            } else {
                VStack(spacing: 8) {
                    ForEach(sorted) { session in
                        Button { liveSession = session } label: {
                            classRow(session, branch: schedule.branchLookup[session.branchID])
                        }
                        .buttonStyle(.plain)
                        if session.id != sorted.last?.id {
                            Divider().opacity(0.3)
                        }
                    }
                }
            }
        })
    }

    private func classRow(_ session: ClassSession, branch: Branch?) -> some View {
        HStack(spacing: 12) {
            VStack(spacing: 0) {
                Text(session.startsAt, format: .dateTime.hour())
                    .scaledFont(.subheadline, weight: .bold, monospacedDigit: true)
                    .environment(\.layoutDirection, .leftToRight)
                Text(session.startsAt, format: .dateTime.minute())
                    .scaledFont(.caption2, monospacedDigit: true)
                    .foregroundStyle(.secondary)
                    .environment(\.layoutDirection, .leftToRight)
            }
            .frame(width: 46)
            .padding(.vertical, 6)
            .background(disciplineColor(session.discipline).opacity(0.12),
                        in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text(verbatim: session.title)
                    .scaledFont(.subheadline, weight: .semibold)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(localizedKey: session.discipline.labelKey)
                    Text(verbatim: "·")
                    Text(localizedKey: session.ageGroup.labelKey)
                    if let branch {
                        Text(verbatim: "·")
                        Text(verbatim: branch.name).lineLimit(1)
                    }
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
            Image(systemName: "chevron.right")
                .scaledFont(.caption, weight: .semibold)
                .foregroundStyle(.secondary)
                .flipsForRightToLeftLayoutDirection(true)
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }

    // MARK: - Squad snapshot

    private var squadSnapshotCard: some View {
        SectionCard("coach.home.squad_snapshot", icon: "chart.bar.xaxis", trailing: {
            Button { showingSquad = true } label: {
                HStack(spacing: 3) {
                    Text("coach.home.view_squad")
                        .scaledFont(.caption2, weight: .semibold)
                    Image(systemName: "chevron.right")
                        .scaledFont(.caption2, weight: .semibold)
                        .flipsForRightToLeftLayoutDirection(true)
                }
                .foregroundStyle(Color.accentColor)
            }
            .buttonStyle(.plain)
        }, content: {
            if squadIntels.isEmpty {
                EmptyStateCard(icon: "person.3",
                               titleKey: "coach.home.squad.empty",
                               messageKey: nil)
            } else {
                HStack(alignment: .center, spacing: 14) {
                    AthleteGradeRing(grade: LetterGrade.from(score: squadComposite),
                                     score: squadComposite, size: 66)
                    Divider().frame(height: 64).opacity(0.5)
                    HStack(spacing: 6) {
                        ForEach(AthleteMetricKind.allCases, id: \.self) { kind in
                            MiniMetricRing(kind: kind, score: squadMetricAvg(kind))
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
        })
    }

    // MARK: - Quick actions

    private var quickActionsCard: some View {
        SectionCard("coach.home.quick_links", icon: "bolt.fill") {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2),
                      spacing: 8) {
                HomeQuickActionTile(icon: "person.3.sequence.fill",
                                    titleKey: "squad.title", tint: .accentColor) {
                    showingSquad = true
                }
                HomeQuickActionTile(icon: "list.bullet.rectangle",
                                    titleKey: "coach.home.drills", tint: .secondaryAccent) {
                    showingDrills = true
                }
                HomeQuickActionTile(icon: "megaphone.fill",
                                    titleKey: "coach.home.announcements", tint: .orange) {
                    showingAnnouncements = true
                }
                if canSchedule {
                    HomeQuickActionTile(icon: "calendar.badge.plus",
                                        titleKey: "class.add", tint: .purple) {
                        showingSchedule = true
                    }
                }
            }
        }
    }

    // MARK: - Derived

    private var squadIntels: [AthleteIntel] {
        guard let squad else { return [] }
        return squad.athletes.map {
            AthleteIntel.make(athlete: $0, score: squad.scoreByAthlete[$0.id], branchName: "")
        }
    }

    private var squadComposite: Double {
        let xs = squadIntels.map(\.composite)
        return xs.isEmpty ? 0 : xs.reduce(0, +) / Double(xs.count)
    }

    private func squadMetricAvg(_ kind: AthleteMetricKind) -> Double {
        let xs = squadIntels.map { $0.metric(kind) }
        return xs.isEmpty ? 0 : xs.reduce(0, +) / Double(xs.count)
    }

    private func athletesToday(_ schedule: ScheduleStore) -> Int {
        Set(schedule.sessionsToday.flatMap { $0.enrolledAthleteIDs }).count
    }

    private func hoursToday(_ schedule: ScheduleStore) -> Double {
        schedule.sessionsToday.reduce(0.0) { acc, s in
            acc + s.endsAt.timeIntervalSince(s.startsAt) / 3600
        }
    }

    private func nextClass(_ schedule: ScheduleStore) -> ClassSession? {
        let now = Date()
        return schedule.sessionsToday
            .filter { $0.startsAt > now }
            .min { $0.startsAt < $1.startsAt }
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
}
