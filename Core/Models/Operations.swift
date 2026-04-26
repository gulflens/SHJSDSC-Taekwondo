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
        rsvpDeadline: Date? = nil
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
