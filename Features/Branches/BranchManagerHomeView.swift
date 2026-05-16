import SwiftUI

/// Branch manager's home dashboard. Stage 1.7 remodel — every block now uses
/// the shared `SectionCard` + `KPITile` + `GreetingHero` primitives so the
/// surface feels part of the federation-grade ecosystem.
public struct BranchManagerHomeView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var store: BranchProfileStore?
    @State private var auditEntries: [AuditEntry] = []
    @State private var sessionsToday: [ClassSession] = []
    @State private var coachLookup: [EntityID: Coach] = [:]
    @State private var userLookup: [EntityID: User] = [:]
    @State private var showingEdit = false
    @State private var showingPrograms = false
    @State private var showingInventory = false
    @State private var showingFinancials = false
    @State private var showingAnnouncement = false

    public init() {}

    public var body: some View {
        Group {
            if let store, let branch = store.branch {
                content(store: store, branch: branch)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .demoRoleSwitcher()
        .task { await load() }
    }

    private var isWide: Bool { sizeClass == .regular }

    private var branchID: EntityID? {
        session.currentUser?.primaryBranchID
    }

    private func load() async {
        guard let branchID else { return }
        if store == nil { store = BranchProfileStore(repository: session.repository) }
        await store?.load(branchID: branchID, monthsBack: 6)
        do {
            sessionsToday = try await session.repository.sessions(branchID: branchID, on: Date())
            let coaches = try await session.repository.coaches(branchID: branchID)
            coachLookup = Dictionary(uniqueKeysWithValues: coaches.map { ($0.id, $0) })
            let since = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            auditEntries = Array(try await session.repository.entries(actor: nil, since: since).prefix(10))
            let actors = try await session.repository.availableUsers()
            userLookup = Dictionary(uniqueKeysWithValues: actors.map { ($0.id, $0) })
        } catch {
            print("BranchManagerHomeView.load:", error)
        }
    }

    @ViewBuilder
    private func content(store: BranchProfileStore, branch: Branch) -> some View {
        ScrollView {
            VStack(spacing: 14) {
                if let user = session.currentUser {
                    GreetingHero(
                        fullName: user.fullName,
                        fullNameAr: user.fullNameAr,
                        roleLabel: NSLocalizedString("role.\(user.role.rawValue)", comment: ""),
                        subtitleKey: "manager.dashboard.subtitle"
                    )
                }
                identityCard(branch: branch, media: store.media)
                analyticsRow(store: store)
                if isWide {
                    HStack(alignment: .top, spacing: 14) {
                        todayScheduleCard(branch: branch).frame(maxWidth: .infinity)
                        complianceAlerts(store: store).frame(maxWidth: .infinity)
                    }
                    HStack(alignment: .top, spacing: 14) {
                        watchListCard(store: store, branch: branch).frame(maxWidth: .infinity)
                        quickActions(branch: branch).frame(maxWidth: .infinity)
                    }
                } else {
                    todayScheduleCard(branch: branch)
                    complianceAlerts(store: store)
                    watchListCard(store: store, branch: branch)
                    quickActions(branch: branch)
                }
                activityFeed
            }
            .padding(.horizontal, isWide ? 20 : 14)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .navigationDestination(isPresented: $showingEdit) {
            BranchEditView(branchID: branch.id)
        }
        .navigationDestination(isPresented: $showingPrograms) {
            BranchEditView(branchID: branch.id, initialTab: .programs)
        }
        .navigationDestination(isPresented: $showingInventory) {
            BranchEditView(branchID: branch.id, initialTab: .inventory)
        }
        .navigationDestination(isPresented: $showingFinancials) {
            BranchEditView(branchID: branch.id, initialTab: .financials)
        }
        .navigationDestination(isPresented: $showingAnnouncement) {
            AnnouncementsView()
        }
    }

    // MARK: - Identity

    private func identityCard(branch: Branch, media: BranchMedia?) -> some View {
        SectionCard {
            HStack(spacing: 14) {
                heroThumb(url: media?.logoURL, branch: branch)
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
                    )
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(verbatim: branch.name).scaledFont(.title3, weight: .bold)
                        if branch.isMain {
                            CategoryBadge(
                                value: NSLocalizedString("branch.badge.main", comment: ""),
                                tone: .elite,
                                icon: "crown.fill"
                            )
                        }
                    }
                    Text(verbatim: branch.nameAr)
                        .scaledFont(.subheadline)
                        .foregroundStyle(.secondary)
                        .environment(\.layoutDirection, .rightToLeft)
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.and.ellipse")
                            .scaledFont(.caption2)
                        Text(verbatim: branch.area.isEmpty ? branch.emirate : "\(branch.area), \(branch.emirate)")
                            .scaledFont(.caption2)
                    }
                    .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Button {
                    showingEdit = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .scaledFont(.title3)
                        .foregroundStyle(.tint)
                        .padding(10)
                        .background(Color.accentColor.opacity(0.12), in: Circle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private func heroThumb(url: String?, branch: Branch) -> some View {
        if let url, let parsed = URL(string: url) {
            AsyncImage(url: parsed) { phase in
                switch phase {
                case .success(let img): img.resizable().aspectRatio(contentMode: .fill)
                default: Color.accentColor.opacity(0.18)
                }
            }
        } else {
            ZStack {
                LinearGradient(
                    colors: [Color.accentColor.opacity(0.85), Color.accentColor.opacity(0.45)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Image(systemName: "building.2.fill")
                    .scaledFont(.title2)
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
    }

    // MARK: - Executive analytics

    private func analyticsRow(store: BranchProfileStore) -> some View {
        let m = store.metrics
        return LazyVGrid(columns: homeAnalyticsColumns(isWide: isWide), spacing: 12) {
            ExecutiveAnalyticsCard(titleKey: "manager.kpi.registered",
                                   systemIcon: "person.3.fill", tint: .accentColor,
                                   value: "\(m.registeredCount)",
                                   spark: homeSpark(1), deltaPct: 7.3)
            ExecutiveAnalyticsCard(titleKey: "manager.kpi.active",
                                   systemIcon: "bolt.fill", tint: .secondaryAccent,
                                   value: "\(m.activeCount)",
                                   spark: homeSpark(2), deltaPct: 4.6)
            ExecutiveAnalyticsCard(titleKey: "manager.kpi.utilisation",
                                   systemIcon: "gauge.with.needle", tint: .purple,
                                   value: "\(Int((m.utilisationPct * 100).rounded()))%",
                                   spark: homeSpark(3), deltaPct: 5.1)
            ExecutiveAnalyticsCard(titleKey: "manager.kpi.sessions_today",
                                   systemIcon: "calendar", tint: .orange,
                                   value: "\(sessionsToday.count)",
                                   spark: homeSpark(4), deltaPct: 2.0)
            ExecutiveAnalyticsCard(titleKey: "manager.kpi.coaches_on_duty",
                                   systemIcon: "figure.taekwondo", tint: .pink,
                                   value: "\(coachesOnDuty)",
                                   spark: homeSpark(5), deltaPct: 0)
            ExecutiveAnalyticsCard(titleKey: "manager.kpi.attendance",
                                   systemIcon: "shield.lefthalf.filled", tint: .cyan,
                                   value: "\(Int((m.avgAttendancePct * 100).rounded()))%",
                                   spark: homeSpark(6), deltaPct: 3.8)
        }
    }

    private var coachesOnDuty: Int {
        Set(sessionsToday.map(\.coachID)).count
    }

    // MARK: - Today's schedule

    private func todayScheduleCard(branch: Branch) -> some View {
        SectionCard("heading.today", icon: "calendar.badge.checkmark") {
            if sessionsToday.isEmpty {
                EmptyStateCard(
                    icon: "calendar",
                    titleKey: "empty.no_classes_today",
                    messageKey: nil
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(sessionsToday.sorted { $0.startsAt < $1.startsAt }) { s in
                        scheduleRow(s)
                        if s.id != sessionsToday.sorted(by: { $0.startsAt < $1.startsAt }).last?.id {
                            Divider().opacity(0.3)
                        }
                    }
                    NavigationLink(destination: AthleteListView(scope: .byBranch(branch.id))) {
                        HStack(spacing: 4) {
                            Text("manager.view_attendance")
                                .scaledFont(.caption, weight: .semibold)
                                .foregroundStyle(.tint)
                            Image(systemName: "chevron.right")
                                .scaledFont(.caption2, weight: .semibold)
                                .foregroundStyle(.tint)
                                .flipsForRightToLeftLayoutDirection(true)
                        }
                        .padding(.top, 4)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func scheduleRow(_ s: ClassSession) -> some View {
        HStack(spacing: 10) {
            Text(s.startsAt, format: .dateTime.hour().minute())
                .scaledFont(.caption, weight: .semibold, monospacedDigit: true)
                .frame(width: 54, alignment: .leading)
                .environment(\.layoutDirection, .leftToRight)
            VStack(alignment: .leading, spacing: 1) {
                Text(verbatim: s.title)
                    .scaledFont(.subheadline, weight: .medium)
                    .lineLimit(1)
                if let c = coachLookup[s.coachID] {
                    Text(verbatim: c.fullName)
                        .scaledFont(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
            Text(verbatim: "\(s.enrolledAthleteIDs.count)/\(s.capacity)")
                .scaledFont(.caption2, monospacedDigit: true)
                .foregroundStyle(.secondary)
                .environment(\.layoutDirection, .leftToRight)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Compliance alerts

    private func complianceAlerts(store: BranchProfileStore) -> some View {
        let now = Date()
        var alerts: [(String, Date?, ComplianceStatus)] = []
        if let c = store.compliance {
            if let d = c.civilDefenceExpiry, daysFrom(d, now) <= 30 {
                alerts.append((NSLocalizedString("compliance.civil_defence", comment: ""), d, daysFrom(d, now) < 0 ? .expired : .expiring))
            }
            if let d = c.sharjahSportsCouncilExpiry, daysFrom(d, now) <= 30 {
                alerts.append((NSLocalizedString("compliance.sports_council", comment: ""), d, daysFrom(d, now) < 0 ? .expired : .expiring))
            }
            if let d = c.insuranceExpiry, daysFrom(d, now) <= 30 {
                alerts.append((NSLocalizedString("compliance.insurance", comment: ""), d, daysFrom(d, now) < 0 ? .expired : .expiring))
            }
        }
        for c in store.coaches {
            if c.firstAidExpiry < now.addingTimeInterval(30 * 24 * 3600) {
                alerts.append(("\(c.fullName) · first-aid", c.firstAidExpiry, c.firstAidExpiry < now ? .expired : .expiring))
            }
            if c.safeguardingExpiry < now.addingTimeInterval(30 * 24 * 3600) {
                alerts.append(("\(c.fullName) · safeguarding", c.safeguardingExpiry, c.safeguardingExpiry < now ? .expired : .expiring))
            }
        }
        return SectionCard("manager.alerts", icon: "exclamationmark.triangle.fill") {
            if alerts.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundStyle(.green)
                    Text("manager.no_alerts")
                        .scaledFont(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(alerts.indices, id: \.self) { i in
                        let (label, date, status) = alerts[i]
                        alertRow(label: label, date: date, status: status)
                        if i < alerts.count - 1 {
                            Divider().opacity(0.3)
                        }
                    }
                }
            }
        }
    }

    private func alertRow(label: String, date: Date?, status: ComplianceStatus) -> some View {
        let color: Color = status == .expired ? .red : .orange
        return HStack(spacing: 10) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(verbatim: label)
                .scaledFont(.footnote)
                .lineLimit(1)
            Spacer(minLength: 0)
            if let d = date {
                Text(d, format: .dateTime.day().month(.abbreviated))
                    .scaledFont(.caption2, monospacedDigit: true)
                    .foregroundStyle(.secondary)
                    .environment(\.layoutDirection, .leftToRight)
            }
        }
    }

    private func daysFrom(_ d: Date, _ now: Date) -> Int {
        Calendar.current.dateComponents([.day], from: now, to: d).day ?? 0
    }

    // MARK: - Watch list

    private func watchListCard(store: BranchProfileStore, branch: Branch) -> some View {
        let count = store.metrics.watchListCount
        return SectionCard("manager.watch_list", icon: "eye.fill") {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(count > 0 ? Color.orange.opacity(0.18) : Color.green.opacity(0.18))
                        .frame(width: 44, height: 44)
                    Text(verbatim: "\(count)")
                        .scaledFont(.title2, weight: .bold, monospacedDigit: true)
                        .foregroundStyle(count > 0 ? .orange : .green)
                        .environment(\.layoutDirection, .leftToRight)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("status.watch")
                        .scaledFont(.subheadline, weight: .semibold)
                    Text("manager.watch_list.subtitle")
                        .scaledFont(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                NavigationLink(destination: AthleteListView(scope: .byBranch(branch.id))) {
                    Image(systemName: "chevron.right")
                        .scaledFont(.subheadline, weight: .semibold)
                        .foregroundStyle(.secondary)
                        .flipsForRightToLeftLayoutDirection(true)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Quick actions

    private func quickActions(branch: Branch) -> some View {
        SectionCard("manager.quick_actions", icon: "bolt.fill") {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2),
                      spacing: 8) {
                HomeQuickActionTile(icon: "person.3.fill", titleKey: "manager.edit_programs",
                                    tint: .accentColor) { showingPrograms = true }
                HomeQuickActionTile(icon: "shippingbox.fill", titleKey: "manager.update_inventory",
                                    tint: .secondaryAccent) { showingInventory = true }
                if let role = session.currentUser?.role,
                   PermissionMatrix.allowed(role: role, permission: .viewBranchFinancials) {
                    HomeQuickActionTile(icon: "dollarsign.circle.fill", titleKey: "manager.log_financials",
                                        tint: .orange) { showingFinancials = true }
                }
                HomeQuickActionTile(icon: "megaphone.fill", titleKey: "manager.compose_announcement",
                                    tint: .purple) { showingAnnouncement = true }
            }
        }
    }

    // MARK: - Activity feed

    private var activityFeed: some View {
        SectionCard("manager.recent_activity", icon: "clock.arrow.circlepath") {
            if auditEntries.isEmpty {
                EmptyStateCard(
                    icon: "tray",
                    titleKey: "manager.no_activity",
                    messageKey: nil
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(auditEntries.prefix(8)) { e in
                        activityRow(e)
                        if e.id != auditEntries.prefix(8).last?.id {
                            Divider().opacity(0.3)
                        }
                    }
                }
            }
        }
    }

    private func activityRow(_ entry: AuditEntry) -> some View {
        let user = userLookup[entry.actorUserID]
        return HStack(alignment: .top, spacing: 10) {
            if let user {
                Avatar(seed: user.avatarSeed, label: initials(user.fullName), size: 28)
            } else {
                Circle().fill(Color.secondary.opacity(0.18)).frame(width: 28, height: 28)
            }
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(verbatim: user?.fullName ?? "—")
                        .scaledFont(.caption, weight: .semibold)
                        .lineLimit(1)
                    Text(verbatim: entry.action)
                        .scaledFont(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    Text(entry.at, format: .relative(presentation: .numeric))
                        .scaledFont(.caption2)
                        .foregroundStyle(.secondary)
                        .environment(\.layoutDirection, .leftToRight)
                }
                Text(verbatim: entry.targetEntity)
                    .scaledFont(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    private func initials(_ name: String) -> String {
        name.split(separator: " ").prefix(2).map { String($0.prefix(1)) }.joined().uppercased()
    }
}
