import Foundation

// MARK: - Announcement dossier
//
// Stage 1.9 — supporting types for the Announcements dashboard remodel.
// `Announcement` (in Operations.swift) gains embedded fields built from
// these. Pure data — no framework imports — so it ports straight to Kotlin.

/// Lifecycle state of an announcement, surfaced as the status pill and the
/// top filter pills.
public enum AnnouncementStatus: String, Codable, CaseIterable, Sendable, Hashable {
    case published, scheduled, draft, archived

    public var labelKey: String { "announcement.status.\(rawValue)" }
}

/// Editorial category — drives the row's pastel icon tile.
public enum AnnouncementCategory: String, Codable, CaseIterable, Sendable, Hashable {
    case general, event, registration, grading, tournament, policy, recognition

    public var labelKey: String { "announcement.category.\(rawValue)" }

    public var systemIcon: String {
        switch self {
        case .general:     "megaphone.fill"
        case .event:       "megaphone.fill"
        case .registration: "calendar"
        case .grading:     "list.bullet.clipboard.fill"
        case .tournament:  "trophy.fill"
        case .policy:      "shield.lefthalf.filled"
        case .recognition: "star.fill"
        }
    }
}

/// A delivery channel an announcement was broadcast on.
public enum AnnouncementChannel: String, Codable, CaseIterable, Sendable, Hashable {
    case email, inApp, sms

    public var labelKey: String { "announcement.channel.\(rawValue)" }

    public var systemIcon: String {
        switch self {
        case .email: "envelope"
        case .inApp: "bell"
        case .sms:   "message"
        }
    }
}

/// Per-channel delivery outcome.
public enum DeliveryState: String, Codable, CaseIterable, Sendable, Hashable {
    case sent, delivered, pending, failed

    public var labelKey: String { "announcement.delivery.\(rawValue)" }
}

/// One channel's delivery row in the detail panel.
public struct AnnouncementDelivery: Codable, Identifiable, Hashable, Sendable {
    public let id: EntityID
    public var channel: AnnouncementChannel
    public var state: DeliveryState

    public init(id: EntityID = UUID(), channel: AnnouncementChannel, state: DeliveryState) {
        self.id = id
        self.channel = channel
        self.state = state
    }
}

/// Reach + interaction counters shown in the Engagement section.
public struct AnnouncementEngagement: Codable, Hashable, Sendable {
    public var recipients: Int
    public var opened: Int
    public var read: Int
    public var clicks: Int

    public init(recipients: Int = 0, opened: Int = 0, read: Int = 0, clicks: Int = 0) {
        self.recipients = recipients
        self.opened = opened
        self.read = read
        self.clicks = clicks
    }

    private func pct(_ n: Int) -> Int {
        recipients > 0 ? Int((Double(n) / Double(recipients) * 100).rounded()) : 0
    }

    public var openedPct: Int  { pct(opened) }
    public var readPct: Int    { pct(read) }
    public var clicksPct: Int  { pct(clicks) }
}

/// A file attached to an announcement.
public struct AnnouncementAttachment: Codable, Identifiable, Hashable, Sendable {
    public let id: EntityID
    public var name: String
    /// Human-readable type + size, e.g. "PDF · 1.2 MB".
    public var detail: String

    public init(id: EntityID = UUID(), name: String, detail: String) {
        self.id = id
        self.name = name
        self.detail = detail
    }
}
