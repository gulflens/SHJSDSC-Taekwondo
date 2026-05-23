import SwiftUI

public enum AthleteListScope: Sendable, Hashable {
    case all
    case byBranch(EntityID)
    case myAthletes(coachID: EntityID)
}

// MARK: - Athletes
//
// Stage 1.12 — premium athlete management dashboard. Header + executive
// analytics cards + filter pills + an adaptive two-panel workspace (athlete
// performance cards + a preview panel on iPad; list with a pushed full
// profile on iPhone).

public struct AthleteListView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.horizontalSizeClass) private var hSize

    @State private var store: AthletesStore?
    @State private var branchNames: [EntityID: String] = [:]
    @State private var query = ""
    @State private var filter: AthleteFilter = .all
    @State private var branchFilter: EntityID?
    @State private var selectedID: EntityID?
    @State private var page = 0
    @State private var showingAdd = false
    @State private var showingImport = false
    @State private var selectedAthleteForProfile: Athlete?

    public let scope: AthleteListScope
    @State private var rowsPerPage = 10

    public init(scope: AthleteListScope) {
        self.scope = scope
    }

    private var isWide: Bool { hSize == .regular }

    public var body: some View {
        VStack(spacing: 0) {
            header
            if let store {
                if store.isLoading && store.athletes.isEmpty {
                    Spacer(); ProgressView(); Spacer()
                } else {
                    content
                }
            } else {
                Spacer(); ProgressView(); Spacer()
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .task {
            if store == nil { store = AthletesStore(repository: session.repository) }
            await reload()
        }
        .onChange(of: query) { _, _ in page = 0 }
        .onChange(of: filter) { _, _ in page = 0 }
        .onChange(of: branchFilter) { _, _ in page = 0 }
        .onChange(of: rowsPerPage) { _, _ in page = 0 }
        .navigationDestination(isPresented: $showingAdd) {
            AddAthleteView(initialBranchID: scopeBranchID()) { newAthlete in
                store?.insertOrUpdate(newAthlete)
                Task { await reload() }
            }
        }
        .navigationDestination(isPresented: $showingImport) {
            AthleteImportView { Task { await reload() } }
        }
        .navigationDestination(isPresented: profileLinkBinding) {
            if let a = selectedAthleteForProfile { AthleteDetailView(athlete: a) }
        }
    }

    // MARK: Header

    private var header: some View {
        Group {
            if isWide {
                HStack(alignment: .center, spacing: 12) {
                    titleBlock
                    Spacer(minLength: 8)
                    SearchAthleteField(text: $query).frame(maxWidth: 240)
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
                        SearchAthleteField(text: $query)
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
            Text("athlete.dashboard.title").scaledFont(.title2, weight: .bold)
            Text("athlete.dashboard.subtitle")
                .scaledFont(.caption).foregroundStyle(.secondary)
        }
    }

    private var filterButton: some View {
        Menu {
            Picker("athlete.filter.branch", selection: $branchFilter) {
                Text("athlete.filter.all_branches").tag(EntityID?.none)
                ForEach(branchNames.sorted { $0.value < $1.value }, id: \.key) { id, name in
                    Text(verbatim: name).tag(EntityID?.some(id))
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "line.3.horizontal.decrease").scaledFont(.caption, weight: .semibold)
                Text("athlete.filter").scaledFont(.subheadline, weight: .semibold)
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
                Text("athlete.export").scaledFont(.subheadline, weight: .semibold)
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
                Text("athlete.add").scaledFont(.subheadline, weight: .semibold)
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
        // The list+detail split is a macOS-only layout (usesSplitDetailLayout());
        // on iPhone and iPad — every orientation — the list fills the width and a tapped row pushes a detail screen.
        GeometryReader { _ in
            let split = usesSplitDetailLayout()
            VStack(spacing: 14) {
                analyticsRow
                filterPills
                if split {
                    GeometryReader { geo in
                        let gap: CGFloat = 16
                        let w = max(0, geo.size.width - gap)
                        HStack(alignment: .top, spacing: gap) {
                            listPanel(split: true).frame(width: w * 0.62)
                            detailColumn.frame(width: w * 0.38)
                        }
                    }
                } else {
                    listPanel(split: false)
                }
            }
            .padding(.horizontal, isWide ? 22 : 14)
            .padding(.top, 4)
            .padding(.bottom, 14)
        }
    }

    // MARK: Executive analytics

    private var analyticsRow: some View {
        let all = allIntels
        let cols = isWide
            ? Array(repeating: GridItem(.flexible(), spacing: 12), count: 6)
            : [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
        let attendanceHealth = all.isEmpty ? 0
            : all.reduce(0.0) { $0 + $1.metric(.attendance) } / Double(all.count)
        return LazyVGrid(columns: cols, spacing: 12) {
            ExecutiveAnalyticsCard(titleKey: "athlete.kpi.total", systemIcon: "person.3.fill",
                                   tint: .accentColor, value: "\(all.count)",
                                   spark: spark(1, true), deltaPct: 8.6)
            ExecutiveAnalyticsCard(titleKey: "athlete.kpi.competition", systemIcon: "trophy.fill",
                                   tint: .red,
                                   value: "\(all.filter { $0.athlete.status == .competitionTeam }.count)",
                                   spark: spark(2, true), deltaPct: 12.5)
            ExecutiveAnalyticsCard(titleKey: "athlete.kpi.grading", systemIcon: "checkmark.seal.fill",
                                   tint: .secondaryAccent,
                                   value: "\(all.filter { $0.athlete.status == .readyToGrade }.count)",
                                   spark: spark(3, true), deltaPct: 15.3)
            ExecutiveAnalyticsCard(titleKey: "athlete.kpi.injury", systemIcon: "cross.case.fill",
                                   tint: .orange,
                                   value: "\(all.filter { $0.athlete.status == .watch }.count)",
                                   spark: spark(4, false), deltaPct: -11.1)
            ExecutiveAnalyticsCard(titleKey: "athlete.kpi.elite", systemIcon: "star.fill",
                                   tint: .purple, value: "\(all.filter(\.isElite).count)",
                                   spark: spark(5, true), deltaPct: 20.0)
            ExecutiveAnalyticsCard(titleKey: "athlete.kpi.attendance", systemIcon: "shield.lefthalf.filled",
                                   tint: .cyan, value: "\(Int(attendanceHealth.rounded()))%",
                                   spark: spark(6, true), deltaPct: 5.4)
        }
    }

    private func spark(_ seed: Int, _ rising: Bool) -> [Double] {
        (0..<12).map { i in
            let t = Double(i) / 11.0
            return 50 + (rising ? 1 : -1) * t * 26 + sin(Double(i) * 1.7 + Double(seed)) * 7
        }
    }

    // MARK: Filter pills

    private var filterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 7) {
                ForEach(AthleteFilter.allCases, id: \.self) { f in
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

    // MARK: List panel

    private func listPanel(split: Bool) -> some View {
        VStack(spacing: 0) {
            if filteredIntels.isEmpty {
                EmptyStateCard(icon: "person.crop.circle.badge.questionmark",
                               titleKey: "athlete.empty.title",
                               messageKey: "athlete.empty.message")
                    .padding(16)
                Spacer(minLength: 0)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(pageSlice) { intel in
                            athleteRow(intel, split: split)
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
    private func athleteRow(_ intel: AthleteIntel, split: Bool) -> some View {
        if split {
            Button {
                withAnimation(.easeInOut(duration: 0.18)) { selectedID = intel.id }
            } label: {
                AthletePerformanceCard(intel: intel, selected: selectedID == intel.id)
            }
            .buttonStyle(.plain)
        } else {
            NavigationLink {
                AthleteDetailView(athlete: intel.athlete)
            } label: {
                AthletePerformanceCard(intel: intel, selected: false)
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
            Text(verbatim: String(format: NSLocalizedString("athlete.showing.fmt", comment: ""),
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
            AthletePreviewPanel(intel: intel) {
                selectedAthleteForProfile = intel.athlete
            }
        } else {
            VStack(spacing: 12) {
                Image(systemName: "person.crop.square.badge.magnifyingglass")
                    .font(.system(size: 38)).foregroundStyle(.tertiary)
                Text("athlete.detail.empty")
                    .scaledFont(.subheadline).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 320)
            .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.secondary.opacity(0.10), lineWidth: 1))
        }
    }

    private var profileLinkBinding: Binding<Bool> {
        Binding(get: { selectedAthleteForProfile != nil },
                set: { if !$0 { selectedAthleteForProfile = nil } })
    }

    // MARK: Data

    private var canEdit: Bool {
        guard let role = session.currentUser?.role else { return false }
        return PermissionMatrix.allowed(role: role, permission: .editAthlete)
    }

    private var allIntels: [AthleteIntel] {
        guard let store else { return [] }
        return store.athletes.map { athlete in
            AthleteIntel.make(athlete: athlete,
                              score: store.scoreByAthlete[athlete.id],
                              branchName: branchNames[athlete.branchID]
                                ?? NSLocalizedString("admin.no_branch", comment: ""))
        }
    }

    private var filteredIntels: [AthleteIntel] {
        var out = allIntels
        if let branchFilter { out = out.filter { $0.athlete.branchID == branchFilter } }
        out = out.filter { filter.matches($0) }
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        if !q.isEmpty {
            out = out.filter {
                $0.athlete.fullName.lowercased().contains(q)
                    || $0.athlete.fullNameAr.contains(query)
                    || $0.branchName.lowercased().contains(q)
            }
        }
        return out.sorted { $0.composite > $1.composite }
    }

    private var pageCount: Int {
        max(1, Int(ceil(Double(filteredIntels.count) / Double(rowsPerPage))))
    }

    private var pageSlice: [AthleteIntel] {
        let all = filteredIntels
        guard !all.isEmpty else { return [] }
        let safe = min(page, pageCount - 1)
        let start = safe * rowsPerPage
        return Array(all[start..<min(start + rowsPerPage, all.count)])
    }

    private var selectedIntel: AthleteIntel? {
        guard let id = selectedID else { return nil }
        return allIntels.first { $0.id == id }
    }

    private var exportText: String {
        let head = "Name,Belt,Age Group,Branch,Status,Score\n"
        let rows = allIntels.map { i -> String in
            let belt = NSLocalizedString(i.athlete.currentBelt.label, comment: "")
            let age = NSLocalizedString(i.ageGroup.labelKey, comment: "")
            let status = NSLocalizedString(i.athlete.status.labelKey, comment: "")
            return "\(i.athlete.fullName),\(belt),\(age),\(i.branchName),\(status),\(String(format: "%.1f", i.composite))"
        }
        return head + rows.joined(separator: "\n")
    }

    private func scopeBranchID() -> EntityID? {
        if case .byBranch(let id) = scope { return id }
        return session.currentUser?.primaryBranchID
    }

    private func reload() async {
        guard let store else { return }
        switch scope {
        case .all:                 await store.loadAll()
        case .byBranch(let bid):   await store.load(branchID: bid)
        case .myAthletes(let cid): await store.loadForCoach(cid)
        }
        do {
            let branches = try await session.repository.branches()
            branchNames = Dictionary(uniqueKeysWithValues: branches.map { ($0.id, $0.name) })
        } catch {
            print("AthleteListView.reload:", error)
        }
        if selectedID == nil, isWide {
            selectedID = filteredIntels.first?.id
        }
    }
}

// MARK: - Filter

enum AthleteFilter: String, CaseIterable, Hashable {
    case all, competitionTeam, elite, readyToGrade, cadets, juniors, kids, inactive

    var labelKey: String { "athlete.filter.\(rawValue)" }

    func matches(_ intel: AthleteIntel) -> Bool {
        switch self {
        case .all:             return true
        case .competitionTeam: return intel.athlete.status == .competitionTeam
        case .elite:           return intel.isElite
        case .readyToGrade:    return intel.athlete.status == .readyToGrade
        case .cadets:          return intel.ageGroup == .cadets
        case .juniors:         return intel.ageGroup == .juniors
        case .kids:            return intel.ageGroup == .kids || intel.ageGroup == .cubs
        case .inactive:        return intel.athlete.status == .rest
        }
    }
}
