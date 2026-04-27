import Foundation

public enum Gender: String, Codable, CaseIterable, Sendable, Hashable {
    case male, female
}

public enum AgeGroup: String, Codable, CaseIterable, Sendable, Hashable {
    case cubs, kids, cadets, juniors, seniors

    public var labelKey: String { "age.\(rawValue)" }

    public static func from(age: Int) -> AgeGroup {
        switch age {
        case ..<10: .cubs
        case 10...11: .kids
        case 12...14: .cadets
        case 15...17: .juniors
        default: .seniors
        }
    }
}

public enum AthleteStatus: String, Codable, CaseIterable, Sendable, Hashable {
    case competitionTeam, readyToGrade, watch, rest, active

    public var labelKey: String { "status.\(rawValue)" }
}

public struct Athlete: Codable, Identifiable, Hashable, Sendable {
    public let id: EntityID
    public var memberNumber: Int
    public var fullName: String
    public var fullNameAr: String
    public var dateOfBirth: Date
    public var gender: Gender
    public var nationality: String
    public var emiratesID: String?
    public var branchID: EntityID
    public var primaryCoachID: EntityID?
    public var joinedAt: Date
    public var currentBelt: Belt
    public var beltHistory: [Belt]
    public var weightKg: Double
    public var status: AthleteStatus
    public var avatarSeed: String
    public var avatarURL: String?

    public init(
        id: EntityID = UUID(),
        memberNumber: Int,
        fullName: String,
        fullNameAr: String,
        dateOfBirth: Date,
        gender: Gender,
        nationality: String = "AE",
        emiratesID: String? = nil,
        branchID: EntityID,
        primaryCoachID: EntityID? = nil,
        joinedAt: Date,
        currentBelt: Belt,
        beltHistory: [Belt] = [],
        weightKg: Double,
        status: AthleteStatus,
        avatarSeed: String,
        avatarURL: String? = nil
    ) {
        self.id = id
        self.memberNumber = memberNumber
        self.fullName = fullName
        self.fullNameAr = fullNameAr
        self.dateOfBirth = dateOfBirth
        self.gender = gender
        self.nationality = nationality
        self.emiratesID = emiratesID
        self.branchID = branchID
        self.primaryCoachID = primaryCoachID
        self.joinedAt = joinedAt
        self.currentBelt = currentBelt
        self.beltHistory = beltHistory
        self.weightKg = weightKg
        self.status = status
        self.avatarSeed = avatarSeed
        self.avatarURL = avatarURL
    }

    public var age: Int {
        Calendar.current.dateComponents([.year], from: dateOfBirth, to: Date()).year ?? 0
    }

    public var ageGroup: AgeGroup { AgeGroup.from(age: age) }

    public var initials: String {
        let parts = fullName.split(separator: " ").prefix(2)
        return parts.map { String($0.prefix(1)) }.joined().uppercased()
    }
}
