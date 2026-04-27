import Foundation

// SupabaseRepository activates only when the supabase-swift SPM package is
// added to the project (File → Add Packages → https://github.com/supabase/supabase-swift).
// Without the package the type doesn't exist and SHJSDSCApp falls back to
// DemoRepository — keeping the build green either way.

#if canImport(Supabase)
import Supabase
import AuthenticationServices

public final class SupabaseRepository: Repository, AuthenticatingRepository, @unchecked Sendable {

    private let client: SupabaseClient

    public init(url: URL, anonKey: String) {
        self.client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: anonKey,
            options: SupabaseClientOptions(
                db: SupabaseClientOptions.DatabaseOptions(
                    encoder: SupabaseRepository.makeEncoder(),
                    decoder: SupabaseRepository.makeDecoder()
                )
            )
        )
    }

    private static func makeEncoder() -> JSONEncoder {
        let e = JSONEncoder()
        e.keyEncodingStrategy = .convertToSnakeCase
        e.dateEncodingStrategy = .iso8601
        return e
    }

    private static func makeDecoder() -> JSONDecoder {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        d.dateDecodingStrategy = .iso8601
        return d
    }

    // MARK: User

    public func currentUser() async throws -> User? {
        do {
            let session = try await client.auth.session
            let response: [User] = try await client
                .from("user_profiles")
                .select()
                .eq("id", value: session.user.id.uuidString)
                .limit(1)
                .execute()
                .value
            return response.first
        } catch {
            return nil
        }
    }

    public func availableUsers() async throws -> [User] {
        try await client.from("user_profiles").select().execute().value
    }

    public func setCurrentUser(id: EntityID) async throws {
        // No-op against Supabase: identity is determined by auth.session.
    }

    public func user(id: EntityID) async throws -> User? {
        let response: [User] = try await client
            .from("user_profiles").select()
            .eq("id", value: id.uuidString).limit(1)
            .execute().value
        return response.first
    }

    public func users(role: Role?) async throws -> [User] {
        var query = client.from("user_profiles").select()
        if let role { _ = query.eq("role", value: role.rawValue) }
        return try await query.execute().value
    }

    // MARK: Branch

    public func branches() async throws -> [Branch] {
        try await client.from("branches").select().order("name").execute().value
    }

    public func branch(id: EntityID) async throws -> Branch? {
        let rows: [Branch] = try await client.from("branches").select()
            .eq("id", value: id.uuidString).limit(1).execute().value
        return rows.first
    }

    // MARK: Athlete

    public func athletes() async throws -> [Athlete] {
        try await client.from("athletes").select().order("full_name").execute().value
    }

    public func athletes(branchID: EntityID) async throws -> [Athlete] {
        try await client.from("athletes").select()
            .eq("branch_id", value: branchID.uuidString)
            .order("full_name").execute().value
    }

    public func athletes(coachID: EntityID) async throws -> [Athlete] {
        try await client.from("athletes").select()
            .eq("primary_coach_id", value: coachID.uuidString)
            .order("full_name").execute().value
    }

    public func athlete(id: EntityID) async throws -> Athlete? {
        let rows: [Athlete] = try await client.from("athletes").select()
            .eq("id", value: id.uuidString).limit(1).execute().value
        return rows.first
    }

    public func upsert(_ athlete: Athlete) async throws {
        try await client.from("athletes").upsert(athlete).execute()
    }

    // MARK: Coach

    public func coaches() async throws -> [Coach] {
        try await client.from("coaches").select().order("full_name").execute().value
    }

    public func coaches(branchID: EntityID) async throws -> [Coach] {
        try await client.from("coaches").select()
            .or("primary_branch_id.eq.\(branchID.uuidString),secondary_branch_ids.cs.{\(branchID.uuidString)}")
            .execute().value
    }

    public func coach(id: EntityID) async throws -> Coach? {
        let rows: [Coach] = try await client.from("coaches").select()
            .eq("id", value: id.uuidString).limit(1).execute().value
        return rows.first
    }

    // MARK: Schedule

    public func sessions(branchID: EntityID, on day: Date) async throws -> [ClassSession] {
        let cal = Calendar.current
        let start = cal.startOfDay(for: day)
        let end = cal.date(byAdding: .day, value: 1, to: start) ?? start
        return try await client.from("class_sessions").select()
            .eq("branch_id", value: branchID.uuidString)
            .gte("starts_at", value: ISO8601DateFormatter().string(from: start))
            .lt("starts_at", value: ISO8601DateFormatter().string(from: end))
            .order("starts_at").execute().value
    }

    public func sessions(coachID: EntityID, on day: Date) async throws -> [ClassSession] {
        let cal = Calendar.current
        let start = cal.startOfDay(for: day)
        let end = cal.date(byAdding: .day, value: 1, to: start) ?? start
        return try await client.from("class_sessions").select()
            .eq("coach_id", value: coachID.uuidString)
            .gte("starts_at", value: ISO8601DateFormatter().string(from: start))
            .lt("starts_at", value: ISO8601DateFormatter().string(from: end))
            .order("starts_at").execute().value
    }

    public func session(id: EntityID) async throws -> ClassSession? {
        let rows: [ClassSession] = try await client.from("class_sessions").select()
            .eq("id", value: id.uuidString).limit(1).execute().value
        return rows.first
    }

    // MARK: Attendance

    public func attendance(sessionID: EntityID) async throws -> [AttendanceRecord] {
        try await client.from("attendance_records").select()
            .eq("session_id", value: sessionID.uuidString)
            .execute().value
    }

    public func attendance(athleteID: EntityID, since: Date) async throws -> [AttendanceRecord] {
        try await client.from("attendance_records").select()
            .eq("athlete_id", value: athleteID.uuidString)
            .gte("recorded_at", value: ISO8601DateFormatter().string(from: since))
            .execute().value
    }

    public func upsertAttendance(_ record: AttendanceRecord) async throws {
        try await client.from("attendance_records").upsert(record).execute()
    }

    public func upsertAttendance(_ records: [AttendanceRecord]) async throws {
        try await client.from("attendance_records").upsert(records).execute()
    }

    // MARK: Performance

    public func score(athleteID: EntityID) async throws -> PerformanceScore? {
        let rows: [PerformanceScore] = try await client.from("performance_scores").select()
            .eq("athlete_id", value: athleteID.uuidString)
            .order("calculated_at", ascending: false).limit(1)
            .execute().value
        return rows.first
    }

    public func scoreHistory(athleteID: EntityID) async throws -> [PerformanceScore] {
        try await client.from("performance_scores").select()
            .eq("athlete_id", value: athleteID.uuidString)
            .order("calculated_at", ascending: false)
            .execute().value
    }

    public func scores(branchID: EntityID) async throws -> [PerformanceScore] {
        // Fetch all scores for athletes in this branch via two-step join.
        let athletes = try await self.athletes(branchID: branchID)
        guard !athletes.isEmpty else { return [] }
        let ids = athletes.map { $0.id.uuidString }
        let raw: [PerformanceScore] = try await client.from("performance_scores").select()
            .in("athlete_id", values: ids)
            .order("calculated_at", ascending: false)
            .execute().value
        return Self.latestPerAthlete(raw)
    }

    public func allScores() async throws -> [PerformanceScore] {
        let raw: [PerformanceScore] = try await client.from("performance_scores").select()
            .order("calculated_at", ascending: false).execute().value
        return Self.latestPerAthlete(raw)
    }

    private static func latestPerAthlete(_ records: [PerformanceScore]) -> [PerformanceScore] {
        var byAthlete: [EntityID: PerformanceScore] = [:]
        for r in records {
            if byAthlete[r.athleteID] == nil { byAthlete[r.athleteID] = r }
        }
        return Array(byAthlete.values)
    }

    // MARK: Match

    public func matches(athleteID: EntityID) async throws -> [Match] {
        try await client.from("matches").select()
            .or("our_athlete_id.eq.\(athleteID.uuidString),opponent_athlete_id.eq.\(athleteID.uuidString)")
            .order("date", ascending: false)
            .execute().value
    }

    public func matches(branchID: EntityID) async throws -> [Match] {
        let athletes = try await self.athletes(branchID: branchID)
        guard !athletes.isEmpty else { return [] }
        let ids = athletes.map { $0.id.uuidString }
        return try await client.from("matches").select()
            .in("our_athlete_id", values: ids)
            .order("date", ascending: false).execute().value
    }

    public func matches(tournamentID: EntityID) async throws -> [Match] {
        try await client.from("matches").select()
            .eq("tournament_id", value: tournamentID.uuidString)
            .order("date").execute().value
    }

    public func upsertMatch(_ match: Match) async throws {
        try await client.from("matches").upsert(match).execute()
    }

    // MARK: Performance entry

    public func physicalTests(athleteID: EntityID) async throws -> [PhysicalTest] {
        try await client.from("physical_tests").select()
            .eq("athlete_id", value: athleteID.uuidString)
            .order("recorded_at", ascending: false).execute().value
    }

    public func assessments(athleteID: EntityID) async throws -> [TechnicalAssessment] {
        try await client.from("technical_assessments").select()
            .eq("athlete_id", value: athleteID.uuidString)
            .order("recorded_at", ascending: false).execute().value
    }

    public func wellness(athleteID: EntityID, since: Date) async throws -> [WellnessEntry] {
        try await client.from("wellness_entries").select()
            .eq("athlete_id", value: athleteID.uuidString)
            .gte("recorded_at", value: ISO8601DateFormatter().string(from: since))
            .order("recorded_at", ascending: false).execute().value
    }

    public func upsert(physicalTest: PhysicalTest) async throws {
        try await client.from("physical_tests").upsert(physicalTest).execute()
    }
    public func upsert(assessment: TechnicalAssessment) async throws {
        try await client.from("technical_assessments").upsert(assessment).execute()
    }
    public func upsert(wellness entry: WellnessEntry) async throws {
        try await client.from("wellness_entries").upsert(entry).execute()
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
        async let attRecords = attendance(athleteID: athleteID, since: since)
        async let techs = assessments(athleteID: athleteID)
        async let physes = physicalTests(athleteID: athleteID)
        return try await GradingEngine.evaluateEligibility(
            athlete: athlete,
            attendance: attRecords,
            technical: techs,
            physical: physes
        )
    }

    public func gradingSessions(branchID: EntityID) async throws -> [GradingSession] {
        try await client.from("grading_sessions").select()
            .eq("branch_id", value: branchID.uuidString)
            .order("scheduled_at").execute().value
    }
    public func gradingSession(id: EntityID) async throws -> GradingSession? {
        let rows: [GradingSession] = try await client.from("grading_sessions").select()
            .eq("id", value: id.uuidString).limit(1).execute().value
        return rows.first
    }
    public func upsert(_ session: GradingSession) async throws {
        try await client.from("grading_sessions").upsert(session).execute()
    }
    public func gradingScores(sessionID: EntityID) async throws -> [GradingScore] {
        try await client.from("grading_scores").select()
            .eq("session_id", value: sessionID.uuidString).execute().value
    }
    public func upsert(_ score: GradingScore) async throws {
        try await client.from("grading_scores").upsert(score).execute()
    }
    public func certificates(athleteID: EntityID) async throws -> [GradingCertificate] {
        try await client.from("grading_certificates").select()
            .eq("athlete_id", value: athleteID.uuidString)
            .order("awarded_at", ascending: false).execute().value
    }
    public func issueCertificate(_ certificate: GradingCertificate) async throws {
        try await client.from("grading_certificates").upsert(certificate).execute()
    }

    // MARK: Tournament

    public func tournaments() async throws -> [Tournament] {
        try await client.from("tournaments").select().order("starts_at").execute().value
    }
    public func tournament(id: EntityID) async throws -> Tournament? {
        let rows: [Tournament] = try await client.from("tournaments").select()
            .eq("id", value: id.uuidString).limit(1).execute().value
        return rows.first
    }
    public func upsert(tournament: Tournament) async throws {
        try await client.from("tournaments").upsert(tournament).execute()
    }
    public func registrations(tournamentID: EntityID) async throws -> [TournamentRegistration] {
        try await client.from("tournament_registrations").select()
            .eq("tournament_id", value: tournamentID.uuidString).execute().value
    }
    public func registrations(athleteID: EntityID) async throws -> [TournamentRegistration] {
        try await client.from("tournament_registrations").select()
            .eq("athlete_id", value: athleteID.uuidString).execute().value
    }
    public func upsert(registration: TournamentRegistration) async throws {
        try await client.from("tournament_registrations").upsert(registration).execute()
    }
    public func weightCutHistory(registrationID: EntityID) async throws -> [WeightCutEntry] {
        try await client.from("weight_cuts").select()
            .eq("registration_id", value: registrationID.uuidString)
            .order("recorded_at").execute().value
    }
    public func upsert(weightCut: WeightCutEntry) async throws {
        try await client.from("weight_cuts").upsert(weightCut).execute()
    }
    public func brackets(tournamentID: EntityID) async throws -> [Bracket] {
        try await client.from("brackets").select()
            .eq("tournament_id", value: tournamentID.uuidString).execute().value
    }
    public func upsert(bracket: Bracket) async throws {
        try await client.from("brackets").upsert(bracket).execute()
    }
    public func bracketMatches(bracketID: EntityID) async throws -> [BracketMatch] {
        try await client.from("bracket_matches").select()
            .eq("bracket_id", value: bracketID.uuidString)
            .order("round").execute().value
    }
    public func upsert(bracketMatch: BracketMatch) async throws {
        try await client.from("bracket_matches").upsert(bracketMatch).execute()
    }

    // MARK: Live match

    public func activeMatch() async throws -> Match? {
        // No server-side notion of "active"; the app uses a finalized flag.
        // Demo behaviour returns the most recent unfinalized match if you
        // model that. For now return nil.
        nil
    }
    public func startMatch(_ match: Match) async throws {
        try await client.from("matches").upsert(match).execute()
    }
    public func recordEvent(_ event: ScoreEvent) async throws {
        try await client.from("score_events").insert(event).execute()
    }
    public func endRound(matchID: EntityID) async throws {
        // Round transitions are inferred from score_events; nothing to write.
    }
    public func finalizeMatch(_ match: Match) async throws {
        try await client.from("matches").upsert(match).execute()
    }

    /// Subscribe to score events for a match. Implementation note: the
    /// supabase-swift Realtime API has shifted across versions; this is the
    /// 2.x v2 channel pattern. Adjust to your installed version.
    public func subscribeToScoreEvents(matchID: EntityID) -> AsyncStream<ScoreEvent> {
        AsyncStream { continuation in
            Task {
                let channel = client.realtimeV2.channel("score-events-\(matchID.uuidString)")
                let stream = channel.postgresChange(
                    InsertAction.self,
                    schema: "public",
                    table: "score_events",
                    filter: "match_id=eq.\(matchID.uuidString)"
                )
                await channel.subscribe()
                for await change in stream {
                    if let decoded = try? change.decodeRecord(as: ScoreEvent.self, decoder: Self.makeDecoder()) {
                        continuation.yield(decoded)
                    }
                }
                continuation.finish()
            }
        }
    }

    // MARK: Operations

    public func announcements(audience: AnnouncementAudience?) async throws -> [Announcement] {
        var query = client.from("announcements").select()
        if let audience {
            _ = query.in("audience", values: [audience.rawValue, AnnouncementAudience.all.rawValue])
        }
        return try await query.order("published_at", ascending: false).execute().value
    }
    public func upsert(announcement: Announcement) async throws {
        try await client.from("announcements").upsert(announcement).execute()
    }
    public func rsvps(announcementID: EntityID) async throws -> [AnnouncementRSVP] {
        try await client.from("announcement_rsvps").select()
            .eq("announcement_id", value: announcementID.uuidString).execute().value
    }
    public func upsert(rsvp: AnnouncementRSVP) async throws {
        try await client.from("announcement_rsvps").upsert(rsvp).execute()
    }
    public func certifications(coachID: EntityID) async throws -> [Certification] {
        try await client.from("certifications").select()
            .eq("coach_id", value: coachID.uuidString)
            .order("expires_at").execute().value
    }
    public func certifications() async throws -> [Certification] {
        try await client.from("certifications").select().order("expires_at").execute().value
    }
    public func upsert(certification: Certification) async throws {
        try await client.from("certifications").upsert(certification).execute()
    }
    public func expiringSoon(within: TimeInterval) async throws -> [Certification] {
        let cutoff = Date().addingTimeInterval(within)
        return try await client.from("certifications").select()
            .lte("expires_at", value: ISO8601DateFormatter().string(from: cutoff))
            .order("expires_at").execute().value
    }

    // MARK: Audit

    public func log(_ entry: AuditEntry) async throws {
        try await client.from("audit_log").insert(entry).execute()
    }
    public func entries(actor: EntityID?, since: Date?) async throws -> [AuditEntry] {
        var query = client.from("audit_log").select()
        if let actor { _ = query.eq("actor_user_id", value: actor.uuidString) }
        if let since { _ = query.gte("at", value: ISO8601DateFormatter().string(from: since)) }
        return try await query.order("at", ascending: false).execute().value
    }
    public func entries(target: EntityID) async throws -> [AuditEntry] {
        try await client.from("audit_log").select()
            .eq("target_id", value: target.uuidString)
            .order("at", ascending: false).execute().value
    }

    // MARK: AuthenticatingRepository

    public func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws {
        guard let tokenData = credential.identityToken,
              let idToken = String(data: tokenData, encoding: .utf8) else {
            throw NSError(domain: "shjsdsc.supabase", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Missing Apple identity token"])
        }
        let nonce = credential.user
        try await client.auth.signInWithIdToken(
            credentials: .init(provider: .apple, idToken: idToken, nonce: nonce)
        )
    }

    public func signInWithEmail(email: String, password: String) async throws {
        try await client.auth.signIn(email: email, password: password)
    }

    public func signOut() async throws {
        try await client.auth.signOut()
    }

    public func claimRole(fullName: String, fullNameAr: String, role: Role, branchID: EntityID?) async throws {
        let session = try await client.auth.session
        struct ProfileInsert: Encodable {
            let id: UUID
            let fullName: String
            let fullNameAr: String
            let role: String
            let primaryBranchId: UUID?
            let avatarSeed: String
        }
        let row = ProfileInsert(
            id: session.user.id,
            fullName: fullName,
            fullNameAr: fullNameAr,
            role: role.rawValue,
            primaryBranchId: branchID,
            avatarSeed: String(fullName.prefix(2)).lowercased()
        )
        try await client.from("user_profiles").upsert(row).execute()
    }
}

#endif
