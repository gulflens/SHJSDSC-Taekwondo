import Foundation

public typealias EntityID = UUID

public enum Role: String, Codable, CaseIterable, Sendable, Hashable {
    // System & technical
    case developer
    case admin                      // labelled "System Administrator"
    case itSupport
    // Federation leadership
    case technicalDirector
    case operationsManager
    case branchManager
    // Coaching staff
    case headCoach
    case coach
    case assistantCoach
    case sparringCoach
    case poomsaeCoach
    case conditioningCoach
    case demoTeamCoach
    // Medical & athlete support
    case teamPhysician
    case physiotherapist
    case sportsPsychologist
    case nutritionist
    case analyst                    // labelled "Performance Analyst"
    // Competition & officiating
    case tournamentAdmin
    case competitionCoordinator
    case referee
    case scorekeeper
    // Grading
    case gradingExaminer
    // Administration & operations
    case registrar
    case frontDesk
    case finance
    case hrManager
    // Members & external
    case athlete
    case parent
    case alumni
    case federationViewer
    case sponsor

    public var label: String {
        switch self {
        case .developer: "role.developer"
        case .admin: "role.admin"
        case .itSupport: "role.itSupport"
        case .technicalDirector: "role.technicalDirector"
        case .operationsManager: "role.operationsManager"
        case .branchManager: "role.branchManager"
        case .headCoach: "role.headCoach"
        case .coach: "role.coach"
        case .assistantCoach: "role.assistantCoach"
        case .sparringCoach: "role.sparringCoach"
        case .poomsaeCoach: "role.poomsaeCoach"
        case .conditioningCoach: "role.conditioningCoach"
        case .demoTeamCoach: "role.demoTeamCoach"
        case .teamPhysician: "role.teamPhysician"
        case .physiotherapist: "role.physiotherapist"
        case .sportsPsychologist: "role.sportsPsychologist"
        case .nutritionist: "role.nutritionist"
        case .analyst: "role.analyst"
        case .tournamentAdmin: "role.tournamentAdmin"
        case .competitionCoordinator: "role.competitionCoordinator"
        case .referee: "role.referee"
        case .scorekeeper: "role.scorekeeper"
        case .gradingExaminer: "role.gradingExaminer"
        case .registrar: "role.registrar"
        case .frontDesk: "role.frontDesk"
        case .finance: "role.finance"
        case .hrManager: "role.hrManager"
        case .athlete: "role.athlete"
        case .parent: "role.parent"
        case .alumni: "role.alumni"
        case .federationViewer: "role.federationViewer"
        case .sponsor: "role.sponsor"
        }
    }
}

public enum PreferredLanguage: String, Codable, CaseIterable, Sendable, Hashable {
    case system, english, arabic

    public var labelKey: String { "language.\(rawValue)" }
}

public struct UserNotificationPreferences: Codable, Hashable, Sendable {
    public var classReminders: Bool
    public var announcements: Bool
    public var weeklyDigest: Bool
    public var promotionAlerts: Bool

    public init(
        classReminders: Bool = true,
        announcements: Bool = true,
        weeklyDigest: Bool = false,
        promotionAlerts: Bool = true
    ) {
        self.classReminders = classReminders
        self.announcements = announcements
        self.weeklyDigest = weeklyDigest
        self.promotionAlerts = promotionAlerts
    }

    public static let `default` = UserNotificationPreferences()
}

public struct User: Codable, Identifiable, Hashable, Sendable {
    public let id: EntityID
    public var fullName: String
    public var fullNameAr: String
    public var role: Role
    public var primaryBranchID: EntityID?
    public var avatarSeed: String
    public var linkedAthleteIDs: [EntityID]

    // === Account-level profile (added in profile-editor pass) ===
    public var avatarURL: String?
    public var email: String?
    public var phone: String?
    public var preferredLanguage: PreferredLanguage
    public var notificationPrefs: UserNotificationPreferences

    public init(
        id: EntityID = UUID(),
        fullName: String,
        fullNameAr: String,
        role: Role,
        primaryBranchID: EntityID? = nil,
        avatarSeed: String,
        linkedAthleteIDs: [EntityID] = [],
        avatarURL: String? = nil,
        email: String? = nil,
        phone: String? = nil,
        preferredLanguage: PreferredLanguage = .system,
        notificationPrefs: UserNotificationPreferences = .default
    ) {
        self.id = id
        self.fullName = fullName
        self.fullNameAr = fullNameAr
        self.role = role
        self.primaryBranchID = primaryBranchID
        self.avatarSeed = avatarSeed
        self.linkedAthleteIDs = linkedAthleteIDs
        self.avatarURL = avatarURL
        self.email = email
        self.phone = phone
        self.preferredLanguage = preferredLanguage
        self.notificationPrefs = notificationPrefs
    }

    // Backwards-compatible decoder: existing rows (demo seed, Supabase) do not
    // yet carry the new account-profile columns. Missing fields default rather
    // than blowing up the decode.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(EntityID.self, forKey: .id)
        self.fullName = try c.decode(String.self, forKey: .fullName)
        self.fullNameAr = try c.decode(String.self, forKey: .fullNameAr)
        self.role = try c.decode(Role.self, forKey: .role)
        self.primaryBranchID = try c.decodeIfPresent(EntityID.self, forKey: .primaryBranchID)
        self.avatarSeed = try c.decode(String.self, forKey: .avatarSeed)
        self.linkedAthleteIDs = try c.decodeIfPresent([EntityID].self, forKey: .linkedAthleteIDs) ?? []
        self.avatarURL = try c.decodeIfPresent(String.self, forKey: .avatarURL)
        self.email = try c.decodeIfPresent(String.self, forKey: .email)
        self.phone = try c.decodeIfPresent(String.self, forKey: .phone)
        self.preferredLanguage = try c.decodeIfPresent(PreferredLanguage.self, forKey: .preferredLanguage) ?? .system
        self.notificationPrefs = try c.decodeIfPresent(UserNotificationPreferences.self, forKey: .notificationPrefs) ?? .default
    }
}

/// Operational status of a branch. More granular than `Branch.isActive` —
/// used by the Branches operational console to surface maintenance windows
/// and tournament-mode lockdowns at-a-glance.
public enum BranchOperationalStatus: String, Codable, CaseIterable, Sendable, Hashable {
    case active, maintenance, tournamentMode, closed

    public var labelKey: String { "branch.status.\(rawValue)" }
}

public struct Branch: Codable, Identifiable, Hashable, Sendable {
    public let id: EntityID
    public var code: String
    public var name: String
    public var nameAr: String
    public var area: String
    /// Max registered athletes the dojang is sized for. Compared against the
    /// roster count to surface the utilisation pill on dashboards.
    public var capacity: Int
    public var managerID: EntityID?
    public var focus: String

    // === Identity / contact (Stage 1.5) ===
    public var streetAddress: String
    public var streetAddressAr: String
    public var emirate: String
    public var country: String
    public var poBox: String?
    public var latitude: Double
    public var longitude: Double
    public var googlePlaceID: String?
    public var phone: String
    public var whatsappBusiness: String?
    public var email: String
    public var foundedAt: Date
    public var isActive: Bool
    public var brandHexColor: String?
    public var taglineEn: String?
    public var taglineAr: String?

    // === Operational hierarchy (Stage 1.6) ===
    /// True for the federation's head branch (Abu Dhabi Main). Exactly one
    /// branch should be marked main; the Branches Overview screen calls out
    /// the main branch with dominant styling.
    public var isMain: Bool
    /// Day-to-day operational state. Distinct from `isActive` (which is a
    /// hard on/off flag) — a branch can be active but in tournament mode.
    public var operationalStatus: BranchOperationalStatus

    public init(
        id: EntityID = UUID(),
        code: String,
        name: String,
        nameAr: String,
        area: String,
        capacity: Int,
        managerID: EntityID? = nil,
        focus: String,
        streetAddress: String = "",
        streetAddressAr: String = "",
        emirate: String = "Sharjah",
        country: String = "AE",
        poBox: String? = nil,
        latitude: Double = 0,
        longitude: Double = 0,
        googlePlaceID: String? = nil,
        phone: String = "",
        whatsappBusiness: String? = nil,
        email: String = "",
        foundedAt: Date = Date(),
        isActive: Bool = true,
        brandHexColor: String? = nil,
        taglineEn: String? = nil,
        taglineAr: String? = nil,
        isMain: Bool = false,
        operationalStatus: BranchOperationalStatus = .active
    ) {
        self.id = id
        self.code = code
        self.name = name
        self.nameAr = nameAr
        self.area = area
        self.capacity = capacity
        self.managerID = managerID
        self.focus = focus
        self.streetAddress = streetAddress
        self.streetAddressAr = streetAddressAr
        self.emirate = emirate
        self.country = country
        self.poBox = poBox
        self.latitude = latitude
        self.longitude = longitude
        self.googlePlaceID = googlePlaceID
        self.phone = phone
        self.whatsappBusiness = whatsappBusiness
        self.email = email
        self.foundedAt = foundedAt
        self.isActive = isActive
        self.brandHexColor = brandHexColor
        self.taglineEn = taglineEn
        self.taglineAr = taglineAr
        self.isMain = isMain
        self.operationalStatus = operationalStatus
    }
}
