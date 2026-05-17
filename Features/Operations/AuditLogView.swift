import SwiftUI

/// Premium audit-log dashboard — Developer-only. A stat-card summary band,
/// category filter chips, and a paginated activity table (Activity / User /
/// Module / IP / Date) that collapses to stacked cards on iPhone.
public struct AuditLogView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.horizontalSizeClass) private var hSize

    @State private var store: AuditStore?
    @State private var selectedActor: EntityID?
    @State private var moduleFilter: String?
    @State private var sinceDate: Date = Date().addingTimeInterval(-30 * 24 * 3600)
    @State private var category: AuditCategory = .all
    @State private var activityType: ActivityType = .all
    @State private var search = ""
    @State private var rowsPerPage = 10
    @State private var page = 0
    @State private var users: [User] = []

    public init() {}

    /// Gated on the `viewAuditLog` permission, which `PermissionMatrix`
    /// grants to the Developer role only — activity history, auth events,
    /// and system actions are exposed to no other role.
    private var canViewAuditLog: Bool {
        session.can(.viewAuditLog)
    }

    private var isWide: Bool { hSize == .regular }

    public var body: some View {
        Group {
            if canViewAuditLog {
                if let store {
                    content(store: store)
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                restrictedAccessView
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .task {
            // Defense in depth: never fetch audit records or user lists for
            // a non-developer, even if this view is somehow instantiated.
            guard canViewAuditLog else { return }
            if store == nil { store = AuditStore(repository: session.repository) }
            users = (try? await session.repository.availableUsers()) ?? []
            await reload()
        }
    }

    private var restrictedAccessView: some View {
        VStack(spacing: 12) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 52, weight: .regular))
                .foregroundStyle(.secondary)
            Text("audit.restricted.title")
                .scaledFont(.title3, weight: .bold)
            Text("audit.restricted.message")
                .scaledFont(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: 420)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Content

    @ViewBuilder
    private func content(store: AuditStore) -> some View {
        ScrollView {
            VStack(spacing: 18) {
                header(store: store)
                statBand(store: store)
                filterBar(store: store)
                categoryChips
                tableCard(store: store)
            }
            .padding(.horizontal, isWide ? 22 : 14)
            .padding(.top, 14)
            .padding(.bottom, 28)
            .frame(maxWidth: 1240)
            .frame(maxWidth: .infinity)
        }
        .onChange(of: category) { _, _ in page = 0 }
        .onChange(of: activityType) { _, _ in page = 0 }
        .onChange(of: search) { _, _ in page = 0 }
        .onChange(of: rowsPerPage) { _, _ in page = 0 }
        .onChange(of: moduleFilter) { _, _ in page = 0 }
    }

    // MARK: - Header

    private func header(store: AuditStore) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("audit.title").scaledFont(.title2, weight: .bold)
                Text("audit.subtitle")
                    .scaledFont(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            if isWide {
                searchField.frame(maxWidth: 240)
            }
            NotificationBellButton()
        }
    }

    private var searchField: some View {
        HStack(spacing: 7) {
            Image(systemName: "magnifyingglass")
                .scaledFont(.footnote, weight: .medium)
                .foregroundStyle(.secondary)
            TextField(text: $search) { Text("audit.search") }
                .textFieldStyle(.plain)
            if !search.isEmpty {
                Button { search = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .scaledFont(.footnote)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 8)
        .background(Color.cardBackground, in: Capsule())
        .overlay(Capsule().stroke(Color.secondary.opacity(0.14), lineWidth: 1))
    }

    // MARK: - Stat band

    private func statBand(store: AuditStore) -> some View {
        let all = store.entries
        let columns = isWide
            ? [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
            : [GridItem(.flexible()), GridItem(.flexible())]
        return LazyVGrid(columns: columns, spacing: 12) {
            AuditStatCard(
                titleKey: "audit.stat.all", icon: "chart.bar.xaxis", tint: .accentColor,
                count: all.count, delta: weekDelta(all)
            )
            AuditStatCard(
                titleKey: "audit.stat.users", icon: "person.2.fill", tint: .secondaryAccent,
                count: Set(all.map(\.actorUserID)).count, delta: nil
            )
            AuditStatCard(
                titleKey: "audit.stat.security", icon: "lock.shield.fill", tint: .purple,
                count: all.filter { AuditCategory.of($0) == .security }.count,
                delta: weekDelta(all.filter { AuditCategory.of($0) == .security })
            )
            AuditStatCard(
                titleKey: "audit.stat.data", icon: "arrow.triangle.2.circlepath", tint: .orange,
                count: all.filter { AuditCategory.of($0) == .dataChanges }.count,
                delta: weekDelta(all.filter { AuditCategory.of($0) == .dataChanges })
            )
        }
    }

    /// Real 7-day-over-7-day percentage change, or nil when there's no prior
    /// week to compare against.
    private func weekDelta(_ entries: [AuditEntry]) -> Int? {
        let now = Date()
        let weekAgo = now.addingTimeInterval(-7 * 86400)
        let twoWeeks = now.addingTimeInterval(-14 * 86400)
        let recent = entries.filter { $0.at >= weekAgo }.count
        let prior = entries.filter { $0.at >= twoWeeks && $0.at < weekAgo }.count
        guard prior > 0 else { return recent > 0 ? 100 : nil }
        return Int((Double(recent - prior) / Double(prior) * 100).rounded())
    }

    // MARK: - Filter bar

    private func filterBar(store: AuditStore) -> some View {
        let modules = Array(Set(store.entries.map(\.targetEntity))).sorted()
        return ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) { filterControls(modules: modules) }
            VStack(spacing: 10) { filterControls(modules: modules) }
        }
    }

    @ViewBuilder
    private func filterControls(modules: [String]) -> some View {
        FilterMenu(icon: "bolt.horizontal.circle", label: NSLocalizedString(activityType.key, comment: "")) {
            ForEach(ActivityType.allCases) { type in
                Button { activityType = type } label: { Text(LocalizedStringKey(type.key)) }
            }
        }
        FilterMenu(icon: "person.crop.circle", label: actorName) {
            Button { selectActor(nil) } label: { Text("filter.all") }
            ForEach(users) { user in
                Button { selectActor(user.id) } label: { Text(verbatim: user.fullName) }
            }
        }
        FilterMenu(icon: "square.grid.2x2", label: moduleName) {
            Button { moduleFilter = nil } label: { Text("filter.all") }
            ForEach(modules, id: \.self) { module in
                Button { moduleFilter = module } label: { Text(verbatim: module.capitalized) }
            }
        }
        DatePicker("", selection: $sinceDate, in: ...Date(), displayedComponents: .date)
            .labelsHidden()
            .onChange(of: sinceDate) { _, _ in Task { await reload() } }
        if !isWide { searchField }
        Spacer(minLength: 0)
        ExportButton(baseFilename: "audit-log", csvProvider: csvData)
    }

    private var actorName: String {
        guard let id = selectedActor, let u = users.first(where: { $0.id == id }) else {
            return NSLocalizedString("audit.filter.user", comment: "")
        }
        return u.fullName
    }

    private var moduleName: String {
        moduleFilter?.capitalized ?? NSLocalizedString("audit.filter.module", comment: "")
    }

    private func selectActor(_ id: EntityID?) {
        selectedActor = id
        page = 0
        Task { await reload() }
    }

    // MARK: - Category chips

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(AuditCategory.allCases) { cat in
                    AuditCategoryChip(
                        category: cat,
                        isSelected: category == cat,
                        action: { withAnimation(.easeInOut(duration: 0.18)) { category = cat } }
                    )
                }
            }
            .padding(.horizontal, 2)
        }
    }

    // MARK: - Table

    private func tableCard(store: AuditStore) -> some View {
        let rows = visibleEntries(store)
        let total = filteredEntries(store).count
        return VStack(spacing: 0) {
            if isWide {
                AuditTableHeader()
                Divider().opacity(0.5)
            }
            if rows.isEmpty {
                EmptyStateCard(
                    icon: "list.bullet.rectangle",
                    titleKey: "audit.empty.title",
                    messageKey: "audit.empty.message"
                )
                .padding(.vertical, 18)
            } else {
                ForEach(Array(rows.enumerated()), id: \.element.id) { index, entry in
                    if index > 0 { Divider().opacity(0.4) }
                    AuditRowView(
                        entry: entry,
                        user: store.userLookup[entry.actorUserID],
                        isWide: isWide
                    )
                }
            }
            if total > 0 {
                Divider().opacity(0.5)
                paginationFooter(total: total)
            }
        }
        .padding(isWide ? 14 : 12)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.secondary.opacity(0.10), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 14, y: 6)
    }

    private func paginationFooter(total: Int) -> some View {
        let pageCount = max(1, Int(ceil(Double(total) / Double(rowsPerPage))))
        let lower = total == 0 ? 0 : page * rowsPerPage + 1
        let upper = min(total, (page + 1) * rowsPerPage)
        return ViewThatFits(in: .horizontal) {
            HStack(spacing: 14) { footerControls(total: total, pageCount: pageCount, lower: lower, upper: upper) }
            VStack(spacing: 10) { footerControls(total: total, pageCount: pageCount, lower: lower, upper: upper) }
        }
        .padding(.top, 12)
    }

    @ViewBuilder
    private func footerControls(total: Int, pageCount: Int, lower: Int, upper: Int) -> some View {
        RowsPerPageMenu(rowsPerPage: $rowsPerPage)

        Text(verbatim: String(format: NSLocalizedString("audit.showing.fmt", comment: ""), lower, upper, total))
            .scaledFont(.caption)
            .foregroundStyle(.secondary)

        Spacer(minLength: 0)

        HStack(spacing: 6) {
            pagerButton(icon: "chevron.left", enabled: page > 0) { page -= 1 }
            ForEach(Array(pageNumbers(pageCount).enumerated()), id: \.offset) { _, item in
                if let p = item {
                    pageNumberButton(p)
                } else {
                    Text(verbatim: "…")
                        .scaledFont(.caption, weight: .semibold)
                        .foregroundStyle(.secondary)
                        .frame(width: 18)
                }
            }
            pagerButton(icon: "chevron.right", enabled: page + 1 < pageCount) { page += 1 }
        }
    }

    /// Page indices to display — collapses long runs with `nil` ellipsis
    /// markers so the control stays compact.
    private func pageNumbers(_ pageCount: Int) -> [Int?] {
        if pageCount <= 7 { return (0..<pageCount).map { Optional($0) } }
        var result: [Int?] = [0]
        let lower = max(1, page - 1)
        let upper = min(pageCount - 2, page + 1)
        if lower > 1 { result.append(nil) }
        for p in lower...upper { result.append(p) }
        if upper < pageCount - 2 { result.append(nil) }
        result.append(pageCount - 1)
        return result
    }

    private func pageNumberButton(_ p: Int) -> some View {
        Button { page = p } label: {
            Text(verbatim: "\(p + 1)")
                .scaledFont(.caption, weight: .semibold)
                .monospacedDigit()
                .frame(width: 30, height: 30)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(p == page ? Color.accentColor : Color.secondary.opacity(0.10))
                )
                .foregroundStyle(p == page ? Color.white : Color.primary)
        }
        .buttonStyle(.plain)
    }

    private func pagerButton(icon: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .scaledFont(.caption, weight: .semibold)
                .frame(width: 30, height: 30)
                .background(Color.secondary.opacity(0.10), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.4)
    }

    // MARK: - Filtering

    private func filteredEntries(_ store: AuditStore) -> [AuditEntry] {
        store.entries.filter { entry in
            if category != .all, AuditCategory.of(entry) != category { return false }
            if !activityType.matches(entry) { return false }
            if let moduleFilter, entry.targetEntity != moduleFilter { return false }
            if !search.isEmpty {
                let needle = search.lowercased()
                let userName = store.userLookup[entry.actorUserID]?.fullName.lowercased() ?? ""
                let hay = "\(entry.action) \(entry.targetEntity) \(userName)".lowercased()
                if !hay.contains(needle) { return false }
            }
            return true
        }
        .sorted { $0.at > $1.at }
    }

    private func visibleEntries(_ store: AuditStore) -> [AuditEntry] {
        let all = filteredEntries(store)
        guard !all.isEmpty else { return [] }
        let start = min(page * rowsPerPage, max(0, all.count - 1))
        let end = min(start + rowsPerPage, all.count)
        return Array(all[start..<end])
    }

    private func csvData() -> Data {
        guard let store else { return Data() }
        var lines = ["Activity,User,Module,IP Address,Date"]
        let fmt = ISO8601DateFormatter()
        for e in filteredEntries(store) {
            let user = store.userLookup[e.actorUserID]?.fullName ?? "—"
            let ip = e.changes["ip"] ?? ""
            func esc(_ s: String) -> String { "\"\(s.replacingOccurrences(of: "\"", with: "\"\""))\"" }
            lines.append([e.action, user, e.targetEntity, ip, fmt.string(from: e.at)].map(esc).joined(separator: ","))
        }
        return Data(lines.joined(separator: "\n").utf8)
    }

    private func reload() async {
        store?.actorFilter = selectedActor
        store?.sinceFilter = sinceDate
        await store?.load()
    }
}

// MARK: - Category

private enum AuditCategory: String, CaseIterable, Identifiable {
    case all, userActions, dataChanges, security, system, announcements

    var id: String { rawValue }

    var labelKey: LocalizedStringKey {
        switch self {
        case .all:           "audit.cat.all"
        case .userActions:   "audit.cat.user"
        case .dataChanges:   "audit.cat.data"
        case .security:      "audit.cat.security"
        case .system:        "audit.cat.system"
        case .announcements: "audit.cat.announcements"
        }
    }

    var icon: String {
        switch self {
        case .all:           "square.grid.2x2.fill"
        case .userActions:   "person.fill"
        case .dataChanges:   "arrow.triangle.2.circlepath"
        case .security:      "lock.shield.fill"
        case .system:        "gearshape.fill"
        case .announcements: "megaphone.fill"
        }
    }

    var tint: Color {
        switch self {
        case .all:           .accentColor
        case .userActions:   .secondaryAccent
        case .dataChanges:   .orange
        case .security:      .purple
        case .system:        .secondary
        case .announcements: .accentColor
        }
    }

    /// Classifies an entry into its primary category from the action code
    /// and target entity.
    static func of(_ entry: AuditEntry) -> AuditCategory {
        let a = entry.action.lowercased()
        let t = entry.targetEntity.lowercased()
        if a.contains("auth") || a.contains("signin") || a.contains("login")
            || a.contains("password") || a.contains("security") {
            return .security
        }
        if t.contains("announcement") { return .announcements }
        if a.contains("create") || a.contains("update") || a.contains("delete")
            || a.contains("upsert") || a.contains("edit") || a.contains("issue") {
            return .dataChanges
        }
        if a.contains("system") || a.contains("sync") || a.contains("backup") {
            return .system
        }
        return .userActions
    }
}

// MARK: - Activity type filter

private enum ActivityType: String, CaseIterable, Identifiable {
    case all, created, updated, deleted, viewed

    var id: String { rawValue }

    /// Localization key — doubles as the menu-label lookup and the menu-item
    /// title so there's a single source of truth.
    var key: String {
        switch self {
        case .all:     "audit.filter.activity_type"
        case .created: "audit.type.created"
        case .updated: "audit.type.updated"
        case .deleted: "audit.type.deleted"
        case .viewed:  "audit.type.viewed"
        }
    }

    func matches(_ entry: AuditEntry) -> Bool {
        guard self != .all else { return true }
        let a = entry.action.lowercased()
        switch self {
        case .all:     return true
        case .created: return a.contains("create") || a.contains("add") || a.contains("issue") || a.contains("signin")
        case .updated: return a.contains("update") || a.contains("edit") || a.contains("upsert")
        case .deleted: return a.contains("delete") || a.contains("remove")
        case .viewed:  return a.contains("view") || a.contains("export") || a.contains("read")
        }
    }
}

// MARK: - Notification bell

private struct NotificationBellButton: View {
    var body: some View {
        NavigationLink {
            NotificationsCenterView()
        } label: {
            Image(systemName: "bell.fill")
                .scaledFont(.footnote, weight: .semibold)
                .foregroundStyle(.secondary)
                .frame(width: 36, height: 36)
                .background(Color.cardBackground, in: Circle())
                .overlay(Circle().stroke(Color.secondary.opacity(0.14), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("audit.notifications"))
    }
}

// MARK: - Stat card

private struct AuditStatCard: View {
    let titleKey: LocalizedStringKey
    let icon: String
    let tint: Color
    let count: Int
    let delta: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .scaledFont(.subheadline, weight: .semibold)
                    .foregroundStyle(tint)
                    .frame(width: 34, height: 34)
                    .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                Spacer(minLength: 0)
            }
            Text(verbatim: count.formatted())
                .scaledFont(.title, weight: .bold)
                .monospacedDigit()
                .environment(\.layoutDirection, .leftToRight)
            HStack(spacing: 4) {
                Text(titleKey)
                    .scaledFont(.caption)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
            }
            if let delta {
                HStack(spacing: 3) {
                    Image(systemName: delta >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .scaledFont(.caption2, weight: .bold)
                    Text(verbatim: "\(abs(delta))%")
                        .scaledFont(.caption2, weight: .semibold)
                        .environment(\.layoutDirection, .leftToRight)
                    Text("audit.trend.week")
                        .scaledFont(.caption2)
                        .foregroundStyle(.secondary)
                }
                .foregroundStyle(delta >= 0 ? Color.secondaryAccent : Color.orange)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(tint.opacity(0.08))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(tint.opacity(0.16), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 10, y: 4)
    }
}

// MARK: - Category chip

private struct AuditCategoryChip: View {
    let category: AuditCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.icon).scaledFont(.caption2, weight: .semibold)
                Text(category.labelKey).scaledFont(.caption, weight: .semibold)
            }
            .padding(.horizontal, 13)
            .padding(.vertical, 8)
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .background(
                Capsule().fill(isSelected ? category.tint : Color.secondary.opacity(0.10))
            )
            .overlay(
                Capsule().stroke(
                    isSelected ? Color.clear : Color.secondary.opacity(0.12), lineWidth: 1
                )
            )
            .shadow(color: isSelected ? category.tint.opacity(0.3) : .clear, radius: 6, y: 3)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Filter menu

private struct FilterMenu<MenuItems: View>: View {
    let icon: String
    let label: String
    @ViewBuilder var menuItems: MenuItems

    var body: some View {
        Menu {
            menuItems
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon).scaledFont(.caption, weight: .medium)
                Text(verbatim: label)
                    .scaledFont(.caption, weight: .medium)
                    .lineLimit(1)
                Image(systemName: "chevron.down").scaledFont(.caption2)
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 8)
            .background(Color.cardBackground, in: Capsule())
            .overlay(Capsule().stroke(Color.secondary.opacity(0.14), lineWidth: 1))
            .foregroundStyle(.primary)
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .menuIndicator(.hidden)
        .fixedSize()
    }
}

// MARK: - Table header

private struct AuditTableHeader: View {
    var body: some View {
        HStack(spacing: 12) {
            Text("audit.col.activity")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("audit.col.user").frame(width: 168, alignment: .leading)
            Text("audit.col.module").frame(width: 124, alignment: .leading)
            Text("audit.col.ip").frame(width: 116, alignment: .leading)
            Text("audit.col.datetime").frame(width: 146, alignment: .leading)
            Spacer().frame(width: 20)
        }
        .scaledFont(.caption2, weight: .semibold)
        .foregroundStyle(.secondary)
        .textCase(.uppercase)
        .padding(.horizontal, 6)
        .padding(.vertical, 8)
    }
}

// MARK: - Row

private struct AuditRowView: View {
    let entry: AuditEntry
    let user: User?
    let isWide: Bool

    private var category: AuditCategory { AuditCategory.of(entry) }

    private var verb: String {
        if let dot = entry.action.firstIndex(of: ".") {
            return String(entry.action[entry.action.index(after: dot)...])
                .replacingOccurrences(of: "_", with: " ").capitalized
        }
        return entry.action.replacingOccurrences(of: "_", with: " ").capitalized
    }

    private var ipText: String { entry.changes["ip"] ?? "—" }

    var body: some View {
        if isWide { wideRow } else { compactRow }
    }

    private var activityCell: some View {
        HStack(spacing: 10) {
            Image(systemName: category.icon)
                .scaledFont(.footnote, weight: .semibold)
                .foregroundStyle(category.tint)
                .frame(width: 36, height: 36)
                .background(category.tint.opacity(0.14), in: Circle())
            VStack(alignment: .leading, spacing: 1) {
                Text(verbatim: verb)
                    .scaledFont(.subheadline, weight: .semibold)
                    .lineLimit(1)
                Text(verbatim: detailLine)
                    .scaledFont(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }

    private var detailLine: String {
        if !entry.changes.isEmpty {
            return entry.changes.map { "\($0.key): \($0.value)" }.sorted().joined(separator: " · ")
        }
        return entry.targetEntity.capitalized
    }

    private var userCell: some View {
        HStack(spacing: 8) {
            if let user {
                Avatar(seed: user.avatarSeed, label: initials(user.fullName), size: 30)
            } else {
                ZStack {
                    Circle().fill(Color.secondary.opacity(0.18))
                    Image(systemName: "questionmark").scaledFont(.caption2, weight: .semibold)
                        .foregroundStyle(.secondary)
                }
                .frame(width: 30, height: 30)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(verbatim: user?.fullName ?? NSLocalizedString("audit.unknown_actor", comment: ""))
                    .scaledFont(.caption, weight: .semibold)
                    .lineLimit(1)
                if let user {
                    Text(localizedKey: user.role.label)
                        .scaledFont(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
    }

    private var modulePill: some View {
        Text(verbatim: entry.targetEntity.capitalized)
            .scaledFont(.caption2, weight: .semibold)
            .lineLimit(1)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(category.tint.opacity(0.14), in: Capsule())
            .foregroundStyle(category.tint)
    }

    private var dateText: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(entry.at, format: .dateTime.day().month(.abbreviated).year())
                .scaledFont(.caption, weight: .medium)
            Text(entry.at, format: .relative(presentation: .named))
                .scaledFont(.caption2)
                .foregroundStyle(.secondary)
        }
        .environment(\.layoutDirection, .leftToRight)
    }

    private var wideRow: some View {
        HStack(spacing: 12) {
            activityCell.frame(maxWidth: .infinity, alignment: .leading)
            userCell.frame(width: 168, alignment: .leading)
            HStack { modulePill; Spacer(minLength: 0) }.frame(width: 124)
            Text(verbatim: ipText)
                .scaledFont(.caption2, design: .monospaced)
                .foregroundStyle(.secondary)
                .frame(width: 116, alignment: .leading)
                .environment(\.layoutDirection, .leftToRight)
            dateText.frame(width: 146, alignment: .leading)
            Image(systemName: "ellipsis")
                .scaledFont(.caption, weight: .semibold)
                .foregroundStyle(.secondary)
                .frame(width: 20)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 10)
    }

    private var compactRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            activityCell
            HStack(spacing: 8) {
                userCell
                Spacer(minLength: 0)
                modulePill
            }
            HStack(spacing: 6) {
                Image(systemName: "clock").scaledFont(.caption2).foregroundStyle(.secondary)
                Text(entry.at, format: .dateTime.day().month(.abbreviated).hour().minute())
                    .scaledFont(.caption2)
                    .foregroundStyle(.secondary)
                    .environment(\.layoutDirection, .leftToRight)
                if ipText != "—" {
                    Text(verbatim: "· \(ipText)")
                        .scaledFont(.caption2, design: .monospaced)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 10)
    }

    private func initials(_ name: String) -> String {
        name.split(separator: " ").prefix(2).map { String($0.prefix(1)) }.joined().uppercased()
    }
}
