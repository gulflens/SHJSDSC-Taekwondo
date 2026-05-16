import Foundation

// Embedded collections that hang off Athlete — coach notes, documents, and a
// snapshot of cross-federation rankings. Kept here so Athlete.swift stays
// readable. Follows the same "embedded Codable" pattern Athlete already uses
// for emergencyContacts / injuries / weightHistory, so no new Repository
// surface area is required.

public enum CoachNoteCategory: String, Codable, CaseIterable, Sendable, Hashable {
    case technical, tactical, behavioural, medical, mental, general

    public var labelKey: String { "coach_note.category.\(rawValue)" }

    public var systemIcon: String {
        switch self {
        case .technical: "figure.taichi"
        case .tactical: "scope"
        case .behavioural: "face.smiling"
        case .medical: "cross.case.fill"
        case .mental: "brain.head.profile"
        case .general: "text.bubble"
        }
    }
}

public struct CoachNote: Codable, Identifiable, Hashable, Sendable {
    public let id: EntityID
    /// Author's coach ID — nil if authored by an admin / unknown principal.
    public var authorCoachID: EntityID?
    /// Denormalised display name so the note renders correctly when the
    /// coach is offline / archived.
    public var authorName: String
    public var date: Date
    public var category: CoachNoteCategory
    public var body: String
    public var isPinned: Bool

    public init(
        id: EntityID = UUID(),
        authorCoachID: EntityID? = nil,
        authorName: String,
        date: Date = Date(),
        category: CoachNoteCategory,
        body: String,
        isPinned: Bool = false
    ) {
        self.id = id
        self.authorCoachID = authorCoachID
        self.authorName = authorName
        self.date = date
        self.category = category
        self.body = body
        self.isPinned = isPinned
    }
}

public enum AthleteDocumentKind: String, Codable, CaseIterable, Sendable, Hashable {
    case emiratesID
    case passport
    case federationLicence
    case worldTaekwondoCard
    case medicalClearance
    case imageRightsConsent
    case travelPermission
    case schoolID
    case other

    public var labelKey: String { "doc.kind.\(rawValue)" }

    public var systemIcon: String {
        switch self {
        case .emiratesID: "person.text.rectangle.fill"
        case .passport: "book.closed.fill"
        case .federationLicence: "rosette"
        case .worldTaekwondoCard: "globe"
        case .medicalClearance: "cross.case.fill"
        case .imageRightsConsent: "camera.fill"
        case .travelPermission: "airplane"
        case .schoolID: "graduationcap.fill"
        case .other: "doc.fill"
        }
    }
}

public enum AthleteDocumentStatus: String, Codable, CaseIterable, Sendable, Hashable {
    case valid, expiringSoon, expired, missing, pending

    public var labelKey: String { "doc.status.\(rawValue)" }
}

public struct AthleteDocument: Codable, Identifiable, Hashable, Sendable {
    public let id: EntityID
    public var kind: AthleteDocumentKind
    /// Free-form override; nil falls back to `kind.labelKey`.
    public var label: String?
    public var issuedAt: Date?
    public var expiresAt: Date?
    public var status: AthleteDocumentStatus
    /// Resolvable URL (Supabase Storage signed URL once Stage 5 ships). Nil in
    /// demo mode — the row falls back to a placeholder icon + empty state.
    public var fileURL: String?
    public var notes: String?

    public init(
        id: EntityID = UUID(),
        kind: AthleteDocumentKind,
        label: String? = nil,
        issuedAt: Date? = nil,
        expiresAt: Date? = nil,
        status: AthleteDocumentStatus = .missing,
        fileURL: String? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.kind = kind
        self.label = label
        self.issuedAt = issuedAt
        self.expiresAt = expiresAt
        self.status = status
        self.fileURL = fileURL
        self.notes = notes
    }

    /// Derived status from expiry — caller passes today's date to keep this
    /// pure (no Date() side-effect in the model). Returns `.valid` /
    /// `.expiringSoon` (within 30 days) / `.expired` based on `expiresAt`,
    /// or falls back to the persisted `status` when no expiry is set.
    public func derivedStatus(asOf now: Date) -> AthleteDocumentStatus {
        guard let expiry = expiresAt else { return status }
        if expiry < now { return .expired }
        let thirtyDays: TimeInterval = 60 * 60 * 24 * 30
        if expiry.timeIntervalSince(now) < thirtyDays { return .expiringSoon }
        return .valid
    }
}

/// Cross-federation ranking snapshot. Nil fields render as "—" in the UI.
public struct AthleteRanking: Codable, Hashable, Sendable {
    /// Rank inside the athlete's own club / branch.
    public var club: Int?
    /// Rank inside the UAE Taekwondo Federation national list.
    public var uae: Int?
    /// World Taekwondo Federation Olympic-ranking points position.
    public var world: Int?
    /// Olympic qualification position (sport-specific quota slot index).
    public var olympic: Int?
    public var asOf: Date

    public init(
        club: Int? = nil,
        uae: Int? = nil,
        world: Int? = nil,
        olympic: Int? = nil,
        asOf: Date = Date()
    ) {
        self.club = club
        self.uae = uae
        self.world = world
        self.olympic = olympic
        self.asOf = asOf
    }
}
