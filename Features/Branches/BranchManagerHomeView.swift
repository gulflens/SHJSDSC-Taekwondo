import SwiftUI

public struct BranchManagerHomeView: View {
    @Environment(AppSession.self) private var session
    @State private var store: BranchProfileStore?
    @State private var auditEntries: [AuditEntry] = []
    @State private var sessionsToday: [ClassSession] = []
    @State private var coachLookup: [EntityID: Coach] = [:]
    @State private var showingEdit = false
    @State private var showingPrograms = false
    @State private var showingInventory = false
    @State private var showingFinancials = false
    @State private var showingAnnouncement = false

    public init() {}

    public var body: some View {
        NavigationStack {
            Group {
                if let store, let branch = store.branch {
                    content(store: store, branch: branch)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle(Text("manager.dashboard"))
            .demoRoleSwitcher()
        }
        .task { await load() }
    }

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
            auditEntries = try await session.repository
                .entries(actor: nil, since: Calendar.current.date(byAdding: .day, value: -7, to: Date()))
                .prefix(15).map { $0 }
        } catch {
            print("BranchManagerHomeView.load:", error)
        }
    }

    @ViewBuilder
    private func content(store: BranchProfileStore, branch: Branch) -> some View {
        ScrollView {
            VStack(spacing: 14) {
                identityCard(branch: branch, media: store.media)
                kpiGrid(store: store)
                todayScheduleCard(branch: branch)
                complianceAlerts(store: store)
                watchListCard(store: store, branch: branch)
                quickActions(branch: branch)
                activityFeed
                Color.clear.frame(height: 24)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
        .background(Color(.systemGroupedBackground))
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

    private func identityCard(branch: Branch, media: BranchMedia?) -> some View {
        HStack(spacing: 12) {
            heroThumb(url: media?.logoURL, branch: branch)
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: branch.name).font(.title3.bold())
                Text(verbatim: branch.nameAr).font(.caption).foregroundStyle(.secondary)
                Text(verbatim: branch.area).font(.caption2).foregroundStyle(.tertiary)
            }
            Spacer()
            Button {
                showingEdit = true
            } label: {
                Image(systemName: "slider.horizontal.3").font(.title3)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private func heroThumb(url: String?, branch: Branch) -> some View {
        if let url, let parsed = URL(string: url) {
            AsyncImage(url: parsed) { phase in
                switch phase {
                case .success(let img): img.resizable().aspectRatio(contentMode: .fill)
                default: Color.accentColor.opacity(0.2)
                }
            }
        } else {
            Color.accentColor.opacity(0.2)
        }
    }

    private func kpiGrid(store: BranchProfileStore) -> some View {
        let m = store.metrics
        let cols = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
        return LazyVGrid(columns: cols, spacing: 8) {
            KPITile(title: "manager.kpi.registered", value: "\(m.registeredCount)", icon: "person.3.fill")
            KPITile(title: "manager.kpi.active", value: "\(m.activeCount)", icon: "bolt.fill")
            KPITile(title: "manager.kpi.utilisation", value: "\(Int(m.utilisationPct * 100))%", icon: "gauge.with.needle")
            KPITile(title: "manager.kpi.sessions_today", value: "\(sessionsToday.count)", icon: "calendar")
            KPITile(title: "manager.kpi.coaches_on_duty", value: "\(coachesOnDuty)", icon: "figure.taekwondo")
            complianceTile(store: store)
        }
    }

    private var coachesOnDuty: Int {
        Set(sessionsToday.map(\.coachID)).count
    }

    private func complianceTile(store: BranchProfileStore) -> some View {
        let status = store.compliance?.status() ?? .ok
        let tint: Color = status == .expired ? .red : (status == .expiring ? .orange : .green)
        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.shield.fill").foregroundStyle(tint)
                Text("manager.kpi.compliance").font(.caption).foregroundStyle(.secondary)
            }
            Text(LocalizedStringKey(status.labelKey))
                .font(.title3.bold())
                .foregroundStyle(tint)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func todayScheduleCard(branch: Branch) -> some View {
        sectionCard(icon: "calendar", title: "heading.today") {
            if sessionsToday.isEmpty {
                Text("empty.no_classes_today").font(.caption).foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(sessionsToday) { s in
                        HStack(spacing: 6) {
                            Text(s.startsAt, style: .time)
                                .font(.caption.monospacedDigit())
                                .frame(width: 56, alignment: .leading)
                                .environment(\.layoutDirection, .leftToRight)
                            Text(verbatim: s.title).font(.caption).lineLimit(1)
                            Spacer()
                            if let c = coachLookup[s.coachID] {
                                Text(verbatim: c.fullName).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                            }
                        }
                    }
                    NavigationLink(destination: AthleteListView(scope: .byBranch(branch.id))) {
                        Text("manager.view_attendance").font(.caption.bold())
                    }
                }
            }
        }
    }

    private func complianceAlerts(store: BranchProfileStore) -> some View {
        let now = Date()
        var alerts: [(LocalizedStringKey, Date?, ComplianceStatus)] = []
        if let c = store.compliance {
            if let d = c.civilDefenceExpiry, daysFrom(d, now) <= 30 {
                alerts.append(("compliance.civil_defence", d, daysFrom(d, now) < 0 ? .expired : .expiring))
            }
            if let d = c.sharjahSportsCouncilExpiry, daysFrom(d, now) <= 30 {
                alerts.append(("compliance.sports_council", d, daysFrom(d, now) < 0 ? .expired : .expiring))
            }
            if let d = c.insuranceExpiry, daysFrom(d, now) <= 30 {
                alerts.append(("compliance.insurance", d, daysFrom(d, now) < 0 ? .expired : .expiring))
            }
        }
        for c in store.coaches {
            if c.firstAidExpiry < now.addingTimeInterval(30 * 24 * 3600) {
                alerts.append((LocalizedStringKey(c.fullName + " · first-aid"), c.firstAidExpiry,
                               c.firstAidExpiry < now ? .expired : .expiring))
            }
            if c.safeguardingExpiry < now.addingTimeInterval(30 * 24 * 3600) {
                alerts.append((LocalizedStringKey(c.fullName + " · safeguarding"), c.safeguardingExpiry,
                               c.safeguardingExpiry < now ? .expired : .expiring))
            }
        }
        return sectionCard(icon: "exclamationmark.triangle.fill", title: "manager.alerts") {
            if alerts.isEmpty {
                Text("manager.no_alerts").font(.caption).foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(alerts.indices, id: \.self) { i in
                        let (label, date, status) = alerts[i]
                        HStack {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 8))
                                .foregroundStyle(status == .expired ? .red : .orange)
                            Text(label).font(.caption)
                            Spacer()
                            if let d = date {
                                Text(d, style: .date).font(.caption2).foregroundStyle(.secondary)
                                    .environment(\.layoutDirection, .leftToRight)
                            }
                        }
                    }
                }
            }
        }
    }

    private func daysFrom(_ d: Date, _ now: Date) -> Int {
        Calendar.current.dateComponents([.day], from: now, to: d).day ?? 0
    }

    private func watchListCard(store: BranchProfileStore, branch: Branch) -> some View {
        let count = store.metrics.watchListCount
        return sectionCard(icon: "eye.fill", title: "manager.watch_list") {
            HStack {
                Text(verbatim: "\(count)")
                    .font(.title2.bold().monospacedDigit())
                    .environment(\.layoutDirection, .leftToRight)
                Text("status.watch").font(.caption).foregroundStyle(.secondary)
                Spacer()
                NavigationLink(destination: AthleteListView(scope: .byBranch(branch.id))) {
                    Image(systemName: "chevron.right")
                }
            }
        }
    }

    private func quickActions(branch: Branch) -> some View {
        sectionCard(icon: "bolt.fill", title: "manager.quick_actions") {
            let cols = [GridItem(.flexible()), GridItem(.flexible())]
            LazyVGrid(columns: cols, spacing: 8) {
                quickAction(icon: "person.3.fill", label: "manager.edit_programs") {
                    showingPrograms = true
                }
                quickAction(icon: "shippingbox.fill", label: "manager.update_inventory") {
                    showingInventory = true
                }
                if let role = session.currentUser?.role,
                   PermissionMatrix.allowed(role: role, permission: .viewBranchFinancials) {
                    quickAction(icon: "dollarsign.circle.fill", label: "manager.log_financials") {
                        showingFinancials = true
                    }
                }
                quickAction(icon: "megaphone.fill", label: "manager.compose_announcement") {
                    showingAnnouncement = true
                }
            }
        }
    }

    private func quickAction(icon: String, label: LocalizedStringKey, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon).foregroundStyle(.tint).frame(width: 22)
                Text(label).font(.caption.bold()).lineLimit(2).multilineTextAlignment(.leading)
                Spacer()
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    private var activityFeed: some View {
        sectionCard(icon: "clock.arrow.circlepath", title: "manager.recent_activity") {
            if auditEntries.isEmpty {
                Text("manager.no_activity").font(.caption).foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(auditEntries.prefix(10)) { e in
                        HStack {
                            Text(verbatim: e.action).font(.caption)
                            Spacer()
                            Text(e.at, style: .relative).font(.caption2).foregroundStyle(.secondary)
                                .environment(\.layoutDirection, .leftToRight)
                        }
                    }
                }
            }
        }
    }

    private func sectionCard<Content: View>(
        icon: String, title: LocalizedStringKey,
        @ViewBuilder _ content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption.bold()).foregroundStyle(.white)
                    .frame(width: 22, height: 22)
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 6))
                Text(title).font(.subheadline.bold())
                Spacer()
            }
            content()
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
    }
}
