import Foundation

/// Stub implementation that conforms to `Repository` but holds no data.
/// Returns empty/nil for every read and silently no-ops for every write.
/// Replace with a real Supabase-backed implementation in Stage 5.
public struct SupabaseRepository: Repository {

    public init() {}

    // MARK: User
    public func currentUser() async throws -> User? { nil }
    public func availableUsers() async throws -> [User] { [] }
    public func setCurrentUser(id: EntityID) async throws {}
    public func user(id: EntityID) async throws -> User? { nil }
    public func users(role: Role?) async throws -> [User] { [] }

    // MARK: Branch
    public func branches() async throws -> [Branch] { [] }
    public func branch(id: EntityID) async throws -> Branch? { nil }

    // MARK: Athlete
    public func athletes() async throws -> [Athlete] { [] }
    public func athletes(branchID: EntityID) async throws -> [Athlete] { [] }
    public func athletes(coachID: EntityID) async throws -> [Athlete] { [] }
    public func athlete(id: EntityID) async throws -> Athlete? { nil }
    public func upsert(_ athlete: Athlete) async throws {}

    // MARK: Coach
    public func coaches() async throws -> [Coach] { [] }
    public func coaches(branchID: EntityID) async throws -> [Coach] { [] }
    public func coach(id: EntityID) async throws -> Coach? { nil }

    // MARK: Schedule
    public func sessions(branchID: EntityID, on day: Date) async throws -> [ClassSession] { [] }
    public func sessions(coachID: EntityID, on day: Date) async throws -> [ClassSession] { [] }
    public func session(id: EntityID) async throws -> ClassSession? { nil }

    // MARK: Attendance
    public func attendance(sessionID: EntityID) async throws -> [AttendanceRecord] { [] }
    public func upsertAttendance(_ record: AttendanceRecord) async throws {}
    public func upsertAttendance(_ records: [AttendanceRecord]) async throws {}

    // MARK: Performance
    public func score(athleteID: EntityID) async throws -> PerformanceScore? { nil }
    public func scores(branchID: EntityID) async throws -> [PerformanceScore] { [] }
    public func allScores() async throws -> [PerformanceScore] { [] }

    // MARK: Match
    public func matches(athleteID: EntityID) async throws -> [Match] { [] }
    public func matches(branchID: EntityID) async throws -> [Match] { [] }
}
