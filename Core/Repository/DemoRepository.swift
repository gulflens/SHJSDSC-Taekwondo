import Foundation

public actor DemoStore {
    public var users: [User]
    public var branches: [Branch]
    public var athletes: [Athlete]
    public var coaches: [Coach]
    public var sessions: [ClassSession]
    public var attendance: [AttendanceRecord]
    public var scores: [PerformanceScore]
    public var matches: [Match]
    public var currentUserID: EntityID

    public init(seed: SeedBundle) {
        self.users = seed.users
        self.branches = seed.branches
        self.coaches = seed.coaches
        self.athletes = seed.athletes
        self.sessions = seed.sessions
        self.attendance = seed.attendance
        self.scores = seed.scores
        self.matches = seed.matches
        self.currentUserID = seed.defaultCurrentUserID
    }

    public func upsertAthlete(_ a: Athlete) {
        if let i = athletes.firstIndex(where: { $0.id == a.id }) { athletes[i] = a } else { athletes.append(a) }
    }

    public func upsertAttendance(_ r: AttendanceRecord) {
        if let i = attendance.firstIndex(where: { $0.sessionID == r.sessionID && $0.athleteID == r.athleteID }) {
            attendance[i] = r
        } else {
            attendance.append(r)
        }
    }

    public func setCurrent(_ id: EntityID) {
        currentUserID = id
    }
}

public struct DemoRepository: Repository {
    private let store: DemoStore

    public init() {
        self.store = DemoStore(seed: SeedData.build())
    }

    // MARK: User

    public func currentUser() async throws -> User? {
        let id = await store.currentUserID
        return await store.users.first { $0.id == id }
    }

    public func availableUsers() async throws -> [User] {
        await store.users
    }

    public func setCurrentUser(id: EntityID) async throws {
        await store.setCurrent(id)
    }

    public func user(id: EntityID) async throws -> User? {
        await store.users.first { $0.id == id }
    }

    public func users(role: Role?) async throws -> [User] {
        let all = await store.users
        guard let role else { return all }
        return all.filter { $0.role == role }
    }

    // MARK: Branch

    public func branches() async throws -> [Branch] {
        await store.branches
    }

    public func branch(id: EntityID) async throws -> Branch? {
        await store.branches.first { $0.id == id }
    }

    // MARK: Athlete

    public func athletes() async throws -> [Athlete] {
        await store.athletes
    }

    public func athletes(branchID: EntityID) async throws -> [Athlete] {
        await store.athletes.filter { $0.branchID == branchID }
    }

    public func athletes(coachID: EntityID) async throws -> [Athlete] {
        await store.athletes.filter { $0.primaryCoachID == coachID }
    }

    public func athlete(id: EntityID) async throws -> Athlete? {
        await store.athletes.first { $0.id == id }
    }

    public func upsert(_ athlete: Athlete) async throws {
        await store.upsertAthlete(athlete)
    }

    // MARK: Coach

    public func coaches() async throws -> [Coach] {
        await store.coaches
    }

    public func coaches(branchID: EntityID) async throws -> [Coach] {
        await store.coaches.filter { $0.primaryBranchID == branchID || $0.secondaryBranchIDs.contains(branchID) }
    }

    public func coach(id: EntityID) async throws -> Coach? {
        await store.coaches.first { $0.id == id }
    }

    // MARK: Schedule

    public func sessions(branchID: EntityID, on day: Date) async throws -> [ClassSession] {
        let cal = Calendar.current
        let all = await store.sessions
        return all
            .filter { $0.branchID == branchID && cal.isDate($0.startsAt, inSameDayAs: day) }
            .sorted { $0.startsAt < $1.startsAt }
    }

    public func sessions(coachID: EntityID, on day: Date) async throws -> [ClassSession] {
        let cal = Calendar.current
        let all = await store.sessions
        return all
            .filter { $0.coachID == coachID && cal.isDate($0.startsAt, inSameDayAs: day) }
            .sorted { $0.startsAt < $1.startsAt }
    }

    public func session(id: EntityID) async throws -> ClassSession? {
        await store.sessions.first { $0.id == id }
    }

    // MARK: Attendance

    public func attendance(sessionID: EntityID) async throws -> [AttendanceRecord] {
        await store.attendance.filter { $0.sessionID == sessionID }
    }

    public func upsertAttendance(_ record: AttendanceRecord) async throws {
        await store.upsertAttendance(record)
    }

    public func upsertAttendance(_ records: [AttendanceRecord]) async throws {
        for r in records { await store.upsertAttendance(r) }
    }

    // MARK: Performance

    public func score(athleteID: EntityID) async throws -> PerformanceScore? {
        await store.scores.first { $0.athleteID == athleteID }
    }

    public func scores(branchID: EntityID) async throws -> [PerformanceScore] {
        let athleteIDs = Set(await store.athletes.filter { $0.branchID == branchID }.map { $0.id })
        return await store.scores.filter { athleteIDs.contains($0.athleteID) }
    }

    public func allScores() async throws -> [PerformanceScore] {
        await store.scores
    }

    // MARK: Match

    public func matches(athleteID: EntityID) async throws -> [Match] {
        await store.matches.filter { $0.ourAthleteID == athleteID }.sorted { $0.date > $1.date }
    }

    public func matches(branchID: EntityID) async throws -> [Match] {
        let athleteIDs = Set(await store.athletes.filter { $0.branchID == branchID }.map { $0.id })
        return await store.matches.filter { athleteIDs.contains($0.ourAthleteID) }
    }
}
