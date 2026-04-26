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
    public func attendance(athleteID: EntityID, since: Date) async throws -> [AttendanceRecord] { [] }
    public func upsertAttendance(_ record: AttendanceRecord) async throws {}
    public func upsertAttendance(_ records: [AttendanceRecord]) async throws {}

    // MARK: Performance
    public func score(athleteID: EntityID) async throws -> PerformanceScore? { nil }
    public func scoreHistory(athleteID: EntityID) async throws -> [PerformanceScore] { [] }
    public func scores(branchID: EntityID) async throws -> [PerformanceScore] { [] }
    public func allScores() async throws -> [PerformanceScore] { [] }

    // MARK: Match
    public func matches(athleteID: EntityID) async throws -> [Match] { [] }
    public func matches(branchID: EntityID) async throws -> [Match] { [] }
    public func matches(tournamentID: EntityID) async throws -> [Match] { [] }
    public func upsertMatch(_ match: Match) async throws {}

    // MARK: Performance entry
    public func physicalTests(athleteID: EntityID) async throws -> [PhysicalTest] { [] }
    public func assessments(athleteID: EntityID) async throws -> [TechnicalAssessment] { [] }
    public func wellness(athleteID: EntityID, since: Date) async throws -> [WellnessEntry] { [] }
    public func upsert(physicalTest: PhysicalTest) async throws {}
    public func upsert(assessment: TechnicalAssessment) async throws {}
    public func upsert(wellness entry: WellnessEntry) async throws {}

    // MARK: Grading
    public func eligibility(athleteID: EntityID, targetBelt: Belt) async throws -> GradingEligibility {
        GradingEligibility(
            athleteID: athleteID, currentBelt: targetBelt, targetBelt: targetBelt,
            monthsAtCurrent: 0, attendancePct: 0,
            latestTechnicalAvg: 0, latestPhysicalComposite: 0,
            isEligible: false, blockingReasons: ["grading.blocking.attendance"]
        )
    }
    public func gradingSessions(branchID: EntityID) async throws -> [GradingSession] { [] }
    public func gradingSession(id: EntityID) async throws -> GradingSession? { nil }
    public func upsert(_ session: GradingSession) async throws {}
    public func gradingScores(sessionID: EntityID) async throws -> [GradingScore] { [] }
    public func upsert(_ score: GradingScore) async throws {}
    public func certificates(athleteID: EntityID) async throws -> [GradingCertificate] { [] }
    public func issueCertificate(_ certificate: GradingCertificate) async throws {}

    // MARK: Tournament
    public func tournaments() async throws -> [Tournament] { [] }
    public func tournament(id: EntityID) async throws -> Tournament? { nil }
    public func upsert(tournament: Tournament) async throws {}
    public func registrations(tournamentID: EntityID) async throws -> [TournamentRegistration] { [] }
    public func registrations(athleteID: EntityID) async throws -> [TournamentRegistration] { [] }
    public func upsert(registration: TournamentRegistration) async throws {}
    public func weightCutHistory(registrationID: EntityID) async throws -> [WeightCutEntry] { [] }
    public func upsert(weightCut: WeightCutEntry) async throws {}
    public func brackets(tournamentID: EntityID) async throws -> [Bracket] { [] }
    public func upsert(bracket: Bracket) async throws {}
    public func bracketMatches(bracketID: EntityID) async throws -> [BracketMatch] { [] }
    public func upsert(bracketMatch: BracketMatch) async throws {}

    // MARK: Live match
    public func activeMatch() async throws -> Match? { nil }
    public func startMatch(_ match: Match) async throws {}
    public func recordEvent(_ event: ScoreEvent) async throws {}
    public func endRound(matchID: EntityID) async throws {}
    public func finalizeMatch(_ match: Match) async throws {}

    // MARK: Operations
    public func announcements(audience: AnnouncementAudience?) async throws -> [Announcement] { [] }
    public func upsert(announcement: Announcement) async throws {}
    public func rsvps(announcementID: EntityID) async throws -> [AnnouncementRSVP] { [] }
    public func upsert(rsvp: AnnouncementRSVP) async throws {}
    public func certifications(coachID: EntityID) async throws -> [Certification] { [] }
    public func certifications() async throws -> [Certification] { [] }
    public func upsert(certification: Certification) async throws {}
    public func expiringSoon(within: TimeInterval) async throws -> [Certification] { [] }

    // MARK: Audit
    public func log(_ entry: AuditEntry) async throws {}
    public func entries(actor: EntityID?, since: Date?) async throws -> [AuditEntry] { [] }
    public func entries(target: EntityID) async throws -> [AuditEntry] { [] }
}
