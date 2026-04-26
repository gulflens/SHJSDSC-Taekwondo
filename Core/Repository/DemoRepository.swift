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
    public var tournaments: [Tournament]
    public var registrations: [TournamentRegistration]
    public var weightCuts: [WeightCutEntry]
    public var brackets: [Bracket]
    public var bracketMatches: [BracketMatch]
    public var activeMatch: Match?
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
        self.tournaments = seed.tournaments
        self.registrations = seed.registrations
        self.weightCuts = seed.weightCuts
        self.brackets = seed.brackets
        self.bracketMatches = seed.bracketMatches
        self.activeMatch = nil
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

    public func setCurrent(_ id: EntityID) { currentUserID = id }

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

    public func appendCertificate(_ c: GradingCertificate) { certificates.append(c) }

    public func upsertTournament(_ t: Tournament) {
        if let i = tournaments.firstIndex(where: { $0.id == t.id }) { tournaments[i] = t } else { tournaments.append(t) }
    }

    public func upsertRegistration(_ r: TournamentRegistration) {
        if let i = registrations.firstIndex(where: { $0.id == r.id }) { registrations[i] = r } else { registrations.append(r) }
    }

    public func upsertWeightCut(_ w: WeightCutEntry) {
        if let i = weightCuts.firstIndex(where: { $0.id == w.id }) { weightCuts[i] = w } else { weightCuts.append(w) }
    }

    public func upsertBracket(_ b: Bracket) {
        if let i = brackets.firstIndex(where: { $0.id == b.id }) { brackets[i] = b } else { brackets.append(b) }
    }

    public func upsertBracketMatch(_ m: BracketMatch) {
        if let i = bracketMatches.firstIndex(where: { $0.id == m.id }) { bracketMatches[i] = m } else { bracketMatches.append(m) }
    }

    public func upsertMatch(_ m: Match) {
        if let i = matches.firstIndex(where: { $0.id == m.id }) { matches[i] = m } else { matches.append(m) }
    }

    public func setActiveMatch(_ m: Match?) { activeMatch = m }

    public func appendEventToActive(_ e: ScoreEvent) {
        guard var m = activeMatch, e.matchID == m.id else { return }
        m.events.append(e)
        let pts = e.action.points
        if e.action == .penalty {
            switch e.side {
            case .chung: m.opponentScore += pts
            case .hong: m.ourScore += pts
            }
        } else {
            switch e.side {
            case .chung: m.ourScore += pts
            case .hong: m.opponentScore += pts
            }
        }
        activeMatch = m
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
    public func user(id: EntityID) async throws -> User? { await store.users.first { $0.id == id } }
    public func users(role: Role?) async throws -> [User] {
        let all = await store.users
        guard let role else { return all }
        return all.filter { $0.role == role }
    }

    // MARK: Branch

    public func branches() async throws -> [Branch] { await store.branches }
    public func branch(id: EntityID) async throws -> Branch? { await store.branches.first { $0.id == id } }

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
    public func upsert(_ athlete: Athlete) async throws { await store.upsertAthlete(athlete) }

    // MARK: Coach

    public func coaches() async throws -> [Coach] { await store.coaches }
    public func coaches(branchID: EntityID) async throws -> [Coach] {
        await store.coaches.filter { $0.primaryBranchID == branchID || $0.secondaryBranchIDs.contains(branchID) }
    }
    public func coach(id: EntityID) async throws -> Coach? { await store.coaches.first { $0.id == id } }

    // MARK: Schedule

    public func sessions(branchID: EntityID, on day: Date) async throws -> [ClassSession] {
        let cal = Calendar.current
        let all = await store.sessions
        return all.filter { $0.branchID == branchID && cal.isDate($0.startsAt, inSameDayAs: day) }
            .sorted { $0.startsAt < $1.startsAt }
    }
    public func sessions(coachID: EntityID, on day: Date) async throws -> [ClassSession] {
        let cal = Calendar.current
        let all = await store.sessions
        return all.filter { $0.coachID == coachID && cal.isDate($0.startsAt, inSameDayAs: day) }
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
    public func upsertAttendance(_ record: AttendanceRecord) async throws { await store.upsertAttendance(record) }
    public func upsertAttendance(_ records: [AttendanceRecord]) async throws {
        for r in records { await store.upsertAttendance(r) }
    }

    // MARK: Performance scores

    public func score(athleteID: EntityID) async throws -> PerformanceScore? {
        await store.scores.filter { $0.athleteID == athleteID }
            .max(by: { $0.calculatedAt < $1.calculatedAt })
    }
    public func scoreHistory(athleteID: EntityID) async throws -> [PerformanceScore] {
        await store.scores.filter { $0.athleteID == athleteID }
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
        await store.matches.filter { $0.ourAthleteID == athleteID || $0.opponentAthleteID == athleteID }
            .sorted { $0.date > $1.date }
    }
    public func matches(branchID: EntityID) async throws -> [Match] {
        let athleteIDs = Set(await store.athletes.filter { $0.branchID == branchID }.map { $0.id })
        return await store.matches.filter { athleteIDs.contains($0.ourAthleteID) }
    }
    public func matches(tournamentID: EntityID) async throws -> [Match] {
        await store.matches.filter { $0.tournamentID == tournamentID }
            .sorted { $0.date < $1.date }
    }
    public func upsertMatch(_ match: Match) async throws { await store.upsertMatch(match) }

    // MARK: Performance entry

    public func physicalTests(athleteID: EntityID) async throws -> [PhysicalTest] {
        await store.physicalTests.filter { $0.athleteID == athleteID }.sorted { $0.recordedAt > $1.recordedAt }
    }
    public func assessments(athleteID: EntityID) async throws -> [TechnicalAssessment] {
        await store.assessments.filter { $0.athleteID == athleteID }.sorted { $0.recordedAt > $1.recordedAt }
    }
    public func wellness(athleteID: EntityID, since: Date) async throws -> [WellnessEntry] {
        await store.wellness.filter { $0.athleteID == athleteID && $0.recordedAt >= since }
            .sorted { $0.recordedAt > $1.recordedAt }
    }
    public func upsert(physicalTest: PhysicalTest) async throws { await store.upsertPhysicalTest(physicalTest) }
    public func upsert(assessment: TechnicalAssessment) async throws { await store.upsertAssessment(assessment) }
    public func upsert(wellness entry: WellnessEntry) async throws { await store.upsertWellness(entry) }

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
        return GradingEngine.evaluateEligibility(athlete: athlete, attendance: attRecords, technical: techs, physical: physes)
    }
    public func gradingSessions(branchID: EntityID) async throws -> [GradingSession] {
        await store.gradingSessions.filter { $0.branchID == branchID }.sorted { $0.scheduledAt < $1.scheduledAt }
    }
    public func gradingSession(id: EntityID) async throws -> GradingSession? {
        await store.gradingSessions.first { $0.id == id }
    }
    public func upsert(_ session: GradingSession) async throws { await store.upsertGradingSession(session) }
    public func gradingScores(sessionID: EntityID) async throws -> [GradingScore] {
        await store.gradingScores.filter { $0.sessionID == sessionID }
    }
    public func upsert(_ score: GradingScore) async throws { await store.upsertGradingScore(score) }
    public func certificates(athleteID: EntityID) async throws -> [GradingCertificate] {
        await store.certificates.filter { $0.athleteID == athleteID }.sorted { $0.awardedAt > $1.awardedAt }
    }
    public func issueCertificate(_ certificate: GradingCertificate) async throws { await store.appendCertificate(certificate) }

    // MARK: Tournament

    public func tournaments() async throws -> [Tournament] {
        await store.tournaments.sorted { $0.startsAt < $1.startsAt }
    }
    public func tournament(id: EntityID) async throws -> Tournament? {
        await store.tournaments.first { $0.id == id }
    }
    public func upsert(tournament: Tournament) async throws { await store.upsertTournament(tournament) }

    public func registrations(tournamentID: EntityID) async throws -> [TournamentRegistration] {
        await store.registrations.filter { $0.tournamentID == tournamentID }
    }
    public func registrations(athleteID: EntityID) async throws -> [TournamentRegistration] {
        await store.registrations.filter { $0.athleteID == athleteID }
    }
    public func upsert(registration: TournamentRegistration) async throws { await store.upsertRegistration(registration) }

    public func weightCutHistory(registrationID: EntityID) async throws -> [WeightCutEntry] {
        await store.weightCuts.filter { $0.registrationID == registrationID }
            .sorted { $0.recordedAt < $1.recordedAt }
    }
    public func upsert(weightCut: WeightCutEntry) async throws { await store.upsertWeightCut(weightCut) }

    public func brackets(tournamentID: EntityID) async throws -> [Bracket] {
        await store.brackets.filter { $0.tournamentID == tournamentID }
    }
    public func upsert(bracket: Bracket) async throws { await store.upsertBracket(bracket) }

    public func bracketMatches(bracketID: EntityID) async throws -> [BracketMatch] {
        await store.bracketMatches.filter { $0.bracketID == bracketID }
            .sorted { $0.round == $1.round ? $0.position < $1.position : $0.round < $1.round }
    }
    public func upsert(bracketMatch: BracketMatch) async throws { await store.upsertBracketMatch(bracketMatch) }

    // MARK: Live match

    public func activeMatch() async throws -> Match? { await store.activeMatch }
    public func startMatch(_ match: Match) async throws { await store.setActiveMatch(match) }
    public func recordEvent(_ event: ScoreEvent) async throws { await store.appendEventToActive(event) }
    public func endRound(matchID: EntityID) async throws {
        // Round transitions are managed in the LiveMatchStore; nothing to persist here
        // until finalize. Kept to satisfy the protocol contract.
    }
    public func finalizeMatch(_ match: Match) async throws {
        await store.upsertMatch(match)
        await store.setActiveMatch(nil)
    }
}
