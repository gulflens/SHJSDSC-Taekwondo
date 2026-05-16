import SwiftUI

// MARK: - Announcements design kit
//
// Stage 1.9 — shared visual vocabulary for the Announcements dashboard:
// status/category colours plus the row, stat-tile, pill, and chip primitives.

public extension AnnouncementStatus {
    /// Pastel compliance-style accent for the status pill and filter pills.
    var tint: Color {
        switch self {
        case .published: .secondaryAccent
        case .scheduled: .orange
        case .draft:     .secondary
        case .archived:  .secondary
        }
    }

    var systemIcon: String {
        switch self {
        case .published: "checkmark.circle.fill"
        case .scheduled: "calendar.badge.clock"
        case .draft:     "pencil.line"
        case .archived:  "archivebox.fill"
        }
    }
}

public extension AnnouncementCategory {
    /// Pastel accent for the row icon tile.
    var tint: Color {
        switch self {
        case .general:     .accentColor
        case .event:       .accentColor
        case .registration: .orange
        case .grading:     .secondaryAccent
        case .tournament:  .purple
        case .policy:      .red
        case .recognition: .yellow
        }
    }
}

public extension DeliveryState {
    var tint: Color {
        switch self {
        case .sent:      .accentColor
        case .delivered: .secondaryAccent
        case .pending:   .orange
        case .failed:    .red
        }
    }
}

/// "May 15, 2026" / "5:40 PM" helpers used across the module.
func announcementDateText(_ date: Date) -> String {
    date.formatted(.dateTime.month(.abbreviated).day().year())
}

func announcementTimeText(_ date: Date) -> String {
    date.formatted(.dateTime.hour().minute())
}

// MARK: - Status pill

/// Small rounded status pill — "Published / Scheduled / Draft / Archived".
public struct AnnouncementStatusPill: View {
    private let status: AnnouncementStatus

    public init(_ status: AnnouncementStatus) {
        self.status = status
    }

    public var body: some View {
        Text(localizedKey: status.labelKey)
            .scaledFont(.caption2, weight: .semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(status.tint.opacity(0.16), in: Capsule())
            .foregroundStyle(status.tint)
    }
}

// MARK: - Category icon

/// Rounded pastel icon tile representing an announcement's category.
public struct AnnouncementCategoryIcon: View {
    private let category: AnnouncementCategory
    private let size: CGFloat

    public init(_ category: AnnouncementCategory, size: CGFloat = 44) {
        self.category = category
        self.size = size
    }

    public var body: some View {
        Image(systemName: category.systemIcon)
            .font(.system(size: size * 0.42, weight: .semibold))
            .foregroundStyle(category.tint)
            .frame(width: size, height: size)
            .background(
                category.tint.opacity(0.14),
                in: RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
            )
    }
}

// MARK: - Stat tile

/// Header summary tile — icon + label + count.
public struct AnnouncementStatTile: View {
    private let titleKey: String
    private let systemIcon: String
    private let tint: Color
    private let value: Int

    public init(titleKey: String, systemIcon: String, tint: Color, value: Int) {
        self.titleKey = titleKey
        self.systemIcon = systemIcon
        self.tint = tint
        self.value = value
    }

    public var body: some View {
        HStack(spacing: 11) {
            Image(systemName: systemIcon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 38, height: 38)
                .background(tint.opacity(0.14),
                            in: RoundedRectangle(cornerRadius: 11, style: .continuous))
            VStack(alignment: .leading, spacing: 1) {
                Text(localizedKey: titleKey)
                    .scaledFont(.caption2, weight: .medium)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(verbatim: value.formatted())
                    .scaledFont(.title3, weight: .bold)
                    .monospacedDigit()
                    .environment(\.layoutDirection, .leftToRight)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .stroke(Color.secondary.opacity(0.10), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 9, y: 4)
    }
}

// MARK: - Hero image

/// Wide announcement image — asset-catalogue image when present, otherwise a
/// category-tinted gradient so the panel is never empty.
public struct AnnouncementHeroImage: View {
    private let announcement: Announcement
    private let height: CGFloat

    public init(_ announcement: Announcement, height: CGFloat = 200) {
        self.announcement = announcement
        self.height = height
    }

    public var body: some View {
        Group {
            if let img = loaded {
                img.resizable().scaledToFill()
            } else {
                LinearGradient(
                    colors: [announcement.category.tint.opacity(0.9),
                             announcement.category.tint.opacity(0.55)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                .overlay(
                    Image(systemName: announcement.category.systemIcon)
                        .font(.system(size: 46, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                )
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var loaded: Image? {
        guard let name = announcement.imageAssetName, !name.isEmpty else { return nil }
        #if os(iOS)
        if let ui = UIImage(named: name) { return Image(uiImage: ui) }
        #elseif os(macOS)
        if let ns = NSImage(named: name) { return Image(nsImage: ns) }
        #endif
        return nil
    }
}

// MARK: - Engagement card

/// One pastel engagement metric — label, big count, and a percentage chip.
public struct EngagementStatCard: View {
    private let titleKey: String
    private let value: Int
    private let percent: Int

    public init(titleKey: String, value: Int, percent: Int) {
        self.titleKey = titleKey
        self.value = value
        self.percent = percent
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(localizedKey: titleKey)
                .scaledFont(.caption2, weight: .medium)
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(verbatim: value.formatted())
                    .scaledFont(.title3, weight: .bold)
                    .monospacedDigit()
                Text(verbatim: "\(percent)%")
                    .scaledFont(.caption2, weight: .semibold)
                    .foregroundStyle(Color.secondaryAccent)
            }
            .environment(\.layoutDirection, .leftToRight)
        }
        .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.secondary.opacity(0.06),
                    in: RoundedRectangle(cornerRadius: 13, style: .continuous))
    }
}

// MARK: - Delivery row

/// One delivery channel + its state, for the detail panel's Delivery card.
public struct DeliveryChannelRow: View {
    private let delivery: AnnouncementDelivery

    public init(_ delivery: AnnouncementDelivery) {
        self.delivery = delivery
    }

    public var body: some View {
        HStack(spacing: 9) {
            Image(systemName: delivery.channel.systemIcon)
                .scaledFont(.footnote, weight: .medium)
                .foregroundStyle(.secondary)
                .frame(width: 18)
            Text(localizedKey: delivery.channel.labelKey)
                .scaledFont(.subheadline)
            Spacer(minLength: 8)
            Text(localizedKey: delivery.state.labelKey)
                .scaledFont(.caption2, weight: .semibold)
                .foregroundStyle(delivery.state.tint)
        }
    }
}

// MARK: - Attachment row

/// A file attachment chip — PDF-style icon + name + size detail.
public struct AttachmentRow: View {
    private let attachment: AnnouncementAttachment

    public init(_ attachment: AnnouncementAttachment) {
        self.attachment = attachment
    }

    public var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "doc.fill")
                .scaledFont(.subheadline, weight: .semibold)
                .foregroundStyle(.red)
                .frame(width: 34, height: 34)
                .background(Color.red.opacity(0.12),
                            in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            VStack(alignment: .leading, spacing: 1) {
                Text(verbatim: attachment.name)
                    .scaledFont(.caption, weight: .semibold)
                    .lineLimit(1)
                Text(verbatim: attachment.detail)
                    .scaledFont(.caption2)
                    .foregroundStyle(.secondary)
                    .environment(\.layoutDirection, .leftToRight)
            }
            Spacer(minLength: 0)
        }
        .padding(9)
        .background(Color.secondary.opacity(0.06),
                    in: RoundedRectangle(cornerRadius: 11, style: .continuous))
    }
}

// MARK: - Search field

/// Rounded glass-material search field for the announcements header.
public struct AnnouncementSearchField: View {
    @Binding private var text: String

    public init(text: Binding<String>) {
        _text = text
    }

    public var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "magnifyingglass")
                .scaledFont(.footnote, weight: .medium)
                .foregroundStyle(.secondary)
            TextField(text: $text) { Text("announcement.search") }
                .textFieldStyle(.plain)
                #if os(iOS)
                .textInputAutocapitalization(.never)
                #endif
                .autocorrectionDisabled()
            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .scaledFont(.footnote)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(.thinMaterial, in: Capsule())
        .overlay(Capsule().stroke(Color.secondary.opacity(0.14), lineWidth: 1))
    }
}
