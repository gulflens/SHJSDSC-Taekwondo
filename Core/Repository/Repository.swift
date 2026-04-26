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
    func attendance(athleteID: EntityID, since: Date) async throws -> [AttendanceRecord]
    func upsertAttendance(_ record: AttendanceRecord) async throws
    func upsertAttendance(_ records: [AttendanceRecord]) async throws
}

public protocol PerformanceRepository: Sendable {
    /// Latest performance score for the athlete.
    func score(athleteID: EntityID) async throws -> PerformanceScore?
    /// Full history of scores for an athlete, sorted newest first.
    func scoreHistory(athleteID: EntityID) async throws -> [PerformanceScore]
    /// Latest score per athlete in branch.
    func scores(branchID: EntityID) async throws -> [PerformanceScore]
    /// Latest score per athlete across the club.
    func allScores() async throws -> [PerformanceScore]
}

public protocol MatchRepository: Sendable {
    func matches(athleteID: EntityID) async throws -> [Match]
    func matches(branchID: EntityID) async throws -> [Match]
}

public protocol PerformanceEntryRepository: Sendable {
    func physicalTests(athleteID: EntityID) async throws -> [PhysicalTest]
    func assessments(athleteID: EntityID) async throws -> [TechnicalAssessment]
    func wellness(athleteID: EntityID, since: Date) async throws -> [WellnessEntry]
    func upsert(physicalTest: PhysicalTest) async throws
    func upsert(assessment: TechnicalAssessment) async throws
    func upsert(wellness entry: WellnessEntry) async throws
}

public protocol GradingRepository: Sendable {
    func eligibility(athleteID: EntityID, targetBelt: Belt) async throws -> GradingEligibility
    func gradingSessions(branchID: EntityID) async throws -> [GradingSession]
    func gradingSession(id: EntityID) async throws -> GradingSession?
    func upsert(_ session: GradingSession) async throws
    func gradingScores(sessionID: EntityID) async throws -> [GradingScore]
    func upsert(_ score: GradingScore) async throws
    func certificates(athleteID: EntityID) async throws -> [GradingCertificate]
    func issueCertificate(_ certificate: GradingCertificate) async throws
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
    PerformanceEntryRepository,
    GradingRepository,
    Sendable {}
