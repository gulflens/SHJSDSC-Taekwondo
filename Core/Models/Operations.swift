import Foundation

public enum AnnouncementAudience: String, Codable, CaseIterable, Sendable, Hashable {
    case all
    case coaches
    case parents
    case athletes
    case branchManagers

    public var labelKey: String { "announcement.audience.\(rawValue)" }
}

public struct Announcement: Codable, Identifiable, Hashable, Sendable {
    public let id: EntityID
    public var branchID: EntityID?
    public var title: String
    public var titleAr: String
    public var body: String
    public var bodyAr: String
    public var audience: AnnouncementAudience
    public var publishedAt: Date
    public var publishedByUserID: EntityID
    public var requiresRSVP: Bool
    public var rsvpDeadline: Date?

    // MARK: Stage 1.9 — announcements dashboard
    /// Lifecycle state — drives the status pill and the top filter pills.
    public var status: AnnouncementStatus
    /// Editorial category — drives the row's pastel icon tile.
    public var category: AnnouncementCategory
    /// Asset-catalogue hero image; `nil` falls back to a category gradient.
    public var imageAssetName: String?
    /// When a scheduled announcement is set to broadcast.
    public var scheduledAt: Date?
    /// Full audience list shown as chips. Empty → derive from `audience`.
    public var audiences: [AnnouncementAudience]
    public var location: String?
    public var eventStart: Date?
    public var eventEnd: Date?
    public var registrationDeadline: Date?
    /// Per-channel delivery outcomes.
    public var delivery: [AnnouncementDelivery]
    /// Reach + interaction counters for the Engagement section.
    public var engagement: AnnouncementEngagement?
    public var attachments: [AnnouncementAttachment]
    /// Display name of the author ("Dr Ali Alawi").
    public var authorName: String?

    public init(
        id: EntityID = UUID(),
        branchID: EntityID? = nil,
        title: String,
        titleAr: String,
        body: String,
        bodyAr: String,
        audience: AnnouncementAudience,
        publishedAt: Date = Date(),
        publishedByUserID: EntityID,
        requiresRSVP: Bool = false,
        rsvpDeadline: Date? = nil,
        status: AnnouncementStatus = .published,
        category: AnnouncementCategory = .general,
        imageAssetName: String? = nil,
        scheduledAt: Date? = nil,
        audiences: [AnnouncementAudience] = [],
        location: String? = nil,
        eventStart: Date? = nil,
        eventEnd: Date? = nil,
        registrationDeadline: Date? = nil,
        delivery: [AnnouncementDelivery] = [],
        engagement: AnnouncementEngagement? = nil,
        attachments: [AnnouncementAttachment] = [],
        authorName: String? = nil
    ) {
        self.id = id
        self.branchID = branchID
        self.title = title
        self.titleAr = titleAr
        self.body = body
        self.bodyAr = bodyAr
        self.audience = audience
        self.publishedAt = publishedAt
        self.publishedByUserID = publishedByUserID
        self.requiresRSVP = requiresRSVP
        self.rsvpDeadline = rsvpDeadline
        self.status = status
        self.category = category
        self.imageAssetName = imageAssetName
        self.scheduledAt = scheduledAt
        self.audiences = audiences
        self.location = location
        self.eventStart = eventStart
        self.eventEnd = eventEnd
        self.registrationDeadline = registrationDeadline
        self.delivery = delivery
        self.engagement = engagement
        self.attachments = attachments
        self.authorName = authorName
    }

    /// Backward-compatible decoder — pre-1.9 rows (no dossier columns) parse
    /// with sensible defaults.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(EntityID.self, forKey: .id)
        self.branchID = try c.decodeIfPresent(EntityID.self, forKey: .branchID)
        self.title = try c.decode(String.self, forKey: .title)
        self.titleAr = try c.decodeIfPresent(String.self, forKey: .titleAr) ?? ""
        self.body = try c.decodeIfPresent(String.self, forKey: .body) ?? ""
        self.bodyAr = try c.decodeIfPresent(String.self, forKey: .bodyAr) ?? ""
        self.audience = try c.decode(AnnouncementAudience.self, forKey: .audience)
        self.publishedAt = try c.decode(Date.self, forKey: .publishedAt)
        self.publishedByUserID = try c.decode(EntityID.self, forKey: .publishedByUserID)
        self.requiresRSVP = try c.decodeIfPresent(Bool.self, forKey: .requiresRSVP) ?? false
        self.rsvpDeadline = try c.decodeIfPresent(Date.self, forKey: .rsvpDeadline)
        self.status = try c.decodeIfPresent(AnnouncementStatus.self, forKey: .status) ?? .published
        self.category = try c.decodeIfPresent(AnnouncementCategory.self, forKey: .category) ?? .general
        self.imageAssetName = try c.decodeIfPresent(String.self, forKey: .imageAssetName)
        self.scheduledAt = try c.decodeIfPresent(Date.self, forKey: .scheduledAt)
        self.audiences = try c.decodeIfPresent([AnnouncementAudience].self, forKey: .audiences) ?? []
        self.location = try c.decodeIfPresent(String.self, forKey: .location)
        self.eventStart = try c.decodeIfPresent(Date.self, forKey: .eventStart)
        self.eventEnd = try c.decodeIfPresent(Date.self, forKey: .eventEnd)
        self.registrationDeadline = try c.decodeIfPresent(Date.self, forKey: .registrationDeadline)
        self.delivery = try c.decodeIfPresent([AnnouncementDelivery].self, forKey: .delivery) ?? []
        self.engagement = try c.decodeIfPresent(AnnouncementEngagement.self, forKey: .engagement)
        self.attachments = try c.decodeIfPresent([AnnouncementAttachment].self, forKey: .attachments) ?? []
        self.authorName = try c.decodeIfPresent(String.self, forKey: .authorName)
    }

    /// Full audience list — falls back to the single `audience` for old rows.
    public var effectiveAudiences: [AnnouncementAudience] {
        audiences.isEmpty ? [audience] : audiences
    }

    /// The date the row and detail panel display.
    public var displayDate: Date {
        if status == .scheduled, let scheduledAt { return scheduledAt }
        return publishedAt
    }
}

public enum RSVPResponse: String, Codable, CaseIterable, Sendable, Hashable {
    case yes, no, maybe

    public var labelKey: String { "announcement.rsvp.\(rawValue)" }
}

public struct AnnouncementRSVP: Codable, Identifiable, Hashable, Sendable {
    public let id: EntityID
    public var announcementID: EntityID
    public var userID: EntityID
    public var response: RSVPResponse
    public var respondedAt: Date

    public init(
        id: EntityID = UUID(),
        announcementID: EntityID,
        userID: EntityID,
        response: RSVPResponse,
        respondedAt: Date = Date()
    ) {
        self.id = id
        self.announcementID = announcementID
        self.userID = userID
        self.response = response
        self.respondedAt = respondedAt
    }
}

public enum CertificationKind: String, Codable, CaseIterable, Sendable, Hashable {
    case firstAid, safeguarding, wtCoaching, doping, refereeing

    public var labelKey: String { "cert.\(rawValue)" }
}

public enum CertificationSeverity: String, Sendable, Hashable {
    case ok, expiring, expired

    public var labelKey: String { "cert.severity.\(rawValue)" }
}

public struct Certification: Codable, Identifiable, Hashable, Sendable {
    public let id: EntityID
    public var coachID: EntityID
    public var kind: CertificationKind
    public var issuer: String
    public var issuedAt: Date
    public var expiresAt: Date
    public var fileRef: String?

    public init(
        id: EntityID = UUID(),
        coachID: EntityID,
        kind: CertificationKind,
        issuer: String,
        issuedAt: Date,
        expiresAt: Date,
        fileRef: String? = nil
    ) {
        self.id = id
        self.coachID = coachID
        self.kind = kind
        self.issuer = issuer
        self.issuedAt = issuedAt
        self.expiresAt = expiresAt
        self.fileRef = fileRef
    }

    public var daysUntilExpiry: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: expiresAt).day ?? 0
    }

    public var severity: CertificationSeverity {
        let days = daysUntilExpiry
        if days < 0 { return .expired }
        if days < 60 { return .expiring }
        return .ok
    }
}
