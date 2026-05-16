import SwiftUI

/// Apple News-style announcements feed. Hero card for the newest item +
/// grouped feed of premium cards for the rest. Reuses the federation-grade
/// design primitives (`SectionCard`, `CategoryBadge`, `EmptyStateCard`) so
/// announcements feel part of the same ecosystem as athlete / coach / branch.
public struct AnnouncementsView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var store: OperationsStore?
    @State private var showCompose = false
    @State private var audienceFilter: AnnouncementAudience?

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
        .toolbar {
            if let role = session.currentUser?.role,
               PermissionMatrix.allowed(role: role, permission: .publishAnnouncement) {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showCompose = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                    .accessibilityLabel(Text("announcement.compose"))
                    .bareToolbarButton()
                }
            }
        }
        .sheet(isPresented: $showCompose) {
            NavigationStack {
                ComposeAnnouncementView { _ in
                    Task { await store?.load() }
                }
            }
        }
        .task {
            if store == nil { store = OperationsStore(repository: session.repository) }
            await store?.load()
        }
    }

    private var isWide: Bool { sizeClass == .regular }

    @ViewBuilder
    private func content(store: OperationsStore) -> some View {
        if store.announcements.isEmpty {
            SectionCard {
                EmptyStateCard(
                    icon: "megaphone",
                    titleKey: "announcement.empty.title",
                    messageKey: "announcement.empty.message"
                )
            }
            .padding(.horizontal, isWide ? 20 : 14)
            .padding(.top, 12)
        } else {
            ScrollView {
                VStack(spacing: 14) {
                    filterStrip
                    if let hero = filtered(store).first {
                        heroCard(hero, store: store)
                    }
                    feedSection(store: store)
                }
                .padding(.horizontal, isWide ? 20 : 14)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
        }
    }

    private func filtered(_ store: OperationsStore) -> [Announcement] {
        let sorted = store.announcements.sorted { $0.publishedAt > $1.publishedAt }
        guard let audienceFilter else { return sorted }
        return sorted.filter { $0.audience == audienceFilter }
    }

    private var filterStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(nil, labelKey: "announcement.filter.all", icon: "tray.full")
                ForEach(AnnouncementAudience.allCases, id: \.rawValue) { audience in
                    filterChip(audience, labelKey: LocalizedStringKey(audience.labelKey), icon: audienceIcon(audience))
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private func filterChip(_ audience: AnnouncementAudience?, labelKey: LocalizedStringKey, icon: String) -> some View {
        let isSelected = audienceFilter == audience
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                audienceFilter = audience
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: icon).scaledFont(.caption2)
                Text(labelKey).scaledFont(.caption, weight: .medium)
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 6)
            .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.12), in: Capsule())
            .foregroundStyle(isSelected ? Color.white : Color.primary)
        }
        .buttonStyle(.plain)
    }

    private func audienceIcon(_ audience: AnnouncementAudience) -> String {
        switch audience.rawValue {
        case "athletes": "person.3.fill"
        case "coaches": "graduationcap.fill"
        case "parents": "person.2.wave.2.fill"
        case "all", "everyone": "person.crop.circle.fill"
        default: "person.fill"
        }
    }

    // MARK: - Hero

    private func heroCard(_ announcement: Announcement, store: OperationsStore) -> some View {
        let myResponse = store.myResponse(announcementID: announcement.id, userID: session.currentUser?.id ?? UUID())
        let rsvpCount = store.rsvpsByAnnouncement[announcement.id]?.count ?? 0
        return VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                CategoryBadge(
                    value: NSLocalizedString(announcement.audience.labelKey, comment: ""),
                    tone: .elite,
                    icon: audienceIcon(announcement.audience)
                )
                if isUrgent(announcement) {
                    CategoryBadge(
                        value: NSLocalizedString("announcement.priority.urgent", comment: ""),
                        tone: .warning,
                        icon: "exclamationmark.bubble.fill"
                    )
                }
                if announcement.requiresRSVP {
                    CategoryBadge(
                        value: NSLocalizedString("announcement.requires_rsvp", comment: ""),
                        tone: .neutral,
                        icon: "checkmark.circle"
                    )
                }
                Spacer(minLength: 0)
                Text(announcement.publishedAt, format: .relative(presentation: .named))
                    .scaledFont(.caption2)
                    .foregroundStyle(.white.opacity(0.85))
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(verbatim: announcement.title)
                    .scaledFont(.title2, weight: .bold)
                    .foregroundStyle(.white)
                    .lineLimit(3)
                Text(verbatim: announcement.titleAr)
                    .scaledFont(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
                    .environment(\.layoutDirection, .rightToLeft)
            }
            Text(verbatim: announcement.body)
                .scaledFont(.body)
                .foregroundStyle(.white.opacity(0.92))
                .lineLimit(4)
            if announcement.requiresRSVP {
                rsvpRow(announcement, myResponse: myResponse, rsvpCount: rsvpCount, isHero: true) { response in
                    guard let userID = session.currentUser?.id else { return }
                    Task { await store.rsvp(announcementID: announcement.id, userID: userID, response: response) }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [
                    Color.accentColor,
                    Color.accentColor.opacity(0.78)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .shadow(color: Color.accentColor.opacity(0.25), radius: 14, y: 8)
    }

    private func isUrgent(_ announcement: Announcement) -> Bool {
        announcement.requiresRSVP
            && (announcement.rsvpDeadline.map { $0.timeIntervalSince(Date()) < 86400 * 2 } ?? false)
    }

    // MARK: - Feed

    @ViewBuilder
    private func feedSection(store: OperationsStore) -> some View {
        let rest = Array(filtered(store).dropFirst())
        let groups = Dictionary(grouping: rest) { Calendar.current.startOfDay(for: $0.publishedAt) }
        let sortedDates = groups.keys.sorted(by: >)
        ForEach(sortedDates, id: \.self) { date in
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Text(date, format: .dateTime.weekday(.wide).day().month(.abbreviated))
                        .scaledFont(.subheadline, weight: .semibold)
                        .foregroundStyle(.primary)
                        .environment(\.layoutDirection, .leftToRight)
                    Spacer(minLength: 0)
                }
                VStack(spacing: 10) {
                    ForEach(groups[date] ?? []) { announcement in
                        feedCard(announcement, store: store)
                    }
                }
            }
        }
    }

    private func feedCard(_ announcement: Announcement, store: OperationsStore) -> some View {
        let myResponse = store.myResponse(announcementID: announcement.id, userID: session.currentUser?.id ?? UUID())
        let rsvpCount = store.rsvpsByAnnouncement[announcement.id]?.count ?? 0
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                CategoryBadge(
                    value: NSLocalizedString(announcement.audience.labelKey, comment: ""),
                    tone: .neutral,
                    icon: audienceIcon(announcement.audience)
                )
                if announcement.requiresRSVP {
                    CategoryBadge(
                        value: "\(rsvpCount)",
                        tone: .success,
                        icon: "checkmark.circle.fill"
                    )
                }
                Spacer(minLength: 0)
                Text(announcement.publishedAt, format: .dateTime.hour().minute())
                    .scaledFont(.caption2)
                    .foregroundStyle(.secondary)
                    .environment(\.layoutDirection, .leftToRight)
            }
            Text(verbatim: announcement.title)
                .scaledFont(.headline)
                .lineLimit(2)
            Text(verbatim: announcement.body)
                .scaledFont(.subheadline)
                .foregroundStyle(.primary.opacity(0.85))
                .lineLimit(3)
            if announcement.requiresRSVP {
                rsvpRow(announcement, myResponse: myResponse, rsvpCount: rsvpCount, isHero: false) { response in
                    guard let userID = session.currentUser?.id else { return }
                    Task { await store.rsvp(announcementID: announcement.id, userID: userID, response: response) }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 12, y: 5)
    }

    private func rsvpRow(_ announcement: Announcement, myResponse: RSVPResponse?, rsvpCount: Int, isHero: Bool, onRSVP: @escaping (RSVPResponse) -> Void) -> some View {
        HStack(spacing: 8) {
            rsvpButton(.yes, color: .green, isSelected: myResponse == .yes, isHero: isHero, onTap: { onRSVP(.yes) })
            rsvpButton(.maybe, color: .orange, isSelected: myResponse == .maybe, isHero: isHero, onTap: { onRSVP(.maybe) })
            rsvpButton(.no, color: .red, isSelected: myResponse == .no, isHero: isHero, onTap: { onRSVP(.no) })
            Spacer(minLength: 0)
            if let deadline = announcement.rsvpDeadline {
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill").scaledFont(.caption2)
                    Text(deadline, format: .dateTime.day().month(.abbreviated))
                        .scaledFont(.caption2, monospacedDigit: true)
                        .environment(\.layoutDirection, .leftToRight)
                }
                .foregroundStyle(isHero ? .white.opacity(0.85) : .secondary)
            }
        }
        .padding(.top, 4)
    }

    private func rsvpButton(_ response: RSVPResponse, color: Color, isSelected: Bool, isHero: Bool, onTap: @escaping () -> Void) -> some View {
        Button(action: onTap) {
            Text(localizedKey: response.labelKey)
                .scaledFont(.caption, weight: .semibold)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    isSelected
                        ? color
                        : (isHero ? Color.white.opacity(0.2) : color.opacity(0.15)),
                    in: Capsule()
                )
                .foregroundStyle(isSelected ? .white : (isHero ? .white : color))
        }
        .buttonStyle(.plain)
    }
}
