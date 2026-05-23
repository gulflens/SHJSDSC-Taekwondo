import '../models/entity_id.dart';
import '../models/improvement_plan.dart';
import '../models/physical_metric.dart';

/// 1:1 port of Core/Services/WeaknessAnalyzer.swift.
///
/// Auto-flag weaknesses by comparing one athlete's latest physical metrics
/// against a peer cohort. The cohort is supplied by the caller — typically
/// athletes in the same age group, optionally same gender — so the engine
/// itself stays a pure function with no repository dependencies.
class WeaknessAnalyzer {
  WeaknessAnalyzer._();

  /// Returns up to [maxWeaknesses] flagged signals where the athlete's
  /// latest captured value sits at or below [cutoffPercentile] (default 25th)
  /// of the cohort distribution.
  ///
  /// Severity bands:
  ///   - high   when percentile ≤ 10
  ///   - medium when 10 < percentile ≤ 20
  ///   - low    otherwise
  static List<Weakness> flag({
    required EntityID athleteId,
    required List<PhysicalMetric> athleteMetrics,
    required List<PhysicalMetric> cohortMetrics,
    double cutoffPercentile = 25,
    int maxWeaknesses = 3,
    required String Function(PhysicalMetricKind) labelFor,
  }) {
    final athleteLatest = athleteMetrics.latestPerKind();

    // Group cohort metrics by athleteId, then take latest per kind.
    final cohortByAthlete = <EntityID, List<PhysicalMetric>>{};
    for (final m in cohortMetrics) {
      cohortByAthlete.putIfAbsent(m.athleteId, () => []).add(m);
    }
    final cohortLatest = cohortByAthlete.map(
      (id, list) => MapEntry(id, list.latestPerKind()),
    );

    // For each kind the athlete has captured, compute the cohort percentile.
    final scored = <({PhysicalMetricKind kind, double percentile})>[];
    for (final entry in athleteLatest) {
      if (entry.kind.isPassFail) continue;
      final kind = entry.kind;

      // Peer values for the same kind (one per peer athlete).
      final peerValues = cohortLatest.entries
          .where((e) => e.key != athleteId)
          .map((e) => e.value.where((m) => m.kind == kind).firstOrNull?.value)
          .whereType<double>()
          .toList();

      if (peerValues.length < 3) continue; // not enough data

      final pct = _percentile(
        value: entry.value,
        peers: peerValues,
        higherIsBetter: kind.higherIsBetter,
      );
      if (pct <= cutoffPercentile) {
        scored.add((kind: kind, percentile: pct));
      }
    }

    scored.sort((a, b) => a.percentile.compareTo(b.percentile));
    return scored.take(maxWeaknesses).map((s) {
      return Weakness(
        kind: s.kind.name,
        label: labelFor(s.kind),
        severity: _severityBand(s.percentile),
        source: WeaknessSource.peer,
      );
    }).toList();
  }

  /// Percentile of [value] against [peers]. When [higherIsBetter] is true
  /// the percentile == fraction of peers worse than the value × 100; when
  /// lower-is-better it's inverted so a low percentile always means "the
  /// athlete sits in the worse end of the distribution".
  static double _percentile({
    required double value,
    required List<double> peers,
    required bool higherIsBetter,
  }) {
    if (peers.isEmpty) return 50;
    final worseCount = peers.fold<int>(0, (acc, peer) {
      if (higherIsBetter) {
        return peer < value ? acc + 1 : acc;
      } else {
        return peer > value ? acc + 1 : acc;
      }
    });
    return worseCount / peers.length * 100;
  }

  static WeaknessSeverity _severityBand(double percentile) {
    if (percentile < 10) return WeaknessSeverity.high;
    if (percentile < 20) return WeaknessSeverity.medium;
    return WeaknessSeverity.low;
  }
}
