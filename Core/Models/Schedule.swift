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

    // === Pillar 5: per-session coach engagement (each 1...5, optional). ===
    public var warmupRating: Int?
    public var listeningRating: Int?
    public var effortRating: Int?
    public var respectRating: Int?

    public init(
        id: EntityID = UUID(),
        sessionID: EntityID,
        athleteID: EntityID,
        state: AttendanceState,
        recordedAt: Date = Date(),
        warmupRating: Int? = nil,
        listeningRating: Int? = nil,
        effortRating: Int? = nil,
        respectRating: Int? = nil
    ) {
        self.id = id
        self.sessionID = sessionID
        self.athleteID = athleteID
        self.state = state
        self.recordedAt = recordedAt
        self.warmupRating = warmupRating.map { max(1, min(5, $0)) }
        self.listeningRating = listeningRating.map { max(1, min(5, $0)) }
        self.effortRating = effortRating.map { max(1, min(5, $0)) }
        self.respectRating = respectRating.map { max(1, min(5, $0)) }
    }

    /// Average of the 4 sub-ratings (1...5), nil if none captured.
    public var engagementAverage: Double? {
        let scores = [warmupRating, listeningRating, effortRating, respectRating].compactMap { $0 }
        guard !scores.isEmpty else { return nil }
        return Double(scores.reduce(0, +)) / Double(scores.count)
    }
}
