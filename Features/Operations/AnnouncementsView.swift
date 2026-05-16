import SwiftUI

// MARK: - Announcements dashboard
//
// Stage 1.9 — premium remodel. Header + summary stat tiles + status filter
// pills + an adaptive two-panel workspace (announcement list + detail panel
// on iPad, list with a pushed detail screen on iPhone).

public struct AnnouncementsView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.horizontalSizeClass) private var hSize

    @State private var store: OperationsStore?
    @State private var searchText = ""
    @State private var statusFilter: AnnouncementStatus?
    @State private var selectedID: EntityID?
    @State private var page = 0
    @State private var showCompose = false

    private let rowsPerPage = 8

    public init() {}

    private var isWide: Bool { hSize == .regular }

    public var body: some View {
        VStack(spacing: 0) {
            header
            if let store {
                if store.announcements.isEmpty {
                    emptyState
                } else {
                    content(store)
                }
            } else {
                Spacer(); ProgressView(); Spacer()
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .task {
            if store == nil { store = OperationsStore(repository: session.repository) }
            await store?.load()
            if selectedID == nil, isWide { selectedID = sortedAll.first?.id }
        }
        .onChange(of: searchText) { _, _ in page = 0 }
        .onChange(of: statusFilter) { _, _ in page = 0 }
        .sheet(isPresented: $showCompose) {
            NavigationStack {
                ComposeAnnouncementView { _ in Task { await reload() } }
            }
        }
    }

    // MARK: Header

    private var header: some View {
        Group {
            if isWide {
                HStack(alignment: .center, spacing: 16) {
                    titleBlock
                    Spacer(minLength: 8)
                    AnnouncementSearchField(text: $searchText).frame(maxWidth: 260)
                    if canManage { newButton }
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        titleBlock
                        Spacer(minLength: 8)
                        if canManage { newButton }
                    }
                    AnnouncementSearchField(text: $searchText)
                }
            }
        }
        .padding(.horizontal, isWide ? 20 : 14)
        .padding(.top, 14)
        .padding(.bottom, 10)
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("announcement.dashboard.title").scaledFont(.title2, weight: .bold)
            Text("announcement.dashboard.subtitle")
                .scaledFont(.caption).foregroundStyle(.secondary)
        }
    }

    private var newButton: some View {
        Button { showCompose = true } label: {
            HStack(spacing: 6) {
                Image(systemName: "plus").scaledFont(.footnote, weight: .semibold)
                Text("announcement.new").scaledFont(.subheadline, weight: .semibold)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 14).padding(.vertical, 9)
            .background(
                Capsule().fill(LinearGradient(
                    colors: [Color.accentColor, Color.accentColor.opacity(0.82)],
                    startPoint: .top, endPoint: .bottom)))
            .shadow(color: Color.accentColor.opacity(0.32), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }

    // MARK: Content

    private func content(_ store: OperationsStore) -> some View {
        VStack(spacing: 14) {
            statTiles(store)
            filterPills
            if isWide {
                HStack(alignment: .top, spacing: 16) {
                    listPanel(store).frame(maxWidth: .infinity)
                    detailColumn.frame(width: 440)
                }
            } else {
                listPanel(store)
            }
        }
        .padding(.horizontal, isWide ? 20 : 14)
        .padding(.top, 4)
        .padding(.bottom, 14)
    }

    private var emptyState: some View {
        VStack {
            Spacer()
            EmptyStateCard(icon: "megaphone",
                           titleKey: "announcement.empty.title",
                           messageKey: "announcement.empty.message")
                .padding(.horizontal, 20)
            Spacer()
        }
    }

    // MARK: Stat tiles

    private func statTiles(_ store: OperationsStore) -> some View {
        let all = store.announcements
        let cols = isWide
            ? Array(repeating: GridItem(.flexible(), spacing: 12), count: 5)
            : [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]
        return LazyVGrid(columns: cols, spacing: 12) {
            AnnouncementStatTile(titleKey: "announcement.stat.total",
                                 systemIcon: "megaphone.fill", tint: .accentColor,
                                 value: all.count)
            AnnouncementStatTile(titleKey: "announcement.stat.published",
                                 systemIcon: "checkmark.circle.fill", tint: .secondaryAccent,
                                 value: all.filter { $0.status == .published }.count)
            AnnouncementStatTile(titleKey: "announcement.stat.scheduled",
                                 systemIcon: "calendar.badge.clock", tint: .orange,
                                 value: all.filter { $0.status == .scheduled }.count)
            AnnouncementStatTile(titleKey: "announcement.stat.drafts",
                                 systemIcon: "pencil.line", tint: .red,
                                 value: all.filter { $0.status == .draft }.count)
            AnnouncementStatTile(titleKey: "announcement.stat.recipients",
                                 systemIcon: "person.3.fill", tint: .indigo,
                                 value: all.compactMap { $0.engagement?.recipients }.reduce(0, +))
        }
    }

    // MARK: Filter pills

    private var filterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 7) {
                pill(nil, "announcement.filter.all")
                ForEach(AnnouncementStatus.allCases, id: \.self) { s in
                    pill(s, s.labelKey)
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private func pill(_ status: AnnouncementStatus?, _ titleKey: String) -> some View {
        let on = statusFilter == status
        return Button {
            withAnimation(.easeInOut(duration: 0.16)) { statusFilter = status }
        } label: {
            Text(localizedKey: titleKey)
                .scaledFont(.caption, weight: .semibold)
                .padding(.horizontal, 13).padding(.vertical, 7)
                .foregroundStyle(on ? Color.white : Color.primary)
                .background(Capsule().fill(on ? Color.accentColor : Color.secondary.opacity(0.10)))
                .shadow(color: on ? Color.accentColor.opacity(0.3) : .clear, radius: 6, y: 3)
        }
        .buttonStyle(.plain)
    }

    // MARK: List panel

    private func listPanel(_ store: OperationsStore) -> some View {
        VStack(spacing: 0) {
            if filtered.isEmpty {
                EmptyStateCard(icon: "magnifyingglass",
                               titleKey: "announcement.empty.filtered.title",
                               messageKey: "announcement.empty.filtered.message")
                    .padding(16)
                Spacer(minLength: 0)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(pageSlice) { row($0) }
                    }
                    .padding(12)
                }
                Divider().opacity(0.5)
                footer
            }
        }
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.secondary.opacity(0.10), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 14, y: 6)
    }

    @ViewBuilder
    private func row(_ announcement: Announcement) -> some View {
        if isWide {
            Button {
                withAnimation(.easeInOut(duration: 0.18)) { selectedID = announcement.id }
            } label: {
                AnnouncementRow(announcement: announcement,
                                selected: selectedID == announcement.id,
                                canManage: canManage,
                                onEdit: { showCompose = true },
                                onArchive: { Task { await archive(announcement) } })
            }
            .buttonStyle(.plain)
        } else {
            NavigationLink {
                AnnouncementDetailScreen(announcement: announcement,
                                         authorName: announcement.authorName ?? "—",
                                         canManage: canManage,
                                         onEdit: { showCompose = true },
                                         onDuplicate: { Task { await duplicate(announcement) } },
                                         onArchive: { Task { await archive(announcement) } })
            } label: {
                AnnouncementRow(announcement: announcement,
                                selected: false,
                                canManage: canManage,
                                onEdit: { showCompose = true },
                                onArchive: { Task { await archive(announcement) } })
            }
            .buttonStyle(.plain)
        }
    }

    private var footer: some View {
        let total = filtered.count
        let lower = total == 0 ? 0 : page * rowsPerPage + 1
        let upper = min(total, (page + 1) * rowsPerPage)
        return HStack(spacing: 10) {
            Text(verbatim: String(format: NSLocalizedString("announcement.showing.fmt", comment: ""),
                                   lower, upper, total))
                .scaledFont(.caption2).foregroundStyle(.secondary)
                .environment(\.layoutDirection, .leftToRight)
            Spacer(minLength: 8)
            HStack(spacing: 6) {
                pagerButton("chevron.left", enabled: page > 0) { page -= 1 }
                Text(verbatim: "\(page + 1) / \(pageCount)")
                    .scaledFont(.caption, weight: .semibold, monospacedDigit: true)
                    .environment(\.layoutDirection, .leftToRight)
                pagerButton("chevron.right", enabled: page + 1 < pageCount) { page += 1 }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }

    private func pagerButton(_ icon: String, enabled: Bool,
                             action: @escaping () -> Void) -> some View {
        Button { withAnimation(.easeInOut(duration: 0.15), action) } label: {
            Image(systemName: icon)
                .scaledFont(.caption, weight: .semibold)
                .frame(width: 30, height: 30)
                .background(Color.secondary.opacity(0.10),
                            in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.4)
    }

    // MARK: Detail column

    @ViewBuilder
    private var detailColumn: some View {
        if let announcement = selected {
            AnnouncementDetailPanel(
                announcement: announcement,
                authorName: announcement.authorName ?? "—",
                canManage: canManage,
                onEdit: { showCompose = true },
                onDuplicate: { Task { await duplicate(announcement) } },
                onArchive: { Task { await archive(announcement) } }
            )
        } else {
            VStack(spacing: 12) {
                Image(systemName: "megaphone")
                    .font(.system(size: 38)).foregroundStyle(.tertiary)
                Text("announcement.detail.empty")
                    .scaledFont(.subheadline).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 320)
            .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.secondary.opacity(0.10), lineWidth: 1)
            )
        }
    }

    // MARK: Data

    private var sortedAll: [Announcement] {
        (store?.announcements ?? []).sorted { $0.displayDate > $1.displayDate }
    }

    private var filtered: [Announcement] {
        var out = sortedAll
        if let statusFilter { out = out.filter { $0.status == statusFilter } }
        let q = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        if !q.isEmpty {
            out = out.filter {
                $0.title.lowercased().contains(q)
                    || $0.body.lowercased().contains(q)
                    || ($0.authorName?.lowercased().contains(q) ?? false)
            }
        }
        return out
    }

    private var pageCount: Int {
        max(1, Int(ceil(Double(filtered.count) / Double(rowsPerPage))))
    }

    private var pageSlice: [Announcement] {
        let all = filtered
        guard !all.isEmpty else { return [] }
        let safe = min(page, pageCount - 1)
        let start = safe * rowsPerPage
        return Array(all[start..<min(start + rowsPerPage, all.count)])
    }

    private var selected: Announcement? {
        guard let id = selectedID else { return nil }
        return store?.announcements.first { $0.id == id }
    }

    private var canManage: Bool {
        guard let role = session.currentUser?.role else { return false }
        return PermissionMatrix.allowed(role: role, permission: .publishAnnouncement)
    }

    private func reload() async {
        await store?.load()
    }

    private func archive(_ announcement: Announcement) async {
        var copy = announcement
        copy.status = .archived
        await store?.publish(copy)
    }

    private func duplicate(_ announcement: Announcement) async {
        let copy = Announcement(
            branchID: announcement.branchID,
            title: announcement.title + " " + NSLocalizedString("announcement.copy_suffix", comment: ""),
            titleAr: announcement.titleAr,
            body: announcement.body,
            bodyAr: announcement.bodyAr,
            audience: announcement.audience,
            publishedAt: Date(),
            publishedByUserID: announcement.publishedByUserID,
            requiresRSVP: announcement.requiresRSVP,
            rsvpDeadline: announcement.rsvpDeadline,
            status: .draft,
            category: announcement.category,
            imageAssetName: announcement.imageAssetName,
            audiences: announcement.audiences,
            location: announcement.location,
            eventStart: announcement.eventStart,
            eventEnd: announcement.eventEnd,
            registrationDeadline: announcement.registrationDeadline,
            attachments: announcement.attachments,
            authorName: announcement.authorName
        )
        await store?.publish(copy)
    }
}

// MARK: - iPhone detail screen

struct AnnouncementDetailScreen: View {
    let announcement: Announcement
    let authorName: String
    let canManage: Bool
    let onEdit: () -> Void
    let onDuplicate: () -> Void
    let onArchive: () -> Void

    var body: some View {
        ScrollView {
            AnnouncementDetailPanel(
                announcement: announcement,
                authorName: authorName,
                canManage: canManage,
                onEdit: onEdit,
                onDuplicate: onDuplicate,
                onArchive: onArchive
            )
            .padding(14)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle(Text(verbatim: announcement.title))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}
