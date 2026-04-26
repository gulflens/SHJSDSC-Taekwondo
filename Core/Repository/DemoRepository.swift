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
    public var physicalTests: [PhysicalTest]
    public var assessments: [TechnicalAssessment]
    public var wellness: [WellnessEntry]
    public var gradingSessions: [GradingSession]
    public var gradingScores: [GradingScore]
    public var certificates: [GradingCertificate]
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
        self.physicalTests = seed.physicalTests
        self.assessments = seed.assessments
        self.wellness = seed.wellness
        self.gradingSessions = seed.gradingSessions
        self.gradingScores = seed.gradingScores
        self.certificates = seed.certificates
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

    public func upsertPhysicalTest(_ t: PhysicalTest) {
        if let i = physicalTests.firstIndex(where: { $0.id == t.id }) { physicalTests[i] = t } else { physicalTests.append(t) }
    }

    public func upsertAssessment(_ a: TechnicalAssessment) {
        if let i = assessments.firstIndex(where: { $0.id == a.id }) { assessments[i] = a } else { assessments.append(a) }
    }

    public func upsertWellness(_ w: WellnessEntry) {
        if let i = wellness.firstIndex(where: { $0.id == w.id }) { wellness[i] = w } else { wellness.append(w) }
    }

    public func upsertGradingSession(_ s: GradingSession) {
        if let i = gradingSessions.firstIndex(where: { $0.id == s.id }) { gradingSessions[i] = s } else { gradingSessions.append(s) }
    }

    public func upsertGradingScore(_ s: GradingScore) {
        if let i = gradingScores.firstIndex(where: { $0.id == s.id || ($0.sessionID == s.sessionID && $0.athleteID == s.athleteID) }) {
            gradingScores[i] = s
        } else {
            gradingScores.append(s)
        }
    }

    public func appendCertificate(_ c: GradingCertificate) {
        certificates.append(c)
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

    public func availableUsers() async throws -> [User] { await store.users }

    public func setCurrentUser(id: EntityID) async throws { await store.setCurrent(id) }

    public func user(id: EntityID) async throws -> User? {
        await store.users.first { $0.id == id }
    }

    public func users(role: Role?) async throws -> [User] {
        let all = await store.users
        guard let role else { return all }
        return all.filter { $0.role == role }
    }

    // MARK: Branch

    public func branches() async throws -> [Branch] { await store.branches }

    public func branch(id: EntityID) async throws -> Branch? {
        await store.branches.first { $0.id == id }
    }

    // MARK: Athlete

    public func athletes() async throws -> [Athlete] { await store.athletes }

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

    public func coaches() async throws -> [Coach] { await store.coaches }

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

    public func attendance(athleteID: EntityID, since: Date) async throws -> [AttendanceRecord] {
        await store.attendance.filter { $0.athleteID == athleteID && $0.recordedAt >= since }
    }

    public func upsertAttendance(_ record: AttendanceRecord) async throws {
        await store.upsertAttendance(record)
    }

    public func upsertAttendance(_ records: [AttendanceRecord]) async throws {
        for r in records { await store.upsertAttendance(r) }
    }

    // MARK: Performance scores

    public func score(athleteID: EntityID) async throws -> PerformanceScore? {
        await store.scores
            .filter { $0.athleteID == athleteID }
            .max(by: { $0.calculatedAt < $1.calculatedAt })
    }

    public func scoreHistory(athleteID: EntityID) async throws -> [PerformanceScore] {
        await store.scores
            .filter { $0.athleteID == athleteID }
            .sorted { $0.calculatedAt > $1.calculatedAt }
    }

    public func scores(branchID: EntityID) async throws -> [PerformanceScore] {
        let athleteIDs = Set(await store.athletes.filter { $0.branchID == branchID }.map { $0.id })
        let all = await store.scores.filter { athleteIDs.contains($0.athleteID) }
        return latestPerAthlete(all)
    }

    public func allScores() async throws -> [PerformanceScore] {
        latestPerAthlete(await store.scores)
    }

    private func latestPerAthlete(_ records: [PerformanceScore]) -> [PerformanceScore] {
        var byAthlete: [EntityID: PerformanceScore] = [:]
        for r in records {
            if let existing = byAthlete[r.athleteID] {
                if r.calculatedAt > existing.calculatedAt { byAthlete[r.athleteID] = r }
            } else {
                byAthlete[r.athleteID] = r
            }
        }
        return Array(byAthlete.values)
    }

    // MARK: Match

    public func matches(athleteID: EntityID) async throws -> [Match] {
        await store.matches.filter { $0.ourAthleteID == athleteID }.sorted { $0.date > $1.date }
    }

    public func matches(branchID: EntityID) async throws -> [Match] {
        let athleteIDs = Set(await store.athletes.filter { $0.branchID == branchID }.map { $0.id })
        return await store.matches.filter { athleteIDs.contains($0.ourAthleteID) }
    }

    // MARK: Performance entry

    public func physicalTests(athleteID: EntityID) async throws -> [PhysicalTest] {
        await store.physicalTests
            .filter { $0.athleteID == athleteID }
            .sorted { $0.recordedAt > $1.recordedAt }
    }

    public func assessments(athleteID: EntityID) async throws -> [TechnicalAssessment] {
        await store.assessments
            .filter { $0.athleteID == athleteID }
            .sorted { $0.recordedAt > $1.recordedAt }
    }

    public func wellness(athleteID: EntityID, since: Date) async throws -> [WellnessEntry] {
        await store.wellness
            .filter { $0.athleteID == athleteID && $0.recordedAt >= since }
            .sorted { $0.recordedAt > $1.recordedAt }
    }

    public func upsert(physicalTest: PhysicalTest) async throws {
        await store.upsertPhysicalTest(physicalTest)
    }

    public func upsert(assessment: TechnicalAssessment) async throws {
        await store.upsertAssessment(assessment)
    }

    public func upsert(wellness entry: WellnessEntry) async throws {
        await store.upsertWellness(entry)
    }

    // MARK: Grading

    public func eligibility(athleteID: EntityID, targetBelt: Belt) async throws -> GradingEligibility {
        guard let athlete = try await athlete(id: athleteID) else {
            return GradingEligibility(
                athleteID: athleteID, currentBelt: targetBelt, targetBelt: targetBelt,
                monthsAtCurrent: 0, attendancePct: 0,
                latestTechnicalAvg: 0, latestPhysicalComposite: 0,
                isEligible: false, blockingReasons: ["grading.blocking.attendance"]
            )
        }
        let since = Date().addingTimeInterval(-90 * 24 * 3600)
        let attRecords = try await attendance(athleteID: athleteID, since: since)
        let techs = try await assessments(athleteID: athleteID)
        let physes = try await physicalTests(athleteID: athleteID)
        return GradingEngine.evaluateEligibility(
            athlete: athlete,
            attendance: attRecords,
            technical: techs,
            physical: physes
        )
    }

    public func gradingSessions(branchID: EntityID) async throws -> [GradingSession] {
        await store.gradingSessions
            .filter { $0.branchID == branchID }
            .sorted { $0.scheduledAt < $1.scheduledAt }
    }

    public func gradingSession(id: EntityID) async throws -> GradingSession? {
        await store.gradingSessions.first { $0.id == id }
    }

    public func upsert(_ session: GradingSession) async throws {
        await store.upsertGradingSession(session)
    }

    public func gradingScores(sessionID: EntityID) async throws -> [GradingScore] {
        await store.gradingScores.filter { $0.sessionID == sessionID }
    }

    public func upsert(_ score: GradingScore) async throws {
        await store.upsertGradingScore(score)
    }

    public func certificates(athleteID: EntityID) async throws -> [GradingCertificate] {
        await store.certificates
            .filter { $0.athleteID == athleteID }
            .sorted { $0.awardedAt > $1.awardedAt }
    }

    public func issueCertificate(_ certificate: GradingCertificate) async throws {
        await store.appendCertificate(certificate)
    }
}
