import Foundation

// SupabaseRepository activates only when the supabase-swift SPM package is
// added to the project (File → Add Packages → https://github.com/supabase/supabase-swift).
// Without the package the type doesn't exist and SHJSDSCApp falls back to
// DemoRepository — keeping the build green either way.

#if canImport(Supabase)
import Supabase
import AuthenticationServices

private struct AnyCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?
    init(stringValue: String) { self.stringValue = stringValue; self.intValue = nil }
    init(intValue: Int) { self.stringValue = String(intValue); self.intValue = intValue }
}

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
                ),
                auth: SupabaseClientOptions.AuthOptions(
                    // Opt in to the supabase-swift v3 behavior so the
                    // locally stored session is always emitted as the
                    // initial session regardless of validity. We then
                    // guard with isExpired in currentUser() below to
                    // treat expired sessions as "no session".
                    // ref: https://github.com/supabase/supabase-swift/pull/822
                    emitLocalSessionAsInitialSession: true
                )
            )
        )
    }

    /// Foundation's built-in snake_case strategies don't know about our
    /// uppercase-acronym property convention — `branchID`, `avatarURL`,
    /// `requiresRSVP`, `revenueAED`, `hasPSS`, `hasAC` would each decompose
    /// into one underscore per uppercase letter, producing nonsense column
    /// names like `avatar_u_r_l` or `has_p_s_s` that Postgres rejects with
    /// PGRST204 ("Could not find the 'avatar_u_r_l' column"). The list below
    /// is every suffix acronym that appears on a Codable property in `Core/`.
    /// Add to it whenever a new acronym is introduced — the decoder uses the
    /// same list to walk the conversion back the other way.
    private static let suffixAcronyms = ["IDs", "ID", "URLs", "URL", "AED", "RSVP", "PSS", "AC"]

    private static func makeEncoder() -> JSONEncoder {
        let e = JSONEncoder()
        e.keyEncodingStrategy = .custom { codingPath in
            AnyCodingKey(stringValue: camelToSnake(codingPath.last!.stringValue))
        }
        e.dateEncodingStrategy = .iso8601
        return e
    }

    private static func makeDecoder() -> JSONDecoder {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .custom { codingPath in
            AnyCodingKey(stringValue: snakeToCamel(codingPath.last!.stringValue))
        }
        d.dateDecodingStrategy = .iso8601
        return d
    }

    private static func camelToSnake(_ key: String) -> String {
        // Normalise an acronym suffix to TitleCase first so the generic
        // splitter treats it as a single word: `avatarURL` → `avatarUrl`,
        // `requiresRSVP` → `requiresRsvp`, `hasAC` → `hasAc`. The first
        // letter stays uppercase so the splitter still inserts an `_`
        // before it.
        var k = key
        for acronym in suffixAcronyms where k.hasSuffix(acronym) {
            let head = String(k.dropLast(acronym.count))
            let firstUpper = String(acronym.prefix(1))
            let restLower = acronym.dropFirst().lowercased()
            k = head + firstUpper + restLower
            break
        }
        var out = ""
        for (i, c) in k.enumerated() {
            if c.isUppercase && i > 0 { out += "_" }
            out.append(c.lowercased())
        }
        return out
    }

    private static func snakeToCamel(_ key: String) -> String {
        // Restore an acronym suffix by matching against the snake-case form
        // (`_url`, `_rsvp`, …) so we don't accidentally upcase unrelated
        // tail tokens like `pss_brand` → `pssBRAND`. Only the exact suffix
        // (`avatar_url` → ends with `_url`) flips back to all-caps.
        for acronym in suffixAcronyms {
            let snakeSuffix = "_" + acronym.lowercased()
            if key.hasSuffix(snakeSuffix) {
                let head = String(key.dropLast(snakeSuffix.count))
                return baseSnakeToCamel(head) + acronym
            }
        }
        return baseSnakeToCamel(key)
    }

    private static func baseSnakeToCamel(_ key: String) -> String {
        guard key.contains("_") else { return key }
        let parts = key.split(separator: "_")
        return parts.enumerated().map { i, part in
            i == 0 ? String(part) : part.capitalized
        }.joined()
    }

    // MARK: User

    public func currentUser() async throws -> User? {
        var session: Session
        do {
            session = try await client.auth.session
        } catch {
            return nil
        }
        if session.isExpired {
            do {
                session = try await client.auth.refreshSession()
            } catch {
                print("SupabaseRepository.currentUser: session refresh failed:", error)
                return nil
            }
        }
        do {
            let response: [User] = try await client
                .from("user_profiles")
                .select()
                .eq("id", value: session.user.id.uuidString)
                .limit(1)
                .execute()
                .value
            return response.first
        } catch {
            print("SupabaseRepository.currentUser profile fetch failed:", error)
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
        let query = client.from("user_profiles").select()
        if let role { _ = query.eq("role", value: role.rawValue) }
        return try await query.execute().value
    }

    public func createAccount(email: String, password: String, fullName: String, fullNameAr: String, role: Role, branchID: EntityID?) async throws {
        // The project-owner email is reserved — see `AppOwner`.
        guard !AppOwner.matches(email) else {
            throw NSError(domain: "shjsdsc.supabase", code: -2,
                          userInfo: [NSLocalizedDescriptionKey: String(localized: "auth.owner_email_reserved")])
        }
        let result = try await client.auth.signUp(email: email, password: password)
        let newUserID = result.user.id
        struct ProfileInsert: Encodable {
            let id: UUID
            let fullName: String
            let fullNameAr: String
            let role: String
            let primaryBranchId: UUID?
            let avatarSeed: String
            let linkedAthleteIds: [UUID]
        }
        let row = ProfileInsert(
            id: newUserID,
            fullName: fullName,
            fullNameAr: fullNameAr,
            role: role.rawValue,
            primaryBranchId: branchID,
            avatarSeed: String(fullName.prefix(2)).lowercased(),
            linkedAthleteIds: []
        )
        try await client.from("user_profiles").upsert(row).execute()
    }

    public func updateUser(_ user: User) async throws {
        var user = user
        // App-owner invariant: the stored owner account can never have its
        // role or identifying email changed by an update — see `AppOwner`.
        if let existing: User = try? await self.user(id: user.id), existing.isAppOwner {
            user.role = .developer
            user.email = AppOwner.email
        }
        try await client.from("user_profiles").upsert(user).execute()
    }

    public func linkChild(userID: EntityID, athleteID: EntityID) async throws {
        guard var user: User = try await user(id: userID) else { return }
        if !user.linkedAthleteIDs.contains(athleteID) {
            user.linkedAthleteIDs.append(athleteID)
        }
        try await client.from("user_profiles")
            .update(["linked_athlete_ids": user.linkedAthleteIDs.map { $0.uuidString }])
            .eq("id", value: userID.uuidString)
            .execute()
    }

    public func unlinkChild(userID: EntityID, athleteID: EntityID) async throws {
        guard var user: User = try await user(id: userID) else { return }
        user.linkedAthleteIDs.removeAll { $0 == athleteID }
        try await client.from("user_profiles")
            .update(["linked_athlete_ids": user.linkedAthleteIDs.map { $0.uuidString }])
            .eq("id", value: userID.uuidString)
            .execute()
    }

    // MARK: Branch

    public func branches() async throws -> [Branch] {
        try await client.from("branches").select().order("name").execute().value
    }

    public func upsert(_ branch: Branch) async throws {
        try await client.from("branches").upsert(branch).execute()
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

    public func athlete(memberNumber: Int) async throws -> Athlete? {
        let rows: [Athlete] = try await client.from("athletes").select()
            .eq("member_number", value: memberNumber).limit(1).execute().value
        return rows.first
    }

    public func nextMemberNumber() async throws -> Int {
        // Postgres sequence guarantees monotonic, never-reused values even
        // after an athlete is deleted (migration 0005). Each call advances
        // the sequence — gaps from cancelled-form-fills are acceptable
        // because reuse is the bigger sin.
        try await client.rpc("next_member_number").execute().value
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

    public func upsert(_ coach: Coach) async throws {
        try await client.from("coaches").upsert(coach).execute()
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
    public func upsert(_ session: ClassSession) async throws {
        try await client.from("class_sessions").upsert(session).execute()
    }
    public func deleteSession(id: EntityID) async throws {
        try await client.from("class_sessions")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
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

    public func physicalMetrics(athleteID: EntityID) async throws -> [PhysicalMetric] {
        try await client.from("athlete_physical_metric").select()
            .eq("athlete_id", value: athleteID.uuidString)
            .order("recorded_at", ascending: false).execute().value
    }

    public func technicalSkills(athleteID: EntityID) async throws -> [TechnicalSkill] {
        try await client.from("technical_skill").select()
            .eq("athlete_id", value: athleteID.uuidString)
            .order("recorded_at", ascending: false).execute().value
    }

    public func poomsaeAssessments(athleteID: EntityID) async throws -> [PoomsaeAssessment] {
        try await client.from("poomsae_assessment").select()
            .eq("athlete_id", value: athleteID.uuidString)
            .order("recorded_at", ascending: false).execute().value
    }

    public func wellness(athleteID: EntityID, since: Date) async throws -> [WellnessEntry] {
        try await client.from("wellness_entries").select()
            .eq("athlete_id", value: athleteID.uuidString)
            .gte("recorded_at", value: ISO8601DateFormatter().string(from: since))
            .order("recorded_at", ascending: false).execute().value
    }

    public func upsert(metric: PhysicalMetric) async throws {
        try await client.from("athlete_physical_metric").upsert(metric).execute()
    }
    public func upsert(skill: TechnicalSkill) async throws {
        try await client.from("technical_skill").upsert(skill).execute()
    }
    public func upsert(poomsae: PoomsaeAssessment) async throws {
        try await client.from("poomsae_assessment").upsert(poomsae).execute()
    }
    public func upsert(wellness entry: WellnessEntry) async throws {
        try await client.from("wellness_entries").upsert(entry).execute()
    }
    public func deletePhysicalMetric(id: EntityID) async throws {
        try await client.from("athlete_physical_metric")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
    public func deleteTechnicalSkill(id: EntityID) async throws {
        try await client.from("technical_skill")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
    public func deletePoomsaeAssessment(id: EntityID) async throws {
        try await client.from("poomsae_assessment")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: Goals

    public func goals(athleteID: EntityID) async throws -> [Goal] {
        try await client.from("goal").select()
            .eq("athlete_id", value: athleteID.uuidString)
            .order("created_at", ascending: false).execute().value
    }
    public func upsert(goal: Goal) async throws {
        try await client.from("goal").upsert(goal).execute()
    }
    public func deleteGoal(id: EntityID) async throws {
        try await client.from("goal")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: Training load

    public func trainingLoad(athleteID: EntityID, since: Date) async throws -> [TrainingLoadEntry] {
        try await client.from("training_load_entry").select()
            .eq("athlete_id", value: athleteID.uuidString)
            .gte("recorded_at", value: ISO8601DateFormatter().string(from: since))
            .order("recorded_at", ascending: false).execute().value
    }
    public func upsert(load: TrainingLoadEntry) async throws {
        try await client.from("training_load_entry").upsert(load).execute()
    }
    public func deleteTrainingLoad(id: EntityID) async throws {
        try await client.from("training_load_entry")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: Improvement plans

    public func drills() async throws -> [DrillLibraryEntry] {
        try await client.from("drill_library_entry").select()
            .order("name", ascending: true).execute().value
    }
    public func upsert(drill: DrillLibraryEntry) async throws {
        try await client.from("drill_library_entry").upsert(drill).execute()
    }
    public func deleteDrill(id: EntityID) async throws {
        try await client.from("drill_library_entry")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
    public func improvementPlans(athleteID: EntityID) async throws -> [ImprovementPlan] {
        try await client.from("improvement_plan").select()
            .eq("athlete_id", value: athleteID.uuidString)
            .order("created_at", ascending: false).execute().value
    }
    public func upsert(plan: ImprovementPlan) async throws {
        try await client.from("improvement_plan").upsert(plan).execute()
    }
    public func deletePlan(id: EntityID) async throws {
        try await client.from("improvement_plan")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: Peer benchmarks

    public func peerBenchmarks() async throws -> [PeerBenchmark] {
        try await client.from("peer_benchmark").select()
            .order("computed_at", ascending: false).execute().value
    }
    public func upsertBenchmarks(_ benchmarks: [PeerBenchmark]) async throws {
        guard !benchmarks.isEmpty else { return }
        try await client.from("peer_benchmark").upsert(benchmarks).execute()
    }
    @discardableResult
    public func recomputeBenchmarks() async throws -> [PeerBenchmark] {
        let allAthletes = try await athletes()
        var allMetrics: [PhysicalMetric] = []
        for a in allAthletes {
            allMetrics.append(contentsOf: try await physicalMetrics(athleteID: a.id))
        }
        let fresh = BenchmarkComputer.compute(athletes: allAthletes, metrics: allMetrics)
        // Wipe-and-replace to drop benchmarks for cohort/metric pairs that no
        // longer have enough data.
        try await client.from("peer_benchmark").delete().neq("id", value: "").execute()
        if !fresh.isEmpty {
            try await client.from("peer_benchmark").insert(fresh).execute()
        }
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
        async let attRecords = attendance(athleteID: athleteID, since: since)
        async let skills = technicalSkills(athleteID: athleteID)
        async let metrics = physicalMetrics(athleteID: athleteID)
        return try await GradingEngine.evaluateEligibility(
            athlete: athlete,
            attendance: attRecords,
            technical: skills,
            physical: metrics
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
    public func scoreEventStream(matchID: EntityID) -> AsyncStream<ScoreEvent> {
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
        let query = client.from("announcements").select()
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
        let query = client.from("audit_log").select()
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

    public func changePassword(newPassword: String) async throws {
        try await client.auth.update(user: UserAttributes(password: newPassword))
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

    // MARK: Storage

    public func uploadAthletePhoto(athleteID: EntityID, data: Data, contentType: String) async throws -> String {
        let ext = contentType.contains("png") ? "png" : "jpg"
        let path = "\(athleteID.uuidString).\(ext)"
        let bucket = client.storage.from("athletePhotos")
        _ = try await bucket.upload(
            path,
            data: data,
            options: FileOptions(contentType: contentType, upsert: true)
        )
        return try bucket.getPublicURL(path: path).absoluteString
    }

    public func uploadUserAvatar(userID: EntityID, data: Data, contentType: String) async throws -> String {
        let ext = contentType.contains("png") ? "png" : "jpg"
        let path = "\(userID.uuidString).\(ext)"
        let bucket = client.storage.from("userAvatars")
        _ = try await bucket.upload(
            path,
            data: data,
            options: FileOptions(contentType: contentType, upsert: true)
        )
        return try bucket.getPublicURL(path: path).absoluteString
    }

    // MARK: BranchProfile

    public func facility(branchID: EntityID) async throws -> BranchFacility? {
        let rows: [BranchFacility] = try await client.from("branch_facilities").select()
            .eq("branch_id", value: branchID.uuidString).limit(1).execute().value
        return rows.first
    }
    public func upsert(_ facility: BranchFacility) async throws {
        try await client.from("branch_facilities").upsert(facility).execute()
    }

    public func hours(branchID: EntityID) async throws -> BranchHours? {
        let rows: [BranchHours] = try await client.from("branch_hours").select()
            .eq("branch_id", value: branchID.uuidString).limit(1).execute().value
        return rows.first
    }
    public func upsert(_ hours: BranchHours) async throws {
        try await client.from("branch_hours").upsert(hours).execute()
    }

    public func programs(branchID: EntityID) async throws -> [BranchProgram] {
        try await client.from("branch_programs").select()
            .eq("branch_id", value: branchID.uuidString)
            .order("start_time").execute().value
    }
    public func upsert(_ program: BranchProgram) async throws {
        try await client.from("branch_programs").upsert(program).execute()
    }

    public func inventory(branchID: EntityID) async throws -> BranchInventory? {
        let rows: [BranchInventory] = try await client.from("branch_inventories").select()
            .eq("branch_id", value: branchID.uuidString).limit(1).execute().value
        return rows.first
    }
    public func upsert(_ inventory: BranchInventory) async throws {
        try await client.from("branch_inventories").upsert(inventory).execute()
    }

    public func compliance(branchID: EntityID) async throws -> BranchCompliance? {
        let rows: [BranchCompliance] = try await client.from("branch_compliances").select()
            .eq("branch_id", value: branchID.uuidString).limit(1).execute().value
        return rows.first
    }
    public func upsert(_ compliance: BranchCompliance) async throws {
        try await client.from("branch_compliances").upsert(compliance).execute()
    }

    public func pricing(branchID: EntityID) async throws -> BranchPricing? {
        let rows: [BranchPricing] = try await client.from("branch_pricings").select()
            .eq("branch_id", value: branchID.uuidString).limit(1).execute().value
        return rows.first
    }
    public func upsert(_ pricing: BranchPricing) async throws {
        try await client.from("branch_pricings").upsert(pricing).execute()
    }

    public func financials(branchID: EntityID, monthsBack: Int) async throws -> [BranchFinancials] {
        let cutoff = Calendar.current.date(byAdding: .month, value: -monthsBack, to: Date()) ?? Date()
        return try await client.from("branch_financials").select()
            .eq("branch_id", value: branchID.uuidString)
            .gte("month", value: ISO8601DateFormatter().string(from: cutoff))
            .order("month").execute().value
    }
    public func upsert(_ financials: BranchFinancials) async throws {
        try await client.from("branch_financials").upsert(financials).execute()
    }

    public func media(branchID: EntityID) async throws -> BranchMedia? {
        let rows: [BranchMedia] = try await client.from("branch_medias").select()
            .eq("branch_id", value: branchID.uuidString).limit(1).execute().value
        return rows.first
    }
    public func upsert(_ media: BranchMedia) async throws {
        try await client.from("branch_medias").upsert(media).execute()
    }

    public func socialLinks(branchID: EntityID) async throws -> BranchSocialLinks? {
        let rows: [BranchSocialLinks] = try await client.from("branch_social_links").select()
            .eq("branch_id", value: branchID.uuidString).limit(1).execute().value
        return rows.first
    }
    public func upsert(_ links: BranchSocialLinks) async throws {
        try await client.from("branch_social_links").upsert(links).execute()
    }

    public func safeguarding(branchID: EntityID) async throws -> BranchSafeguarding? {
        let rows: [BranchSafeguarding] = try await client.from("branch_safeguardings").select()
            .eq("branch_id", value: branchID.uuidString).limit(1).execute().value
        return rows.first
    }
    public func upsert(_ safe: BranchSafeguarding) async throws {
        try await client.from("branch_safeguardings").upsert(safe).execute()
    }

    public func milestones(branchID: EntityID) async throws -> [BranchMilestone] {
        try await client.from("branch_milestones").select()
            .eq("branch_id", value: branchID.uuidString)
            .order("occurred_at", ascending: false).execute().value
    }
    public func upsert(_ milestone: BranchMilestone) async throws {
        try await client.from("branch_milestones").upsert(milestone).execute()
    }

    // MARK: AthleteGroup

    public func athleteGroups() async throws -> [AthleteGroup] {
        try await client.from("athlete_groups").select()
            .order("created_at", ascending: false).execute().value
    }
    public func athleteGroup(id: EntityID) async throws -> AthleteGroup? {
        let rows: [AthleteGroup] = try await client.from("athlete_groups").select()
            .eq("id", value: id.uuidString).limit(1).execute().value
        return rows.first
    }
    public func upsert(_ group: AthleteGroup) async throws {
        try await client.from("athlete_groups").upsert(group).execute()
    }
    public func deleteAthleteGroup(id: EntityID) async throws {
        try await client.from("athlete_groups")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
}

#endif
