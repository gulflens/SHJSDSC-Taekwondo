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

    public init() {}

    private var isWide: Bool { hSize == .regular }

    public var body: some View {
        VStack(spacing: 0) {
            header
            if loading {
                Spacer(); ProgressView(); Spacer()
            } else {
                content
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .task { await load() }
        // Create-account opens as a full pushed view (not a sheet) — it takes
        // over the content area with a back button to return to the list.
        .navigationDestination(isPresented: $showCreate) {
            AdminCreateAccountView(initialRole: createRole)
        }
        .onChange(of: showCreate) { _, showing in
            if !showing { Task { await load() } }
        }
        .onChange(of: search) { _, _ in page = 0 }
        .onChange(of: groupFilter) { _, _ in page = 0 }
        .onChange(of: rowsPerPage) { _, _ in page = 0 }
    }

    // MARK: - Header

    private var header: some View {
        Group {
            if isWide {
                HStack(alignment: .center, spacing: 12) {
                    titleBlock
                    Spacer(minLength: 8)
                    searchField.frame(maxWidth: 240)
                    createMenu
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        titleBlock
                        Spacer(minLength: 8)
                        createMenu
                    }
                    searchField
                }
            }
        }
        .padding(.horizontal, isWide ? 22 : 14)
        .padding(.top, 14)
        .padding(.bottom, 10)
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("users.title").scaledFont(.title2, weight: .bold)
            Text("users.subtitle").scaledFont(.caption).foregroundStyle(.secondary)
        }
    }

    /// Premium create button — a menu of role quick-starts (replaces the
    /// former standalone create-hero card).
    private var createMenu: some View {
        Menu {
            Button { createRole = .coach; showCreate = true } label: {
                Label("users.shortcut.coach", systemImage: Role.coach.icon)
            }
            Button { createRole = .athlete; showCreate = true } label: {
                Label("users.shortcut.athlete", systemImage: Role.athlete.icon)
            }
            Button { createRole = .parent; showCreate = true } label: {
                Label("users.shortcut.parent", systemImage: Role.parent.icon)
            }
            Button { createRole = .frontDesk; showCreate = true } label: {
                Label("users.shortcut.staff", systemImage: Role.frontDesk.icon)
            }
        } label: {
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
        .menuStyle(.button).buttonStyle(.plain).menuIndicator(.hidden)
    }

    // MARK: - Content

    private var content: some View {
        // The list+detail split is shown only on a wide landscape canvas;
        // iPhone and iPad-portrait drop the panel and push a detail screen.
        GeometryReader { _ in
            let split = usesSplitDetailLayout()
            VStack(spacing: 14) {
                statBand
                filterPills
                if split {
                    GeometryReader { geo in
                        let gap: CGFloat = 18
                        let w = max(0, geo.size.width - gap)
                        HStack(alignment: .top, spacing: gap) {
                            tableCard(split: true).frame(width: w * 0.5)
                            detailPane.frame(width: w * 0.5)
                        }
                    }
                } else {
                    tableCard(split: false)
                }
            }
            .padding(.horizontal, isWide ? 22 : 14)
            .padding(.top, 4)
            .padding(.bottom, 14)
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

    // MARK: - Table

    private func tableCard(split: Bool) -> some View {
        VStack(spacing: 0) {
            if filtered.isEmpty {
                EmptyStateCard(icon: "person.crop.circle.badge.questionmark",
                               titleKey: "users.empty.title", messageKey: "users.empty.message")
                    .padding(16)
                Spacer(minLength: 0)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(pageSlice) { user in
                            userRow(user, split: split)
                        }
                    }
                    .padding(12)
                }
                Divider().opacity(0.5)
                paginationFooter
                    .padding(.horizontal, 12)
                    .padding(.bottom, 10)
            }
        }
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.secondary.opacity(0.10), lineWidth: 1))
        .shadow(color: .black.opacity(0.05), radius: 14, y: 6)
    }

    @ViewBuilder
    private func userRow(_ user: User, split: Bool) -> some View {
        if split {
            Button {
                withAnimation(.easeInOut(duration: 0.18)) { selectedUser = user }
            } label: {
                UserRowContent(user: user, selected: selectedUser?.id == user.id)
            }
            .buttonStyle(.plain)
        } else {
            NavigationLink {
                UserDetailScreen(user: user, branchName: branchName(user))
            } label: {
                UserRowContent(user: user, selected: false)
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
            RowsPerPageMenu(rowsPerPage: $rowsPerPage)
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

    private var detailPane: some View {
        ScrollView {
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
                .frame(maxWidth: .infinity, minHeight: 340)
                .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.secondary.opacity(0.10), lineWidth: 1))
            }
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
    let selected: Bool

    var body: some View {
        HStack(spacing: 11) {
            Avatar(seed: user.avatarSeed, label: initials(user.fullName), size: 42)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(verbatim: user.fullName)
                        .scaledFont(.subheadline, weight: .semibold)
                        .lineLimit(1)
                    if user.isAppOwner { ownerBadge }
                }
                Group {
                    if let email = user.email, !email.isEmpty {
                        Text(verbatim: email)
                    } else {
                        Text(localizedKey: user.role.group.labelKey)
                    }
                }
                .scaledFont(.caption2).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 5) {
                rolePill
                accessChip
            }
            .frame(maxWidth: 150, alignment: .trailing)
        }
        .padding(.horizontal, 11).padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(selected ? Color.accentColor.opacity(0.07) : Color.secondary.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(selected ? Color.accentColor : Color.secondary.opacity(0.08),
                        lineWidth: selected ? 1.5 : 1)
        )
        .shadow(color: selected ? Color.accentColor.opacity(0.16) : .clear, radius: 8, y: 3)
        .contentShape(Rectangle())
    }

    /// Marks the permanent project-owner account in the roster.
    private var ownerBadge: some View {
        HStack(spacing: 3) {
            Image(systemName: "lock.shield.fill")
                .scaledFont(.caption2, weight: .bold)
            Text("users.owner_badge")
                .scaledFont(.caption2, weight: .bold)
                .lineLimit(1)
        }
        .padding(.horizontal, 7).padding(.vertical, 3)
        .foregroundStyle(Color.secondaryAccent)
        .background(Color.secondaryAccent.opacity(0.16), in: Capsule())
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
            if user.isAppOwner { ownerProtectedBanner }
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

    /// Banner shown on the project-owner profile — states that the account
    /// holds permanent full access and is not modifiable by other users.
    private var ownerProtectedBanner: some View {
        HStack(spacing: 9) {
            Image(systemName: "lock.shield.fill")
                .scaledFont(.subheadline)
                .foregroundStyle(Color.secondaryAccent)
            VStack(alignment: .leading, spacing: 2) {
                Text("users.owner_badge")
                    .scaledFont(.caption, weight: .semibold)
                Text("users.owner.protected_note")
                    .scaledFont(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondaryAccent.opacity(0.10), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
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
        .subviewChrome(Text(verbatim: user.fullName))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}
