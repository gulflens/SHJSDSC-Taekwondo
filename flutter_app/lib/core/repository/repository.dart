import 'dart:typed_data';

import '../models/athlete.dart';
import '../models/athlete_group.dart';
import '../models/audit_log.dart';
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
import '../models/belt.dart';
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

/// Port of the protocol surface in Core/Repository/Repository.swift.
///
/// Each Swift `protocol` maps to one Dart `abstract class`. All 21 sub-protocols
/// are composed into the single [Repository] facade so a single instance
/// (Demo or Supabase) can be injected app-wide via get_it.
///
/// Dart cannot overload by parameter type. Swift overloads are disambiguated
/// with descriptive suffixes — see the disambiguation table in FLUTTER_PORT.md.

// ──────────────────────────────────────────────────────────────────────────────
// 1. UserRepository
// ──────────────────────────────────────────────────────────────────────────────

abstract class UserRepository {
  // Existing — must not be renamed (called by session_cubit, screens, tests).
  Future<User?> currentUser();
  Future<List<User>> availableUsers();
  Future<void> setCurrentUser(EntityID id);
  Future<User?> user(EntityID id);

  // New in this port.
  /// Filter by role; null = all roles.
  Future<List<User>> usersByRole(Role? role);
  Future<void> createAccount({
    required String email,
    required String password,
    required String fullName,
    required String fullNameAr,
    required Role role,
    EntityID? branchId,
  });
  Future<void> updateUser(User user);
  Future<void> linkChild({
    required EntityID userId,
    required EntityID athleteId,
  });
  Future<void> unlinkChild({
    required EntityID userId,
    required EntityID athleteId,
  });
}

// ──────────────────────────────────────────────────────────────────────────────
// 2. BranchRepository
// ──────────────────────────────────────────────────────────────────────────────

abstract class BranchRepository {
  // Existing.
  Future<List<Branch>> branches();
  Future<Branch?> branch(EntityID id);

  // New.
  Future<void> upsertBranch(Branch branch);
}

// ──────────────────────────────────────────────────────────────────────────────
// 3. AthleteRepository
// ──────────────────────────────────────────────────────────────────────────────

abstract class AthleteRepository {
  // Existing — must not be renamed.
  Future<List<Athlete>> athletes();
  Future<List<Athlete>> athletesInBranch(EntityID branchId);
  Future<List<Athlete>> athletesForCoach(EntityID coachId);
  Future<Athlete?> athlete(EntityID id);
  Future<void> upsertAthlete(Athlete athlete);

  // New.
  /// Lookup by member number; Swift: `athlete(memberNumber:)`.
  Future<Athlete?> athleteByMemberNumber(int memberNumber);
  Future<int> nextMemberNumber();
}

// ──────────────────────────────────────────────────────────────────────────────
// 4. CoachRepository
// ──────────────────────────────────────────────────────────────────────────────

abstract class CoachRepository {
  Future<List<Coach>> coaches();
  Future<List<Coach>> coachesInBranch(EntityID branchId);
  Future<Coach?> coach(EntityID id);
  Future<void> upsertCoach(Coach coach);
}

// ──────────────────────────────────────────────────────────────────────────────
// 5. ScheduleRepository
// ──────────────────────────────────────────────────────────────────────────────

abstract class ScheduleRepository {
  /// Swift: `sessions(branchID:on:)`.
  Future<List<ClassSession>> sessionsForBranch(EntityID branchId, DateTime day);

  /// Swift: `sessions(coachID:on:)`.
  Future<List<ClassSession>> sessionsForCoach(EntityID coachId, DateTime day);

  Future<ClassSession?> session(EntityID id);
  Future<void> upsertSession(ClassSession session);
  Future<void> deleteSession(EntityID id);
}

// ──────────────────────────────────────────────────────────────────────────────
// 6. AttendanceRepository
// ──────────────────────────────────────────────────────────────────────────────

abstract class AttendanceRepository {
  /// Swift: `attendance(sessionID:)`.
  Future<List<AttendanceRecord>> attendanceForSession(EntityID sessionId);

  /// Swift: `attendance(athleteID:since:)`.
  Future<List<AttendanceRecord>> attendanceForAthlete(
    EntityID athleteId,
    DateTime since,
  );

  /// Upsert a single record. Swift: `upsertAttendance(_ record:)`.
  Future<void> upsertAttendance(AttendanceRecord record);

  /// Upsert a batch. Swift: `upsertAttendance(_ records:)`.
  Future<void> upsertAttendanceBatch(List<AttendanceRecord> records);
}

// ──────────────────────────────────────────────────────────────────────────────
// 7. PerformanceRepository
// ──────────────────────────────────────────────────────────────────────────────

abstract class PerformanceRepository {
  // Existing — must not be renamed.
  Future<PerformanceScore?> score(EntityID athleteId);
  Future<List<PerformanceScore>> scoreHistory(EntityID athleteId);
  Future<List<PerformanceScore>> scoresInBranch(EntityID branchId);
  Future<List<PerformanceScore>> allScores();
}

// ──────────────────────────────────────────────────────────────────────────────
// 8. MatchRepository
// ──────────────────────────────────────────────────────────────────────────────

abstract class MatchRepository {
  /// Swift: `matches(athleteID:)`.
  Future<List<Match>> matchesForAthlete(EntityID athleteId);

  /// Swift: `matches(branchID:)`.
  Future<List<Match>> matchesForBranch(EntityID branchId);

  /// Swift: `matches(tournamentID:)`.
  Future<List<Match>> matchesForTournament(EntityID tournamentId);

  Future<void> upsertMatch(Match match);
}

// ──────────────────────────────────────────────────────────────────────────────
// 9. PerformanceEntryRepository
// ──────────────────────────────────────────────────────────────────────────────

abstract class PerformanceEntryRepository {
  Future<List<PhysicalMetric>> physicalMetrics(EntityID athleteId);
  Future<List<TechnicalSkill>> technicalSkills(EntityID athleteId);
  Future<List<PoomsaeAssessment>> poomsaeAssessments(EntityID athleteId);

  /// Swift: `wellness(athleteID:since:)`.
  Future<List<WellnessEntry>> wellness(EntityID athleteId, DateTime since);

  /// Swift: `upsert(metric:)`.
  Future<void> upsertPhysicalMetric(PhysicalMetric metric);

  /// Swift: `upsert(skill:)`.
  Future<void> upsertTechnicalSkill(TechnicalSkill skill);

  /// Swift: `upsert(poomsae:)`.
  Future<void> upsertPoomsaeAssessment(PoomsaeAssessment poomsae);

  /// Swift: `upsert(wellness:)`.
  Future<void> upsertWellness(WellnessEntry entry);

  Future<void> deletePhysicalMetric(EntityID id);
  Future<void> deleteTechnicalSkill(EntityID id);
  Future<void> deletePoomsaeAssessment(EntityID id);
}

// ──────────────────────────────────────────────────────────────────────────────
// 10. GoalRepository
// ──────────────────────────────────────────────────────────────────────────────

abstract class GoalRepository {
  Future<List<Goal>> goals(EntityID athleteId);

  /// Swift: `upsert(goal:)`.
  Future<void> upsertGoal(Goal goal);
  Future<void> deleteGoal(EntityID id);
}

// ──────────────────────────────────────────────────────────────────────────────
// 11. TrainingLoadRepository
// ──────────────────────────────────────────────────────────────────────────────

abstract class TrainingLoadRepository {
  /// Swift: `trainingLoad(athleteID:since:)`.
  Future<List<TrainingLoadEntry>> trainingLoad(
    EntityID athleteId,
    DateTime since,
  );

  /// Swift: `upsert(load:)`.
  Future<void> upsertTrainingLoad(TrainingLoadEntry load);
  Future<void> deleteTrainingLoad(EntityID id);
}

// ──────────────────────────────────────────────────────────────────────────────
// 12. ImprovementPlanRepository
// ──────────────────────────────────────────────────────────────────────────────

abstract class ImprovementPlanRepository {
  Future<List<DrillLibraryEntry>> drills();

  /// Swift: `upsert(drill:)`.
  Future<void> upsertDrill(DrillLibraryEntry drill);
  Future<void> deleteDrill(EntityID id);

  Future<List<ImprovementPlan>> improvementPlans(EntityID athleteId);

  /// Swift: `upsert(plan:)`.
  Future<void> upsertPlan(ImprovementPlan plan);
  Future<void> deletePlan(EntityID id);
}

// ──────────────────────────────────────────────────────────────────────────────
// 13. PeerBenchmarkRepository
// ──────────────────────────────────────────────────────────────────────────────

abstract class PeerBenchmarkRepository {
  Future<List<PeerBenchmark>> peerBenchmarks();
  Future<void> upsertBenchmarks(List<PeerBenchmark> benchmarks);

  /// Wipe and recompute from current athlete + metric data.
  Future<List<PeerBenchmark>> recomputeBenchmarks();
}

// ──────────────────────────────────────────────────────────────────────────────
// 14. GradingRepository
// ──────────────────────────────────────────────────────────────────────────────

abstract class GradingRepository {
  /// Swift: `eligibility(athleteID:targetBelt:)`.
  Future<GradingEligibility> eligibility(EntityID athleteId, Belt targetBelt);

  /// Swift: `gradingSessions(branchID:)`.
  Future<List<GradingSession>> gradingSessionsForBranch(EntityID branchId);

  Future<GradingSession?> gradingSession(EntityID id);

  /// Swift: `upsert(_ session: GradingSession)`.
  Future<void> upsertGradingSession(GradingSession session);

  Future<List<GradingScore>> gradingScores(EntityID sessionId);

  /// Swift: `upsert(_ score: GradingScore)`.
  Future<void> upsertGradingScore(GradingScore gradingScore);

  Future<List<GradingCertificate>> certificates(EntityID athleteId);
  Future<void> issueCertificate(GradingCertificate certificate);
}

// ──────────────────────────────────────────────────────────────────────────────
// 15. TournamentRepository
// ──────────────────────────────────────────────────────────────────────────────

abstract class TournamentRepository {
  Future<List<Tournament>> tournaments();
  Future<Tournament?> tournament(EntityID id);

  /// Swift: `upsert(tournament:)`.
  Future<void> upsertTournament(Tournament tournament);

  /// Swift: `registrations(tournamentID:)`.
  Future<List<TournamentRegistration>> registrationsForTournament(
    EntityID tournamentId,
  );

  /// Swift: `registrations(athleteID:)`.
  Future<List<TournamentRegistration>> registrationsForAthlete(
    EntityID athleteId,
  );

  /// Swift: `upsert(registration:)`.
  Future<void> upsertRegistration(TournamentRegistration registration);

  /// Swift: `weightCutHistory(registrationID:)`.
  Future<List<WeightCutEntry>> weightCutHistory(EntityID registrationId);

  /// Swift: `upsert(weightCut:)`.
  Future<void> upsertWeightCut(WeightCutEntry weightCut);

  /// Swift: `brackets(tournamentID:)`.
  Future<List<Bracket>> brackets(EntityID tournamentId);

  /// Swift: `upsert(bracket:)`.
  Future<void> upsertBracket(Bracket bracket);

  /// Swift: `bracketMatches(bracketID:)`.
  Future<List<BracketMatch>> bracketMatches(EntityID bracketId);

  /// Swift: `upsert(bracketMatch:)`.
  Future<void> upsertBracketMatch(BracketMatch bracketMatch);
}

// ──────────────────────────────────────────────────────────────────────────────
// 16. LiveMatchRepository
// ──────────────────────────────────────────────────────────────────────────────

abstract class LiveMatchRepository {
  Future<Match?> activeMatch();
  Future<void> startMatch(Match match);
  Future<void> recordEvent(ScoreEvent event);
  Future<void> endRound(EntityID matchId);
  Future<void> finalizeMatch(Match match);

  /// Swift `AsyncStream<ScoreEvent>` → Dart `Stream<ScoreEvent>`.
  /// Demo returns `const Stream.empty()`.
  Stream<ScoreEvent> scoreEventStream(EntityID matchId);
}

// ──────────────────────────────────────────────────────────────────────────────
// 17. OperationsRepository
// ──────────────────────────────────────────────────────────────────────────────

abstract class OperationsRepository {
  /// Swift: `announcements(audience:)` — null = all audiences.
  Future<List<Announcement>> announcements(AnnouncementAudience? audience);

  /// Swift: `upsert(announcement:)`.
  Future<void> upsertAnnouncement(Announcement announcement);

  /// Swift: `rsvps(announcementID:)`.
  Future<List<AnnouncementRSVP>> rsvps(EntityID announcementId);

  /// Swift: `upsert(rsvp:)`.
  Future<void> upsertRsvp(AnnouncementRSVP rsvp);

  /// Swift: `certifications(coachID:)`.
  Future<List<Certification>> certificationsForCoach(EntityID coachId);

  /// Swift: `certifications()` — all coaches.
  Future<List<Certification>> certifications();

  /// Swift: `upsert(certification:)`.
  Future<void> upsertCertification(Certification certification);

  /// Swift: `expiringSoon(within:)` — [seconds] maps to Swift's `TimeInterval`.
  Future<List<Certification>> expiringSoon(double seconds);
}

// ──────────────────────────────────────────────────────────────────────────────
// 18. AuditRepository
// ──────────────────────────────────────────────────────────────────────────────

abstract class AuditRepository {
  Future<void> log(AuditEntry entry);

  /// Swift: `entries(actor:since:)` — either param may be null.
  Future<List<AuditEntry>> entriesForActor({
    EntityID? actorId,
    DateTime? since,
  });

  /// Swift: `entries(target:)`.
  Future<List<AuditEntry>> entriesForTarget(EntityID targetId);
}

// ──────────────────────────────────────────────────────────────────────────────
// 19. StorageRepository
// ──────────────────────────────────────────────────────────────────────────────

abstract class StorageRepository {
  /// Swift: `uploadAthletePhoto(athleteID:data:contentType:)`.
  /// Returns a publicly-resolvable URL string.
  Future<String> uploadAthletePhoto({
    required EntityID athleteId,
    required Uint8List data,
    required String contentType,
  });

  /// Swift: `uploadUserAvatar(userID:data:contentType:)`.
  Future<String> uploadUserAvatar({
    required EntityID userId,
    required Uint8List data,
    required String contentType,
  });
}

// ──────────────────────────────────────────────────────────────────────────────
// 20. BranchProfileRepository
// ──────────────────────────────────────────────────────────────────────────────

abstract class BranchProfileRepository {
  Future<BranchFacility?> facility(EntityID branchId);

  /// Swift: `upsert(_ facility:)`.
  Future<void> upsertFacility(BranchFacility facility);

  Future<BranchHours?> hours(EntityID branchId);
  Future<void> upsertHours(BranchHours hours);

  Future<List<BranchProgram>> programs(EntityID branchId);
  Future<void> upsertProgram(BranchProgram program);

  Future<BranchInventory?> inventory(EntityID branchId);
  Future<void> upsertInventory(BranchInventory inventory);

  Future<BranchCompliance?> compliance(EntityID branchId);
  Future<void> upsertCompliance(BranchCompliance compliance);

  Future<BranchPricing?> pricing(EntityID branchId);
  Future<void> upsertPricing(BranchPricing pricing);

  /// Swift: `financials(branchID:monthsBack:)`.
  Future<List<BranchFinancials>> financials(EntityID branchId, int monthsBack);
  Future<void> upsertFinancials(BranchFinancials financials);

  Future<BranchMedia?> media(EntityID branchId);
  Future<void> upsertMedia(BranchMedia media);

  Future<BranchSocialLinks?> socialLinks(EntityID branchId);
  Future<void> upsertSocialLinks(BranchSocialLinks links);

  Future<BranchSafeguarding?> safeguarding(EntityID branchId);
  Future<void> upsertSafeguarding(BranchSafeguarding safe);

  Future<List<BranchMilestone>> milestones(EntityID branchId);
  Future<void> upsertMilestone(BranchMilestone milestone);
}

// ──────────────────────────────────────────────────────────────────────────────
// 21. AthleteGroupRepository
// ──────────────────────────────────────────────────────────────────────────────

abstract class AthleteGroupRepository {
  Future<List<AthleteGroup>> athleteGroups();
  Future<AthleteGroup?> athleteGroup(EntityID id);

  /// Swift: `upsert(_ group:)`.
  Future<void> upsertGroup(AthleteGroup group);
  Future<void> deleteAthleteGroup(EntityID id);
}

// ──────────────────────────────────────────────────────────────────────────────
// Composed facade
// ──────────────────────────────────────────────────────────────────────────────

/// The composed facade injected app-wide. Mirrors the Swift `Repository`
/// protocol-composition pattern (21 sub-protocols). Repository swap is one
/// line in `lib/app/locator.dart`.
abstract class Repository
    implements
        UserRepository,
        BranchRepository,
        AthleteRepository,
        CoachRepository,
        ScheduleRepository,
        AttendanceRepository,
        PerformanceRepository,
        MatchRepository,
        PerformanceEntryRepository,
        GoalRepository,
        TrainingLoadRepository,
        ImprovementPlanRepository,
        PeerBenchmarkRepository,
        GradingRepository,
        TournamentRepository,
        LiveMatchRepository,
        OperationsRepository,
        AuditRepository,
        StorageRepository,
        BranchProfileRepository,
        AthleteGroupRepository {}

/// Optional auth surface — mirrors the Swift `AuthenticatingRepository`
/// protocol (separate from [Repository] because not every backend
/// authenticates). [DemoRepository] implements it as a no-friction demo
/// switch; [SupabaseRepository] backs it with real Supabase Auth. Callers
/// feature-detect via `repo is AuthRepository`.
abstract class AuthRepository {
  Future<void> signInWithEmail({required String email, required String password});
  Future<void> signOut();
}

/// Thrown when account creation or update targets the reserved [AppOwner]
/// email on a non-owner record — the owner account can't be created,
/// impersonated, demoted, or renamed by any other user.
class OwnerEmailReservedException implements Exception {
  const OwnerEmailReservedException();
  @override
  String toString() => 'That email address is reserved.';
}
