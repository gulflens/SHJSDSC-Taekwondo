import 'dart:typed_data';

import '../models/athlete.dart';
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
import 'seed_data.dart';

/// Port of `DemoRepository` (Core/Repository/DemoRepository.swift). The Swift
/// type is a `Sendable actor` for thread-safe in-memory state. Dart is
/// single-threaded per isolate, so an `async` class gives the same guarantee
/// without locking — every method stays `Future`-returning so swapping in the
/// network-backed [SupabaseRepository] is a drop-in.
///
/// Entity types not present in the seed start as empty in-memory collections.
/// Upsert adds/replaces by `id`, delete removes. Queries filter in memory.
class DemoRepository implements Repository, AuthRepository {
  DemoRepository() {
    final bundle = SeedData.build();
    _branches = {for (final b in bundle.branches) b.id: b};
    _users = bundle.users;
    _athletes = {for (final a in bundle.athletes) a.id: a};
    _scores = bundle.scores;
    _coaches = {for (final c in bundle.coaches) c.id: c};
    _sessions.addAll({for (final s in bundle.sessions) s.id: s});
    _gradingSessions.addAll(bundle.gradingSessions);
    _physicalMetrics.addAll(bundle.physicalMetrics);
    _technicalSkills.addAll(bundle.technicalSkills);
    _wellness.addAll(bundle.wellness);
    _announcements.addAll(bundle.announcements);
    _certifications.addAll(bundle.certifications);
    _auditLog.addAll(bundle.auditEntries);
    _tournaments.addAll({for (final t in bundle.tournaments) t.id: t});
    _registrations.addAll(bundle.registrations);
    _weightCuts.addAll(bundle.weightCuts);
    _attendance.addAll(bundle.attendance);
    _brackets.addAll({for (final b in bundle.brackets) b.id: b});
    _bracketMatches.addAll(bundle.bracketMatches);
    _goals.addAll({for (final g in bundle.goals) g.id: g});
    _currentUserId = _users.first.id;
  }

  // ── Core seeded collections ───────────────────────────────────────────────
  late Map<EntityID, Branch> _branches;
  late List<User> _users;
  late Map<EntityID, Athlete> _athletes;
  late List<PerformanceScore> _scores;
  late Map<EntityID, Coach> _coaches;
  EntityID? _currentUserId;

  // ── Empty in-memory stores (all other entity types) ───────────────────────
  final Map<EntityID, ClassSession> _sessions = {};
  final List<AttendanceRecord> _attendance = [];
  final List<Match> _matches = [];
  final List<PhysicalMetric> _physicalMetrics = [];
  final List<TechnicalSkill> _technicalSkills = [];
  final List<PoomsaeAssessment> _poomsaeAssessments = [];
  final List<WellnessEntry> _wellness = [];
  final Map<EntityID, Goal> _goals = {};
  final List<TrainingLoadEntry> _trainingLoad = [];
  final Map<EntityID, DrillLibraryEntry> _drills = {};
  final Map<EntityID, ImprovementPlan> _plans = {};
  final List<PeerBenchmark> _benchmarks = [];
  final List<GradingSession> _gradingSessions = [];
  final List<GradingScore> _gradingScores = [];
  final List<GradingCertificate> _gradingCertificates = [];
  final Map<EntityID, Tournament> _tournaments = {};
  final List<TournamentRegistration> _registrations = [];
  final List<WeightCutEntry> _weightCuts = [];
  final Map<EntityID, Bracket> _brackets = {};
  final List<BracketMatch> _bracketMatches = [];
  Match? _activeMatch;
  final List<Announcement> _announcements = [];
  final List<AnnouncementRSVP> _rsvps = [];
  final List<Certification> _certifications = [];
  final List<AuditEntry> _auditLog = [];
  final Map<EntityID, AthleteGroup> _groups = {};

  // BranchProfile — one entry per branch for singleton types, lists for others.
  final Map<EntityID, BranchFacility> _facilities = {};
  final Map<EntityID, BranchHours> _hours = {};
  final List<BranchProgram> _programs = [];
  final Map<EntityID, BranchInventory> _inventory = {};
  final Map<EntityID, BranchCompliance> _compliance = {};
  final Map<EntityID, BranchPricing> _pricing = {};
  final List<BranchFinancials> _financials = [];
  final Map<EntityID, BranchMedia> _media = {};
  final Map<EntityID, BranchSocialLinks> _socialLinks = {};
  final Map<EntityID, BranchSafeguarding> _safeguarding = {};
  final List<BranchMilestone> _milestones = [];

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// True when [day] falls on the same calendar date as [reference].
  bool _sameDay(DateTime day, DateTime reference) =>
      day.year == reference.year &&
      day.month == reference.month &&
      day.day == reference.day;

  // ══════════════════════════════════════════════════════════════════════════
  // UserRepository
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Future<User?> currentUser() async {
    if (_currentUserId == null) return null;
    return user(_currentUserId!);
  }

  @override
  Future<List<User>> availableUsers() async => List.unmodifiable(_users);

  @override
  Future<void> setCurrentUser(EntityID id) async => _currentUserId = id;

  // === AuthRepository (demo: credentials ignored, resolves a seeded user) ===
  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    // Match by email if a seeded user has one; otherwise sign in as the owner.
    final match = _users.cast<User?>().firstWhere(
          (u) => u?.email != null && u!.email!.toLowerCase() == email.toLowerCase().trim(),
          orElse: () => null,
        );
    _currentUserId = (match ?? _users.first).id;
  }

  @override
  Future<void> signOut() async => _currentUserId = null;

  @override
  Future<User?> user(EntityID id) async {
    for (final u in _users) {
      if (u.id == id) return u;
    }
    return null;
  }

  @override
  Future<List<User>> usersByRole(Role? role) async {
    if (role == null) return List.unmodifiable(_users);
    return _users.where((u) => u.role == role).toList();
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
    final id = newEntityId();
    _users = [
      ..._users,
      User(
        id: id,
        fullName: fullName,
        fullNameAr: fullNameAr,
        role: role,
        primaryBranchId: branchId,
        avatarSeed: id,
        email: email,
      ),
    ];
  }

  @override
  Future<void> updateUser(User user) async {
    _users = [
      for (final u in _users)
        if (u.id == user.id) user else u,
    ];
  }

  @override
  Future<void> linkChild({
    required EntityID userId,
    required EntityID athleteId,
  }) async {
    final u = await user(userId);
    if (u == null) return;
    final updated = User(
      id: u.id,
      fullName: u.fullName,
      fullNameAr: u.fullNameAr,
      role: u.role,
      primaryBranchId: u.primaryBranchId,
      avatarSeed: u.avatarSeed,
      linkedAthleteIds: [...u.linkedAthleteIds, athleteId],
      avatarUrl: u.avatarUrl,
      email: u.email,
    );
    await updateUser(updated);
  }

  @override
  Future<void> unlinkChild({
    required EntityID userId,
    required EntityID athleteId,
  }) async {
    final u = await user(userId);
    if (u == null) return;
    final updated = User(
      id: u.id,
      fullName: u.fullName,
      fullNameAr: u.fullNameAr,
      role: u.role,
      primaryBranchId: u.primaryBranchId,
      avatarSeed: u.avatarSeed,
      linkedAthleteIds: u.linkedAthleteIds
          .where((id) => id != athleteId)
          .toList(),
      avatarUrl: u.avatarUrl,
      email: u.email,
    );
    await updateUser(updated);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BranchRepository
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Future<List<Branch>> branches() async =>
      _branches.values.toList()..sort((a, b) => a.name.compareTo(b.name));

  @override
  Future<Branch?> branch(EntityID id) async => _branches[id];

  @override
  Future<void> upsertBranch(Branch branch) async =>
      _branches[branch.id] = branch;

  // ══════════════════════════════════════════════════════════════════════════
  // AthleteRepository
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Future<List<Athlete>> athletes() async =>
      _athletes.values.toList()
        ..sort((a, b) => a.memberNumber.compareTo(b.memberNumber));

  @override
  Future<List<Athlete>> athletesInBranch(EntityID branchId) async =>
      (await athletes()).where((a) => a.branchId == branchId).toList();

  @override
  Future<List<Athlete>> athletesForCoach(EntityID coachId) async =>
      (await athletes()).where((a) => a.primaryCoachId == coachId).toList();

  @override
  Future<Athlete?> athlete(EntityID id) async => _athletes[id];

  @override
  Future<void> upsertAthlete(Athlete athlete) async =>
      _athletes[athlete.id] = athlete;

  @override
  Future<Athlete?> athleteByMemberNumber(int memberNumber) async {
    for (final a in _athletes.values) {
      if (a.memberNumber == memberNumber) return a;
    }
    return null;
  }

  @override
  Future<int> nextMemberNumber() async {
    if (_athletes.isEmpty) return 1001;
    final maxMember = _athletes.values
        .map((a) => a.memberNumber)
        .reduce((a, b) => a > b ? a : b);
    return maxMember + 1;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CoachRepository
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Future<List<Coach>> coaches() async =>
      _coaches.values.toList()
        ..sort((a, b) => a.fullName.compareTo(b.fullName));

  @override
  Future<List<Coach>> coachesInBranch(EntityID branchId) async =>
      (await coaches())
          .where(
            (c) =>
                c.primaryBranchId == branchId ||
                c.secondaryBranchIds.contains(branchId),
          )
          .toList();

  @override
  Future<Coach?> coach(EntityID id) async => _coaches[id];

  @override
  Future<void> upsertCoach(Coach coach) async => _coaches[coach.id] = coach;

  // ══════════════════════════════════════════════════════════════════════════
  // ScheduleRepository
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Future<List<ClassSession>> sessionsForBranch(
    EntityID branchId,
    DateTime day,
  ) async => _sessions.values
      .where((s) => s.branchId == branchId && _sameDay(s.startsAt, day))
      .toList();

  @override
  Future<List<ClassSession>> sessionsForCoach(
    EntityID coachId,
    DateTime day,
  ) async => _sessions.values
      .where((s) => s.coachId == coachId && _sameDay(s.startsAt, day))
      .toList();

  @override
  Future<ClassSession?> session(EntityID id) async => _sessions[id];

  @override
  Future<void> upsertSession(ClassSession session) async =>
      _sessions[session.id] = session;

  @override
  Future<void> deleteSession(EntityID id) async => _sessions.remove(id);

  // ══════════════════════════════════════════════════════════════════════════
  // AttendanceRepository
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Future<List<AttendanceRecord>> attendanceForSession(
    EntityID sessionId,
  ) async => _attendance.where((r) => r.sessionId == sessionId).toList();

  @override
  Future<List<AttendanceRecord>> attendanceForAthlete(
    EntityID athleteId,
    DateTime since,
  ) async => _attendance
      .where((r) => r.athleteId == athleteId && !r.recordedAt.isBefore(since))
      .toList();

  @override
  Future<void> upsertAttendance(AttendanceRecord record) async {
    _attendance.removeWhere((r) => r.id == record.id);
    _attendance.add(record);
  }

  @override
  Future<void> upsertAttendanceBatch(List<AttendanceRecord> records) async {
    for (final r in records) {
      await upsertAttendance(r);
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PerformanceRepository
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Future<PerformanceScore?> score(EntityID athleteId) async {
    final history = await scoreHistory(athleteId);
    return history.isEmpty ? null : history.first;
  }

  @override
  Future<List<PerformanceScore>> scoreHistory(EntityID athleteId) async =>
      _scores.where((s) => s.athleteId == athleteId).toList()
        ..sort((a, b) => b.calculatedAt.compareTo(a.calculatedAt));

  @override
  Future<List<PerformanceScore>> scoresInBranch(EntityID branchId) async {
    final ids = (await athletesInBranch(branchId)).map((a) => a.id).toSet();
    return _scores.where((s) => ids.contains(s.athleteId)).toList();
  }

  @override
  Future<List<PerformanceScore>> allScores() async =>
      List.unmodifiable(_scores);

  // ══════════════════════════════════════════════════════════════════════════
  // MatchRepository
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Future<List<Match>> matchesForAthlete(EntityID athleteId) async =>
      _matches.where((m) => m.ourAthleteId == athleteId).toList();

  @override
  Future<List<Match>> matchesForBranch(EntityID branchId) async {
    final ids = (await athletesInBranch(branchId)).map((a) => a.id).toSet();
    return _matches.where((m) => ids.contains(m.ourAthleteId)).toList();
  }

  @override
  Future<List<Match>> matchesForTournament(EntityID tournamentId) async =>
      _matches.where((m) => m.tournamentId == tournamentId).toList();

  @override
  Future<void> upsertMatch(Match match) async {
    _matches.removeWhere((m) => m.id == match.id);
    _matches.add(match);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PerformanceEntryRepository
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Future<List<PhysicalMetric>> physicalMetrics(EntityID athleteId) async =>
      _physicalMetrics.where((m) => m.athleteId == athleteId).toList();

  @override
  Future<List<TechnicalSkill>> technicalSkills(EntityID athleteId) async =>
      _technicalSkills.where((s) => s.athleteId == athleteId).toList();

  @override
  Future<List<PoomsaeAssessment>> poomsaeAssessments(
    EntityID athleteId,
  ) async =>
      _poomsaeAssessments.where((p) => p.athleteId == athleteId).toList();

  @override
  Future<List<WellnessEntry>> wellness(
    EntityID athleteId,
    DateTime since,
  ) async => _wellness
      .where((w) => w.athleteId == athleteId && !w.recordedAt.isBefore(since))
      .toList();

  @override
  Future<void> upsertPhysicalMetric(PhysicalMetric metric) async {
    _physicalMetrics.removeWhere((m) => m.id == metric.id);
    _physicalMetrics.add(metric);
  }

  @override
  Future<void> upsertTechnicalSkill(TechnicalSkill skill) async {
    _technicalSkills.removeWhere((s) => s.id == skill.id);
    _technicalSkills.add(skill);
  }

  @override
  Future<void> upsertPoomsaeAssessment(PoomsaeAssessment poomsae) async {
    _poomsaeAssessments.removeWhere((p) => p.id == poomsae.id);
    _poomsaeAssessments.add(poomsae);
  }

  @override
  Future<void> upsertWellness(WellnessEntry entry) async {
    _wellness.removeWhere((w) => w.id == entry.id);
    _wellness.add(entry);
  }

  @override
  Future<void> deletePhysicalMetric(EntityID id) async =>
      _physicalMetrics.removeWhere((m) => m.id == id);

  @override
  Future<void> deleteTechnicalSkill(EntityID id) async =>
      _technicalSkills.removeWhere((s) => s.id == id);

  @override
  Future<void> deletePoomsaeAssessment(EntityID id) async =>
      _poomsaeAssessments.removeWhere((p) => p.id == id);

  // ══════════════════════════════════════════════════════════════════════════
  // GoalRepository
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Future<List<Goal>> goals(EntityID athleteId) async =>
      _goals.values.where((g) => g.athleteId == athleteId).toList();

  @override
  Future<void> upsertGoal(Goal goal) async => _goals[goal.id] = goal;

  @override
  Future<void> deleteGoal(EntityID id) async => _goals.remove(id);

  // ══════════════════════════════════════════════════════════════════════════
  // TrainingLoadRepository
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Future<List<TrainingLoadEntry>> trainingLoad(
    EntityID athleteId,
    DateTime since,
  ) async => _trainingLoad
      .where((e) => e.athleteId == athleteId && !e.recordedAt.isBefore(since))
      .toList();

  @override
  Future<void> upsertTrainingLoad(TrainingLoadEntry load) async {
    _trainingLoad.removeWhere((e) => e.id == load.id);
    _trainingLoad.add(load);
  }

  @override
  Future<void> deleteTrainingLoad(EntityID id) async =>
      _trainingLoad.removeWhere((e) => e.id == id);

  // ══════════════════════════════════════════════════════════════════════════
  // ImprovementPlanRepository
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Future<List<DrillLibraryEntry>> drills() async =>
      _drills.values.toList()..sort((a, b) => a.name.compareTo(b.name));

  @override
  Future<void> upsertDrill(DrillLibraryEntry drill) async =>
      _drills[drill.id] = drill;

  @override
  Future<void> deleteDrill(EntityID id) async => _drills.remove(id);

  @override
  Future<List<ImprovementPlan>> improvementPlans(EntityID athleteId) async =>
      _plans.values.where((p) => p.athleteId == athleteId).toList();

  @override
  Future<void> upsertPlan(ImprovementPlan plan) async => _plans[plan.id] = plan;

  @override
  Future<void> deletePlan(EntityID id) async => _plans.remove(id);

  // ══════════════════════════════════════════════════════════════════════════
  // PeerBenchmarkRepository
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Future<List<PeerBenchmark>> peerBenchmarks() async =>
      List.unmodifiable(_benchmarks);

  @override
  Future<void> upsertBenchmarks(List<PeerBenchmark> benchmarks) async {
    for (final b in benchmarks) {
      _benchmarks.removeWhere((x) => x.id == b.id);
      _benchmarks.add(b);
    }
  }

  @override
  Future<List<PeerBenchmark>> recomputeBenchmarks() async {
    final athleteList = _athletes.values.toList();
    final computed = BenchmarkComputer.compute(
      athletes: athleteList,
      metrics: _physicalMetrics,
    );
    _benchmarks
      ..clear()
      ..addAll(computed);
    return computed;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // GradingRepository
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Future<GradingEligibility> eligibility(
    EntityID athleteId,
    Belt targetBelt,
  ) async {
    final a = await athlete(athleteId);
    if (a == null) {
      // Fallback: ineligible with a generic reason.
      return GradingEligibility(
        athleteId: athleteId,
        currentBelt: Belt(
          color: BeltColor.white,
          kind: BeltKind.gup,
          number: 10,
          awardedAt: DateTime.now(),
        ),
        targetBelt: targetBelt,
        monthsAtCurrent: 0,
        attendancePct: 0,
        latestTechnicalAvg: 0,
        latestPhysicalComposite: 0,
        isEligible: false,
        blockingReasons: ['grading.block.athlete_not_found'],
      );
    }
    final since = DateTime.now().subtract(const Duration(days: 90));
    final attendanceRecords = await attendanceForAthlete(athleteId, since);
    final skills = await technicalSkills(athleteId);
    final physical = await physicalMetrics(athleteId);
    return GradingEngine.evaluateEligibility(
      athlete: a,
      attendance: attendanceRecords,
      technical: skills,
      physical: physical,
    );
  }

  @override
  Future<List<GradingSession>> gradingSessionsForBranch(
    EntityID branchId,
  ) async => _gradingSessions.where((s) => s.branchId == branchId).toList();

  @override
  Future<GradingSession?> gradingSession(EntityID id) async {
    for (final s in _gradingSessions) {
      if (s.id == id) return s;
    }
    return null;
  }

  @override
  Future<void> upsertGradingSession(GradingSession session) async {
    _gradingSessions.removeWhere((s) => s.id == session.id);
    _gradingSessions.add(session);
  }

  @override
  Future<List<GradingScore>> gradingScores(EntityID sessionId) async =>
      _gradingScores.where((s) => s.sessionId == sessionId).toList();

  @override
  Future<void> upsertGradingScore(GradingScore gradingScore) async {
    _gradingScores.removeWhere((s) => s.id == gradingScore.id);
    _gradingScores.add(gradingScore);
  }

  @override
  Future<List<GradingCertificate>> certificates(EntityID athleteId) async =>
      _gradingCertificates.where((c) => c.athleteId == athleteId).toList();

  @override
  Future<void> issueCertificate(GradingCertificate certificate) async {
    _gradingCertificates.removeWhere((c) => c.id == certificate.id);
    _gradingCertificates.add(certificate);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TournamentRepository
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Future<List<Tournament>> tournaments() async =>
      _tournaments.values.toList()
        ..sort((a, b) => b.startsAt.compareTo(a.startsAt));

  @override
  Future<Tournament?> tournament(EntityID id) async => _tournaments[id];

  @override
  Future<void> upsertTournament(Tournament tournament) async =>
      _tournaments[tournament.id] = tournament;

  @override
  Future<List<TournamentRegistration>> registrationsForTournament(
    EntityID tournamentId,
  ) async =>
      _registrations.where((r) => r.tournamentId == tournamentId).toList();

  @override
  Future<List<TournamentRegistration>> registrationsForAthlete(
    EntityID athleteId,
  ) async => _registrations.where((r) => r.athleteId == athleteId).toList();

  @override
  Future<void> upsertRegistration(TournamentRegistration registration) async {
    _registrations.removeWhere((r) => r.id == registration.id);
    _registrations.add(registration);
  }

  @override
  Future<List<WeightCutEntry>> weightCutHistory(
    EntityID registrationId,
  ) async =>
      _weightCuts.where((w) => w.registrationId == registrationId).toList();

  @override
  Future<void> upsertWeightCut(WeightCutEntry weightCut) async {
    _weightCuts.removeWhere((w) => w.id == weightCut.id);
    _weightCuts.add(weightCut);
  }

  @override
  Future<List<Bracket>> brackets(EntityID tournamentId) async =>
      _brackets.values.where((b) => b.tournamentId == tournamentId).toList();

  @override
  Future<void> upsertBracket(Bracket bracket) async =>
      _brackets[bracket.id] = bracket;

  @override
  Future<List<BracketMatch>> bracketMatches(EntityID bracketId) async =>
      _bracketMatches.where((bm) => bm.bracketId == bracketId).toList();

  @override
  Future<void> upsertBracketMatch(BracketMatch bracketMatch) async {
    _bracketMatches.removeWhere((bm) => bm.id == bracketMatch.id);
    _bracketMatches.add(bracketMatch);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LiveMatchRepository
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Future<Match?> activeMatch() async => _activeMatch;

  @override
  Future<void> startMatch(Match match) async {
    _activeMatch = match;
    _matches.removeWhere((m) => m.id == match.id);
    _matches.add(match);
  }

  @override
  Future<void> recordEvent(ScoreEvent event) async {
    // In the demo, events are embedded in the Match model — we simply store them
    // in the audit log as signals; real aggregation deferred to Supabase stage.
  }

  @override
  Future<void> endRound(EntityID matchId) async {
    // No-op in demo.
  }

  @override
  Future<void> finalizeMatch(Match match) async {
    _activeMatch = null;
    _matches.removeWhere((m) => m.id == match.id);
    _matches.add(match);
  }

  @override
  Stream<ScoreEvent> scoreEventStream(EntityID matchId) => const Stream.empty();

  // ══════════════════════════════════════════════════════════════════════════
  // OperationsRepository
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Future<List<Announcement>> announcements(
    AnnouncementAudience? audience,
  ) async {
    if (audience == null) return List.unmodifiable(_announcements);
    return _announcements
        .where((a) => a.effectiveAudiences.contains(audience))
        .toList();
  }

  @override
  Future<void> upsertAnnouncement(Announcement announcement) async {
    _announcements.removeWhere((a) => a.id == announcement.id);
    _announcements.add(announcement);
  }

  @override
  Future<List<AnnouncementRSVP>> rsvps(EntityID announcementId) async =>
      _rsvps.where((r) => r.announcementId == announcementId).toList();

  @override
  Future<void> upsertRsvp(AnnouncementRSVP rsvp) async {
    _rsvps.removeWhere((r) => r.id == rsvp.id);
    _rsvps.add(rsvp);
  }

  @override
  Future<List<Certification>> certificationsForCoach(EntityID coachId) async =>
      _certifications.where((c) => c.coachId == coachId).toList();

  @override
  Future<List<Certification>> certifications() async =>
      List.unmodifiable(_certifications);

  @override
  Future<void> upsertCertification(Certification certification) async {
    _certifications.removeWhere((c) => c.id == certification.id);
    _certifications.add(certification);
  }

  @override
  Future<List<Certification>> expiringSoon(double seconds) async {
    final threshold = DateTime.now().add(Duration(seconds: seconds.toInt()));
    return _certifications
        .where((c) => c.expiresAt.isBefore(threshold))
        .toList();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // AuditRepository
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Future<void> log(AuditEntry entry) async => _auditLog.add(entry);

  @override
  Future<List<AuditEntry>> entriesForActor({
    EntityID? actorId,
    DateTime? since,
  }) async => _auditLog.where((e) {
    if (actorId != null && e.actorUserId != actorId) return false;
    if (since != null && e.at.isBefore(since)) return false;
    return true;
  }).toList();

  @override
  Future<List<AuditEntry>> entriesForTarget(EntityID targetId) async =>
      _auditLog.where((e) => e.targetId == targetId).toList();

  // ══════════════════════════════════════════════════════════════════════════
  // StorageRepository
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Future<String> uploadAthletePhoto({
    required EntityID athleteId,
    required Uint8List data,
    required String contentType,
  }) async => 'memory://athlete/$athleteId/photo';

  @override
  Future<String> uploadUserAvatar({
    required EntityID userId,
    required Uint8List data,
    required String contentType,
  }) async => 'memory://user/$userId/avatar';

  // ══════════════════════════════════════════════════════════════════════════
  // BranchProfileRepository
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Future<BranchFacility?> facility(EntityID branchId) async =>
      _facilities[branchId];

  @override
  Future<void> upsertFacility(BranchFacility facility) async =>
      _facilities[facility.branchId] = facility;

  @override
  Future<BranchHours?> hours(EntityID branchId) async => _hours[branchId];

  @override
  Future<void> upsertHours(BranchHours hours) async =>
      _hours[hours.branchId] = hours;

  @override
  Future<List<BranchProgram>> programs(EntityID branchId) async =>
      _programs.where((p) => p.branchId == branchId).toList();

  @override
  Future<void> upsertProgram(BranchProgram program) async {
    _programs.removeWhere((p) => p.id == program.id);
    _programs.add(program);
  }

  @override
  Future<BranchInventory?> inventory(EntityID branchId) async =>
      _inventory[branchId];

  @override
  Future<void> upsertInventory(BranchInventory inventory) async =>
      _inventory[inventory.branchId] = inventory;

  @override
  Future<BranchCompliance?> compliance(EntityID branchId) async =>
      _compliance[branchId];

  @override
  Future<void> upsertCompliance(BranchCompliance compliance) async =>
      _compliance[compliance.branchId] = compliance;

  @override
  Future<BranchPricing?> pricing(EntityID branchId) async => _pricing[branchId];

  @override
  Future<void> upsertPricing(BranchPricing pricing) async =>
      _pricing[pricing.branchId] = pricing;

  @override
  Future<List<BranchFinancials>> financials(
    EntityID branchId,
    int monthsBack,
  ) async {
    final cutoff = DateTime.now().subtract(Duration(days: monthsBack * 30));
    return _financials
        .where((f) => f.branchId == branchId && !f.month.isBefore(cutoff))
        .toList();
  }

  @override
  Future<void> upsertFinancials(BranchFinancials financials) async {
    _financials.removeWhere((f) => f.id == financials.id);
    _financials.add(financials);
  }

  @override
  Future<BranchMedia?> media(EntityID branchId) async => _media[branchId];

  @override
  Future<void> upsertMedia(BranchMedia media) async =>
      _media[media.branchId] = media;

  @override
  Future<BranchSocialLinks?> socialLinks(EntityID branchId) async =>
      _socialLinks[branchId];

  @override
  Future<void> upsertSocialLinks(BranchSocialLinks links) async =>
      _socialLinks[links.branchId] = links;

  @override
  Future<BranchSafeguarding?> safeguarding(EntityID branchId) async =>
      _safeguarding[branchId];

  @override
  Future<void> upsertSafeguarding(BranchSafeguarding safe) async =>
      _safeguarding[safe.branchId] = safe;

  @override
  Future<List<BranchMilestone>> milestones(EntityID branchId) async =>
      _milestones.where((m) => m.branchId == branchId).toList();

  @override
  Future<void> upsertMilestone(BranchMilestone milestone) async {
    _milestones.removeWhere((m) => m.id == milestone.id);
    _milestones.add(milestone);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // AthleteGroupRepository
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Future<List<AthleteGroup>> athleteGroups() async =>
      _groups.values.toList()..sort((a, b) => a.name.compareTo(b.name));

  @override
  Future<AthleteGroup?> athleteGroup(EntityID id) async => _groups[id];

  @override
  Future<void> upsertGroup(AthleteGroup group) async =>
      _groups[group.id] = group;

  @override
  Future<void> deleteAthleteGroup(EntityID id) async => _groups.remove(id);
}
