import 'dart:typed_data';

// Hide `User` to avoid an ambiguous-import conflict with our domain
// `lib/core/models/user.dart`. We only need SupabaseClient, FileOptions and the
// PostgREST builders from this package — not the GoTrue `User` type.
import 'package:supabase/supabase.dart' hide User;

import '../models/athlete.dart';
import '../models/app_owner.dart';
import '../models/athlete_group.dart';
import '../models/audit_log.dart';
import '../models/belt.dart';
import '../models/branch.dart';
import '../models/branch_compliance.dart';
import '../models/branch_facility.dart';
import '../models/branch_financials.dart';
import '../models/branch_hours.dart';
import '../models/branch_inventory.dart';
import '../models/branch_media.dart';
import '../models/branch_milestone.dart';
import '../models/branch_pricing.dart';
import '../models/branch_program.dart';
import '../models/branch_safeguarding.dart';
import '../models/branch_social_links.dart';
import '../models/coach.dart';
import '../models/entity_id.dart';
import '../models/goal.dart';
import '../models/grading.dart';
import '../models/improvement_plan.dart';
import '../models/match.dart';
import '../models/operations.dart';
import '../models/peer_benchmark.dart';
import '../models/performance_entry.dart';
import '../models/performance_score.dart';
import '../models/physical_metric.dart';
import '../models/poomsae_assessment.dart';
import '../models/role.dart';
import '../models/schedule.dart';
import '../models/technical_skill.dart';
import '../models/tournament.dart';
import '../models/training_load_entry.dart';
import '../models/user.dart';
import '../services/benchmark_computer.dart';
import '../services/grading_engine.dart';
import 'repository.dart';
import 'supabase_key_codec.dart';

/// Live implementation of [Repository] backed by Supabase.
///
/// Mirrors Core/Repository/SupabaseRepository.swift 1:1:
///   - Table names, filter column names and order columns are identical.
///   - Key encoding: every write calls [encodeKeys] (camelCase → snake_case)
///     and every read calls [decodeRow] (snake_case → camelCase) via
///     [supabase_key_codec.dart], matching the Swift custom encoder/decoder.
///   - The pure-Dart `package:supabase` client is used throughout; the Flutter
///     wrapper `package:supabase_flutter` is never imported here so that
///     `lib/core` stays Flutter-free.
class SupabaseRepository implements Repository, AuthRepository {
  final SupabaseClient _client;
  SupabaseRepository(this._client);

  // === AuthRepository ===
  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<void> signOut() async => _client.auth.signOut();

  // ── helpers ────────────────────────────────────────────────────────────────

  /// Encode a model [toJson()] map for a Supabase write.
  Map<String, dynamic> _encode(Map<String, dynamic> json) =>
      encodeKeys(json) as Map<String, dynamic>;

  /// Decode a Supabase row for a model [fromJson].
  Map<String, dynamic> _row(Map<String, dynamic> r) => decodeRow(r);

  /// Format a [DateTime] as an ISO-8601 string (UTC, with 'Z' suffix) for
  /// Supabase filter values, mirroring Swift's `ISO8601DateFormatter`.
  String _iso(DateTime dt) => dt.toUtc().toIso8601String();

  // ──────────────────────────────────────────────────────────────────────────
  // UserRepository
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Future<User?> currentUser() async {
    final session = _client.auth.currentSession;
    // No session → not authenticated; RoleRouter shows the sign-in screen.
    if (session == null) return null;
    final row = await _client
        .from('user_profiles')
        .select()
        .eq('id', session.user.id)
        .maybeSingle();
    if (row != null) return User.fromJson(_row(row));
    // Signed in but no profile row yet — fall back to the first profile so the
    // session still lands somewhere navigable (resilience for the demo DB).
    final users = await availableUsers();
    return users.isEmpty ? null : users.first;
  }

  @override
  Future<List<User>> availableUsers() async {
    final rows = await _client.from('user_profiles').select();
    return rows.map((r) => User.fromJson(_row(r))).toList();
  }

  @override
  Future<void> setCurrentUser(EntityID id) async {
    // No-op against Supabase: identity is determined by auth.session.
  }

  @override
  Future<User?> user(EntityID id) async {
    final row = await _client
        .from('user_profiles')
        .select()
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : User.fromJson(_row(row));
  }

  @override
  Future<List<User>> usersByRole(Role? role) async {
    final query = _client.from('user_profiles').select();
    final rows = role == null ? await query : await query.eq('role', role.name);
    return rows.map((r) => User.fromJson(_row(r))).toList();
  }

  @override
  Future<void> createAccount({
    required String email,
    required String password,
    required String fullName,
    required String fullNameAr,
    required Role role,
    EntityID? branchId,
  }) async {
    // The owner account is reserved — never (re)creatable via sign-up.
    if (AppOwner.matches(email)) throw const OwnerEmailReservedException();
    // Create the auth.users row, then the matching user_profiles row keyed by
    // the new auth user id. (If the project requires email confirmation the
    // session won't be active until confirmed; sign-in then surfaces that.)
    final res = await _client.auth.signUp(
      email: email.trim(),
      password: password,
    );
    final authId = res.user?.id;
    if (authId == null) {
      throw StateError('Sign-up did not return a user id');
    }
    final profile = User(
      id: authId,
      fullName: fullName,
      fullNameAr: fullNameAr,
      role: role,
      primaryBranchId: branchId,
      avatarSeed: authId,
      email: email.trim(),
    );
    await _client.from('user_profiles').insert(_encode(profile.toJson()));
  }

  @override
  Future<void> updateUser(User user) async {
    // Fail closed: read the existing record first so a network/RLS error blocks
    // the write rather than letting an owner-affecting update through unchecked.
    final row = await _client
        .from('user_profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();
    final existing = row == null ? null : User.fromJson(_row(row));
    User next = user;
    if (existing != null && existing.isAppOwner) {
      // The owner can't be demoted or renamed — re-pin role + email.
      next = user.pinnedAsOwner();
    } else if (user.isAppOwner) {
      // A non-owner record may not claim the reserved owner email.
      throw const OwnerEmailReservedException();
    }
    await _client.from('user_profiles').upsert(_encode(next.toJson()));
  }

  @override
  Future<void> linkChild({
    required EntityID userId,
    required EntityID athleteId,
  }) async {
    final u = await user(userId);
    if (u == null) return;
    final ids = <EntityID>[...u.linkedAthleteIds];
    if (!ids.contains(athleteId)) ids.add(athleteId);
    await _client
        .from('user_profiles')
        .update({'linked_athlete_ids': ids})
        .eq('id', userId);
  }

  @override
  Future<void> unlinkChild({
    required EntityID userId,
    required EntityID athleteId,
  }) async {
    final u = await user(userId);
    if (u == null) return;
    final ids = u.linkedAthleteIds.where((id) => id != athleteId).toList();
    await _client
        .from('user_profiles')
        .update({'linked_athlete_ids': ids})
        .eq('id', userId);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // BranchRepository
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Future<List<Branch>> branches() async {
    final rows = await _client.from('branches').select().order('name');
    return rows.map((r) => Branch.fromJson(_row(r))).toList();
  }

  @override
  Future<Branch?> branch(EntityID id) async {
    final row = await _client
        .from('branches')
        .select()
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : Branch.fromJson(_row(row));
  }

  @override
  Future<void> upsertBranch(Branch branch) async {
    await _client.from('branches').upsert(_encode(branch.toJson()));
  }

  // ──────────────────────────────────────────────────────────────────────────
  // AthleteRepository
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Future<List<Athlete>> athletes() async {
    final rows = await _client.from('athletes').select().order('full_name');
    return rows.map((r) => Athlete.fromJson(_row(r))).toList();
  }

  @override
  Future<List<Athlete>> athletesInBranch(EntityID branchId) async {
    final rows = await _client
        .from('athletes')
        .select()
        .eq('branch_id', branchId)
        .order('full_name');
    return rows.map((r) => Athlete.fromJson(_row(r))).toList();
  }

  @override
  Future<List<Athlete>> athletesForCoach(EntityID coachId) async {
    final rows = await _client
        .from('athletes')
        .select()
        .eq('primary_coach_id', coachId)
        .order('full_name');
    return rows.map((r) => Athlete.fromJson(_row(r))).toList();
  }

  @override
  Future<Athlete?> athlete(EntityID id) async {
    final row = await _client
        .from('athletes')
        .select()
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : Athlete.fromJson(_row(row));
  }

  @override
  Future<void> upsertAthlete(Athlete athlete) async {
    await _client.from('athletes').upsert(_encode(athlete.toJson()));
  }

  @override
  Future<Athlete?> athleteByMemberNumber(int memberNumber) async {
    final row = await _client
        .from('athletes')
        .select()
        .eq('member_number', memberNumber)
        .maybeSingle();
    return row == null ? null : Athlete.fromJson(_row(row));
  }

  @override
  Future<int> nextMemberNumber() async {
    // Calls the Postgres sequence function added in migration 0005.
    final result = await _client.rpc('next_member_number');
    return result as int;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // CoachRepository
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Future<List<Coach>> coaches() async {
    final rows = await _client.from('coaches').select().order('full_name');
    return rows.map((r) => Coach.fromJson(_row(r))).toList();
  }

  @override
  Future<List<Coach>> coachesInBranch(EntityID branchId) async {
    // Mirror Swift: .or("primary_branch_id.eq.<id>,secondary_branch_ids.cs.{<id>}")
    final rows = await _client
        .from('coaches')
        .select()
        .or(
          'primary_branch_id.eq.$branchId,secondary_branch_ids.cs.{$branchId}',
        );
    return rows.map((r) => Coach.fromJson(_row(r))).toList();
  }

  @override
  Future<Coach?> coach(EntityID id) async {
    final row = await _client
        .from('coaches')
        .select()
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : Coach.fromJson(_row(row));
  }

  @override
  Future<void> upsertCoach(Coach coach) async {
    await _client.from('coaches').upsert(_encode(coach.toJson()));
  }

  // ──────────────────────────────────────────────────────────────────────────
  // ScheduleRepository
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Future<List<ClassSession>> sessionsForBranch(
    EntityID branchId,
    DateTime day,
  ) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final rows = await _client
        .from('class_sessions')
        .select()
        .eq('branch_id', branchId)
        .gte('starts_at', _iso(start))
        .lt('starts_at', _iso(end))
        .order('starts_at');
    return rows.map((r) => ClassSession.fromJson(_row(r))).toList();
  }

  @override
  Future<List<ClassSession>> sessionsForCoach(
    EntityID coachId,
    DateTime day,
  ) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final rows = await _client
        .from('class_sessions')
        .select()
        .eq('coach_id', coachId)
        .gte('starts_at', _iso(start))
        .lt('starts_at', _iso(end))
        .order('starts_at');
    return rows.map((r) => ClassSession.fromJson(_row(r))).toList();
  }

  @override
  Future<ClassSession?> session(EntityID id) async {
    final row = await _client
        .from('class_sessions')
        .select()
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : ClassSession.fromJson(_row(row));
  }

  @override
  Future<void> upsertSession(ClassSession session) async {
    await _client.from('class_sessions').upsert(_encode(session.toJson()));
  }

  @override
  Future<void> deleteSession(EntityID id) async {
    await _client.from('class_sessions').delete().eq('id', id);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // AttendanceRepository
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Future<List<AttendanceRecord>> attendanceForSession(
    EntityID sessionId,
  ) async {
    final rows = await _client
        .from('attendance_records')
        .select()
        .eq('session_id', sessionId);
    return rows.map((r) => AttendanceRecord.fromJson(_row(r))).toList();
  }

  @override
  Future<List<AttendanceRecord>> attendanceForAthlete(
    EntityID athleteId,
    DateTime since,
  ) async {
    final rows = await _client
        .from('attendance_records')
        .select()
        .eq('athlete_id', athleteId)
        .gte('recorded_at', _iso(since));
    return rows.map((r) => AttendanceRecord.fromJson(_row(r))).toList();
  }

  @override
  Future<void> upsertAttendance(AttendanceRecord record) async {
    await _client.from('attendance_records').upsert(_encode(record.toJson()));
  }

  @override
  Future<void> upsertAttendanceBatch(List<AttendanceRecord> records) async {
    if (records.isEmpty) return;
    await _client
        .from('attendance_records')
        .upsert(records.map((r) => _encode(r.toJson())).toList());
  }

  // ──────────────────────────────────────────────────────────────────────────
  // PerformanceRepository
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Future<PerformanceScore?> score(EntityID athleteId) async {
    final row = await _client
        .from('performance_scores')
        .select()
        .eq('athlete_id', athleteId)
        .order('calculated_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return row == null ? null : PerformanceScore.fromJson(_row(row));
  }

  @override
  Future<List<PerformanceScore>> scoreHistory(EntityID athleteId) async {
    final rows = await _client
        .from('performance_scores')
        .select()
        .eq('athlete_id', athleteId)
        .order('calculated_at', ascending: false);
    return rows.map((r) => PerformanceScore.fromJson(_row(r))).toList();
  }

  @override
  Future<List<PerformanceScore>> scoresInBranch(EntityID branchId) async {
    // Two-step join — mirror Swift.
    final athletesList = await athletesInBranch(branchId);
    if (athletesList.isEmpty) return [];
    final ids = athletesList.map((a) => a.id).toList();
    final rows = await _client
        .from('performance_scores')
        .select()
        .inFilter('athlete_id', ids)
        .order('calculated_at', ascending: false);
    return _latestPerAthlete(
      rows.map((r) => PerformanceScore.fromJson(_row(r))).toList(),
    );
  }

  @override
  Future<List<PerformanceScore>> allScores() async {
    final rows = await _client
        .from('performance_scores')
        .select()
        .order('calculated_at', ascending: false);
    return _latestPerAthlete(
      rows.map((r) => PerformanceScore.fromJson(_row(r))).toList(),
    );
  }

  /// Keep only the most-recent score per athlete — mirrors Swift's
  /// `latestPerAthlete(_:)` helper.
  List<PerformanceScore> _latestPerAthlete(List<PerformanceScore> records) {
    final seen = <EntityID>{};
    final out = <PerformanceScore>[];
    for (final r in records) {
      if (seen.add(r.athleteId)) out.add(r);
    }
    return out;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // MatchRepository
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Future<List<Match>> matchesForAthlete(EntityID athleteId) async {
    final rows = await _client
        .from('matches')
        .select()
        .or('our_athlete_id.eq.$athleteId,opponent_athlete_id.eq.$athleteId')
        .order('date', ascending: false);
    return rows.map((r) => Match.fromJson(_row(r))).toList();
  }

  @override
  Future<List<Match>> matchesForBranch(EntityID branchId) async {
    final athletesList = await athletesInBranch(branchId);
    if (athletesList.isEmpty) return [];
    final ids = athletesList.map((a) => a.id).toList();
    final rows = await _client
        .from('matches')
        .select()
        .inFilter('our_athlete_id', ids)
        .order('date', ascending: false);
    return rows.map((r) => Match.fromJson(_row(r))).toList();
  }

  @override
  Future<List<Match>> matchesForTournament(EntityID tournamentId) async {
    final rows = await _client
        .from('matches')
        .select()
        .eq('tournament_id', tournamentId)
        .order('date');
    return rows.map((r) => Match.fromJson(_row(r))).toList();
  }

  @override
  Future<void> upsertMatch(Match match) async {
    await _client.from('matches').upsert(_encode(match.toJson()));
  }

  // ──────────────────────────────────────────────────────────────────────────
  // PerformanceEntryRepository
  // ──────────────────────────────────────────────────────────────────────────

  // Table names: Swift uses singular forms without the 'athlete_' prefix for
  // technical_skill and poomsae_assessment, and 'athlete_physical_metric' for
  // physical metrics. wellness_entries is plural.

  @override
  Future<List<PhysicalMetric>> physicalMetrics(EntityID athleteId) async {
    final rows = await _client
        .from('athlete_physical_metric')
        .select()
        .eq('athlete_id', athleteId)
        .order('recorded_at', ascending: false);
    return rows.map((r) => PhysicalMetric.fromJson(_row(r))).toList();
  }

  @override
  Future<List<TechnicalSkill>> technicalSkills(EntityID athleteId) async {
    final rows = await _client
        .from('technical_skill')
        .select()
        .eq('athlete_id', athleteId)
        .order('recorded_at', ascending: false);
    return rows.map((r) => TechnicalSkill.fromJson(_row(r))).toList();
  }

  @override
  Future<List<PoomsaeAssessment>> poomsaeAssessments(EntityID athleteId) async {
    final rows = await _client
        .from('poomsae_assessment')
        .select()
        .eq('athlete_id', athleteId)
        .order('recorded_at', ascending: false);
    return rows.map((r) => PoomsaeAssessment.fromJson(_row(r))).toList();
  }

  @override
  Future<List<WellnessEntry>> wellness(
    EntityID athleteId,
    DateTime since,
  ) async {
    final rows = await _client
        .from('wellness_entries')
        .select()
        .eq('athlete_id', athleteId)
        .gte('recorded_at', _iso(since))
        .order('recorded_at', ascending: false);
    return rows.map((r) => WellnessEntry.fromJson(_row(r))).toList();
  }

  @override
  Future<void> upsertPhysicalMetric(PhysicalMetric metric) async {
    await _client
        .from('athlete_physical_metric')
        .upsert(_encode(metric.toJson()));
  }

  @override
  Future<void> upsertTechnicalSkill(TechnicalSkill skill) async {
    await _client.from('technical_skill').upsert(_encode(skill.toJson()));
  }

  @override
  Future<void> upsertPoomsaeAssessment(PoomsaeAssessment poomsae) async {
    await _client.from('poomsae_assessment').upsert(_encode(poomsae.toJson()));
  }

  @override
  Future<void> upsertWellness(WellnessEntry entry) async {
    await _client.from('wellness_entries').upsert(_encode(entry.toJson()));
  }

  @override
  Future<void> deletePhysicalMetric(EntityID id) async {
    await _client.from('athlete_physical_metric').delete().eq('id', id);
  }

  @override
  Future<void> deleteTechnicalSkill(EntityID id) async {
    await _client.from('technical_skill').delete().eq('id', id);
  }

  @override
  Future<void> deletePoomsaeAssessment(EntityID id) async {
    await _client.from('poomsae_assessment').delete().eq('id', id);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // GoalRepository
  // ──────────────────────────────────────────────────────────────────────────

  // Table: 'goal' (singular) — mirror Swift.

  @override
  Future<List<Goal>> goals(EntityID athleteId) async {
    final rows = await _client
        .from('goal')
        .select()
        .eq('athlete_id', athleteId)
        .order('created_at', ascending: false);
    return rows.map((r) => Goal.fromJson(_row(r))).toList();
  }

  @override
  Future<void> upsertGoal(Goal goal) async {
    await _client.from('goal').upsert(_encode(goal.toJson()));
  }

  @override
  Future<void> deleteGoal(EntityID id) async {
    await _client.from('goal').delete().eq('id', id);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // TrainingLoadRepository
  // ──────────────────────────────────────────────────────────────────────────

  // Table: 'training_load_entry' (singular) — mirror Swift.

  @override
  Future<List<TrainingLoadEntry>> trainingLoad(
    EntityID athleteId,
    DateTime since,
  ) async {
    final rows = await _client
        .from('training_load_entry')
        .select()
        .eq('athlete_id', athleteId)
        .gte('recorded_at', _iso(since))
        .order('recorded_at', ascending: false);
    return rows.map((r) => TrainingLoadEntry.fromJson(_row(r))).toList();
  }

  @override
  Future<void> upsertTrainingLoad(TrainingLoadEntry load) async {
    await _client.from('training_load_entry').upsert(_encode(load.toJson()));
  }

  @override
  Future<void> deleteTrainingLoad(EntityID id) async {
    await _client.from('training_load_entry').delete().eq('id', id);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // ImprovementPlanRepository
  // ──────────────────────────────────────────────────────────────────────────

  // Tables: 'drill_library_entry' and 'improvement_plan' (both singular) —
  // mirror Swift.

  @override
  Future<List<DrillLibraryEntry>> drills() async {
    final rows = await _client
        .from('drill_library_entry')
        .select()
        .order('name');
    return rows.map((r) => DrillLibraryEntry.fromJson(_row(r))).toList();
  }

  @override
  Future<void> upsertDrill(DrillLibraryEntry drill) async {
    await _client.from('drill_library_entry').upsert(_encode(drill.toJson()));
  }

  @override
  Future<void> deleteDrill(EntityID id) async {
    await _client.from('drill_library_entry').delete().eq('id', id);
  }

  @override
  Future<List<ImprovementPlan>> improvementPlans(EntityID athleteId) async {
    final rows = await _client
        .from('improvement_plan')
        .select()
        .eq('athlete_id', athleteId)
        .order('created_at', ascending: false);
    return rows.map((r) => ImprovementPlan.fromJson(_row(r))).toList();
  }

  @override
  Future<void> upsertPlan(ImprovementPlan plan) async {
    await _client.from('improvement_plan').upsert(_encode(plan.toJson()));
  }

  @override
  Future<void> deletePlan(EntityID id) async {
    await _client.from('improvement_plan').delete().eq('id', id);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // PeerBenchmarkRepository
  // ──────────────────────────────────────────────────────────────────────────

  // Table: 'peer_benchmark' (singular) — mirror Swift.

  @override
  Future<List<PeerBenchmark>> peerBenchmarks() async {
    final rows = await _client
        .from('peer_benchmark')
        .select()
        .order('computed_at', ascending: false);
    return rows.map((r) => PeerBenchmark.fromJson(_row(r))).toList();
  }

  @override
  Future<void> upsertBenchmarks(List<PeerBenchmark> benchmarks) async {
    if (benchmarks.isEmpty) return;
    await _client
        .from('peer_benchmark')
        .upsert(benchmarks.map((b) => _encode(b.toJson())).toList());
  }

  @override
  Future<List<PeerBenchmark>> recomputeBenchmarks() async {
    // Mirror Swift: fetch all athletes + all physical metrics, compute via
    // BenchmarkComputer, wipe-and-replace the peer_benchmark table.
    final allAthletes = await athletes();
    final allMetrics = <PhysicalMetric>[];
    for (final a in allAthletes) {
      allMetrics.addAll(await physicalMetrics(a.id));
    }
    final fresh = BenchmarkComputer.compute(
      athletes: allAthletes,
      metrics: allMetrics,
    );
    // Wipe existing rows then insert the fresh set.
    await _client.from('peer_benchmark').delete().neq('id', '');
    if (fresh.isNotEmpty) {
      await _client
          .from('peer_benchmark')
          .insert(fresh.map((b) => _encode(b.toJson())).toList());
    }
    return fresh;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // GradingRepository
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Future<GradingEligibility> eligibility(
    EntityID athleteId,
    Belt targetBelt,
  ) async {
    final a = await athlete(athleteId);
    if (a == null) {
      return GradingEligibility(
        athleteId: athleteId,
        currentBelt: targetBelt,
        targetBelt: targetBelt,
        monthsAtCurrent: 0,
        attendancePct: 0,
        latestTechnicalAvg: 0,
        latestPhysicalComposite: 0,
        isEligible: false,
        blockingReasons: const ['grading.blocking.attendance'],
      );
    }
    final since = DateTime.now().subtract(const Duration(days: 90));
    final attRecords = await attendanceForAthlete(athleteId, since);
    final skills = await technicalSkills(athleteId);
    final metrics = await physicalMetrics(athleteId);
    return GradingEngine.evaluateEligibility(
      athlete: a,
      attendance: attRecords,
      technical: skills,
      physical: metrics,
    );
  }

  @override
  Future<List<GradingSession>> gradingSessionsForBranch(
    EntityID branchId,
  ) async {
    final rows = await _client
        .from('grading_sessions')
        .select()
        .eq('branch_id', branchId)
        .order('scheduled_at');
    return rows.map((r) => GradingSession.fromJson(_row(r))).toList();
  }

  @override
  Future<GradingSession?> gradingSession(EntityID id) async {
    final row = await _client
        .from('grading_sessions')
        .select()
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : GradingSession.fromJson(_row(row));
  }

  @override
  Future<void> upsertGradingSession(GradingSession session) async {
    await _client.from('grading_sessions').upsert(_encode(session.toJson()));
  }

  @override
  Future<List<GradingScore>> gradingScores(EntityID sessionId) async {
    final rows = await _client
        .from('grading_scores')
        .select()
        .eq('session_id', sessionId);
    return rows.map((r) => GradingScore.fromJson(_row(r))).toList();
  }

  @override
  Future<void> upsertGradingScore(GradingScore gradingScore) async {
    await _client.from('grading_scores').upsert(_encode(gradingScore.toJson()));
  }

  @override
  Future<List<GradingCertificate>> certificates(EntityID athleteId) async {
    final rows = await _client
        .from('grading_certificates')
        .select()
        .eq('athlete_id', athleteId)
        .order('awarded_at', ascending: false);
    return rows.map((r) => GradingCertificate.fromJson(_row(r))).toList();
  }

  @override
  Future<void> issueCertificate(GradingCertificate certificate) async {
    await _client
        .from('grading_certificates')
        .upsert(_encode(certificate.toJson()));
  }

  // ──────────────────────────────────────────────────────────────────────────
  // TournamentRepository
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Future<List<Tournament>> tournaments() async {
    final rows = await _client.from('tournaments').select().order('starts_at');
    return rows.map((r) => Tournament.fromJson(_row(r))).toList();
  }

  @override
  Future<Tournament?> tournament(EntityID id) async {
    final row = await _client
        .from('tournaments')
        .select()
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : Tournament.fromJson(_row(row));
  }

  @override
  Future<void> upsertTournament(Tournament tournament) async {
    await _client.from('tournaments').upsert(_encode(tournament.toJson()));
  }

  @override
  Future<List<TournamentRegistration>> registrationsForTournament(
    EntityID tournamentId,
  ) async {
    final rows = await _client
        .from('tournament_registrations')
        .select()
        .eq('tournament_id', tournamentId);
    return rows.map((r) => TournamentRegistration.fromJson(_row(r))).toList();
  }

  @override
  Future<List<TournamentRegistration>> registrationsForAthlete(
    EntityID athleteId,
  ) async {
    final rows = await _client
        .from('tournament_registrations')
        .select()
        .eq('athlete_id', athleteId);
    return rows.map((r) => TournamentRegistration.fromJson(_row(r))).toList();
  }

  @override
  Future<void> upsertRegistration(TournamentRegistration registration) async {
    await _client
        .from('tournament_registrations')
        .upsert(_encode(registration.toJson()));
  }

  @override
  Future<List<WeightCutEntry>> weightCutHistory(EntityID registrationId) async {
    final rows = await _client
        .from('weight_cuts')
        .select()
        .eq('registration_id', registrationId)
        .order('recorded_at');
    return rows.map((r) => WeightCutEntry.fromJson(_row(r))).toList();
  }

  @override
  Future<void> upsertWeightCut(WeightCutEntry weightCut) async {
    await _client.from('weight_cuts').upsert(_encode(weightCut.toJson()));
  }

  @override
  Future<List<Bracket>> brackets(EntityID tournamentId) async {
    final rows = await _client
        .from('brackets')
        .select()
        .eq('tournament_id', tournamentId);
    return rows.map((r) => Bracket.fromJson(_row(r))).toList();
  }

  @override
  Future<void> upsertBracket(Bracket bracket) async {
    await _client.from('brackets').upsert(_encode(bracket.toJson()));
  }

  @override
  Future<List<BracketMatch>> bracketMatches(EntityID bracketId) async {
    final rows = await _client
        .from('bracket_matches')
        .select()
        .eq('bracket_id', bracketId)
        .order('round');
    return rows.map((r) => BracketMatch.fromJson(_row(r))).toList();
  }

  @override
  Future<void> upsertBracketMatch(BracketMatch bracketMatch) async {
    await _client
        .from('bracket_matches')
        .upsert(_encode(bracketMatch.toJson()));
  }

  // ──────────────────────────────────────────────────────────────────────────
  // LiveMatchRepository
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Future<Match?> activeMatch() async {
    // Mirror Swift: no server-side notion of "active"; return nil.
    return null;
  }

  @override
  Future<void> startMatch(Match match) async {
    await _client.from('matches').upsert(_encode(match.toJson()));
  }

  @override
  Future<void> recordEvent(ScoreEvent event) async {
    await _client.from('score_events').insert(_encode(event.toJson()));
  }

  @override
  Future<void> endRound(EntityID matchId) async {
    // Round transitions are inferred from score_events; nothing to write.
    // Mirror Swift no-op.
  }

  @override
  Future<void> finalizeMatch(Match match) async {
    await _client.from('matches').upsert(_encode(match.toJson()));
  }

  @override
  Stream<ScoreEvent> scoreEventStream(EntityID matchId) {
    // Live-backend impl. Mirrors Swift's `scoreEventStream(matchID:)` Realtime
    // subscription on the `score_events` table filtered by `match_id`. The
    // supabase-dart v2 `.stream(...)` builder emits the full filtered row set
    // (snake_case keys) on every insert/update; we decode each row through
    // `_row` (snake → camel) into `ScoreEvent` and flatten the per-snapshot
    // lists into a single event stream.
    return _client
        .from('score_events')
        .stream(primaryKey: ['id'])
        .eq('match_id', matchId)
        .map((rows) => rows.map((r) => ScoreEvent.fromJson(_row(r))).toList())
        .expand((events) => events);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // OperationsRepository
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Future<List<Announcement>> announcements(
    AnnouncementAudience? audience,
  ) async {
    List<Map<String, dynamic>> rows;
    if (audience != null) {
      rows = await _client
          .from('announcements')
          .select()
          .inFilter('audience', [audience.name, AnnouncementAudience.all.name])
          .order('published_at', ascending: false);
    } else {
      rows = await _client
          .from('announcements')
          .select()
          .order('published_at', ascending: false);
    }
    return rows.map((r) => Announcement.fromJson(_row(r))).toList();
  }

  @override
  Future<void> upsertAnnouncement(Announcement announcement) async {
    await _client.from('announcements').upsert(_encode(announcement.toJson()));
  }

  @override
  Future<List<AnnouncementRSVP>> rsvps(EntityID announcementId) async {
    final rows = await _client
        .from('announcement_rsvps')
        .select()
        .eq('announcement_id', announcementId);
    return rows.map((r) => AnnouncementRSVP.fromJson(_row(r))).toList();
  }

  @override
  Future<void> upsertRsvp(AnnouncementRSVP rsvp) async {
    await _client.from('announcement_rsvps').upsert(_encode(rsvp.toJson()));
  }

  @override
  Future<List<Certification>> certificationsForCoach(EntityID coachId) async {
    final rows = await _client
        .from('certifications')
        .select()
        .eq('coach_id', coachId)
        .order('expires_at');
    return rows.map((r) => Certification.fromJson(_row(r))).toList();
  }

  @override
  Future<List<Certification>> certifications() async {
    final rows = await _client
        .from('certifications')
        .select()
        .order('expires_at');
    return rows.map((r) => Certification.fromJson(_row(r))).toList();
  }

  @override
  Future<void> upsertCertification(Certification certification) async {
    await _client
        .from('certifications')
        .upsert(_encode(certification.toJson()));
  }

  @override
  Future<List<Certification>> expiringSoon(double seconds) async {
    final cutoff = DateTime.now().add(
      Duration(milliseconds: (seconds * 1000).round()),
    );
    final rows = await _client
        .from('certifications')
        .select()
        .lte('expires_at', _iso(cutoff))
        .order('expires_at');
    return rows.map((r) => Certification.fromJson(_row(r))).toList();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // AuditRepository
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Future<void> log(AuditEntry entry) async {
    await _client.from('audit_log').insert(_encode(entry.toJson()));
  }

  @override
  Future<List<AuditEntry>> entriesForActor({
    EntityID? actorId,
    DateTime? since,
  }) async {
    var query = _client.from('audit_log').select();
    if (actorId != null) query = query.eq('actor_user_id', actorId);
    if (since != null) query = query.gte('at', _iso(since));
    final rows = await query.order('at', ascending: false);
    return rows.map((r) => AuditEntry.fromJson(_row(r))).toList();
  }

  @override
  Future<List<AuditEntry>> entriesForTarget(EntityID targetId) async {
    final rows = await _client
        .from('audit_log')
        .select()
        .eq('target_id', targetId)
        .order('at', ascending: false);
    return rows.map((r) => AuditEntry.fromJson(_row(r))).toList();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // StorageRepository
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Future<String> uploadAthletePhoto({
    required EntityID athleteId,
    required Uint8List data,
    required String contentType,
  }) async {
    // Live-backend impl. Mirrors Swift's `uploadAthletePhoto`: object key
    // `<athleteId>.<ext>` in the `athletePhotos` Storage bucket, upsert, then
    // return the public URL.
    final ext = contentType.contains('png') ? 'png' : 'jpg';
    final path = '$athleteId.$ext';
    final bucket = _client.storage.from('athletePhotos');
    await bucket.uploadBinary(
      path,
      data,
      fileOptions: FileOptions(contentType: contentType, upsert: true),
    );
    return bucket.getPublicUrl(path);
  }

  @override
  Future<String> uploadUserAvatar({
    required EntityID userId,
    required Uint8List data,
    required String contentType,
  }) async {
    // Live-backend impl. Mirrors Swift's `uploadUserAvatar`: object key
    // `<userId>.<ext>` in the `userAvatars` Storage bucket, upsert, then return
    // the public URL.
    final ext = contentType.contains('png') ? 'png' : 'jpg';
    final path = '$userId.$ext';
    final bucket = _client.storage.from('userAvatars');
    await bucket.uploadBinary(
      path,
      data,
      fileOptions: FileOptions(contentType: contentType, upsert: true),
    );
    return bucket.getPublicUrl(path);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // BranchProfileRepository
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Future<BranchFacility?> facility(EntityID branchId) async {
    final row = await _client
        .from('branch_facilities')
        .select()
        .eq('branch_id', branchId)
        .maybeSingle();
    return row == null ? null : BranchFacility.fromJson(_row(row));
  }

  @override
  Future<void> upsertFacility(BranchFacility facility) async {
    await _client.from('branch_facilities').upsert(_encode(facility.toJson()));
  }

  @override
  Future<BranchHours?> hours(EntityID branchId) async {
    final row = await _client
        .from('branch_hours')
        .select()
        .eq('branch_id', branchId)
        .maybeSingle();
    return row == null ? null : BranchHours.fromJson(_row(row));
  }

  @override
  Future<void> upsertHours(BranchHours hours) async {
    await _client.from('branch_hours').upsert(_encode(hours.toJson()));
  }

  @override
  Future<List<BranchProgram>> programs(EntityID branchId) async {
    final rows = await _client
        .from('branch_programs')
        .select()
        .eq('branch_id', branchId)
        .order('start_time');
    return rows.map((r) => BranchProgram.fromJson(_row(r))).toList();
  }

  @override
  Future<void> upsertProgram(BranchProgram program) async {
    await _client.from('branch_programs').upsert(_encode(program.toJson()));
  }

  @override
  Future<BranchInventory?> inventory(EntityID branchId) async {
    final row = await _client
        .from('branch_inventories')
        .select()
        .eq('branch_id', branchId)
        .maybeSingle();
    return row == null ? null : BranchInventory.fromJson(_row(row));
  }

  @override
  Future<void> upsertInventory(BranchInventory inventory) async {
    await _client
        .from('branch_inventories')
        .upsert(_encode(inventory.toJson()));
  }

  @override
  Future<BranchCompliance?> compliance(EntityID branchId) async {
    final row = await _client
        .from('branch_compliances')
        .select()
        .eq('branch_id', branchId)
        .maybeSingle();
    return row == null ? null : BranchCompliance.fromJson(_row(row));
  }

  @override
  Future<void> upsertCompliance(BranchCompliance compliance) async {
    await _client
        .from('branch_compliances')
        .upsert(_encode(compliance.toJson()));
  }

  @override
  Future<BranchPricing?> pricing(EntityID branchId) async {
    final row = await _client
        .from('branch_pricings')
        .select()
        .eq('branch_id', branchId)
        .maybeSingle();
    return row == null ? null : BranchPricing.fromJson(_row(row));
  }

  @override
  Future<void> upsertPricing(BranchPricing pricing) async {
    await _client.from('branch_pricings').upsert(_encode(pricing.toJson()));
  }

  @override
  Future<List<BranchFinancials>> financials(
    EntityID branchId,
    int monthsBack,
  ) async {
    final cutoff = DateTime(
      DateTime.now().year,
      DateTime.now().month - monthsBack,
      1,
    );
    final rows = await _client
        .from('branch_financials')
        .select()
        .eq('branch_id', branchId)
        .gte('month', _iso(cutoff))
        .order('month');
    return rows.map((r) => BranchFinancials.fromJson(_row(r))).toList();
  }

  @override
  Future<void> upsertFinancials(BranchFinancials financials) async {
    await _client
        .from('branch_financials')
        .upsert(_encode(financials.toJson()));
  }

  @override
  Future<BranchMedia?> media(EntityID branchId) async {
    final row = await _client
        .from('branch_medias')
        .select()
        .eq('branch_id', branchId)
        .maybeSingle();
    return row == null ? null : BranchMedia.fromJson(_row(row));
  }

  @override
  Future<void> upsertMedia(BranchMedia media) async {
    await _client.from('branch_medias').upsert(_encode(media.toJson()));
  }

  @override
  Future<BranchSocialLinks?> socialLinks(EntityID branchId) async {
    final row = await _client
        .from('branch_social_links')
        .select()
        .eq('branch_id', branchId)
        .maybeSingle();
    return row == null ? null : BranchSocialLinks.fromJson(_row(row));
  }

  @override
  Future<void> upsertSocialLinks(BranchSocialLinks links) async {
    await _client.from('branch_social_links').upsert(_encode(links.toJson()));
  }

  @override
  Future<BranchSafeguarding?> safeguarding(EntityID branchId) async {
    final row = await _client
        .from('branch_safeguardings')
        .select()
        .eq('branch_id', branchId)
        .maybeSingle();
    return row == null ? null : BranchSafeguarding.fromJson(_row(row));
  }

  @override
  Future<void> upsertSafeguarding(BranchSafeguarding safe) async {
    await _client.from('branch_safeguardings').upsert(_encode(safe.toJson()));
  }

  @override
  Future<List<BranchMilestone>> milestones(EntityID branchId) async {
    final rows = await _client
        .from('branch_milestones')
        .select()
        .eq('branch_id', branchId)
        .order('occurred_at', ascending: false);
    return rows.map((r) => BranchMilestone.fromJson(_row(r))).toList();
  }

  @override
  Future<void> upsertMilestone(BranchMilestone milestone) async {
    await _client.from('branch_milestones').upsert(_encode(milestone.toJson()));
  }

  // ──────────────────────────────────────────────────────────────────────────
  // AthleteGroupRepository
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Future<List<AthleteGroup>> athleteGroups() async {
    final rows = await _client
        .from('athlete_groups')
        .select()
        .order('created_at', ascending: false);
    return rows.map((r) => AthleteGroup.fromJson(_row(r))).toList();
  }

  @override
  Future<AthleteGroup?> athleteGroup(EntityID id) async {
    final row = await _client
        .from('athlete_groups')
        .select()
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : AthleteGroup.fromJson(_row(row));
  }

  @override
  Future<void> upsertGroup(AthleteGroup group) async {
    await _client.from('athlete_groups').upsert(_encode(group.toJson()));
  }

  @override
  Future<void> deleteAthleteGroup(EntityID id) async {
    await _client.from('athlete_groups').delete().eq('id', id);
  }
}
