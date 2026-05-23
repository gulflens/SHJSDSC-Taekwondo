import 'dart:math' as math;

import '../models/athlete.dart';
import '../models/belt.dart';
import '../models/entity_id.dart';
import '../models/peer_benchmark.dart';
import '../models/physical_metric.dart';
import '../models/tournament.dart';

/// 1:1 port of Core/Services/BenchmarkComputer.swift.
///
/// Compute peer benchmarks (mean + σ + n) across cohort slices. Pure
/// function — caller is responsible for fetching [athletes] and the matching
/// physical metrics. Output is a flat array of [PeerBenchmark] rows that the
/// caller upserts into the repository, replacing any existing rows for the
/// same (cohort, metric) tuples.
class BenchmarkComputer {
  BenchmarkComputer._();

  /// Slices to compute by default. Each slice produces one benchmark per
  /// metric kind that has at least [defaultMinSampleSize] data points.
  static const List<BenchmarkSlice> defaultSlices = [
    BenchmarkSlice.ageDivision,
    BenchmarkSlice.beltRank,
    BenchmarkSlice.ageDivisionAndBelt,
  ];

  static const int defaultMinSampleSize = 5;

  /// Compute benchmarks across the configured slices for every
  /// [PhysicalMetricKind] that has enough samples.
  ///
  /// - [athletes]: cohort source — every athlete contributes their most
  ///   recent value per metric.
  /// - [metrics]: all physical metrics for the athletes (any window —
  ///   latest-per-(athlete, kind) is selected internally).
  /// - [slices]: cohort slices to materialise.
  /// - [minSampleSize]: skip cohorts with fewer than this many athletes.
  static List<PeerBenchmark> compute({
    required List<Athlete> athletes,
    required List<PhysicalMetric> metrics,
    List<BenchmarkSlice> slices = const [
      BenchmarkSlice.ageDivision,
      BenchmarkSlice.beltRank,
      BenchmarkSlice.ageDivisionAndBelt,
    ],
    int minSampleSize = defaultMinSampleSize,
    DateTime? now,
  }) {
    now ??= DateTime.now();

    // Latest value per (athleteId, kind) — pass-fail kinds excluded.
    final metricsByAthlete = <EntityID, List<PhysicalMetric>>{};
    for (final m in metrics) {
      metricsByAthlete.putIfAbsent(m.athleteId, () => []).add(m);
    }

    final latestByAthleteAndKind =
        <EntityID, Map<PhysicalMetricKind, double>>{};
    for (final entry in metricsByAthlete.entries) {
      final athleteId = entry.key;
      final ms = entry.value;
      final byKind = <PhysicalMetricKind, double>{};
      for (final m in ms.latestPerKind()) {
        if (!m.kind.isPassFail && m.leg == null) {
          byKind[m.kind] = m.value;
        }
      }
      latestByAthleteAndKind[athleteId] = byKind;
    }

    final out = <PeerBenchmark>[];
    for (final slice in slices) {
      final grouped = _groupAthletes(athletes, slice);
      for (final entry in grouped.entries) {
        final cohortKey = entry.key;
        final group = entry.value;
        if (group.length < minSampleSize) continue;
        for (final kind in PhysicalMetricKind.values) {
          if (kind.isPassFail) continue;
          final values = group
              .map((a) => latestByAthleteAndKind[a.id]?[kind])
              .whereType<double>()
              .toList();
          if (values.length < minSampleSize) continue;
          final s = _stats(values);
          out.add(
            PeerBenchmark(
              beltRank: cohortKey.beltRank,
              ageDivision: cohortKey.ageDivision,
              weightClass: cohortKey.weightClass,
              metricKey: kind.name,
              mean: s.mean,
              standardDeviation: s.stdDev,
              sampleSize: values.length,
              computedAt: now,
            ),
          );
        }
      }
    }
    return out;
  }

  // ---------------------------------------------------------------------------
  // Helpers

  static Map<_CohortKey, List<Athlete>> _groupAthletes(
    List<Athlete> athletes,
    BenchmarkSlice slice,
  ) {
    final out = <_CohortKey, List<Athlete>>{};
    for (final a in athletes) {
      final _CohortKey key;
      switch (slice) {
        case BenchmarkSlice.ageDivision:
          key = _CohortKey(ageDivision: a.ageGroup);
          break;
        case BenchmarkSlice.beltRank:
          key = _CohortKey(beltRank: a.currentBelt.rank);
          break;
        case BenchmarkSlice.ageDivisionAndBelt:
          key = _CohortKey(
            beltRank: a.currentBelt.rank,
            ageDivision: a.ageGroup,
          );
          break;
        case BenchmarkSlice.weightClass:
          final wc = WeightCategory.suggested(a);
          if (wc == null) continue;
          key = _CohortKey(weightClass: wc);
          break;
      }
      out.putIfAbsent(key, () => []).add(a);
    }
    return out;
  }

  static ({double mean, double stdDev}) _stats(List<double> values) {
    if (values.isEmpty) return (mean: 0, stdDev: 0);
    final n = values.length.toDouble();
    final mean = values.reduce((a, b) => a + b) / n;
    final variance =
        values.fold<double>(0, (acc, v) => acc + math.pow(v - mean, 2)) / n;
    return (mean: mean, stdDev: math.sqrt(variance));
  }
}

enum BenchmarkSlice { ageDivision, beltRank, ageDivisionAndBelt, weightClass }

/// Private cohort grouping key. Implements value equality so it can be
/// used as a Map key.
class _CohortKey {
  final BeltRank? beltRank;
  final AgeGroup? ageDivision;
  final WeightCategory? weightClass;

  const _CohortKey({this.beltRank, this.ageDivision, this.weightClass});

  @override
  bool operator ==(Object other) =>
      other is _CohortKey &&
      beltRank?.kind == other.beltRank?.kind &&
      beltRank?.number == other.beltRank?.number &&
      ageDivision == other.ageDivision &&
      weightClass == other.weightClass;

  @override
  int get hashCode =>
      Object.hash(beltRank?.kind, beltRank?.number, ageDivision, weightClass);
}
