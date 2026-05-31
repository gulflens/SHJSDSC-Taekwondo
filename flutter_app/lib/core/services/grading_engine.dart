import '../models/athlete.dart';
import '../models/belt.dart';
import '../models/grading.dart';
import '../models/physical_metric.dart';
import '../models/schedule.dart';
import '../models/technical_skill.dart';

/// 1:1 port of Core/Services/GradingEngine.swift.
///
/// Kukkiwon grading rules: eligibility check + outcome decision.
class GradingEngine {
  GradingEngine._();

  /// Kukkiwon ladder. Past 9th Dan returns the same belt.
  static Belt nextBelt(Belt current) {
    final now = DateTime.now();
    Belt make(BeltColor c, BeltKind k, int n) =>
        Belt(color: c, kind: k, number: n, awardedAt: now);

    final color = current.color;
    final kind = current.kind;
    final number = current.number;

    if (color == BeltColor.white && kind == BeltKind.gup && number == 10) {
      return make(BeltColor.white, BeltKind.gup, 9);
    }
    if (color == BeltColor.white && kind == BeltKind.gup && number == 9) {
      return make(BeltColor.yellow, BeltKind.gup, 8);
    }
    if (color == BeltColor.yellow && kind == BeltKind.gup && number == 8) {
      return make(BeltColor.yellow, BeltKind.gup, 7);
    }
    if (color == BeltColor.yellow && kind == BeltKind.gup && number == 7) {
      return make(BeltColor.green, BeltKind.gup, 6);
    }
    if (color == BeltColor.green && kind == BeltKind.gup && number == 6) {
      return make(BeltColor.green, BeltKind.gup, 5);
    }
    if (color == BeltColor.green && kind == BeltKind.gup && number == 5) {
      return make(BeltColor.blue, BeltKind.gup, 4);
    }
    if (color == BeltColor.blue && kind == BeltKind.gup && number == 4) {
      return make(BeltColor.blue, BeltKind.gup, 3);
    }
    if (color == BeltColor.blue && kind == BeltKind.gup && number == 3) {
      return make(BeltColor.red, BeltKind.gup, 2);
    }
    if (color == BeltColor.red && kind == BeltKind.gup && number == 2) {
      return make(BeltColor.red, BeltKind.gup, 1);
    }
    if (color == BeltColor.red && kind == BeltKind.gup && number == 1) {
      return make(BeltColor.black, BeltKind.poom, 1);
    }
    if (color == BeltColor.black && kind == BeltKind.poom && number < 4) {
      return make(BeltColor.black, BeltKind.poom, number + 1);
    }
    if (color == BeltColor.black && kind == BeltKind.poom) {
      return make(BeltColor.black, BeltKind.dan, 1);
    }
    if (color == BeltColor.black && kind == BeltKind.dan && number < 9) {
      return make(BeltColor.black, BeltKind.dan, number + 1);
    }
    return current;
  }

  static GradingEligibility evaluateEligibility({
    required Athlete athlete,
    required List<AttendanceRecord> attendance,
    required List<TechnicalSkill> technical,
    required List<PhysicalMetric> physical,
  }) {
    final target = nextBelt(athlete.currentBelt);
    final now = DateTime.now();
    final monthsAtCurrent =
        (now.year - athlete.currentBelt.awardedAt.year) * 12 +
        (now.month - athlete.currentBelt.awardedAt.month);

    final last90 = now.subtract(const Duration(days: 90));
    final recent = attendance
        .where((r) => !r.recordedAt.isBefore(last90))
        .toList();
    final attended = recent
        .where(
          (r) =>
              r.state == AttendanceState.present ||
              r.state == AttendanceState.late,
        )
        .length;
    final attendancePct = recent.isEmpty ? 0.0 : attended / recent.length;

    final technicalAvg = technical.latestAverageScore;
    final physicalComposite = physicalCompositeScore(physical);

    final requiredMonths = athlete.currentBelt.kind == BeltKind.gup ? 3 : 6;
    final blocking = <String>[];
    if (monthsAtCurrent < requiredMonths) {
      blocking.add('grading.blocking.months_at_rank');
    }
    if (attendancePct < 0.75) {
      blocking.add('grading.blocking.attendance');
    }
    if (technicalAvg < 6.5) {
      blocking.add('grading.blocking.technical');
    }
    if (physicalComposite < 60) {
      blocking.add('grading.blocking.physical');
    }

    return GradingEligibility(
      athleteId: athlete.id,
      currentBelt: athlete.currentBelt,
      targetBelt: target,
      monthsAtCurrent: monthsAtCurrent,
      attendancePct: attendancePct,
      latestTechnicalAvg: technicalAvg,
      latestPhysicalComposite: physicalComposite,
      isEligible: blocking.isEmpty,
      blockingReasons: blocking,
    );
  }

  /// 0..100 composite from the latest measurement of each captured kind.
  /// Each metric self-normalises against its [inputRange]. Categories that
  /// have any captured kind contribute their average; missing categories are
  /// not penalised so an athlete with only flexibility data still scores.
  static double physicalCompositeScore(List<PhysicalMetric> metrics) {
    if (metrics.isEmpty) return 0;
    final latest = metrics.latestPerKind();
    final byCategory = <PhysicalCategory, List<PhysicalMetric>>{};
    for (final m in latest) {
      byCategory.putIfAbsent(m.kind.category, () => []).add(m);
    }
    final categoryScores = byCategory.values.map((entries) {
      final normalised = entries
          .map((m) => m.kind.normalized(m.value))
          .toList();
      return normalised.reduce((a, b) => a + b) / normalised.length;
    }).toList();
    if (categoryScores.isEmpty) return 0;
    return (categoryScores.reduce((a, b) => a + b) / categoryScores.length) *
        100;
  }

  static GradingDecision decideOutcome(GradingScore score) {
    final total = score.total;
    if (total >= 70) return GradingDecision.pass;
    if (total >= 60) return GradingDecision.retry;
    return GradingDecision.fail;
  }
}
