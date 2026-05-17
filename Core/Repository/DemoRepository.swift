import Foundation
import CryptoKit

public enum DemoAuthError: Error, LocalizedError {
    case invalidCredentials
    /// Raised when account creation targets the reserved project-owner email.
    case ownerEmailReserved

    public var errorDescription: String? {
        switch self {
        case .invalidCredentials: String(localized: "auth.invalid_credential")
        case .ownerEmailReserved: String(localized: "auth.owner_email_reserved")
        }
    }
}

nonisolated enum PasswordHasher {
    static func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

public actor DemoStore {
    public var users: [User]
    public var branches: [Branch]
    public var athletes: [Athlete]
    public var coaches: [Coach]
    public var sessions: [ClassSession]
    public var attendance: [AttendanceRecord]
    public var scores: [PerformanceScore]
    public var matches: [Match]
    public var physicalMetrics: [PhysicalMetric]
    public var technicalSkills: [TechnicalSkill]
    public var poomsaeAssessments: [PoomsaeAssessment]
    public var goals: [Goal] = []
    public var trainingLoad: [TrainingLoadEntry] = []
    public var drills: [DrillLibraryEntry] = []
    public var improvementPlans: [ImprovementPlan] = []
    public var peerBenchmarks: [PeerBenchmark] = []
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
    public var announcements: [Announcement]
    public var rsvps: [AnnouncementRSVP]
    public var certifications: [Certification]
    public var auditLog: [AuditEntry]
    public var facilities: [BranchFacility]
    public var branchHours: [BranchHours]
    public var branchPrograms: [BranchProgram]
    public var branchInventories: [BranchInventory]
    public var branchCompliances: [BranchCompliance]
    public var branchPricings: [BranchPricing]
    public var branchFinancials: [BranchFinancials]
    public var branchMedias: [BranchMedia]
    public var branchSocialLinks: [BranchSocialLinks]
    public var branchSafeguardings: [BranchSafeguarding]
    public var branchMilestones: [BranchMilestone]
    public var athleteGroups: [AthleteGroup]
    public var currentUserID: EntityID
    private var emailPasswordHashes: [String: String] = [:]
    private var emailUserIDs: [String: EntityID] = [:]
    /// Monotonic counter — starts above the highest seeded member number,
    /// only ever advances. Mirrors Postgres sequence semantics so demo
    /// behaviour matches the live backend (deleting an athlete does not
    /// recycle their number).
    private var memberNumberCounter: Int = 1001

    public init(seed: SeedBundle) {
        self.users = seed.users
        self.branches = seed.branches
        self.coaches = seed.coaches
        self.athletes = seed.athletes
        self.sessions = seed.sessions
        self.attendance = seed.attendance
        self.scores = seed.scores
        self.matches = seed.matches
        self.physicalMetrics = seed.physicalMetrics
        self.technicalSkills = seed.technicalSkills
        self.poomsaeAssessments = seed.poomsaeAssessments
        self.trainingLoad = seed.trainingLoad
        self.drills = seed.drills
        self.improvementPlans = seed.improvementPlans
        self.peerBenchmarks = seed.peerBenchmarks
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
        self.announcements = seed.announcements
        self.rsvps = seed.rsvps
        self.certifications = seed.certifications
        self.auditLog = seed.auditLog
        self.facilities = seed.facilities
        self.branchHours = seed.branchHours
        self.branchPrograms = seed.branchPrograms
        self.branchInventories = seed.branchInventories
        self.branchCompliances = seed.branchCompliances
        self.branchPricings = seed.branchPricings
        self.branchFinancials = seed.branchFinancials
        self.branchMedias = seed.branchMedias
        self.branchSocialLinks = seed.branchSocialLinks
        self.branchSafeguardings = seed.branchSafeguardings
        self.branchMilestones = seed.branchMilestones
        self.athleteGroups = seed.athleteGroups
        self.currentUserID = seed.defaultCurrentUserID
        for cred in seed.credentials {
            let key = DemoStore.normalizedEmail(cred.email)
            emailPasswordHashes[key] = cred.passwordHash
            emailUserIDs[key] = cred.userID
        }
        self.memberNumberCounter = max(1001, (seed.athletes.map(\.memberNumber).max() ?? 1000) + 1)
    }

    public func reserveNextMemberNumber() -> Int {
        let value = memberNumberCounter
        memberNumberCounter += 1
        return value
    }

    /// Email lookup key — trimmed and lower-cased so sign-in tolerates stray
    /// whitespace and any capitalisation the keyboard or a paste introduces.
    nonisolated static func normalizedEmail(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    public func validateSignIn(email: String, password: String) throws {
        let key = DemoStore.normalizedEmail(email)
        let inputHash = PasswordHasher.sha256(password)
        guard let storedHash = emailPasswordHashes[key], storedHash == inputHash,
              let userID = emailUserIDs[key] else {
            throw DemoAuthError.invalidCredentials
        }
        currentUserID = userID
    }

    public func registerCredential(email: String, password: String, userID: EntityID) {
        let key = DemoStore.normalizedEmail(email)
        emailPasswordHashes[key] = PasswordHasher.sha256(password)
        emailUserIDs[key] = userID
    }

    public func upsertAthlete(_ a: Athlete) {
        if let i = athletes.firstIndex(where: { $0.id == a.id }) { athletes[i] = a } else { athletes.append(a) }
    }

    public func upsertCoach(_ c: Coach) {
        if let i = coaches.firstIndex(where: { $0.id == c.id }) { coaches[i] = c } else { coaches.append(c) }
    }

    public func upsertBranch(_ b: Branch) {
        if let i = branches.firstIndex(where: { $0.id == b.id }) { branches[i] = b } else { branches.append(b) }
    }

    public func upsertFacility(_ f: BranchFacility) {
        if let i = facilities.firstIndex(where: { $0.branchID == f.branchID }) {
            facilities[i] = f
        } else {
            facilities.append(f)
        }
    }
    public func upsertBranchHours(_ h: BranchHours) {
        if let i = branchHours.firstIndex(where: { $0.branchID == h.branchID }) {
            branchHours[i] = h
        } else {
            branchHours.append(h)
        }
    }
    public func upsertBranchProgram(_ p: BranchProgram) {
        if let i = branchPrograms.firstIndex(where: { $0.id == p.id }) {
            branchPrograms[i] = p
        } else {
            branchPrograms.append(p)
        }
    }
    public func upsertBranchInventory(_ inv: BranchInventory) {
        if let i = branchInventories.firstIndex(where: { $0.branchID == inv.branchID }) {
            branchInventories[i] = inv
        } else {
            branchInventories.append(inv)
        }
    }
    public func upsertBranchCompliance(_ c: BranchCompliance) {
        if let i = branchCompliances.firstIndex(where: { $0.branchID == c.branchID }) {
            branchCompliances[i] = c
        } else {
            branchCompliances.append(c)
        }
    }
    public func upsertBranchPricing(_ p: BranchPricing) {
        if let i = branchPricings.firstIndex(where: { $0.branchID == p.branchID }) {
            branchPricings[i] = p
        } else {
            branchPricings.append(p)
        }
    }
    public func upsertBranchFinancials(_ f: BranchFinancials) {
        if let i = branchFinancials.firstIndex(where: { $0.id == f.id }) {
            branchFinancials[i] = f
        } else {
            branchFinancials.append(f)
        }
    }
    public func upsertBranchMedia(_ m: BranchMedia) {
        if let i = branchMedias.firstIndex(where: { $0.branchID == m.branchID }) {
            branchMedias[i] = m
        } else {
            branchMedias.append(m)
        }
    }
    public func upsertBranchSocialLinks(_ s: BranchSocialLinks) {
        if let i = branchSocialLinks.firstIndex(where: { $0.branchID == s.branchID }) {
            branchSocialLinks[i] = s
        } else {
            branchSocialLinks.append(s)
        }
    }
    public func upsertBranchSafeguarding(_ s: BranchSafeguarding) {
        if let i = branchSafeguardings.firstIndex(where: { $0.branchID == s.branchID }) {
            branchSafeguardings[i] = s
        } else {
            branchSafeguardings.append(s)
        }
    }
    public func upsertBranchMilestone(_ m: BranchMilestone) {
        if let i = branchMilestones.firstIndex(where: { $0.id == m.id }) {
            branchMilestones[i] = m
        } else {
            branchMilestones.append(m)
        }
    }

    public func upsertAthleteGroup(_ g: AthleteGroup) {
        if let i = athleteGroups.firstIndex(where: { $0.id == g.id }) {
            athleteGroups[i] = g
        } else {
            athleteGroups.append(g)
        }
    }

    public func deleteAthleteGroup(id: EntityID) {
        athleteGroups.removeAll { $0.id == id }
    }

    public func upsertSession(_ s: ClassSession) {
        if let i = sessions.firstIndex(where: { $0.id == s.id }) { sessions[i] = s } else { sessions.append(s) }
    }

    public func deleteSession(id: EntityID) {
        sessions.removeAll { $0.id == id }
    }

    public func upsertAttendance(_ r: AttendanceRecord) {
        if let i = attendance.firstIndex(where: { $0.sessionID == r.sessionID && $0.athleteID == r.athleteID }) {
            attendance[i] = r
        } else {
            attendance.append(r)
        }
    }

    public func setCurrent(_ id: EntityID) { currentUserID = id }

    public func upsertPhysicalMetric(_ m: PhysicalMetric) {
        if let i = physicalMetrics.firstIndex(where: { $0.id == m.id }) { physicalMetrics[i] = m } else { physicalMetrics.append(m) }
    }

    public func deletePhysicalMetric(id: EntityID) {
        physicalMetrics.removeAll { $0.id == id }
    }

    public func upsertTechnicalSkill(_ s: TechnicalSkill) {
        if let i = technicalSkills.firstIndex(where: { $0.id == s.id }) { technicalSkills[i] = s } else { technicalSkills.append(s) }
    }

    public func deleteTechnicalSkill(id: EntityID) {
        technicalSkills.removeAll { $0.id == id }
    }

    public func upsertPoomsaeAssessment(_ a: PoomsaeAssessment) {
        if let i = poomsaeAssessments.firstIndex(where: { $0.id == a.id }) { poomsaeAssessments[i] = a } else { poomsaeAssessments.append(a) }
    }

    public func deletePoomsaeAssessment(id: EntityID) {
        poomsaeAssessments.removeAll { $0.id == id }
    }

    public func upsertGoal(_ g: Goal) {
        if let i = goals.firstIndex(where: { $0.id == g.id }) { goals[i] = g } else { goals.append(g) }
    }

    public func deleteGoal(id: EntityID) {
        goals.removeAll { $0.id == id }
    }

    public func upsertTrainingLoad(_ entry: TrainingLoadEntry) {
        if let i = trainingLoad.firstIndex(where: { $0.id == entry.id }) {
            trainingLoad[i] = entry
        } else {
            trainingLoad.append(entry)
        }
    }

    public func deleteTrainingLoad(id: EntityID) {
        trainingLoad.removeAll { $0.id == id }
    }

    public func upsertDrill(_ d: DrillLibraryEntry) {
        if let i = drills.firstIndex(where: { $0.id == d.id }) { drills[i] = d } else { drills.append(d) }
    }

    public func deleteDrill(id: EntityID) {
        drills.removeAll { $0.id == id }
    }

    public func upsertPlan(_ p: ImprovementPlan) {
        if let i = improvementPlans.firstIndex(where: { $0.id == p.id }) {
            improvementPlans[i] = p
        } else {
            improvementPlans.append(p)
        }
    }

    public func deletePlan(id: EntityID) {
        improvementPlans.removeAll { $0.id == id }
    }

    public func replaceBenchmarks(_ benchmarks: [PeerBenchmark]) {
        peerBenchmarks = benchmarks
    }

    public func mergeBenchmarks(_ benchmarks: [PeerBenchmark]) {
        for b in benchmarks {
            if let i = peerBenchmarks.firstIndex(where: { $0.id == b.id }) {
                peerBenchmarks[i] = b
            } else {
                peerBenchmarks.append(b)
            }
        }
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

    public func upsertAnnouncement(_ a: Announcement) {
        if let i = announcements.firstIndex(where: { $0.id == a.id }) { announcements[i] = a } else { announcements.append(a) }
    }

    public func upsertRSVP(_ r: AnnouncementRSVP) {
        if let i = rsvps.firstIndex(where: { $0.announcementID == r.announcementID && $0.userID == r.userID }) { rsvps[i] = r } else { rsvps.append(r) }
    }

    public func upsertCertification(_ c: Certification) {
        if let i = certifications.firstIndex(where: { $0.id == c.id }) { certifications[i] = c } else { certifications.append(c) }
    }

    public func appendAudit(_ entry: AuditEntry) {
        auditLog.append(entry)
        if auditLog.count > 200 { auditLog.removeFirst(auditLog.count - 200) }
    }

    public func logAudit(action: String, target: String, targetID: EntityID, changes: [String: String] = [:]) {
        let entry = AuditEntry(actorUserID: currentUserID, action: action, targetEntity: target, targetID: targetID, changes: changes)
        appendAudit(entry)
    }

    public func upsertUser(_ u: User) {
        var u = u
        // App-owner invariant: the owner's role and identifying email are
        // immutable. No edit — by any user, through any surface — can demote
        // or rename the project owner. See `AppOwner`.
        if let existing = users.first(where: { $0.id == u.id }), existing.isAppOwner {
            u.role = .developer
            u.email = AppOwner.email
        }
        if let i = users.firstIndex(where: { $0.id == u.id }) { users[i] = u } else { users.append(u) }
    }

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

    public func signIn(email: String, password: String) async throws {
        try await store.validateSignIn(email: email, password: password)
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
    public func createAccount(email: String, password: String, fullName: String, fullNameAr: String, role: Role, branchID: EntityID?) async throws {
        // The project-owner email is reserved — it can never be re-registered
        // to a new account, so the owner login cannot be hijacked.
        guard !AppOwner.matches(email) else { throw DemoAuthError.ownerEmailReserved }
        let user = User(fullName: fullName, fullNameAr: fullNameAr, role: role, primaryBranchID: branchID, avatarSeed: fullName.lowercased().replacingOccurrences(of: " ", with: ""))
        await store.upsertUser(user)
        await store.registerCredential(email: email, password: password, userID: user.id)
        await store.logAudit(action: "createAccount", target: "User", targetID: user.id)
    }
    public func updateUser(_ user: User) async throws {
        await store.upsertUser(user)
        await store.logAudit(action: "updateUser", target: "User", targetID: user.id)
    }
    public func linkChild(userID: EntityID, athleteID: EntityID) async throws {
        guard var user = await store.users.first(where: { $0.id == userID }) else { return }
        if !user.linkedAthleteIDs.contains(athleteID) {
            user.linkedAthleteIDs.append(athleteID)
            await store.upsertUser(user)
            await store.logAudit(action: "linkChild", target: "User", targetID: userID, changes: ["athleteID": athleteID.uuidString])
        }
    }
    public func unlinkChild(userID: EntityID, athleteID: EntityID) async throws {
        guard var user = await store.users.first(where: { $0.id == userID }) else { return }
        user.linkedAthleteIDs.removeAll { $0 == athleteID }
        await store.upsertUser(user)
        await store.logAudit(action: "unlinkChild", target: "User", targetID: userID, changes: ["athleteID": athleteID.uuidString])
    }

    // MARK: Branch

    public func branches() async throws -> [Branch] { await store.branches }
    public func branch(id: EntityID) async throws -> Branch? { await store.branches.first { $0.id == id } }
    public func upsert(_ branch: Branch) async throws {
        await store.upsertBranch(branch)
        await store.logAudit(action: "upsertBranch", target: "Branch", targetID: branch.id)
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
    public func athlete(memberNumber: Int) async throws -> Athlete? {
        await store.athletes.first { $0.memberNumber == memberNumber }
    }
    public func nextMemberNumber() async throws -> Int {
        await store.reserveNextMemberNumber()
    }
    public func upsert(_ athlete: Athlete) async throws {
        await store.upsertAthlete(athlete)
        await store.logAudit(action: "editAthlete", target: "Athlete", targetID: athlete.id)
    }

    // MARK: Coach

    public func coaches() async throws -> [Coach] { await store.coaches }
    public func coaches(branchID: EntityID) async throws -> [Coach] {
        await store.coaches.filter { $0.primaryBranchID == branchID || $0.secondaryBranchIDs.contains(branchID) }
    }
    public func coach(id: EntityID) async throws -> Coach? { await store.coaches.first { $0.id == id } }
    public func upsert(_ coach: Coach) async throws {
        await store.upsertCoach(coach)
        await store.logAudit(action: "editCoach", target: "Coach", targetID: coach.id)
    }

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
    public func upsert(_ session: ClassSession) async throws { await store.upsertSession(session) }
    public func deleteSession(id: EntityID) async throws { await store.deleteSession(id: id) }

    // MARK: Attendance

    public func attendance(sessionID: EntityID) async throws -> [AttendanceRecord] {
        await store.attendance.filter { $0.sessionID == sessionID }
    }
    public func attendance(athleteID: EntityID, since: Date) async throws -> [AttendanceRecord] {
        await store.attendance.filter { $0.athleteID == athleteID && $0.recordedAt >= since }
    }
    public func upsertAttendance(_ record: AttendanceRecord) async throws {
        await store.upsertAttendance(record)
        await store.logAudit(action: "recordAttendance", target: "Attendance", targetID: record.id)
    }
    public func upsertAttendance(_ records: [AttendanceRecord]) async throws {
        for r in records { await store.upsertAttendance(r) }
        if let first = records.first {
            await store.logAudit(action: "recordAttendance", target: "Session", targetID: first.sessionID, changes: ["count": "\(records.count)"])
        }
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

    public func physicalMetrics(athleteID: EntityID) async throws -> [PhysicalMetric] {
        await store.physicalMetrics.filter { $0.athleteID == athleteID }.sorted { $0.recordedAt > $1.recordedAt }
    }
    public func technicalSkills(athleteID: EntityID) async throws -> [TechnicalSkill] {
        await store.technicalSkills.filter { $0.athleteID == athleteID }.sorted { $0.recordedAt > $1.recordedAt }
    }
    public func poomsaeAssessments(athleteID: EntityID) async throws -> [PoomsaeAssessment] {
        await store.poomsaeAssessments.filter { $0.athleteID == athleteID }.sorted { $0.recordedAt > $1.recordedAt }
    }
    public func wellness(athleteID: EntityID, since: Date) async throws -> [WellnessEntry] {
        await store.wellness.filter { $0.athleteID == athleteID && $0.recordedAt >= since }
            .sorted { $0.recordedAt > $1.recordedAt }
    }
    public func upsert(metric: PhysicalMetric) async throws { await store.upsertPhysicalMetric(metric) }
    public func upsert(skill: TechnicalSkill) async throws { await store.upsertTechnicalSkill(skill) }
    public func upsert(poomsae: PoomsaeAssessment) async throws { await store.upsertPoomsaeAssessment(poomsae) }
    public func upsert(wellness entry: WellnessEntry) async throws { await store.upsertWellness(entry) }
    public func deletePhysicalMetric(id: EntityID) async throws { await store.deletePhysicalMetric(id: id) }
    public func deleteTechnicalSkill(id: EntityID) async throws { await store.deleteTechnicalSkill(id: id) }
    public func deletePoomsaeAssessment(id: EntityID) async throws { await store.deletePoomsaeAssessment(id: id) }

    // MARK: Goals
    public func goals(athleteID: EntityID) async throws -> [Goal] {
        await store.goals.filter { $0.athleteID == athleteID }
            .sorted { $0.createdAt > $1.createdAt }
    }
    public func upsert(goal: Goal) async throws { await store.upsertGoal(goal) }
    public func deleteGoal(id: EntityID) async throws { await store.deleteGoal(id: id) }

    // MARK: Training load
    public func trainingLoad(athleteID: EntityID, since: Date) async throws -> [TrainingLoadEntry] {
        await store.trainingLoad
            .filter { $0.athleteID == athleteID && $0.recordedAt >= since }
            .sorted { $0.recordedAt > $1.recordedAt }
    }
    public func upsert(load: TrainingLoadEntry) async throws { await store.upsertTrainingLoad(load) }
    public func deleteTrainingLoad(id: EntityID) async throws { await store.deleteTrainingLoad(id: id) }

    // MARK: Improvement plans
    public func drills() async throws -> [DrillLibraryEntry] {
        await store.drills.sorted { $0.name < $1.name }
    }
    public func upsert(drill: DrillLibraryEntry) async throws { await store.upsertDrill(drill) }
    public func deleteDrill(id: EntityID) async throws { await store.deleteDrill(id: id) }
    public func improvementPlans(athleteID: EntityID) async throws -> [ImprovementPlan] {
        await store.improvementPlans.filter { $0.athleteID == athleteID }
            .sorted { $0.createdAt > $1.createdAt }
    }
    public func upsert(plan: ImprovementPlan) async throws { await store.upsertPlan(plan) }
    public func deletePlan(id: EntityID) async throws { await store.deletePlan(id: id) }

    // MARK: Peer benchmarks
    public func peerBenchmarks() async throws -> [PeerBenchmark] {
        await store.peerBenchmarks
    }
    public func upsertBenchmarks(_ benchmarks: [PeerBenchmark]) async throws {
        await store.mergeBenchmarks(benchmarks)
    }
    @discardableResult
    public func recomputeBenchmarks() async throws -> [PeerBenchmark] {
        // Pull all athletes; then their physical metrics.
        let allAthletes = try await athletes()
        var allMetrics: [PhysicalMetric] = []
        for a in allAthletes {
            allMetrics.append(contentsOf: try await physicalMetrics(athleteID: a.id))
        }
        let fresh = BenchmarkComputer.compute(athletes: allAthletes, metrics: allMetrics)
        await store.replaceBenchmarks(fresh)
        return fresh
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
        let skills = try await technicalSkills(athleteID: athleteID)
        let metrics = try await physicalMetrics(athleteID: athleteID)
        return GradingEngine.evaluateEligibility(athlete: athlete, attendance: attRecords, technical: skills, physical: metrics)
    }
    public func gradingSessions(branchID: EntityID) async throws -> [GradingSession] {
        await store.gradingSessions.filter { $0.branchID == branchID }.sorted { $0.scheduledAt < $1.scheduledAt }
    }
    public func gradingSession(id: EntityID) async throws -> GradingSession? {
        await store.gradingSessions.first { $0.id == id }
    }
    public func upsert(_ session: GradingSession) async throws {
        await store.upsertGradingSession(session)
        await store.logAudit(action: "scheduleGrading", target: "GradingSession", targetID: session.id)
    }
    public func gradingScores(sessionID: EntityID) async throws -> [GradingScore] {
        await store.gradingScores.filter { $0.sessionID == sessionID }
    }
    public func upsert(_ score: GradingScore) async throws {
        await store.upsertGradingScore(score)
        await store.logAudit(action: "scoreGrading", target: "GradingScore", targetID: score.id, changes: ["decision": score.decision.rawValue])
    }
    public func certificates(athleteID: EntityID) async throws -> [GradingCertificate] {
        await store.certificates.filter { $0.athleteID == athleteID }.sorted { $0.awardedAt > $1.awardedAt }
    }
    public func issueCertificate(_ certificate: GradingCertificate) async throws {
        await store.appendCertificate(certificate)
        await store.logAudit(action: "issueCertificate", target: "GradingCertificate", targetID: certificate.id)
    }

    // MARK: Tournament

    public func tournaments() async throws -> [Tournament] {
        await store.tournaments.sorted { $0.startsAt < $1.startsAt }
    }
    public func tournament(id: EntityID) async throws -> Tournament? {
        await store.tournaments.first { $0.id == id }
    }
    public func upsert(tournament: Tournament) async throws {
        await store.upsertTournament(tournament)
        await store.logAudit(action: "createTournament", target: "Tournament", targetID: tournament.id)
    }

    public func registrations(tournamentID: EntityID) async throws -> [TournamentRegistration] {
        await store.registrations.filter { $0.tournamentID == tournamentID }
    }
    public func registrations(athleteID: EntityID) async throws -> [TournamentRegistration] {
        await store.registrations.filter { $0.athleteID == athleteID }
    }
    public func upsert(registration: TournamentRegistration) async throws {
        await store.upsertRegistration(registration)
        await store.logAudit(action: "registerAthlete", target: "Registration", targetID: registration.id)
    }

    public func weightCutHistory(registrationID: EntityID) async throws -> [WeightCutEntry] {
        await store.weightCuts.filter { $0.registrationID == registrationID }
            .sorted { $0.recordedAt < $1.recordedAt }
    }
    public func upsert(weightCut: WeightCutEntry) async throws { await store.upsertWeightCut(weightCut) }

    public func brackets(tournamentID: EntityID) async throws -> [Bracket] {
        await store.brackets.filter { $0.tournamentID == tournamentID }
    }
    public func upsert(bracket: Bracket) async throws {
        await store.upsertBracket(bracket)
        await store.logAudit(action: "generateBracket", target: "Bracket", targetID: bracket.id)
    }

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
        await store.logAudit(action: "finalizeMatch", target: "Match", targetID: match.id)
    }

    // MARK: Operations

    public func announcements(audience: AnnouncementAudience?) async throws -> [Announcement] {
        let all = await store.announcements
        let filtered = audience.map { aud in all.filter { $0.audience == aud || $0.audience == .all } } ?? all
        return filtered.sorted { $0.publishedAt > $1.publishedAt }
    }

    public func upsert(announcement: Announcement) async throws {
        await store.upsertAnnouncement(announcement)
        await store.logAudit(action: "publishAnnouncement", target: "Announcement", targetID: announcement.id)
    }

    public func rsvps(announcementID: EntityID) async throws -> [AnnouncementRSVP] {
        await store.rsvps.filter { $0.announcementID == announcementID }
    }

    public func upsert(rsvp: AnnouncementRSVP) async throws {
        await store.upsertRSVP(rsvp)
        await store.logAudit(action: "rsvp", target: "Announcement", targetID: rsvp.announcementID, changes: ["response": rsvp.response.rawValue])
    }

    public func certifications(coachID: EntityID) async throws -> [Certification] {
        await store.certifications.filter { $0.coachID == coachID }
            .sorted { $0.expiresAt < $1.expiresAt }
    }

    public func certifications() async throws -> [Certification] {
        await store.certifications.sorted { $0.expiresAt < $1.expiresAt }
    }

    public func upsert(certification: Certification) async throws {
        await store.upsertCertification(certification)
        await store.logAudit(action: "upsertCertification", target: "Certification", targetID: certification.id)
    }

    public func expiringSoon(within: TimeInterval) async throws -> [Certification] {
        let cutoff = Date().addingTimeInterval(within)
        return await store.certifications.filter { $0.expiresAt <= cutoff }
            .sorted { $0.expiresAt < $1.expiresAt }
    }

    // MARK: Audit

    public func log(_ entry: AuditEntry) async throws {
        await store.appendAudit(entry)
    }

    public func entries(actor: EntityID?, since: Date?) async throws -> [AuditEntry] {
        var all = await store.auditLog
        if let actor { all = all.filter { $0.actorUserID == actor } }
        if let since { all = all.filter { $0.at >= since } }
        return all.sorted { $0.at > $1.at }
    }

    public func entries(target: EntityID) async throws -> [AuditEntry] {
        await store.auditLog.filter { $0.targetID == target }.sorted { $0.at > $1.at }
    }

    // MARK: Storage

    public func uploadAthletePhoto(athleteID: EntityID, data: Data, contentType: String) async throws -> String {
        let documents = try FileManager.default.url(
            for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true
        )
        let dir = documents.appendingPathComponent("athletePhotos", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let ext = contentType.contains("png") ? "png" : "jpg"
        let dest = dir.appendingPathComponent("\(athleteID.uuidString).\(ext)")
        try data.write(to: dest, options: .atomic)
        return dest.absoluteString
    }

    public func uploadUserAvatar(userID: EntityID, data: Data, contentType: String) async throws -> String {
        let documents = try FileManager.default.url(
            for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true
        )
        let dir = documents.appendingPathComponent("userAvatars", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let ext = contentType.contains("png") ? "png" : "jpg"
        let dest = dir.appendingPathComponent("\(userID.uuidString).\(ext)")
        try data.write(to: dest, options: .atomic)
        return dest.absoluteString
    }

    // MARK: BranchProfile

    public func facility(branchID: EntityID) async throws -> BranchFacility? {
        await store.facilities.first { $0.branchID == branchID }
    }
    public func upsert(_ facility: BranchFacility) async throws {
        await store.upsertFacility(facility)
        await store.logAudit(action: "upsertFacility", target: "BranchFacility", targetID: facility.id)
    }

    public func hours(branchID: EntityID) async throws -> BranchHours? {
        await store.branchHours.first { $0.branchID == branchID }
    }
    public func upsert(_ hours: BranchHours) async throws {
        await store.upsertBranchHours(hours)
        await store.logAudit(action: "upsertHours", target: "BranchHours", targetID: hours.id)
    }

    public func programs(branchID: EntityID) async throws -> [BranchProgram] {
        await store.branchPrograms.filter { $0.branchID == branchID }
    }
    public func upsert(_ program: BranchProgram) async throws {
        await store.upsertBranchProgram(program)
        await store.logAudit(action: "upsertProgram", target: "BranchProgram", targetID: program.id)
    }

    public func inventory(branchID: EntityID) async throws -> BranchInventory? {
        await store.branchInventories.first { $0.branchID == branchID }
    }
    public func upsert(_ inventory: BranchInventory) async throws {
        await store.upsertBranchInventory(inventory)
        await store.logAudit(action: "upsertInventory", target: "BranchInventory", targetID: inventory.id)
    }

    public func compliance(branchID: EntityID) async throws -> BranchCompliance? {
        await store.branchCompliances.first { $0.branchID == branchID }
    }
    public func upsert(_ compliance: BranchCompliance) async throws {
        await store.upsertBranchCompliance(compliance)
        await store.logAudit(action: "upsertCompliance", target: "BranchCompliance", targetID: compliance.id)
    }

    public func pricing(branchID: EntityID) async throws -> BranchPricing? {
        await store.branchPricings.first { $0.branchID == branchID }
    }
    public func upsert(_ pricing: BranchPricing) async throws {
        await store.upsertBranchPricing(pricing)
        await store.logAudit(action: "upsertPricing", target: "BranchPricing", targetID: pricing.id)
    }

    public func financials(branchID: EntityID, monthsBack: Int) async throws -> [BranchFinancials] {
        let cutoff = Calendar.current.date(byAdding: .month, value: -monthsBack, to: Date()) ?? Date()
        return await store.branchFinancials
            .filter { $0.branchID == branchID && $0.month >= cutoff }
            .sorted { $0.month < $1.month }
    }
    public func upsert(_ financials: BranchFinancials) async throws {
        await store.upsertBranchFinancials(financials)
        await store.logAudit(action: "upsertFinancials", target: "BranchFinancials", targetID: financials.id)
    }

    public func media(branchID: EntityID) async throws -> BranchMedia? {
        await store.branchMedias.first { $0.branchID == branchID }
    }
    public func upsert(_ media: BranchMedia) async throws {
        await store.upsertBranchMedia(media)
        await store.logAudit(action: "upsertMedia", target: "BranchMedia", targetID: media.id)
    }

    public func socialLinks(branchID: EntityID) async throws -> BranchSocialLinks? {
        await store.branchSocialLinks.first { $0.branchID == branchID }
    }
    public func upsert(_ links: BranchSocialLinks) async throws {
        await store.upsertBranchSocialLinks(links)
        await store.logAudit(action: "upsertSocialLinks", target: "BranchSocialLinks", targetID: links.id)
    }

    public func safeguarding(branchID: EntityID) async throws -> BranchSafeguarding? {
        await store.branchSafeguardings.first { $0.branchID == branchID }
    }
    public func upsert(_ safe: BranchSafeguarding) async throws {
        await store.upsertBranchSafeguarding(safe)
        await store.logAudit(action: "upsertSafeguarding", target: "BranchSafeguarding", targetID: safe.id)
    }

    public func milestones(branchID: EntityID) async throws -> [BranchMilestone] {
        await store.branchMilestones
            .filter { $0.branchID == branchID }
            .sorted { $0.occurredAt > $1.occurredAt }
    }
    public func upsert(_ milestone: BranchMilestone) async throws {
        await store.upsertBranchMilestone(milestone)
        await store.logAudit(action: "upsertMilestone", target: "BranchMilestone", targetID: milestone.id)
    }

    // MARK: AthleteGroup

    public func athleteGroups() async throws -> [AthleteGroup] {
        await store.athleteGroups.sorted { $0.createdAt > $1.createdAt }
    }
    public func athleteGroup(id: EntityID) async throws -> AthleteGroup? {
        await store.athleteGroups.first { $0.id == id }
    }
    public func upsert(_ group: AthleteGroup) async throws {
        await store.upsertAthleteGroup(group)
        await store.logAudit(action: "upsertSquad", target: "AthleteGroup", targetID: group.id)
    }
    public func deleteAthleteGroup(id: EntityID) async throws {
        await store.deleteAthleteGroup(id: id)
        await store.logAudit(action: "deleteSquad", target: "AthleteGroup", targetID: id)
    }
}
