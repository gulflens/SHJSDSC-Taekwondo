import Foundation

public protocol UserRepository: Sendable {
    func currentUser() async throws -> User?
    func availableUsers() async throws -> [User]
    func setCurrentUser(id: EntityID) async throws
    func user(id: EntityID) async throws -> User?
    func users(role: Role?) async throws -> [User]
    func createAccount(email: String, password: String, fullName: String, fullNameAr: String, role: Role, branchID: EntityID?) async throws
    func linkChild(userID: EntityID, athleteID: EntityID) async throws
    func unlinkChild(userID: EntityID, athleteID: EntityID) async throws
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
    func athlete(memberNumber: Int) async throws -> Athlete?
    func nextMemberNumber() async throws -> Int
    func upsert(_ athlete: Athlete) async throws
}

public protocol CoachRepository: Sendable {
    func coaches() async throws -> [Coach]
    func coaches(branchID: EntityID) async throws -> [Coach]
    func coach(id: EntityID) async throws -> Coach?
    func upsert(_ coach: Coach) async throws
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
    func score(athleteID: EntityID) async throws -> PerformanceScore?
    func scoreHistory(athleteID: EntityID) async throws -> [PerformanceScore]
    func scores(branchID: EntityID) async throws -> [PerformanceScore]
    func allScores() async throws -> [PerformanceScore]
}

public protocol MatchRepository: Sendable {
    func matches(athleteID: EntityID) async throws -> [Match]
    func matches(branchID: EntityID) async throws -> [Match]
    func matches(tournamentID: EntityID) async throws -> [Match]
    func upsertMatch(_ match: Match) async throws
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

public protocol TournamentRepository: Sendable {
    func tournaments() async throws -> [Tournament]
    func tournament(id: EntityID) async throws -> Tournament?
    func upsert(tournament: Tournament) async throws

    func registrations(tournamentID: EntityID) async throws -> [TournamentRegistration]
    func registrations(athleteID: EntityID) async throws -> [TournamentRegistration]
    func upsert(registration: TournamentRegistration) async throws

    func weightCutHistory(registrationID: EntityID) async throws -> [WeightCutEntry]
    func upsert(weightCut: WeightCutEntry) async throws

    func brackets(tournamentID: EntityID) async throws -> [Bracket]
    func upsert(bracket: Bracket) async throws

    func bracketMatches(bracketID: EntityID) async throws -> [BracketMatch]
    func upsert(bracketMatch: BracketMatch) async throws
}

public protocol LiveMatchRepository: Sendable {
    func activeMatch() async throws -> Match?
    func startMatch(_ match: Match) async throws
    func recordEvent(_ event: ScoreEvent) async throws
    func endRound(matchID: EntityID) async throws
    func finalizeMatch(_ match: Match) async throws
    /// AsyncStream of score events for the given match. Demo repository returns
    /// an empty stream; Supabase backend bridges the realtime channel.
    func scoreEventStream(matchID: EntityID) -> AsyncStream<ScoreEvent>
}

public extension LiveMatchRepository {
    func scoreEventStream(matchID: EntityID) -> AsyncStream<ScoreEvent> {
        AsyncStream { $0.finish() }
    }
}

public protocol OperationsRepository: Sendable {
    func announcements(audience: AnnouncementAudience?) async throws -> [Announcement]
    func upsert(announcement: Announcement) async throws
    func rsvps(announcementID: EntityID) async throws -> [AnnouncementRSVP]
    func upsert(rsvp: AnnouncementRSVP) async throws
    func certifications(coachID: EntityID) async throws -> [Certification]
    func certifications() async throws -> [Certification]
    func upsert(certification: Certification) async throws
    func expiringSoon(within: TimeInterval) async throws -> [Certification]
}

public protocol AuditRepository: Sendable {
    func log(_ entry: AuditEntry) async throws
    func entries(actor: EntityID?, since: Date?) async throws -> [AuditEntry]
    func entries(target: EntityID) async throws -> [AuditEntry]
}

public protocol StorageRepository: Sendable {
    /// Uploads athlete photo bytes and returns a publicly-resolvable URL string
    /// the Avatar view can render via AsyncImage.
    func uploadAthletePhoto(athleteID: EntityID, data: Data, contentType: String) async throws -> String
}

public protocol BranchProfileRepository: Sendable {
    func facility(branchID: EntityID) async throws -> BranchFacility?
    func upsert(_ facility: BranchFacility) async throws

    func hours(branchID: EntityID) async throws -> BranchHours?
    func upsert(_ hours: BranchHours) async throws

    func programs(branchID: EntityID) async throws -> [BranchProgram]
    func upsert(_ program: BranchProgram) async throws

    func inventory(branchID: EntityID) async throws -> BranchInventory?
    func upsert(_ inventory: BranchInventory) async throws

    func compliance(branchID: EntityID) async throws -> BranchCompliance?
    func upsert(_ compliance: BranchCompliance) async throws

    func pricing(branchID: EntityID) async throws -> BranchPricing?
    func upsert(_ pricing: BranchPricing) async throws

    func financials(branchID: EntityID, monthsBack: Int) async throws -> [BranchFinancials]
    func upsert(_ financials: BranchFinancials) async throws

    func media(branchID: EntityID) async throws -> BranchMedia?
    func upsert(_ media: BranchMedia) async throws

    func socialLinks(branchID: EntityID) async throws -> BranchSocialLinks?
    func upsert(_ links: BranchSocialLinks) async throws

    func safeguarding(branchID: EntityID) async throws -> BranchSafeguarding?
    func upsert(_ safe: BranchSafeguarding) async throws

    func milestones(branchID: EntityID) async throws -> [BranchMilestone]
    func upsert(_ milestone: BranchMilestone) async throws
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
    TournamentRepository,
    LiveMatchRepository,
    OperationsRepository,
    AuditRepository,
    StorageRepository,
    BranchProfileRepository,
    Sendable {}
