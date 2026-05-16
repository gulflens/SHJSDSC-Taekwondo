import SwiftUI

/// Users management console — the operational home for account management.
/// Header + 6 analytics cards + a create-account hero with role shortcuts +
/// role-group filter pills + a user table with a master-detail preview pane
/// (wide) or list→push detail (iPhone). Replaces the standalone Create
/// Account sidebar item.
public struct UsersConsoleView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.horizontalSizeClass) private var hSize

    @State private var users: [User] = []
    @State private var loading = true
    @State private var search = ""
    @State private var groupFilter: RoleGroup?
    @State private var selectedUser: User?
    @State private var rowsPerPage = 10
    @State private var page = 0
    @State private var showCreate = false
    @State private var createRole: Role = .coach
    /// Measured width of the table/detail split row — drives the 40/60 ratio.
    @State private var splitWidth: CGFloat = 0

    public init() {}

    private var isWide: Bool { hSize == .regular }

    public var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                header
                statBand
                createHeroCard
                filterPills
                mainArea
            }
            .padding(.horizontal, isWide ? 22 : 14)
            .padding(.top, 14)
            .padding(.bottom, 28)
            .frame(maxWidth: 1320)
            .frame(maxWidth: .infinity)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .task { await load() }
        .sheet(isPresented: $showCreate) {
            NavigationStack {
                AdminCreateAccountView(initialRole: createRole)
            }
            .onDisappear { Task { await load() } }
        }
        .onChange(of: search) { _, _ in page = 0 }
        .onChange(of: groupFilter) { _, _ in page = 0 }
        .onChange(of: rowsPerPage) { _, _ in page = 0 }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("users.title").scaledFont(.title2, weight: .bold)
                Text("users.subtitle").scaledFont(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            if isWide {
                searchField.frame(maxWidth: 220)
                Button { createRole = .coach; showCreate = true } label: {
                    Label("admin.create_account", systemImage: "person.badge.plus")
                        .scaledFont(.subheadline, weight: .semibold)
                        .padding(.horizontal, 14).padding(.vertical, 9)
                        .foregroundStyle(.white)
                        .background(
                            Capsule().fill(
                                LinearGradient(colors: [Color.accentColor, Color.accentColor.opacity(0.82)],
                                               startPoint: .top, endPoint: .bottom))
                        )
                        .shadow(color: Color.accentColor.opacity(0.32), radius: 9, y: 4)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: 7) {
            Image(systemName: "magnifyingglass").scaledFont(.footnote, weight: .medium).foregroundStyle(.secondary)
            TextField(text: $search) { Text("users.search") }.textFieldStyle(.plain)
            if !search.isEmpty {
                Button { search = "" } label: {
                    Image(systemName: "xmark.circle.fill").scaledFont(.footnote).foregroundStyle(.secondary)
                }.buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 11).padding(.vertical, 8)
        .background(Color.cardBackground, in: Capsule())
        .overlay(Capsule().stroke(Color.secondary.opacity(0.14), lineWidth: 1))
    }

    // MARK: - Stat band

    private var statBand: some View {
        let cols = isWide
            ? Array(repeating: GridItem(.flexible()), count: 6)
            : [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
        return LazyVGrid(columns: cols, spacing: 12) {
            stat("users.stat.total", "person.3.fill", .accentColor, users.count)
            stat("users.stat.admins", "shield.lefthalf.filled", .purple,
                 users.filter { $0.role.group == .system }.count)
            stat("users.stat.coaches", "figure.taekwondo", .secondaryAccent,
                 users.filter { $0.role.group == .coaching }.count)
            stat("users.stat.athletes", "figure.run", .orange,
                 users.filter { $0.role == .athlete }.count)
            stat("users.stat.parents", "figure.2.and.child.holdinghands", .cyan,
                 users.filter { $0.role == .parent }.count)
            stat("users.stat.staff", "briefcase.fill", .indigo,
                 users.filter { staffGroups.contains($0.role.group) }.count)
        }
    }

    private var staffGroups: Set<RoleGroup> {
        [.leadership, .support, .competition, .grading, .administration]
    }

    private func stat(_ titleKey: LocalizedStringKey, _ icon: String, _ tint: Color, _ count: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .scaledFont(.footnote, weight: .semibold)
                .foregroundStyle(tint)
                .frame(width: 32, height: 32)
                .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            Text(verbatim: count.formatted())
                .scaledFont(.title2, weight: .bold)
                .monospacedDigit()
                .environment(\.layoutDirection, .leftToRight)
            Text(titleKey).scaledFont(.caption2).foregroundStyle(.secondary)
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(Color.cardBackground)
                .overlay(RoundedRectangle(cornerRadius: 15, style: .continuous).fill(tint.opacity(0.07)))
        )
        .overlay(RoundedRectangle(cornerRadius: 15, style: .continuous).stroke(tint.opacity(0.15), lineWidth: 1))
        .shadow(color: .black.opacity(0.04), radius: 9, y: 4)
    }

    // MARK: - Create hero

    private var createHeroCard: some View {
        let shortcuts: [(LocalizedStringKey, Role)] = [
            ("users.shortcut.coach", .coach),
            ("users.shortcut.athlete", .athlete),
            ("users.shortcut.parent", .parent),
            ("users.shortcut.staff", .frontDesk),
        ]
        return VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: "person.crop.circle.badge.plus")
                    .scaledFont(.title2, weight: .semibold)
                    .foregroundStyle(.white)
                    .frame(width: 46, height: 46)
                    .background(
                        LinearGradient(colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text("users.create_hero.title").scaledFont(.headline)
                    Text("users.create_hero.subtitle").scaledFont(.caption).foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) { ForEach(shortcuts.indices, id: \.self) { shortcutButton(shortcuts[$0]) } }
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(shortcuts.indices, id: \.self) { shortcutButton(shortcuts[$0]) }
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(LinearGradient(colors: [Color.accentColor.opacity(0.10), Color.cardBackground],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
        )
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.secondary.opacity(0.10), lineWidth: 1))
        .shadow(color: .black.opacity(0.05), radius: 14, y: 6)
    }

    private func shortcutButton(_ shortcut: (LocalizedStringKey, Role)) -> some View {
        Button {
            createRole = shortcut.1
            showCreate = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: shortcut.1.icon).scaledFont(.footnote, weight: .semibold)
                Text(shortcut.0).scaledFont(.subheadline, weight: .semibold)
            }
            .foregroundStyle(Color.accentColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.accentColor.opacity(0.28), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Filter pills

    private var filterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                pill(nil, "users.filter.all")
                ForEach(RoleGroup.allCases, id: \.self) { group in
                    pill(group, LocalizedStringKey(group.labelKey))
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private func pill(_ group: RoleGroup?, _ label: LocalizedStringKey) -> some View {
        let selected = groupFilter == group
        return Button {
            withAnimation(.easeInOut(duration: 0.18)) { groupFilter = group }
        } label: {
            Text(label)
                .scaledFont(.caption, weight: .semibold)
                .padding(.horizontal, 13).padding(.vertical, 8)
                .foregroundStyle(selected ? Color.white : Color.primary)
                .background(Capsule().fill(selected ? Color.accentColor : Color.secondary.opacity(0.10)))
                .shadow(color: selected ? Color.accentColor.opacity(0.3) : .clear, radius: 6, y: 3)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Main area (table + detail)

    @ViewBuilder
    private var mainArea: some View {
        if isWide {
            HStack(alignment: .top, spacing: 18) {
                tableCard.frame(width: panelWidth(0.4))
                detailPane.frame(width: panelWidth(0.6))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                GeometryReader { geo in
                    Color.clear
                        .onAppear { splitWidth = geo.size.width }
                        .onChange(of: geo.size.width) { _, w in splitWidth = w }
                }
            )
        } else {
            tableCard
        }
    }

    /// 40 / 60 split of the available width, minus the 18 pt gap.
    private func panelWidth(_ fraction: CGFloat) -> CGFloat {
        max(0, splitWidth - 18) * fraction
    }

    private var tableCard: some View {
        let rows = pageSlice
        return VStack(spacing: 0) {
            if loading {
                ProgressView().frame(maxWidth: .infinity).padding(.vertical, 30)
            } else if rows.isEmpty {
                EmptyStateCard(icon: "person.crop.circle.badge.questionmark",
                               titleKey: "users.empty.title", messageKey: "users.empty.message")
                    .padding(.vertical, 16)
            } else {
                ForEach(Array(rows.enumerated()), id: \.element.id) { index, user in
                    if index > 0 { Divider().opacity(0.4) }
                    userRow(user)
                }
            }
            if !filtered.isEmpty {
                Divider().opacity(0.5)
                paginationFooter
            }
        }
        .padding(12)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.secondary.opacity(0.10), lineWidth: 1))
        .shadow(color: .black.opacity(0.05), radius: 14, y: 6)
    }

    @ViewBuilder
    private func userRow(_ user: User) -> some View {
        if isWide {
            Button { selectedUser = user } label: {
                UserRowContent(user: user, branchName: branchName(user), selected: selectedUser?.id == user.id)
            }
            .buttonStyle(.plain)
        } else {
            NavigationLink {
                UserDetailScreen(user: user, branchName: branchName(user))
            } label: {
                UserRowContent(user: user, branchName: branchName(user), selected: false)
            }
            .buttonStyle(.plain)
        }
    }

    private var paginationFooter: some View {
        let total = filtered.count
        let pageCount = max(1, Int(ceil(Double(total) / Double(rowsPerPage))))
        let lower = total == 0 ? 0 : page * rowsPerPage + 1
        let upper = min(total, (page + 1) * rowsPerPage)
        return HStack(spacing: 12) {
            Menu {
                ForEach([10, 25, 50], id: \.self) { n in
                    Button { rowsPerPage = n } label: { Text(verbatim: "\(n)") }
                }
            } label: {
                HStack(spacing: 5) {
                    Text("audit.rows_per_page").scaledFont(.caption).foregroundStyle(.secondary)
                    Text(verbatim: "\(rowsPerPage)").scaledFont(.caption, weight: .semibold)
                    Image(systemName: "chevron.up.chevron.down").scaledFont(.caption2).foregroundStyle(.secondary)
                }
            }
            .menuStyle(.button).buttonStyle(.plain).menuIndicator(.hidden)
            Text(verbatim: String(format: NSLocalizedString("audit.showing.fmt", comment: ""), lower, upper, total))
                .scaledFont(.caption).foregroundStyle(.secondary)
            Spacer(minLength: 0)
            HStack(spacing: 6) {
                pagerButton("chevron.left", page > 0) { page -= 1 }
                Text(verbatim: "\(page + 1) / \(pageCount)")
                    .scaledFont(.caption, weight: .semibold).monospacedDigit()
                pagerButton("chevron.right", page + 1 < pageCount) { page += 1 }
            }
        }
        .padding(.top, 12)
    }

    private func pagerButton(_ icon: String, _ enabled: Bool, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .scaledFont(.caption, weight: .semibold)
                .frame(width: 30, height: 30)
                .background(Color.secondary.opacity(0.10), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain).disabled(!enabled).opacity(enabled ? 1 : 0.4)
    }

    // MARK: - Detail pane (wide)

    @ViewBuilder
    private var detailPane: some View {
        if let user = selectedUser {
            UserDetailContent(user: user, branchName: branchName(user))
        } else {
            VStack(spacing: 10) {
                Image(systemName: "person.crop.square.badge.magnifyingglass")
                    .font(.system(size: 40))
                    .foregroundStyle(.tertiary)
                Text("users.detail.empty")
                    .scaledFont(.subheadline).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 50)
            .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.secondary.opacity(0.10), lineWidth: 1))
        }
    }

    // MARK: - Data

    private var filtered: [User] {
        users.filter { user in
            if let groupFilter, user.role.group != groupFilter { return false }
            if !search.isEmpty {
                let hay = "\(user.fullName) \(user.email ?? "")".lowercased()
                if !hay.contains(search.lowercased()) { return false }
            }
            return true
        }
        .sorted { $0.fullName < $1.fullName }
    }

    private var pageSlice: [User] {
        let all = filtered
        guard !all.isEmpty else { return [] }
        let start = min(page * rowsPerPage, max(0, all.count - 1))
        return Array(all[start..<min(start + rowsPerPage, all.count)])
    }

    private func branchName(_ user: User) -> String {
        guard let id = user.primaryBranchID, let b = session.branch(id: id) else {
            return NSLocalizedString("admin.no_branch", comment: "")
        }
        return b.name
    }

    private func load() async {
        loading = true
        let all = (try? await session.repository.users(role: nil)) ?? []
        // Client-side scoping — branch-tier viewers see only their branch.
        let scope = session.accessScope
        switch scope {
        case .all:
            users = all
        case .branch(let id):
            users = all.filter { $0.primaryBranchID == id || $0.id == session.currentUser?.id }
        case .ownRecordsOnly:
            users = all.filter { $0.id == session.currentUser?.id }
        }
        loading = false
    }
}

// MARK: - User row content

private struct UserRowContent: View {
    let user: User
    let branchName: String
    let selected: Bool
    @Environment(\.horizontalSizeClass) private var hSize
    private var isWide: Bool { hSize == .regular }

    var body: some View {
        HStack(spacing: 12) {
            Avatar(seed: user.avatarSeed, label: initials(user.fullName), size: 38)
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: user.fullName).scaledFont(.subheadline, weight: .semibold).lineLimit(1)
                Group {
                    if let email = user.email, !email.isEmpty {
                        Text(verbatim: email)
                    } else {
                        Text(localizedKey: user.role.group.labelKey)
                    }
                }
                .scaledFont(.caption2).foregroundStyle(.secondary).lineLimit(1)
            }
            if isWide {
                Spacer(minLength: 8)
                rolePill.frame(width: 150, alignment: .leading)
                Text(verbatim: branchName)
                    .scaledFont(.caption, weight: .medium)
                    .foregroundStyle(.secondary)
                    .frame(width: 130, alignment: .leading).lineLimit(1)
                accessChip.frame(width: 116, alignment: .leading)
                statusChip.frame(width: 84, alignment: .leading)
                Image(systemName: "ellipsis").scaledFont(.caption, weight: .semibold)
                    .foregroundStyle(.secondary).frame(width: 20)
            } else {
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 4) {
                    rolePill
                    accessChip
                }
            }
        }
        .padding(.horizontal, 6).padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(selected ? Color.accentColor.opacity(0.08) : Color.clear)
        )
        .contentShape(Rectangle())
    }

    private var rolePill: some View {
        HStack(spacing: 5) {
            Image(systemName: user.role.icon).scaledFont(.caption2, weight: .semibold)
            Text(localizedKey: user.role.label).scaledFont(.caption2, weight: .semibold).lineLimit(1)
        }
        .padding(.horizontal, 9).padding(.vertical, 4)
        .background(Color.accentColor.opacity(0.12), in: Capsule())
        .foregroundStyle(Color.accentColor)
    }

    private var accessChip: some View {
        Text(localizedKey: user.role.accessLevel.labelKey)
            .scaledFont(.caption2, weight: .semibold)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(accessTint.opacity(0.14), in: Capsule())
            .foregroundStyle(accessTint)
    }

    private var accessTint: Color {
        switch user.role.accessLevel {
        case .full: .secondaryAccent
        case .branchLimited: .accentColor
        case .readOnly: .secondary
        case .restricted: .orange
        }
    }

    private var statusChip: some View {
        HStack(spacing: 4) {
            Circle().fill(Color.secondaryAccent).frame(width: 6, height: 6)
            Text("users.status.active").scaledFont(.caption2, weight: .semibold)
        }
        .foregroundStyle(Color.secondaryAccent)
    }

    private func initials(_ name: String) -> String {
        name.split(separator: " ").prefix(2).map { String($0.prefix(1)) }.joined().uppercased()
    }
}

// MARK: - User detail

private struct UserDetailContent: View {
    let user: User
    let branchName: String
    @Environment(AppSession.self) private var session

    private var capabilityCount: Int {
        Permission.allCases.filter { PermissionMatrix.allowed(role: user.role, permission: $0) }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(spacing: 8) {
                Avatar(seed: user.avatarSeed, label: initials(user.fullName), size: 64)
                Text(verbatim: user.fullName).scaledFont(.headline).multilineTextAlignment(.center)
                Text(localizedKey: user.role.label).scaledFont(.caption).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            Divider().opacity(0.5)
            detailRow("person.badge.shield.checkmark.fill", "users.detail.group",
                      LocalizedStringKey(user.role.group.labelKey))
            detailRow("lock.shield.fill", "users.detail.access",
                      LocalizedStringKey(user.role.accessLevel.labelKey))
            detailRow("building.2.fill", "users.detail.branch", Text(verbatim: branchName))
            if let email = user.email, !email.isEmpty {
                detailRow("envelope.fill", "users.detail.email", Text(verbatim: email))
            }
            if let phone = user.phone, !phone.isEmpty {
                detailRow("phone.fill", "users.detail.phone", Text(verbatim: phone))
            }
            detailRow("key.fill", "users.detail.capabilities",
                      Text(verbatim: String(format: NSLocalizedString("users.detail.capabilities.fmt", comment: ""), capabilityCount)))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.secondary.opacity(0.10), lineWidth: 1))
        .shadow(color: .black.opacity(0.05), radius: 14, y: 6)
    }

    private func detailRow(_ icon: String, _ label: LocalizedStringKey, _ value: some View) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).scaledFont(.footnote, weight: .semibold)
                .foregroundStyle(.tint).frame(width: 22)
            Text(label).scaledFont(.caption).foregroundStyle(.secondary)
            Spacer(minLength: 8)
            value.scaledFont(.caption, weight: .semibold).lineLimit(1)
        }
    }

    private func detailRow(_ icon: String, _ label: LocalizedStringKey, _ value: LocalizedStringKey) -> some View {
        detailRow(icon, label, Text(value))
    }

    private func initials(_ name: String) -> String {
        name.split(separator: " ").prefix(2).map { String($0.prefix(1)) }.joined().uppercased()
    }
}

/// iPhone push destination wrapping the detail card.
private struct UserDetailScreen: View {
    let user: User
    let branchName: String

    var body: some View {
        ScrollView {
            UserDetailContent(user: user, branchName: branchName)
                .padding(16)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle(Text(verbatim: user.fullName))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}
