import SwiftUI

// MARK: - Coaches
//
// Stage 1.14 — premium coach-management dashboard. Header + executive
// analytics cards + filter pills + an adaptive two-panel workspace (coach
// performance cards + a preview panel on iPad; list with a pushed full
// profile on iPhone) + a coaching-intelligence insights strip. Replaces the
// flat `List`.

public struct CoachListView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.horizontalSizeClass) private var hSize

    @State private var coaches: [Coach] = []
    @State private var branchNames: [EntityID: String] = [:]
    @State private var athleteCountByCoach: [EntityID: Int] = [:]
    @State private var loaded = false
    @State private var query = ""
    @State private var filter: CoachFilter = .all
    @State private var branchFilter: EntityID?
    @State private var selectedID: EntityID?
    @State private var page = 0
    @State private var showingAdd = false
    @State private var selectedCoachForProfile: Coach?

    public init() {}

    @State private var rowsPerPage = 10
    private var isWide: Bool { hSize == .regular }

    public var body: some View {
        VStack(spacing: 0) {
            header
            if loaded {
                content
            } else {
                Spacer(); ProgressView(); Spacer()
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .task { await load() }
        .onChange(of: query) { _, _ in page = 0 }
        .onChange(of: filter) { _, _ in page = 0 }
        .onChange(of: branchFilter) { _, _ in page = 0 }
        .onChange(of: rowsPerPage) { _, _ in page = 0 }
        .navigationDestination(isPresented: $showingAdd) {
            AddCoachView(initialBranchID: session.currentUser?.primaryBranchID) { newCoach in
                if let i = coaches.firstIndex(where: { $0.id == newCoach.id }) {
                    coaches[i] = newCoach
                } else {
                    coaches.append(newCoach)
                }
            }
        }
        .navigationDestination(isPresented: profileLinkBinding) {
            if let c = selectedCoachForProfile { CoachDetailView(coach: c) }
        }
    }

    // MARK: Header

    private var header: some View {
        Group {
            if isWide {
                HStack(alignment: .center, spacing: 12) {
                    titleBlock
                    Spacer(minLength: 8)
                    SearchCoachField(text: $query).frame(maxWidth: 240)
                    filterButton
                    exportButton
                    if canEdit { addButton }
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        titleBlock
                        Spacer(minLength: 8)
                        if canEdit { addButton }
                    }
                    HStack(spacing: 8) {
                        SearchCoachField(text: $query)
                        filterButton
                    }
                }
            }
        }
        .padding(.horizontal, isWide ? 22 : 14)
        .padding(.top, 14)
        .padding(.bottom, 10)
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("coach.dashboard.title").scaledFont(.title2, weight: .bold)
            Text("coach.dashboard.subtitle")
                .scaledFont(.caption).foregroundStyle(.secondary)
        }
    }

    private var filterButton: some View {
        Menu {
            Picker("coach.filter.branch", selection: $branchFilter) {
                Text("coach.filter.all_branches").tag(EntityID?.none)
                ForEach(branchNames.sorted { $0.value < $1.value }, id: \.key) { id, name in
                    Text(verbatim: name).tag(EntityID?.some(id))
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "line.3.horizontal.decrease").scaledFont(.caption, weight: .semibold)
                Text("coach.filter").scaledFont(.subheadline, weight: .semibold)
            }
            .foregroundStyle(branchFilter == nil ? Color.primary : Color.accentColor)
            .padding(.horizontal, 13).padding(.vertical, 8)
            .background(Capsule().fill(branchFilter == nil
                                       ? Color.secondary.opacity(0.10)
                                       : Color.accentColor.opacity(0.14)))
            .overlay(Capsule().stroke(Color.secondary.opacity(0.16), lineWidth: 1))
        }
        .menuStyle(.button).buttonStyle(.plain).menuIndicator(.hidden)
    }

    private var exportButton: some View {
        ShareLink(item: exportText) {
            HStack(spacing: 6) {
                Image(systemName: "square.and.arrow.up").scaledFont(.caption, weight: .semibold)
                Text("coach.export").scaledFont(.subheadline, weight: .semibold)
            }
            .foregroundStyle(.primary)
            .padding(.horizontal, 13).padding(.vertical, 8)
            .background(Capsule().fill(Color.secondary.opacity(0.10)))
            .overlay(Capsule().stroke(Color.secondary.opacity(0.16), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var addButton: some View {
        Button { showingAdd = true } label: {
            HStack(spacing: 6) {
                Image(systemName: "plus").scaledFont(.footnote, weight: .semibold)
                Text("coach.add").scaledFont(.subheadline, weight: .semibold)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 14).padding(.vertical, 9)
            .background(Capsule().fill(LinearGradient(
                colors: [Color.accentColor, Color.accentColor.opacity(0.82)],
                startPoint: .top, endPoint: .bottom)))
            .shadow(color: Color.accentColor.opacity(0.32), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }

    // MARK: Content

    private var content: some View {
        // The list+detail split is shown only on a wide landscape canvas;
        // iPhone and iPad-portrait drop the panel and push a detail screen.
        GeometryReader { _ in
            let split = usesSplitDetailLayout()
            ScrollView {
                VStack(spacing: 14) {
                    analyticsRow
                    filterPills
                    if split {
                        GeometryReader { geo in
                            let gap: CGFloat = 16
                            let w = max(0, geo.size.width - gap)
                            HStack(alignment: .top, spacing: gap) {
                                listColumn(split: true).frame(width: w * 0.62)
                                detailColumn.frame(width: w * 0.38)
                            }
                        }
                        .frame(height: 560)
                    } else {
                        listColumn(split: false)
                    }
                    insightsCard
                }
                .padding(.horizontal, isWide ? 22 : 14)
                .padding(.top, 4)
                .padding(.bottom, 18)
            }
        }
    }

    // MARK: Executive analytics

    private var analyticsRow: some View {
        let all = allIntels
        let perfAvg = all.isEmpty ? 0
            : all.reduce(0.0) { $0 + $1.composite } / Double(all.count)
        let attendanceAvg = all.isEmpty ? 0
            : all.reduce(0.0) { $0 + $1.attendancePct } / Double(all.count)
        return LazyVGrid(columns: homeAnalyticsColumns(isWide: isWide), spacing: 12) {
            ExecutiveAnalyticsCard(titleKey: "coach.kpi.total", systemIcon: "person.3.fill",
                                   tint: .accentColor, value: "\(all.count)",
                                   spark: homeSpark(1), deltaPct: 6.0)
            ExecutiveAnalyticsCard(titleKey: "coach.kpi.head", systemIcon: "star.circle.fill",
                                   tint: .secondaryAccent,
                                   value: "\(all.filter(\.isHeadCoach).count)",
                                   spark: homeSpark(2), deltaPct: 4.2)
            ExecutiveAnalyticsCard(titleKey: "coach.kpi.assistant", systemIcon: "person.fill",
                                   tint: .purple,
                                   value: "\(all.filter { !$0.isHeadCoach }.count)",
                                   spark: homeSpark(3), deltaPct: 8.0)
            ExecutiveAnalyticsCard(titleKey: "coach.kpi.certified", systemIcon: "checkmark.seal.fill",
                                   tint: .orange, value: "\(compliantCount)",
                                   spark: homeSpark(4), deltaPct: 3.1)
            ExecutiveAnalyticsCard(titleKey: "coach.kpi.performance", systemIcon: "chart.line.uptrend.xyaxis",
                                   tint: .pink, value: String(format: "%.0f", perfAvg),
                                   spark: homeSpark(5), deltaPct: 5.4)
            ExecutiveAnalyticsCard(titleKey: "coach.kpi.attendance", systemIcon: "shield.lefthalf.filled",
                                   tint: .cyan, value: "\(Int(attendanceAvg.rounded()))%",
                                   spark: homeSpark(6), deltaPct: 2.6)
        }
    }

    // MARK: Filter pills

    private var filterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 7) {
                ForEach(CoachFilter.allCases, id: \.self) { f in
                    let on = filter == f
                    Button {
                        withAnimation(.easeInOut(duration: 0.16)) { filter = f }
                    } label: {
                        Text(localizedKey: f.labelKey)
                            .scaledFont(.caption, weight: .semibold)
                            .padding(.horizontal, 13).padding(.vertical, 7)
                            .foregroundStyle(on ? Color.white : Color.primary)
                            .background(Capsule().fill(on ? Color.accentColor : Color.secondary.opacity(0.10)))
                            .shadow(color: on ? Color.accentColor.opacity(0.3) : .clear, radius: 6, y: 3)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 2)
        }
    }

    // MARK: List column

    private func listColumn(split: Bool) -> some View {
        VStack(spacing: 0) {
            if filteredIntels.isEmpty {
                EmptyStateCard(icon: "person.crop.circle.badge.questionmark",
                               titleKey: "coach.empty.title",
                               messageKey: "coach.empty.message")
                    .padding(16)
                Spacer(minLength: 0)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(pageSlice) { intel in
                            coachRow(intel, split: split)
                        }
                    }
                    .padding(12)
                }
                Divider().opacity(0.5)
                paginationFooter
            }
        }
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
            .stroke(Color.secondary.opacity(0.10), lineWidth: 1))
        .shadow(color: .black.opacity(0.05), radius: 14, y: 6)
    }

    @ViewBuilder
    private func coachRow(_ intel: CoachIntel, split: Bool) -> some View {
        if split {
            Button {
                withAnimation(.easeInOut(duration: 0.18)) { selectedID = intel.id }
            } label: {
                CoachPerformanceCard(intel: intel, selected: selectedID == intel.id)
            }
            .buttonStyle(.plain)
        } else {
            NavigationLink {
                CoachDetailView(coach: intel.coach)
            } label: {
                CoachPerformanceCard(intel: intel, selected: false)
            }
            .buttonStyle(.plain)
        }
    }

    private var paginationFooter: some View {
        let total = filteredIntels.count
        let lower = total == 0 ? 0 : page * rowsPerPage + 1
        let upper = min(total, (page + 1) * rowsPerPage)
        return HStack(spacing: 10) {
            RowsPerPageMenu(rowsPerPage: $rowsPerPage)
            Text(verbatim: String(format: NSLocalizedString("coach.showing.fmt", comment: ""),
                                   lower, upper, total))
                .scaledFont(.caption2).foregroundStyle(.secondary)
                .environment(\.layoutDirection, .leftToRight)
            Spacer(minLength: 8)
            HStack(spacing: 6) {
                pagerButton("chevron.left", page > 0) { page -= 1 }
                Text(verbatim: "\(page + 1) / \(pageCount)")
                    .scaledFont(.caption, weight: .semibold, monospacedDigit: true)
                    .environment(\.layoutDirection, .leftToRight)
                pagerButton("chevron.right", page + 1 < pageCount) { page += 1 }
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 11)
    }

    private func pagerButton(_ icon: String, _ enabled: Bool, _ action: @escaping () -> Void) -> some View {
        Button { withAnimation(.easeInOut(duration: 0.15), action) } label: {
            Image(systemName: icon)
                .scaledFont(.caption, weight: .semibold)
                .frame(width: 30, height: 30)
                .background(Color.secondary.opacity(0.10),
                            in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain).disabled(!enabled).opacity(enabled ? 1 : 0.4)
    }

    // MARK: Detail column

    @ViewBuilder
    private var detailColumn: some View {
        if let intel = selectedIntel {
            CoachPreviewPanel(intel: intel) {
                selectedCoachForProfile = intel.coach
            }
        } else {
            VStack(spacing: 12) {
                Image(systemName: "person.crop.square.badge.magnifyingglass")
                    .font(.system(size: 38)).foregroundStyle(.tertiary)
                Text("coach.detail.empty")
                    .scaledFont(.subheadline).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.secondary.opacity(0.10), lineWidth: 1))
        }
    }

    // MARK: Insights

    private var insightsCard: some View {
        SectionCard("coach.insights", icon: "sparkles") {
            let cols = isWide
                ? Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)
                : [GridItem(.flexible())]
            LazyVGrid(columns: cols, spacing: 10) {
                ForEach(insights, id: \.0) { _, icon, tint, text in
                    CoachInsightCard(systemIcon: icon, tint: tint, text: text)
                }
            }
        }
    }

    private var insights: [(Int, String, Color, AttributedString)] {
        let all = allIntels
        guard !all.isEmpty else { return [] }
        var out: [(Int, String, Color, AttributedString)] = []
        if let topAtt = all.max(by: { $0.attendancePct < $1.attendancePct }) {
            out.append((0, "chart.line.uptrend.xyaxis", .secondaryAccent,
                        insightText("coach.insight.attendance.fmt",
                                    topAtt.coach.fullName, Int(topAtt.attendancePct.rounded()))))
        }
        if let topDis = all.max(by: { $0.metric(.discipline) < $1.metric(.discipline) }) {
            out.append((1, "shield.lefthalf.filled", .accentColor,
                        insightText("coach.insight.discipline.fmt", topDis.coach.fullName, nil)))
        }
        if let renew = all.first(where: { needsRenewal($0.coach) }) {
            out.append((2, "exclamationmark.triangle.fill", .orange,
                        insightText("coach.insight.renewal.fmt", renew.coach.fullName, nil)))
        }
        return out
    }

    private func insightText(_ key: String, _ name: String, _ number: Int?) -> AttributedString {
        let raw = NSLocalizedString(key, comment: "")
        let filled = number.map { String(format: raw, name, $0) } ?? String(format: raw, name)
        return AttributedString(filled)
    }

    private var profileLinkBinding: Binding<Bool> {
        Binding(get: { selectedCoachForProfile != nil },
                set: { if !$0 { selectedCoachForProfile = nil } })
    }

    // MARK: Data

    private var canEdit: Bool {
        guard let role = session.currentUser?.role else { return false }
        return PermissionMatrix.allowed(role: role, permission: .editCoach)
    }

    private var allIntels: [CoachIntel] {
        coaches.map { coach in
            CoachIntel.make(
                coach: coach,
                branchName: branchNames[coach.primaryBranchID]
                    ?? NSLocalizedString("admin.no_branch", comment: ""),
                athleteCount: athleteCountByCoach[coach.id] ?? 0)
        }
    }

    private var filteredIntels: [CoachIntel] {
        var out = allIntels
        if let branchFilter { out = out.filter { $0.coach.primaryBranchID == branchFilter } }
        out = out.filter { filter.matches($0) }
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        if !q.isEmpty {
            out = out.filter {
                $0.coach.fullName.lowercased().contains(q)
                    || $0.coach.fullNameAr.contains(query)
                    || $0.branchName.lowercased().contains(q)
            }
        }
        return out.sorted { $0.composite > $1.composite }
    }

    private var pageCount: Int {
        max(1, Int(ceil(Double(filteredIntels.count) / Double(rowsPerPage))))
    }

    private var pageSlice: [CoachIntel] {
        let all = filteredIntels
        guard !all.isEmpty else { return [] }
        let safe = min(page, pageCount - 1)
        let start = safe * rowsPerPage
        return Array(all[start..<min(start + rowsPerPage, all.count)])
    }

    private var selectedIntel: CoachIntel? {
        guard let id = selectedID else { return nil }
        return allIntels.first { $0.id == id }
    }

    private var compliantCount: Int {
        coaches.filter { !needsRenewal($0) }.count
    }

    private func needsRenewal(_ coach: Coach) -> Bool {
        guard let next = coach.nextCertificationExpiry else { return false }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: next).day ?? 0
        return days < 60
    }

    private var exportText: String {
        let head = "Name,Branch,Dan,Experience,Status,Score\n"
        let rows = allIntels.map { i -> String in
            let status = NSLocalizedString(i.coach.employmentStatus.labelKey, comment: "")
            return "\(i.coach.fullName),\(i.branchName),\(i.coach.danRank),"
                + "\(i.experienceYears),\(status),\(String(format: "%.1f", i.composite))"
        }
        return head + rows.joined(separator: "\n")
    }

    private func load() async {
        do {
            coaches = try await session.repository.coaches()
            let bs = try await session.repository.branches()
            branchNames = Dictionary(uniqueKeysWithValues: bs.map { ($0.id, $0.name) })
            let athletes = try await session.repository.athletes()
            var counts: [EntityID: Int] = [:]
            for a in athletes {
                if let cid = a.primaryCoachID { counts[cid, default: 0] += 1 }
            }
            athleteCountByCoach = counts
        } catch {
            print("CoachListView.load:", error)
        }
        if selectedID == nil, isWide {
            selectedID = filteredIntels.first?.id
        }
        loaded = true
    }
}

// MARK: - Filter

enum CoachFilter: String, CaseIterable, Hashable {
    case all, head, assistant, elite, active, onLeave, competition

    var labelKey: String { "coach.filter.\(rawValue)" }

    func matches(_ intel: CoachIntel) -> Bool {
        switch self {
        case .all:         return true
        case .head:        return intel.isHeadCoach
        case .assistant:   return !intel.isHeadCoach
        case .elite:       return intel.isElite
        case .active:      return !intel.onLeave && intel.coach.employmentStatus == .active
        case .onLeave:     return intel.onLeave
        case .competition: return intel.coach.nationalTeamStatus != .none
        }
    }
}
