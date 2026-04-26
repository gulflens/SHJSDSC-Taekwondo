import Foundation

public protocol UserRepository: Sendable {
    func currentUser() async throws -> User?
    func availableUsers() async throws -> [User]
    func setCurrentUser(id: EntityID) async throws
    func user(id: EntityID) async throws -> User?
    func users(role: Role?) async throws -> [User]
}

public protocol BranchRepository: Sendable {
    func branches() async throws -> [Branch]
    func branch(id: EntityID) async throws -> Branch?
}

public protocol AthleteRepository: Sendable {
    func athletes() async throws -> [Athlete]
    func athletes(branchID: EntityID) async throws -> [Athlete]
    func athletes(coachID: EntityID) async throws -> [Athlete]
    func athlete(id: EntityID) async throws -> Athlete?
    func upsert(_ athlete: Athlete) async throws
}

public protocol CoachRepository: Sendable {
    func coaches() async throws -> [Coach]
    func coaches(branchID: EntityID) async throws -> [Coach]
    func coach(id: EntityID) async throws -> Coach?
}

public protocol ScheduleRepository: Sendable {
    func sessions(branchID: EntityID, on day: Date) async throws -> [ClassSession]
    func sessions(coachID: EntityID, on day: Date) async throws -> [ClassSession]
    func session(id: EntityID) async throws -> ClassSession?
}

public protocol AttendanceRepository: Sendable {
    func attendance(sessionID: EntityID) async throws -> [AttendanceRecord]
    func upsertAttendance(_ record: AttendanceRecord) async throws
    func upsertAttendance(_ records: [AttendanceRecord]) async throws
}

public protocol PerformanceRepository: Sendable {
    func score(athleteID: EntityID) async throws -> PerformanceScore?
    func scores(branchID: EntityID) async throws -> [PerformanceScore]
    func allScores() async throws -> [PerformanceScore]
}

public protocol MatchRepository: Sendable {
    func matches(athleteID: EntityID) async throws -> [Match]
    func matches(branchID: EntityID) async throws -> [Match]
}

public protocol Repository:
    UserRepository,
    BranchRepository,
    AthleteRepository,
    CoachRepository,
    ScheduleRepository,
    AttendanceRepository,
    PerformanceRepository,
    MatchRepository,
    Sendable {}
