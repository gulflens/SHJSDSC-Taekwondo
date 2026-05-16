import SwiftUI

/// Coach's home dashboard — greeting hero, today's classes as rich rows,
/// quick squad shortcut. Replaces the Stage 1.5 bare-`List` version.
public struct CoachHomeView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var store: ScheduleStore?
    @State private var showingSchedule = false
    @State private var liveSession: ClassSession?

    public init() {}

    public var body: some View {
        Group {
            if let store {
                content(store: store)
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
                        await store?.loadCoachDay(coachID: coachID)
                    }
                }
            }
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
            if store == nil { store = ScheduleStore(repository: session.repository) }
            guard let store, let coachID = session.currentUser?.id else { return }
            await store.loadCoachDay(coachID: coachID)
        }
    }

    private var isWide: Bool { sizeClass == .regular }

    private var canSchedule: Bool {
        guard let role = session.currentUser?.role else { return false }
        return PermissionMatrix.allowed(role: role, permission: .scheduleSession)
    }

    @ViewBuilder
    private func content(store: ScheduleStore) -> some View {
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
                kpiStrip(store: store)
                todayCard(store: store)
                if let coachID = session.currentUser?.id {
                    PromotionReadinessCard(coachID: coachID)
                }
                quickLinksCard
            }
            .padding(.horizontal, isWide ? 20 : 14)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
    }

    private func kpiStrip(store: ScheduleStore) -> some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: isWide ? 4 : 2),
            spacing: 12
        ) {
            KPITile(
                title: "coach.home.kpi.classes_today",
                value: "\(store.sessionsToday.count)",
                icon: "calendar.badge.checkmark"
            )
            KPITile(
                title: "coach.home.kpi.athletes_today",
                value: "\(athletesToday(store))",
                icon: "person.3.fill"
            )
            KPITile(
                title: "coach.home.kpi.hours",
                value: String(format: "%.1fh", hoursToday(store)),
                icon: "clock.fill"
            )
            KPITile(
                title: "coach.home.kpi.next_class",
                value: nextClassTime(store),
                icon: "calendar.badge.clock"
            )
        }
    }

    private func todayCard(store: ScheduleStore) -> some View {
        SectionCard("heading.today", icon: "calendar") {
            if store.sessionsToday.isEmpty {
                EmptyStateCard(
                    icon: "calendar",
                    titleKey: "empty.no_classes_today",
                    messageKey: "coach.home.no_classes.message"
                )
            } else {
                let sorted = store.sessionsToday.sorted { $0.startsAt < $1.startsAt }
                VStack(spacing: 8) {
                    ForEach(sorted) { session in
                        Button {
                            liveSession = session
                        } label: {
                            classRow(session, branch: store.branchLookup[session.branchID])
                        }
                        .buttonStyle(.plain)
                        if session.id != sorted.last?.id {
                            Divider().opacity(0.3)
                        }
                    }
                }
            }
        }
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
            .background(disciplineColor(session.discipline).opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
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

    private var quickLinksCard: some View {
        SectionCard("coach.home.quick_links", icon: "bolt.fill") {
            VStack(spacing: 0) {
                NavigationLink(destination: SquadListView()) {
                    quickLinkRow(icon: "person.3.sequence.fill", labelKey: "squad.title")
                }
                .buttonStyle(.plain)
                Divider().opacity(0.3)
                NavigationLink(destination: DrillLibraryView()) {
                    quickLinkRow(icon: "list.bullet.rectangle", labelKey: "coach.home.drills")
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func quickLinkRow(icon: String, labelKey: LocalizedStringKey) -> some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.accentColor.opacity(0.14))
                Image(systemName: icon)
                    .scaledFont(.subheadline, weight: .semibold)
                    .foregroundStyle(.tint)
            }
            .frame(width: 34, height: 34)
            Text(labelKey)
                .scaledFont(.subheadline, weight: .semibold)
                .foregroundStyle(.primary)
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .scaledFont(.caption, weight: .semibold)
                .foregroundStyle(.secondary)
                .flipsForRightToLeftLayoutDirection(true)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }

    // MARK: - Derived

    private func athletesToday(_ store: ScheduleStore) -> Int {
        Set(store.sessionsToday.flatMap { $0.enrolledAthleteIDs }).count
    }

    private func hoursToday(_ store: ScheduleStore) -> Double {
        store.sessionsToday.reduce(0.0) { acc, s in
            acc + s.endsAt.timeIntervalSince(s.startsAt) / 3600
        }
    }

    private func nextClassTime(_ store: ScheduleStore) -> String {
        let now = Date()
        guard let next = store.sessionsToday.filter({ $0.startsAt > now }).min(by: { $0.startsAt < $1.startsAt }) else {
            return "—"
        }
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: next.startsAt)
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
