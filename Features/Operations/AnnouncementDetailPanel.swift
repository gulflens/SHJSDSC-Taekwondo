import SwiftUI

// MARK: - Announcement row
//
// Stage 1.9 — premium row for the announcements list panel: category icon +
// title + status pill + audience, with date/time and a contextual menu.

public struct AnnouncementRow: View {
    private let announcement: Announcement
    private let selected: Bool
    private let canManage: Bool
    private let onEdit: () -> Void
    private let onArchive: () -> Void

    public init(
        announcement: Announcement,
        selected: Bool,
        canManage: Bool,
        onEdit: @escaping () -> Void,
        onArchive: @escaping () -> Void
    ) {
        self.announcement = announcement
        self.selected = selected
        self.canManage = canManage
        self.onEdit = onEdit
        self.onArchive = onArchive
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AnnouncementCategoryIcon(announcement.category, size: 46)
            VStack(alignment: .leading, spacing: 5) {
                Text(verbatim: announcement.title)
                    .scaledFont(.subheadline, weight: .bold)
                    .lineLimit(1)
                AnnouncementStatusPill(announcement.status)
                Text(verbatim: audienceText)
                    .scaledFont(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 6) {
                if canManage {
                    Menu {
                        Button { onEdit() } label: { Label("action.edit", systemImage: "pencil") }
                        if announcement.status != .archived {
                            Button { onArchive() } label: {
                                Label("announcement.archive", systemImage: "archivebox")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .scaledFont(.subheadline, weight: .semibold)
                            .foregroundStyle(.secondary)
                            .frame(width: 26, height: 22)
                            .contentShape(Rectangle())
                    }
                    .menuStyle(.button).buttonStyle(.plain).menuIndicator(.hidden)
                } else {
                    Color.clear.frame(width: 26, height: 22)
                }
                Spacer(minLength: 4)
                Text(verbatim: dateLine)
                    .scaledFont(.caption2, weight: .medium)
                    .foregroundStyle(.secondary)
                    .environment(\.layoutDirection, .leftToRight)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .frame(minHeight: 78)
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

    private var audienceText: String {
        announcement.effectiveAudiences
            .map { NSLocalizedString($0.labelKey, comment: "") }
            .joined(separator: ", ")
    }

    private var dateLine: String {
        let d = announcement.displayDate
        return announcementDateText(d) + " · " + announcementTimeText(d)
    }
}

// MARK: - Announcement detail panel

/// The right-hand workspace panel — header, hero image, body, event meta,
/// audience + delivery cards, engagement grid, and attachments.
public struct AnnouncementDetailPanel: View {
    private let announcement: Announcement
    private let authorName: String
    private let canManage: Bool
    private let onEdit: () -> Void
    private let onDuplicate: () -> Void
    private let onArchive: () -> Void

    @Environment(\.horizontalSizeClass) private var hSize

    public init(
        announcement: Announcement,
        authorName: String,
        canManage: Bool,
        onEdit: @escaping () -> Void,
        onDuplicate: @escaping () -> Void,
        onArchive: @escaping () -> Void
    ) {
        self.announcement = announcement
        self.authorName = authorName
        self.canManage = canManage
        self.onEdit = onEdit
        self.onDuplicate = onDuplicate
        self.onArchive = onArchive
    }

    private var isWide: Bool { hSize == .regular }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                AnnouncementHeroImage(announcement, height: isWide ? 210 : 170)
                bodyText
                metaRows
                if isWide {
                    HStack(alignment: .top, spacing: 14) {
                        audienceCard.frame(maxWidth: .infinity)
                        deliveryCard.frame(maxWidth: .infinity)
                    }
                } else {
                    audienceCard
                    deliveryCard
                }
                if let engagement = announcement.engagement {
                    engagementSection(engagement)
                }
                if !announcement.attachments.isEmpty {
                    attachmentsSection
                }
            }
            .padding(20)
        }
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.secondary.opacity(0.10), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 16, y: 8)
        .id(announcement.id)
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                AnnouncementCategoryIcon(announcement.category, size: 52)
                VStack(alignment: .leading, spacing: 4) {
                    Text(verbatim: announcement.title)
                        .scaledFont(.title3, weight: .bold)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(verbatim: bylineText)
                        .scaledFont(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            HStack(spacing: 10) {
                AnnouncementStatusPill(announcement.status)
                Spacer(minLength: 0)
                if canManage {
                    actionButton("action.edit", "pencil", action: onEdit)
                    actionButton("announcement.duplicate", "doc.on.doc", action: onDuplicate)
                    Menu {
                        if announcement.status != .archived {
                            Button { onArchive() } label: {
                                Label("announcement.archive", systemImage: "archivebox")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .scaledFont(.subheadline, weight: .semibold)
                            .foregroundStyle(.primary)
                            .frame(width: 34, height: 34)
                            .background(Color.secondary.opacity(0.10), in: Circle())
                    }
                    .menuStyle(.button).buttonStyle(.plain).menuIndicator(.hidden)
                }
            }
        }
    }

    private func actionButton(_ titleKey: String, _ icon: String,
                              action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label {
                Text(localizedKey: titleKey)
            } icon: {
                Image(systemName: icon)
            }
            .scaledFont(.subheadline, weight: .semibold)
            .padding(.horizontal, 13).padding(.vertical, 8)
            .foregroundStyle(.primary)
            .background(Color.secondary.opacity(0.10), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private var bodyText: some View {
        Text(verbatim: announcement.body)
            .scaledFont(.subheadline)
            .foregroundStyle(.primary.opacity(0.9))
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Meta rows

    @ViewBuilder
    private var metaRows: some View {
        VStack(alignment: .leading, spacing: 9) {
            if let start = announcement.eventStart {
                metaRow("calendar", text: eventRangeText(start, announcement.eventEnd), tint: .primary)
            }
            if let location = announcement.location, !location.isEmpty {
                metaRow("mappin.and.ellipse", text: location, tint: .primary)
            }
            metaRow("person.3.fill", text: audienceText, tint: .primary)
            if let deadline = announcement.registrationDeadline {
                metaRow("flag.checkered",
                        text: NSLocalizedString("announcement.reg_deadline", comment: "")
                            + " " + announcementDateText(deadline),
                        tint: .orange)
            }
        }
    }

    private func metaRow(_ icon: String, text: String, tint: Color) -> some View {
        HStack(spacing: 9) {
            Image(systemName: icon)
                .scaledFont(.footnote, weight: .semibold)
                .foregroundStyle(tint == .primary ? Color.accentColor : tint)
                .frame(width: 20)
            Text(verbatim: text)
                .scaledFont(.subheadline, weight: .medium)
                .foregroundStyle(tint)
            Spacer(minLength: 0)
        }
    }

    // MARK: Audience + delivery

    private var audienceCard: some View {
        cardShell(titleKey: "announcement.audience") {
            FlowChips(announcement.effectiveAudiences) { aud in
                Text(localizedKey: aud.labelKey)
                    .scaledFont(.caption, weight: .semibold)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Color.accentColor.opacity(0.10), in: Capsule())
                    .foregroundStyle(Color.accentColor)
            }
        }
    }

    @ViewBuilder
    private var deliveryCard: some View {
        if announcement.delivery.isEmpty {
            cardShell(titleKey: "announcement.delivery_section") {
                Text("announcement.no_delivery")
                    .scaledFont(.caption).foregroundStyle(.secondary)
            }
        } else {
            cardShell(titleKey: "announcement.delivery_section") {
                VStack(spacing: 9) {
                    ForEach(announcement.delivery) { DeliveryChannelRow($0) }
                }
            }
        }
    }

    private func cardShell<Content: View>(
        titleKey: String, @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(localizedKey: titleKey)
                .scaledFont(.subheadline, weight: .semibold)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.secondary.opacity(0.05),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.secondary.opacity(0.08), lineWidth: 1)
        )
    }

    // MARK: Engagement

    private func engagementSection(_ e: AnnouncementEngagement) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("announcement.engagement")
                .scaledFont(.headline, weight: .semibold)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 10)], spacing: 10) {
                EngagementStatCard(titleKey: "announcement.metric.recipients",
                                   value: e.recipients, percent: 100)
                EngagementStatCard(titleKey: "announcement.metric.opened",
                                   value: e.opened, percent: e.openedPct)
                EngagementStatCard(titleKey: "announcement.metric.read",
                                   value: e.read, percent: e.readPct)
                EngagementStatCard(titleKey: "announcement.metric.clicks",
                                   value: e.clicks, percent: e.clicksPct)
            }
        }
    }

    // MARK: Attachments

    private var attachmentsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(verbatim: String(format: NSLocalizedString("announcement.attachments.fmt", comment: ""),
                                   announcement.attachments.count))
                .scaledFont(.headline, weight: .semibold)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 200), spacing: 10)], spacing: 10) {
                ForEach(announcement.attachments) { AttachmentRow($0) }
            }
        }
    }

    // MARK: Text

    private var bylineText: String {
        let verb = announcement.status == .scheduled
            ? NSLocalizedString("announcement.byline.scheduled", comment: "")
            : NSLocalizedString("announcement.byline.published", comment: "")
        let d = announcement.displayDate
        let datePart = announcementDateText(d) + " · " + announcementTimeText(d)
        return verb + " " + datePart + " · " + authorName
    }

    private var audienceText: String {
        announcement.effectiveAudiences
            .map { NSLocalizedString($0.labelKey, comment: "") }
            .joined(separator: ", ")
    }

    private func eventRangeText(_ start: Date, _ end: Date?) -> String {
        guard let end else { return announcementDateText(start) }
        return announcementDateText(start) + " – " + announcementDateText(end)
    }
}
