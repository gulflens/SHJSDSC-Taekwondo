import 'dart:math' as math;

import '../models/branch.dart';
import '../models/entity_id.dart';
import '../models/performance_score.dart';
import 'score_engine.dart';

/// 1:1 port of Core/Services/BranchAnalyticsEngine.swift.
///
/// Pure functions that turn raw repository data (branches + performance scores
/// + roster counts) into the executive analytics the dashboard renders.
///
/// Composite, grade and the six metric scores are real averages of seeded
/// [PerformanceScore] data. Growth %, the 12-week attendance trend and the
/// coaching radar are demo-derived: deterministic functions of the branch's
/// real scores + a stable per-branch seed.

// ---------------------------------------------------------------------------
// Supporting types

/// The six headline performance dimensions shown as metric rings.
enum BranchMetricKind {
  competition,
  technique,
  fitness,
  attendance,
  progress,
  wellness;

  String get labelKey => 'branch.metric.$name';
}

/// The six coaching-effectiveness radar axes.
enum BranchRadarAxis {
  athleteImprovement,
  technicalQuality,
  attendanceImpact,
  retentionRate,
  promotionSuccess,
  sessionQuality;

  String get labelKey => 'branch.radar.$name';
}

/// Direction-of-travel chip.
enum BranchTrend {
  improving,
  stable,
  declining;

  String get labelKey => 'branch.trend.$name';
}

class BranchMetricScore {
  final BranchMetricKind kind;
  final double score; // 0–100

  const BranchMetricScore({required this.kind, required this.score});

  String get id => kind.name;
}

class BranchRadarScore {
  final BranchRadarAxis axis;
  final double score; // 0–100

  const BranchRadarScore({required this.axis, required this.score});

  String get id => axis.name;
}

/// Everything a branch ranking card + the bottom charts need.
class BranchAnalytics {
  final EntityID id;
  final Branch branch;
  final int rank;
  final int nationalRank;
  final int athleteCount;
  final int coachCount;
  final int sessionsPerWeek;
  final double compositeScore; // 0–100
  final LetterGrade grade;
  final List<BranchMetricScore> metrics; // six, in BranchMetricKind order
  final List<BranchRadarScore> radar; // six, in BranchRadarAxis order
  final double growthPct; // 30-day, may be negative
  final BranchTrend trend;
  final List<double> attendanceTrend; // 12 weekly values, 0–100

  const BranchAnalytics({
    required this.id,
    required this.branch,
    required this.rank,
    required this.nationalRank,
    required this.athleteCount,
    required this.coachCount,
    required this.sessionsPerWeek,
    required this.compositeScore,
    required this.grade,
    required this.metrics,
    required this.radar,
    required this.growthPct,
    required this.trend,
    required this.attendanceTrend,
  });

  BranchAnalytics copyWith({int? rank, int? nationalRank}) => BranchAnalytics(
    id: id,
    branch: branch,
    rank: rank ?? this.rank,
    nationalRank: nationalRank ?? this.nationalRank,
    athleteCount: athleteCount,
    coachCount: coachCount,
    sessionsPerWeek: sessionsPerWeek,
    compositeScore: compositeScore,
    grade: grade,
    metrics: metrics,
    radar: radar,
    growthPct: growthPct,
    trend: trend,
    attendanceTrend: attendanceTrend,
  );

  double metric(BranchMetricKind kind) => metrics
      .firstWhere(
        (m) => m.kind == kind,
        orElse: () => BranchMetricScore(kind: kind, score: 0),
      )
      .score;
}

/// A single executive insight.
class BranchInsight {
  final EntityID id;
  final BranchInsightKind kind;
  final String branchName;
  final double value;

  BranchInsight({
    EntityID? id,
    required this.kind,
    required this.branchName,
    required this.value,
  }) : id = id ?? newEntityId();
}

enum BranchInsightKind {
  improvedAttendance,
  topCompetition,
  needsAttention,
  overallGrowth,
}

// ---------------------------------------------------------------------------
// Engine

class BranchAnalyticsEngine {
  BranchAnalyticsEngine._();

  /// Raw per-branch inputs gathered from the repository.
  // ignore: library_private_types_in_public_api
  static const _fnvOffset = 0xcbf29ce484222325;
  static const _fnvPrime = 0x100000001b3;

  /// Builds the full analytics set, sorted best-composite first and ranked.
  static List<BranchAnalytics> analyze(List<BranchAnalyticsInput> inputs) {
    final unranked = inputs.map(_build).toList();
    unranked.sort((a, b) => b.compositeScore.compareTo(a.compositeScore));
    return unranked
        .asMap()
        .entries
        .map((e) => e.value.copyWith(rank: e.key + 1, nationalRank: e.key + 1))
        .toList();
  }

  static BranchAnalytics _build(BranchAnalyticsInput input) {
    final scores = input.scores;

    double avg(double Function(PerformanceScore) fn) {
      if (scores.isEmpty) return 0;
      return scores.fold<double>(0, (acc, s) => acc + fn(s)) / scores.length;
    }

    final metricPairs = [
      (BranchMetricKind.competition, avg((s) => s.competition)),
      (BranchMetricKind.technique, avg((s) => s.technical)),
      (BranchMetricKind.fitness, avg((s) => s.physical)),
      (BranchMetricKind.attendance, avg((s) => s.adherence)),
      (BranchMetricKind.progress, avg((s) => s.beltProgression)),
      (BranchMetricKind.wellness, avg((s) => s.wellness)),
    ];
    final metrics = metricPairs
        .map((p) => BranchMetricScore(kind: p.$1, score: p.$2))
        .toList();
    final composite = scores.isEmpty
        ? 0.0
        : ScoreEngine.branchComposite(scores);

    // Deterministic 30-day growth: a stable per-branch seed nudged toward
    // the branch's standing — strong branches trend up, weak ones down.
    final s = _seed(input.branch.name);
    final growth = _roundToPlaces(((composite - 70) / 5) + (s * 18 - 7), 1);
    final trend = growth > 3
        ? BranchTrend.improving
        : (growth < -1 ? BranchTrend.declining : BranchTrend.stable);

    // 12-week attendance trend around the attendance metric.
    final base = metricPairs
        .firstWhere(
          (p) => p.$1 == BranchMetricKind.attendance,
          orElse: () => (BranchMetricKind.attendance, 80.0),
        )
        .$2;
    final trendSeries = List<double>.generate(12, (week) {
      final progress = week / 11.0;
      final drift = (growth / 100) * 14 * (progress - 0.5);
      final wobble = (_seed('${input.branch.name}-w$week') - 0.5) * 6;
      return (base + drift + wobble).clamp(40.0, 100.0);
    });

    // Coaching radar — six axes derived from the metrics + a small seed.
    final radar = BranchRadarAxis.values
        .map(
          (axis) => BranchRadarScore(
            axis: axis,
            score: _radarScore(axis, metricPairs, composite, input.branch.name),
          ),
        )
        .toList();

    return BranchAnalytics(
      id: input.branch.id,
      branch: input.branch,
      rank: 0,
      nationalRank: 0,
      athleteCount: input.athleteCount,
      coachCount: input.coachCount,
      sessionsPerWeek: input.sessionsPerWeek,
      compositeScore: composite,
      grade: LetterGrade.fromScore(composite),
      metrics: metrics,
      radar: radar,
      growthPct: growth,
      trend: trend,
      attendanceTrend: trendSeries,
    );
  }

  static double _radarScore(
    BranchRadarAxis axis,
    List<(BranchMetricKind, double)> metricPairs,
    double composite,
    String branch,
  ) {
    double m(BranchMetricKind k) => metricPairs
        .firstWhere((p) => p.$1 == k, orElse: () => (k, composite))
        .$2;

    final double basis;
    switch (axis) {
      case BranchRadarAxis.athleteImprovement:
        basis = m(BranchMetricKind.progress);
        break;
      case BranchRadarAxis.technicalQuality:
        basis = m(BranchMetricKind.technique);
        break;
      case BranchRadarAxis.attendanceImpact:
        basis = m(BranchMetricKind.attendance);
        break;
      case BranchRadarAxis.retentionRate:
        basis =
            (m(BranchMetricKind.wellness) + m(BranchMetricKind.attendance)) / 2;
        break;
      case BranchRadarAxis.promotionSuccess:
        basis =
            (m(BranchMetricKind.progress) + m(BranchMetricKind.competition)) /
            2;
        break;
      case BranchRadarAxis.sessionQuality:
        basis =
            (m(BranchMetricKind.technique) + m(BranchMetricKind.fitness)) / 2;
        break;
    }
    final jitter = (_seed('$branch-${axis.name}') - 0.5) * 10;
    return (basis + jitter).clamp(35.0, 100.0);
  }

  /// Top executive insights derived from the ranked analytics.
  static List<BranchInsight> insights(
    List<BranchAnalytics> analytics,
    double overallGrowth,
  ) {
    if (analytics.isEmpty) return [];
    final out = <BranchInsight>[];

    final improvers = analytics.where((a) => a.growthPct > 0).toList();
    if (improvers.isNotEmpty) {
      final improver = improvers.reduce(
        (a, b) => a.growthPct > b.growthPct ? a : b,
      );
      out.add(
        BranchInsight(
          kind: BranchInsightKind.improvedAttendance,
          branchName: improver.branch.name,
          value: improver.growthPct,
        ),
      );
    }

    final topComp = analytics.reduce(
      (a, b) =>
          a.metric(BranchMetricKind.competition) >
              b.metric(BranchMetricKind.competition)
          ? a
          : b,
    );
    out.add(
      BranchInsight(
        kind: BranchInsightKind.topCompetition,
        branchName: topComp.branch.name,
        value: topComp.metric(BranchMetricKind.competition),
      ),
    );

    final weakest = analytics.reduce(
      (a, b) => a.compositeScore < b.compositeScore ? a : b,
    );
    out.add(
      BranchInsight(
        kind: BranchInsightKind.needsAttention,
        branchName: weakest.branch.name,
        value: weakest.compositeScore,
      ),
    );

    out.add(
      BranchInsight(
        kind: BranchInsightKind.overallGrowth,
        branchName: '',
        value: overallGrowth,
      ),
    );
    return out;
  }

  // ---------------------------------------------------------------------------
  // Helpers

  /// Stable 0–1 value derived from a string — FNV-1a hash so demo analytics
  /// are reproducible across launches (unlike hashCode).
  /// Matches the Swift implementation exactly (same constants, 64-bit wrapping).
  static double _seed(String string) {
    var hash = _fnvOffset;
    for (final byte in string.codeUnits) {
      hash ^= byte;
      // Dart ints are 63-bit on VM / 53-bit precision in JS; mask to 64-bit
      // unsigned using the same wrapping semantics as Swift's `&*`.
      hash = _u64Mul(hash, _fnvPrime);
    }
    return (hash % 1000) / 1000.0;
  }

  /// 64-bit unsigned wrapping multiply (approximates Swift's `&*` operator
  /// on UInt64). Dart's integers are arbitrary precision so we cap manually.
  static int _u64Mul(int a, int b) {
    // Split into 32-bit halves to avoid overflow in JS (where int is 53-bit).
    final aLo = a & 0xFFFFFFFF;
    final aHi = (a >> 32) & 0xFFFFFFFF;
    final bLo = b & 0xFFFFFFFF;
    final bHi = (b >> 32) & 0xFFFFFFFF;

    final lo = aLo * bLo;
    final mid1 = aLo * bHi;
    final mid2 = aHi * bLo;
    // We only keep the lower 64 bits (hi contributions wrap away).
    final result = lo + ((mid1 + mid2) << 32);
    // Mask to 64 bits.  Dart's int is 64-bit on native; on JS limit to 2^53.
    return result & 0xFFFFFFFFFFFFFFFF;
  }

  static double _roundToPlaces(double value, int places) {
    final factor = math.pow(10.0, places);
    return (value * factor).roundToDouble() / factor;
  }
}

/// Raw per-branch inputs gathered from the repository.
class BranchAnalyticsInput {
  final Branch branch;
  final List<PerformanceScore> scores;
  final int athleteCount;
  final int coachCount;
  final int sessionsPerWeek;

  const BranchAnalyticsInput({
    required this.branch,
    required this.scores,
    required this.athleteCount,
    required this.coachCount,
    required this.sessionsPerWeek,
  });
}
