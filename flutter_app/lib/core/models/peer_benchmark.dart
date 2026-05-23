import 'athlete.dart';
import 'belt.dart';
import 'entity_id.dart';
import 'tournament.dart';

/// Port of Core/Models/PeerBenchmark.swift.
///
/// Materialised cohort statistics for a single metric. One row per
/// (cohort definition, metric) tuple. Any cohort dimension left null means
/// "across all values for that dimension".
class PeerBenchmark {
  final EntityID id;
  final BeltRank? beltRank;
  final AgeGroup? ageDivision;
  final WeightCategory? weightClass;

  /// Canonical metric identifier. Typically a [PhysicalMetricKind] raw value.
  final String metricKey;
  final double mean;
  final double standardDeviation;
  final int sampleSize;
  final DateTime computedAt;

  PeerBenchmark({
    EntityID? id,
    this.beltRank,
    this.ageDivision,
    this.weightClass,
    required this.metricKey,
    required this.mean,
    required this.standardDeviation,
    required this.sampleSize,
    DateTime? computedAt,
  }) : id = id ?? newEntityId(),
       computedAt = computedAt ?? DateTime.now();

  /// True when this benchmark applies to the given athlete (each cohort
  /// dimension either matches or is unconstrained on the benchmark).
  ///
  /// NOTE: [Athlete.weightClass] (optional override stored on the athlete
  /// record) is deferred — until it lands, [WeightCategory.suggested] is used
  /// as a proxy so benchmark matching works end-to-end today.
  bool appliesTo(Athlete athlete) {
    if (beltRank != null && beltRank != athlete.currentBelt.rank) return false;
    if (ageDivision != null && ageDivision != athlete.ageGroup) return false;
    if (weightClass != null) {
      final athleteWeightClass = WeightCategory.suggested(athlete);
      if (athleteWeightClass != weightClass) return false;
    }
    return true;
  }

  /// z-score = (value − mean) / σ. Returns null when σ is zero.
  double? zScore(double value) {
    if (standardDeviation <= 0) return null;
    return (value - mean) / standardDeviation;
  }

  /// Number of cohort dimensions explicitly set (used for most-specific match).
  int get _specificity {
    var n = 0;
    if (beltRank != null) n++;
    if (ageDivision != null) n++;
    if (weightClass != null) n++;
    return n;
  }

  factory PeerBenchmark.fromJson(Map<String, dynamic> json) => PeerBenchmark(
    id: json['id'] as String,
    beltRank: json['beltRank'] != null
        ? _beltRankFromJson(json['beltRank'] as Map<String, dynamic>)
        : null,
    ageDivision: json['ageDivision'] != null
        ? AgeGroup.fromJson(json['ageDivision'] as String)
        : null,
    weightClass: json['weightClass'] != null
        ? WeightCategory.fromJson(json['weightClass'] as String)
        : null,
    metricKey: json['metricKey'] as String,
    mean: (json['mean'] as num).toDouble(),
    standardDeviation: (json['standardDeviation'] as num).toDouble(),
    sampleSize: json['sampleSize'] as int,
    computedAt: DateTime.parse(json['computedAt'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'beltRank': beltRank != null
        ? {'kind': beltRank!.kind.name, 'number': beltRank!.number}
        : null,
    'ageDivision': ageDivision?.name,
    'weightClass': weightClass?.name,
    'metricKey': metricKey,
    'mean': mean,
    'standardDeviation': standardDeviation,
    'sampleSize': sampleSize,
    'computedAt': computedAt.toIso8601String(),
  };
}

BeltRank _beltRankFromJson(Map<String, dynamic> json) => BeltRank(
  kind: BeltKind.fromJson(json['kind'] as String),
  number: json['number'] as int,
);

extension PeerBenchmarkListExt on List<PeerBenchmark> {
  /// Best-fit benchmark for the athlete + metric — prefer the most specific
  /// cohort match (more dimensions set), fall back to progressively broader
  /// cohorts. Returns null when no benchmark exists for the metric at all.
  PeerBenchmark? best(Athlete athlete, String metricKey) {
    final candidates = where(
      (b) => b.metricKey == metricKey && b.appliesTo(athlete),
    ).toList();
    if (candidates.isEmpty) return null;
    candidates.sort((a, b) => b._specificity.compareTo(a._specificity));
    return candidates.first;
  }
}
