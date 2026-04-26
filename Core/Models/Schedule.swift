import Foundation

public enum ClassDiscipline: String, Codable, CaseIterable, Sendable, Hashable {
    case poomsae, kyorugi, fundamentals, competition, fitness

    public var labelKey: String { "discipline.\(rawValue)" }
}

public struct ClassSession: Codable, Identifiable, Hashable, Sendable {
    public let id: EntityID
    public var title: String
    public var discipline: ClassDiscipline
    public var branchID: EntityID
    public var coachID: EntityID
    public var startsAt: Date
    public var endsAt: Date
    public var capacity: Int
    public var enrolledAthleteIDs: [EntityID]
    public var ageGroup: AgeGroup

    public init(
        id: EntityID = UUID(),
        title: String,
        discipline: ClassDiscipline,
        branchID: EntityID,
        coachID: EntityID,
        startsAt: Date,
        endsAt: Date,
        capacity: Int,
        enrolledAthleteIDs: [EntityID] = [],
        ageGroup: AgeGroup
    ) {
        self.id = id
        self.title = title
        self.discipline = discipline
        self.branchID = branchID
        self.coachID = coachID
        self.startsAt = startsAt
        self.endsAt = endsAt
        self.capacity = capacity
        self.enrolledAthleteIDs = enrolledAthleteIDs
        self.ageGroup = ageGroup
    }
}

public enum AttendanceState: String, Codable, CaseIterable, Sendable, Hashable {
    case present, absent, late, excused

    public var labelKey: String { "attendance.\(rawValue)" }
}

public struct AttendanceRecord: Codable, Identifiable, Hashable, Sendable {
    public let id: EntityID
    public var sessionID: EntityID
    public var athleteID: EntityID
    public var state: AttendanceState
    public var recordedAt: Date

    public init(
        id: EntityID = UUID(),
        sessionID: EntityID,
        athleteID: EntityID,
        state: AttendanceState,
        recordedAt: Date = Date()
    ) {
        self.id = id
        self.sessionID = sessionID
        self.athleteID = athleteID
        self.state = state
        self.recordedAt = recordedAt
    }
}
