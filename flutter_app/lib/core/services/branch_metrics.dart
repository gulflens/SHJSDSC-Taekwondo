import '../models/athlete.dart';
import '../models/branch.dart';
import '../models/coach.dart';
import '../models/schedule.dart';

/// 1:1 port of Core/Services/BranchMetrics.swift.
///
/// Snapshot operational KPIs for a single branch. Every input is supplied by
/// the caller so the service can be unit-tested without touching the repository
/// or clock state.

class BranchOperationalMetrics {
  final int registeredCount;
  final int activeCount;
  final int waitlistCount;
  final double utilisationPct;
  final double retentionPct90d;
  final int newSignups30d;
  final int churn30d;
  final double avgAttendancePct;
  final int competitionTeamCount;
  final int readyToGradeCount;
  final int watchListCount;
  final int restCount;
  final int sessionsPerWeek;
  final int totalCoaches;
  final double coachesWithCurrentSafeguardingPct;

  const BranchOperationalMetrics({
    required this.registeredCount,
    required this.activeCount,
    required this.waitlistCount,
    required this.utilisationPct,
    required this.retentionPct90d,
    required this.newSignups30d,
    required this.churn30d,
    required this.avgAttendancePct,
    required this.competitionTeamCount,
    required this.readyToGradeCount,
    required this.watchListCount,
    required this.restCount,
    required this.sessionsPerWeek,
    required this.totalCoaches,
    required this.coachesWithCurrentSafeguardingPct,
  });

  static const empty = BranchOperationalMetrics(
    registeredCount: 0,
    activeCount: 0,
    waitlistCount: 0,
    utilisationPct: 0,
    retentionPct90d: 0,
    newSignups30d: 0,
    churn30d: 0,
    avgAttendancePct: 0,
    competitionTeamCount: 0,
    readyToGradeCount: 0,
    watchListCount: 0,
    restCount: 0,
    sessionsPerWeek: 0,
    totalCoaches: 0,
    coachesWithCurrentSafeguardingPct: 0,
  );
}

/// Pure compute namespace — every input is supplied by the caller so the
/// service can be unit-tested without touching the repository or clock state.
class BranchMetrics {
  BranchMetrics._();

  static BranchOperationalMetrics compute({
    required Branch branch,
    required List<Athlete> athletes,
    required List<AttendanceRecord> attendance,
    required List<ClassSession> sessions,
    required List<Coach> coaches,
    DateTime? now,
  }) {
    now ??= DateTime.now();
    final day30 = now.subtract(const Duration(days: 30));
    final day90 = now.subtract(const Duration(days: 90));

    final registered = athletes.length;
    final active = athletes.where((a) => a.status != AthleteStatus.rest).length;
    final utilisation = branch.capacity > 0
        ? (registered / branch.capacity).clamp(0.0, 1.0)
        : 0.0;
    final waitlist = (registered - branch.capacity).clamp(0, registered);

    final newSignups30 = athletes
        .where((a) => !a.joinedAt.isBefore(day30))
        .length;

    // Churn proxy: athletes who joined ≥30d ago but are now resting.
    final churn30 = athletes
        .where(
          (a) => a.joinedAt.isBefore(day30) && a.status == AthleteStatus.rest,
        )
        .length;

    final cohort90 = athletes.where((a) => a.joinedAt.isBefore(day90)).toList();
    final cohortStart = cohort90.length;
    final cohortStillActive = cohort90
        .where((a) => a.status != AthleteStatus.rest)
        .length;
    final retention = cohortStart > 0 ? cohortStillActive / cohortStart : 0.0;

    final recentAttendance = attendance
        .where((r) => !r.recordedAt.isBefore(day30))
        .toList();
    final attendanceTotal = recentAttendance.length;
    final attendancePresent = recentAttendance
        .where(
          (r) =>
              r.state == AttendanceState.present ||
              r.state == AttendanceState.late,
        )
        .length;
    final avgAttendance = attendanceTotal > 0
        ? attendancePresent / attendanceTotal
        : 0.0;

    final comp = athletes
        .where((a) => a.status == AthleteStatus.competitionTeam)
        .length;
    final ready = athletes
        .where((a) => a.status == AthleteStatus.readyToGrade)
        .length;
    final watch = athletes.where((a) => a.status == AthleteStatus.watch).length;
    final rest = athletes.where((a) => a.status == AthleteStatus.rest).length;

    // Distinct sessions in a 7-day window centred on [now].
    final weekStart = now.subtract(const Duration(days: 7));
    final sessPerWeek = sessions
        .where(
          (s) => !s.startsAt.isBefore(weekStart) && !s.startsAt.isAfter(now!),
        )
        .length;

    final withSafeguarding = coaches
        .where((c) => !c.safeguardingExpiry.isBefore(now!))
        .length;
    final safeguardingPct = coaches.isEmpty
        ? 0.0
        : withSafeguarding / coaches.length;

    return BranchOperationalMetrics(
      registeredCount: registered,
      activeCount: active,
      waitlistCount: waitlist,
      utilisationPct: utilisation,
      retentionPct90d: retention,
      newSignups30d: newSignups30,
      churn30d: churn30,
      avgAttendancePct: avgAttendance,
      competitionTeamCount: comp,
      readyToGradeCount: ready,
      watchListCount: watch,
      restCount: rest,
      sessionsPerWeek: sessPerWeek,
      totalCoaches: coaches.length,
      coachesWithCurrentSafeguardingPct: safeguardingPct,
    );
  }
}
