import Foundation

public enum WeightCategory: String, Codable, CaseIterable, Sendable, Hashable {
    case cubsUnder28
    case cubsUnder32
    case cubsUnder36
    case cubsOver36
    case cadetsUnder37
    case cadetsUnder45
    case cadetsUnder53
    case cadetsUnder61
    case cadetsOver61
    case juniorsUnder48
    case juniorsUnder55
    case juniorsUnder63
    case juniorsUnder73
    case juniorsOver73
    case seniorsUnder58
    case seniorsUnder68
    case seniorsUnder80
    case seniorsHeavy

    public var range: (lower: Double?, upper: Double?) {
        switch self {
        case .cubsUnder28: (nil, 28)
        case .cubsUnder32: (28, 32)
        case .cubsUnder36: (32, 36)
        case .cubsOver36: (36, nil)
        case .cadetsUnder37: (nil, 37)
        case .cadetsUnder45: (37, 45)
        case .cadetsUnder53: (45, 53)
        case .cadetsUnder61: (53, 61)
        case .cadetsOver61: (61, nil)
        case .juniorsUnder48: (nil, 48)
        case .juniorsUnder55: (48, 55)
        case .juniorsUnder63: (55, 63)
        case .juniorsUnder73: (63, 73)
        case .juniorsOver73: (73, nil)
        case .seniorsUnder58: (nil, 58)
        case .seniorsUnder68: (58, 68)
        case .seniorsUnder80: (68, 80)
        case .seniorsHeavy: (80, nil)
        }
    }

    public var ageGroup: AgeGroup {
        switch self {
        case .cubsUnder28, .cubsUnder32, .cubsUnder36, .cubsOver36: .cubs
        case .cadetsUnder37, .cadetsUnder45, .cadetsUnder53, .cadetsUnder61, .cadetsOver61: .cadets
        case .juniorsUnder48, .juniorsUnder55, .juniorsUnder63, .juniorsUnder73, .juniorsOver73: .juniors
        case .seniorsUnder58, .seniorsUnder68, .seniorsUnder80, .seniorsHeavy: .seniors
        }
    }

    public var labelKey: String { "weight.\(rawValue)" }

    public var shortLabel: String {
        let lower = range.lower
        let upper = range.upper
        if let upper, lower == nil { return "−\(Int(upper))kg" }
        if let lower, upper == nil { return "+\(Int(lower))kg" }
        if let lower, let upper { return "\(Int(lower))–\(Int(upper))kg" }
        return rawValue
    }

    /// Closest matching category given an athlete's age group + weight (treats
    /// `.kids` as cubs since WT competitions only start at cadet age).
    public static func suggested(for athlete: Athlete) -> WeightCategory? {
        let groupForCompetition: AgeGroup = athlete.ageGroup == .kids ? .cubs : athlete.ageGroup
        let weight = athlete.weightKg
        return Self.allCases.first { wc in
            guard wc.ageGroup == groupForCompetition else { return false }
            let lowerOK = wc.range.lower.map { weight > $0 } ?? true
            let upperOK = wc.range.upper.map { weight <= $0 } ?? true
            return lowerOK && upperOK
        }
    }
}

public enum HostingFederation: String, Codable, CaseIterable, Sendable, Hashable {
    case wtf, gcc, uae, clubInternal

    public var labelKey: String { "federation.\(rawValue)" }
}

/// Geographic / political reach of an event (Pillar 7).
public enum EventLevel: String, Codable, CaseIterable, Sendable, Hashable {
    case local, national, regional, international

    public var labelKey: String { "event_level.\(rawValue)" }

    /// Color used for level pills in the UI — escalates with reach.
    public var rank: Int {
        switch self {
        case .local: 1
        case .national: 2
        case .regional: 3
        case .international: 4
        }
    }
}

public struct Tournament: Codable, Identifiable, Hashable, Sendable {
    public let id: EntityID
    public var name: String
    public var nameAr: String?
    public var hostingFederation: HostingFederation
    public var startsAt: Date
    public var endsAt: Date
    public var location: String
    public var locationAr: String?
    public var isOfficial: Bool
    public var weightCategoriesOffered: [WeightCategory]

    /// Reach — local / national / regional / international (Pillar 7).
    public var level: EventLevel?
    /// Free-form name of the body sanctioning the event when more granular
    /// than `hostingFederation` (e.g. "UAE TKD Federation", "WT", "Asian TKD").
    public var sanctioningBody: String?

    public init(
        id: EntityID = UUID(),
        name: String,
        nameAr: String? = nil,
        hostingFederation: HostingFederation,
        startsAt: Date,
        endsAt: Date,
        location: String,
        locationAr: String? = nil,
        isOfficial: Bool,
        weightCategoriesOffered: [WeightCategory],
        level: EventLevel? = nil,
        sanctioningBody: String? = nil
    ) {
        self.id = id
        self.name = name
        self.nameAr = nameAr
        self.hostingFederation = hostingFederation
        self.startsAt = startsAt
        self.endsAt = endsAt
        self.location = location
        self.locationAr = locationAr
        self.isOfficial = isOfficial
        self.weightCategoriesOffered = weightCategoriesOffered
        self.level = level
        self.sanctioningBody = sanctioningBody
    }
}

public enum RegistrationStatus: String, Codable, CaseIterable, Sendable, Hashable {
    case registered, weighedIn, withdrawn, disqualified

    public var labelKey: String { "registration.\(rawValue)" }
}

public struct TournamentRegistration: Codable, Identifiable, Hashable, Sendable {
    public let id: EntityID
    public var tournamentID: EntityID
    public var athleteID: EntityID
    public var weightCategory: WeightCategory
    public var seedRank: Int?
    public var registeredAt: Date
    public var status: RegistrationStatus

    // === Pillar 7: per-event result ===
    public var ageDivisionEntered: AgeGroup?
    public var bracketSize: Int?
    public var finalPosition: Int?
    public var medal: MedalType?

    public init(
        id: EntityID = UUID(),
        tournamentID: EntityID,
        athleteID: EntityID,
        weightCategory: WeightCategory,
        seedRank: Int? = nil,
        registeredAt: Date = Date(),
        status: RegistrationStatus = .registered,
        ageDivisionEntered: AgeGroup? = nil,
        bracketSize: Int? = nil,
        finalPosition: Int? = nil,
        medal: MedalType? = nil
    ) {
        self.id = id
        self.tournamentID = tournamentID
        self.athleteID = athleteID
        self.weightCategory = weightCategory
        self.seedRank = seedRank
        self.registeredAt = registeredAt
        self.status = status
        self.ageDivisionEntered = ageDivisionEntered
        self.bracketSize = bracketSize
        self.finalPosition = finalPosition
        self.medal = medal
    }
}

public struct WeightCutEntry: Codable, Identifiable, Hashable, Sendable {
    public let id: EntityID
    public var registrationID: EntityID
    public var recordedAt: Date
    public var currentKg: Double
    public var targetKg: Double
    public var notes: String?

    public init(
        id: EntityID = UUID(),
        registrationID: EntityID,
        recordedAt: Date,
        currentKg: Double,
        targetKg: Double,
        notes: String? = nil
    ) {
        self.id = id
        self.registrationID = registrationID
        self.recordedAt = recordedAt
        self.currentKg = currentKg
        self.targetKg = targetKg
        self.notes = notes
    }

    public var deltaKg: Double { currentKg - targetKg }

    public func daysToCompetition(_ competitionDate: Date) -> Int {
        let cal = Calendar.current
        return cal.dateComponents([.day], from: recordedAt, to: competitionDate).day ?? 0
    }
}

public struct Bracket: Codable, Identifiable, Hashable, Sendable {
    public let id: EntityID
    public var tournamentID: EntityID
    public var weightCategory: WeightCategory
    public var seeds: [EntityID]
    public var generatedAt: Date

    public init(
        id: EntityID = UUID(),
        tournamentID: EntityID,
        weightCategory: WeightCategory,
        seeds: [EntityID],
        generatedAt: Date = Date()
    ) {
        self.id = id
        self.tournamentID = tournamentID
        self.weightCategory = weightCategory
        self.seeds = seeds
        self.generatedAt = generatedAt
    }
}

public struct BracketMatch: Codable, Identifiable, Hashable, Sendable {
    public let id: EntityID
    public var bracketID: EntityID
    public var round: Int
    public var position: Int
    public var athleteAID: EntityID?
    public var athleteBID: EntityID?
    public var winnerID: EntityID?
    public var matchID: EntityID?

    public init(
        id: EntityID = UUID(),
        bracketID: EntityID,
        round: Int,
        position: Int,
        athleteAID: EntityID? = nil,
        athleteBID: EntityID? = nil,
        winnerID: EntityID? = nil,
        matchID: EntityID? = nil
    ) {
        self.id = id
        self.bracketID = bracketID
        self.round = round
        self.position = position
        self.athleteAID = athleteAID
        self.athleteBID = athleteBID
        self.winnerID = winnerID
        self.matchID = matchID
    }
}
