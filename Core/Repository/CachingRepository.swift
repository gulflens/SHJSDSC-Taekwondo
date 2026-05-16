import Foundation
import AuthenticationServices

/// Offline-cache decorator over a live `Repository` (the Supabase backend).
///
/// Behaviour:
/// - **Core collection reads** (`athletes()`, `branches()`, `coaches()`, …)
///   are cached to disk on every successful online fetch. When the user has
///   enabled Offline Mode — or a network read fails — the last cached copy
///   is served instead, so the main lists stay populated without a network.
/// - **Writes** (`upsert…`, `delete…`, uploads) are blocked while Offline
///   Mode is on and surface `OfflineError.unavailable`; the caller can show
///   a "reconnect to save" message.
/// - **Parameterised / detail reads** pass straight through — they need a
///   connection. This keeps the cache honest: it never invents data it
///   has not actually seen.
///
/// The decorator only wraps the Supabase repository; `DemoRepository` is
/// fully in-memory and needs no caching, so it is used unwrapped.
///
/// This file is generated from `Repository.swift` — see `gen_caching_repo.py`.
@MainActor
public final class CachingRepository: Repository, AuthenticatingRepository {
    private let base: any Repository

    public init(base: any Repository) {
        self.base = base
    }

    public enum OfflineError: LocalizedError {
        case unavailable
        public var errorDescription: String? {
            String(localized: "offline.error.unavailable")
        }
    }

    /// True when the user has explicitly switched on Offline Mode.
    private var offlineForced: Bool {
        UserDefaults.standard.bool(forKey: "prefs.offlineMode")
    }

    // MARK: - Disk cache

    private func cacheURL(_ key: String) -> URL? {
        guard let dir = try? FileManager.default.url(
            for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true
        ) else { return nil }
        let sub = dir.appendingPathComponent("RepositoryCache", isDirectory: true)
        try? FileManager.default.createDirectory(at: sub, withIntermediateDirectories: true)
        return sub.appendingPathComponent("\(key).json")
    }

    private func readCache<T: Decodable>(_ key: String) -> T? {
        guard let url = cacheURL(key), let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    private func writeCache<T: Encodable>(_ key: String, _ value: T) {
        guard let url = cacheURL(key), let data = try? JSONEncoder().encode(value) else { return }
        try? data.write(to: url)
    }

    /// Online: fetch, persist, return. Offline (or on failure): serve the
    /// last cached copy; only throw if there is nothing cached.
    private func cacheThrough<T: Codable>(
        _ key: String,
        _ fetch: () async throws -> T
    ) async throws -> T {
        if offlineForced {
            if let cached: T = readCache(key) { return cached }
            throw OfflineError.unavailable
        }
        do {
            let value = try await fetch()
            writeCache(key, value)
            return value
        } catch {
            if let cached: T = readCache(key) { return cached }
            throw error
        }
    }

    // MARK: - Repository conformance (generated)

    public func currentUser() async throws -> User? {
        try await cacheThrough("currentUser") { try await base.currentUser() }
    }

    public func availableUsers() async throws -> [User] {
        try await cacheThrough("availableUsers") { try await base.availableUsers() }
    }

    public func setCurrentUser(id: EntityID) async throws {
        try await base.setCurrentUser(id: id)
    }

    public func user(id: EntityID) async throws -> User? {
        return try await base.user(id: id)
    }

    public func users(role: Role?) async throws -> [User] {
        return try await base.users(role: role)
    }

    public func createAccount(email: String, password: String, fullName: String, fullNameAr: String, role: Role, branchID: EntityID?) async throws {
        if offlineForced { throw OfflineError.unavailable }
        try await base.createAccount(email: email, password: password, fullName: fullName, fullNameAr: fullNameAr, role: role, branchID: branchID)
    }

    public func updateUser(_ user: User) async throws {
        if offlineForced { throw OfflineError.unavailable }
        try await base.updateUser(user)
    }

    public func linkChild(userID: EntityID, athleteID: EntityID) async throws {
        if offlineForced { throw OfflineError.unavailable }
        try await base.linkChild(userID: userID, athleteID: athleteID)
    }

    public func unlinkChild(userID: EntityID, athleteID: EntityID) async throws {
        if offlineForced { throw OfflineError.unavailable }
        try await base.unlinkChild(userID: userID, athleteID: athleteID)
    }

    public func branches() async throws -> [Branch] {
        try await cacheThrough("branches") { try await base.branches() }
    }

    public func branch(id: EntityID) async throws -> Branch? {
        return try await base.branch(id: id)
    }

    public func upsert(_ branch: Branch) async throws {
        if offlineForced { throw OfflineError.unavailable }
        try await base.upsert(branch)
    }

    public func athletes() async throws -> [Athlete] {
        try await cacheThrough("athletes") { try await base.athletes() }
    }

    public func athletes(branchID: EntityID) async throws -> [Athlete] {
        return try await base.athletes(branchID: branchID)
    }

    public func athletes(coachID: EntityID) async throws -> [Athlete] {
        return try await base.athletes(coachID: coachID)
    }

    public func athlete(id: EntityID) async throws -> Athlete? {
        return try await base.athlete(id: id)
    }

    public func athlete(memberNumber: Int) async throws -> Athlete? {
        return try await base.athlete(memberNumber: memberNumber)
    }

    public func nextMemberNumber() async throws -> Int {
        return try await base.nextMemberNumber()
    }

    public func upsert(_ athlete: Athlete) async throws {
        if offlineForced { throw OfflineError.unavailable }
        try await base.upsert(athlete)
    }

    public func coaches() async throws -> [Coach] {
        try await cacheThrough("coaches") { try await base.coaches() }
    }

    public func coaches(branchID: EntityID) async throws -> [Coach] {
        return try await base.coaches(branchID: branchID)
    }

    public func coach(id: EntityID) async throws -> Coach? {
        return try await base.coach(id: id)
    }

    public func upsert(_ coach: Coach) async throws {
        if offlineForced { throw OfflineError.unavailable }
        try await base.upsert(coach)
    }

    public func sessions(branchID: EntityID, on day: Date) async throws -> [ClassSession] {
        return try await base.sessions(branchID: branchID, on: day)
    }

    public func sessions(coachID: EntityID, on day: Date) async throws -> [ClassSession] {
        return try await base.sessions(coachID: coachID, on: day)
    }

    public func session(id: EntityID) async throws -> ClassSession? {
        return try await base.session(id: id)
    }

    public func upsert(_ session: ClassSession) async throws {
        if offlineForced { throw OfflineError.unavailable }
        try await base.upsert(session)
    }

    public func deleteSession(id: EntityID) async throws {
        if offlineForced { throw OfflineError.unavailable }
        try await base.deleteSession(id: id)
    }

    public func attendance(sessionID: EntityID) async throws -> [AttendanceRecord] {
        return try await base.attendance(sessionID: sessionID)
    }

    public func attendance(athleteID: EntityID, since: Date) async throws -> [AttendanceRecord] {
        return try await base.attendance(athleteID: athleteID, since: since)
    }

    public func upsertAttendance(_ record: AttendanceRecord) async throws {
        if offlineForced { throw OfflineError.unavailable }
        try await base.upsertAttendance(record)
    }

    public func upsertAttendance(_ records: [AttendanceRecord]) async throws {
        if offlineForced { throw OfflineError.unavailable }
        try await base.upsertAttendance(records)
    }

    public func score(athleteID: EntityID) async throws -> PerformanceScore? {
        return try await base.score(athleteID: athleteID)
    }

    public func scoreHistory(athleteID: EntityID) async throws -> [PerformanceScore] {
        return try await base.scoreHistory(athleteID: athleteID)
    }

    public func scores(branchID: EntityID) async throws -> [PerformanceScore] {
        return try await base.scores(branchID: branchID)
    }

    public func allScores() async throws -> [PerformanceScore] {
        try await cacheThrough("allScores") { try await base.allScores() }
    }

    public func matches(athleteID: EntityID) async throws -> [Match] {
        return try await base.matches(athleteID: athleteID)
    }

    public func matches(branchID: EntityID) async throws -> [Match] {
        return try await base.matches(branchID: branchID)
    }

    public func matches(tournamentID: EntityID) async throws -> [Match] {
        return try await base.matches(tournamentID: tournamentID)
    }

    public func upsertMatch(_ match: Match) async throws {
        if offlineForced { throw OfflineError.unavailable }
        try await base.upsertMatch(match)
    }

    public func physicalMetrics(athleteID: EntityID) async throws -> [PhysicalMetric] {
        return try await base.physicalMetrics(athleteID: athleteID)
    }

    public func technicalSkills(athleteID: EntityID) async throws -> [TechnicalSkill] {
        return try await base.technicalSkills(athleteID: athleteID)
    }

    public func poomsaeAssessments(athleteID: EntityID) async throws -> [PoomsaeAssessment] {
        return try await base.poomsaeAssessments(athleteID: athleteID)
    }

    public func wellness(athleteID: EntityID, since: Date) async throws -> [WellnessEntry] {
        return try await base.wellness(athleteID: athleteID, since: since)
    }

    public func upsert(metric: PhysicalMetric) async throws {
        if offlineForced { throw OfflineError.unavailable }
        try await base.upsert(metric: metric)
    }

    public func upsert(skill: TechnicalSkill) async throws {
        if offlineForced { throw OfflineError.unavailable }
        try await base.upsert(skill: skill)
    }

    public func upsert(poomsae: PoomsaeAssessment) async throws {
        if offlineForced { throw OfflineError.unavailable }
        try await base.upsert(poomsae: poomsae)
    }

    public func upsert(wellness entry: WellnessEntry) async throws {
        if offlineForced { throw OfflineError.unavailable }
        try await base.upsert(wellness: entry)
    }

    public func deletePhysicalMetric(id: EntityID) async throws {
        if offlineForced { throw OfflineError.unavailable }
        try await base.deletePhysicalMetric(id: id)
    }

    public func deleteTechnicalSkill(id: EntityID) async throws {
        if offlineForced { throw OfflineError.unavailable }
        try await base.deleteTechnicalSkill(id: id)
    }

    public func deletePoomsaeAssessment(id: EntityID) async throws {
        if offlineForced { throw OfflineError.unavailable }
        try await base.deletePoomsaeAssessment(id: id)
    }

    public func goals(athleteID: EntityID) async throws -> [Goal] {
        return try await base.goals(athleteID: athleteID)
    }

    public func upsert(goal: Goal) async throws {
        if offlineForced { throw OfflineError.unavailable }
        try await base.upsert(goal: goal)
    }

    public func deleteGoal(id: EntityID) async throws {
        if offlineForced { throw OfflineError.unavailable }
        try await base.deleteGoal(id: id)
    }

    public func trainingLoad(athleteID: EntityID, since: Date) async throws -> [TrainingLoadEntry] {
        return try await base.trainingLoad(athleteID: athleteID, since: since)
    }

    public func upsert(load: TrainingLoadEntry) async throws {
        if offlineForced { throw OfflineError.unavailable }
        try await base.upsert(load: load)
    }

    public func deleteTrainingLoad(id: EntityID) async throws {
        if offlineForced { throw OfflineError.unavailable }
        try await base.deleteTrainingLoad(id: id)
    }

    public func drills() async throws -> [DrillLibraryEntry] {
        try await cacheThrough("drills") { try await base.drills() }
    }

    public func upsert(drill: DrillLibraryEntry) async throws {
        if offlineForced { throw OfflineError.unavailable }
        try await base.upsert(drill: drill)
    }

    public func deleteDrill(id: EntityID) async throws {
        if offlineForced { throw OfflineError.unavailable }
        try await base.deleteDrill(id: id)
    }

    public func improvementPlans(athleteID: EntityID) async throws -> [ImprovementPlan] {
        return try await base.improvementPlans(athleteID: athleteID)
    }

    public func upsert(plan: ImprovementPlan) async throws {
        if offlineForced { throw OfflineError.unavailable }
        try await base.upsert(plan: plan)
    }

    public func deletePlan(id: EntityID) async throws {
        if offlineForced { throw OfflineError.unavailable }
        try await base.deletePlan(id: id)
    }

    public func peerBenchmarks() async throws -> [PeerBenchmark] {
        try await cacheThrough("peerBenchmarks") { try await base.peerBenchmarks() }
    }

    public func upsertBenchmarks(_ benchmarks: [PeerBenchmark]) async throws {
        if offlineForced { throw OfflineError.unavailable }
        try await base.upsertBenchmarks(benchmarks)
    }

    public func recomputeBenchmarks() async throws -> [PeerBenchmark] {
        if offlineForced { throw OfflineError.unavailable }
        return try await base.recomputeBenchmarks()
    }

    public func eligibility(athleteID: EntityID, targetBelt: Belt) async throws -> GradingEligibility {
        return try await base.eligibility(athleteID: athleteID, targetBelt: targetBelt)
    }

    public func gradingSessions(branchID: EntityID) async throws -> [GradingSession] {
        return try await base.gradingSessions(branchID: branchID)
    }

    public func gradingSession(id: EntityID) async throws -> GradingSession? {
        return try await base.gradingSession(id: id)
    }

    public func upsert(_ session: GradingSession) async throws {
        if offlineForced { throw OfflineError.unavailable }
        try await base.upsert(session)
    }

    public func gradingScores(sessionID: EntityID) async throws -> [GradingScore] {
        return try await base.gradingScores(sessionID: sessionID)
    }

    public func upsert(_ score: GradingScore) async throws {
        if offlineForced { throw OfflineError.unavailable }
        try await base.upsert(score)
    }

    public func certificates(athleteID: EntityID) async throws -> [GradingCertificate] {
        return try await base.certificates(athleteID: athleteID)
    }

    public func issueCertificate(_ certificate: GradingCertificate) async throws {
        if offlineForced { throw OfflineError.unavailable }
        try await base.issueCertificate(certificate)
    }

    public func tournaments() async throws -> [Tournament] {
        try await cacheThrough("tournaments") { try await base.tournaments() }
    }

    public func tournament(id: EntityID) async throws -> Tournament? {
        return try await base.tournament(id: id)
    }

    public func upsert(tournament: Tournament) async throws {
        if offlineForced { throw OfflineError.unavailable }
        try await base.upsert(tournament: tournament)
    }

    public func registrations(tournamentID: EntityID) async throws -> [TournamentRegistration] {
        return try await base.registrations(tournamentID: tournamentID)
    }

    public func registrations(athleteID: EntityID) async throws -> [TournamentRegistration] {
        return try await base.registrations(athleteID: athleteID)
    }

    public func upsert(registration: TournamentRegistration) async throws {
        if offlineForced { throw OfflineError.unavailable }
        try await base.upsert(registration: registration)
    }

    public func weightCutHistory(registrationID: EntityID) async throws -> [WeightCutEntry] {
        return try await base.weightCutHistory(registrationID: registrationID)
    }

    public func upsert(weightCut: WeightCutEntry) async throws {
        if offlineForced { throw OfflineError.unavailable }
        try await base.upsert(weightCut: weightCut)
    }

    public func brackets(tournamentID: EntityID) async throws -> [Bracket] {
        return try await base.brackets(tournamentID: tournamentID)
    }

    public func upsert(bracket: Bracket) async throws {
        if offlineForced { throw OfflineError.unavailable }
        try await base.upsert(bracket: bracket)
    }

    public func bracketMatches(bracketID: EntityID) async throws -> [BracketMatch] {
        return try await base.bracketMatches(bracketID: bracketID)
    }

    public func upsert(bracketMatch: BracketMatch) async throws {
        if offlineForced { throw OfflineError.unavailable }
        try await base.upsert(bracketMatch: bracketMatch)
    }

    public func activeMatch() async throws -> Match? {
        return try await base.activeMatch()
    }

    public func startMatch(_ match: Match) async throws {
        if offlineForced { throw OfflineError.unavailable }
        try await base.startMatch(match)
    }

    public func recordEvent(_ event: ScoreEvent) async throws {
        if offlineForced { throw OfflineError.unavailable }
        try await base.recordEvent(event)
    }

    public func endRound(matchID: EntityID) async throws {
        if offlineForced { throw OfflineError.unavailable }
        try await base.endRound(matchID: matchID)
    }

    public func finalizeMatch(_ match: Match) async throws {
        if offlineForced { throw OfflineError.unavailable }
        try await base.finalizeMatch(match)
    }

    public nonisolated func scoreEventStream(matchID: EntityID) -> AsyncStream<ScoreEvent> {
        base.scoreEventStream(matchID: matchID)
    }

    public func announcements(audience: AnnouncementAudience?) async throws -> [Announcement] {
        return try await base.announcements(audience: audience)
    }

    public func upsert(announcement: Announcement) async throws {
        if offlineForced { throw OfflineError.unavailable }
        try await base.upsert(announcement: announcement)
    }

    public func rsvps(announcementID: EntityID) async throws -> [AnnouncementRSVP] {
        return try await base.rsvps(announcementID: announcementID)
    }

    public func upsert(rsvp: AnnouncementRSVP) async throws {
        if offlineForced { throw OfflineError.unavailable }
        try await base.upsert(rsvp: rsvp)
    }

    public func certifications(coachID: EntityID) async throws -> [Certification] {
        return try await base.certifications(coachID: coachID)
    }

    public func certifications() async throws -> [Certification] {
        try await cacheThrough("certifications") { try await base.certifications() }
    }

    public func upsert(certification: Certification) async throws {
        if offlineForced { throw OfflineError.unavailable }
        try await base.upsert(certification: certification)
    }

    public func expiringSoon(within: TimeInterval) async throws -> [Certification] {
        return try await base.expiringSoon(within: within)
    }

    public func log(_ entry: AuditEntry) async throws {
        if offlineForced { throw OfflineError.unavailable }
        try await base.log(entry)
    }

    public func entries(actor: EntityID?, since: Date?) async throws -> [AuditEntry] {
        return try await base.entries(actor: actor, since: since)
    }

    public func entries(target: EntityID) async throws -> [AuditEntry] {
        return try await base.entries(target: target)
    }

    public func uploadAthletePhoto(athleteID: EntityID, data: Data, contentType: String) async throws -> String {
        if offlineForced { throw OfflineError.unavailable }
        return try await base.uploadAthletePhoto(athleteID: athleteID, data: data, contentType: contentType)
    }

    public func uploadUserAvatar(userID: EntityID, data: Data, contentType: String) async throws -> String {
        if offlineForced { throw OfflineError.unavailable }
        return try await base.uploadUserAvatar(userID: userID, data: data, contentType: contentType)
    }

    public func facility(branchID: EntityID) async throws -> BranchFacility? {
        return try await base.facility(branchID: branchID)
    }

    public func upsert(_ facility: BranchFacility) async throws {
        if offlineForced { throw OfflineError.unavailable }
        try await base.upsert(facility)
    }

    public func hours(branchID: EntityID) async throws -> BranchHours? {
        return try await base.hours(branchID: branchID)
    }

    public func upsert(_ hours: BranchHours) async throws {
        if offlineForced { throw OfflineError.unavailable }
        try await base.upsert(hours)
    }

    public func programs(branchID: EntityID) async throws -> [BranchProgram] {
        return try await base.programs(branchID: branchID)
    }

    public func upsert(_ program: BranchProgram) async throws {
        if offlineForced { throw OfflineError.unavailable }
        try await base.upsert(program)
    }

    public func inventory(branchID: EntityID) async throws -> BranchInventory? {
        return try await base.inventory(branchID: branchID)
    }

    public func upsert(_ inventory: BranchInventory) async throws {
        if offlineForced { throw OfflineError.unavailable }
        try await base.upsert(inventory)
    }

    public func compliance(branchID: EntityID) async throws -> BranchCompliance? {
        return try await base.compliance(branchID: branchID)
    }

    public func upsert(_ compliance: BranchCompliance) async throws {
        if offlineForced { throw OfflineError.unavailable }
        try await base.upsert(compliance)
    }

    public func pricing(branchID: EntityID) async throws -> BranchPricing? {
        return try await base.pricing(branchID: branchID)
    }

    public func upsert(_ pricing: BranchPricing) async throws {
        if offlineForced { throw OfflineError.unavailable }
        try await base.upsert(pricing)
    }

    public func financials(branchID: EntityID, monthsBack: Int) async throws -> [BranchFinancials] {
        return try await base.financials(branchID: branchID, monthsBack: monthsBack)
    }

    public func upsert(_ financials: BranchFinancials) async throws {
        if offlineForced { throw OfflineError.unavailable }
        try await base.upsert(financials)
    }

    public func media(branchID: EntityID) async throws -> BranchMedia? {
        return try await base.media(branchID: branchID)
    }

    public func upsert(_ media: BranchMedia) async throws {
        if offlineForced { throw OfflineError.unavailable }
        try await base.upsert(media)
    }

    public func socialLinks(branchID: EntityID) async throws -> BranchSocialLinks? {
        return try await base.socialLinks(branchID: branchID)
    }

    public func upsert(_ links: BranchSocialLinks) async throws {
        if offlineForced { throw OfflineError.unavailable }
        try await base.upsert(links)
    }

    public func safeguarding(branchID: EntityID) async throws -> BranchSafeguarding? {
        return try await base.safeguarding(branchID: branchID)
    }

    public func upsert(_ safe: BranchSafeguarding) async throws {
        if offlineForced { throw OfflineError.unavailable }
        try await base.upsert(safe)
    }

    public func milestones(branchID: EntityID) async throws -> [BranchMilestone] {
        return try await base.milestones(branchID: branchID)
    }

    public func upsert(_ milestone: BranchMilestone) async throws {
        if offlineForced { throw OfflineError.unavailable }
        try await base.upsert(milestone)
    }

    public func athleteGroups() async throws -> [AthleteGroup] {
        try await cacheThrough("athleteGroups") { try await base.athleteGroups() }
    }

    public func athleteGroup(id: EntityID) async throws -> AthleteGroup? {
        return try await base.athleteGroup(id: id)
    }

    public func upsert(_ group: AthleteGroup) async throws {
        if offlineForced { throw OfflineError.unavailable }
        try await base.upsert(group)
    }

    public func deleteAthleteGroup(id: EntityID) async throws {
        if offlineForced { throw OfflineError.unavailable }
        try await base.deleteAthleteGroup(id: id)
    }

    // MARK: - AuthenticatingRepository (forwarded to the live backend)

    private func auth() throws -> any AuthenticatingRepository {
        guard let backend = base as? AuthenticatingRepository else {
            throw OfflineError.unavailable
        }
        return backend
    }

    public func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws {
        try await auth().signInWithApple(credential: credential)
    }

    public func signInWithEmail(email: String, password: String) async throws {
        try await auth().signInWithEmail(email: email, password: password)
    }

    public func signOut() async throws {
        try await auth().signOut()
    }

    public func claimRole(fullName: String, fullNameAr: String, role: Role, branchID: EntityID?) async throws {
        try await auth().claimRole(fullName: fullName, fullNameAr: fullNameAr, role: role, branchID: branchID)
    }

    public func changePassword(newPassword: String) async throws {
        if offlineForced { throw OfflineError.unavailable }
        try await auth().changePassword(newPassword: newPassword)
    }
}
