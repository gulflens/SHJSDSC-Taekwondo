import 'entity_id.dart';

/// Port of Core/Models/PhysicalMetric.swift.

enum BodySide {
  left,
  right;

  String get labelKey => 'body_side.$name';

  static BodySide fromJson(String raw) => BodySide.values.firstWhere(
    (e) => e.name == raw,
    orElse: () => BodySide.left,
  );
}

enum PhysicalCategory {
  flexibility,
  power,
  speed,
  endurance,
  strength,
  bodyComposition;

  String get labelKey => 'physical_category.$name';

  String get systemIcon => switch (this) {
    PhysicalCategory.flexibility => 'figure.flexibility',
    PhysicalCategory.power => 'bolt.fill',
    PhysicalCategory.speed => 'hare.fill',
    PhysicalCategory.endurance => 'lungs.fill',
    PhysicalCategory.strength => 'dumbbell.fill',
    PhysicalCategory.bodyComposition => 'scalemass.fill',
  };
}

enum TestFrequency {
  weekly,
  monthly,
  quarterly;

  String get labelKey => 'test_frequency.$name';

  /// Days between recommended captures.
  int get dayInterval => switch (this) {
    TestFrequency.weekly => 7,
    TestFrequency.monthly => 30,
    TestFrequency.quarterly => 90,
  };

  /// Past this many days beyond [dayInterval], the test is considered overdue.
  int get graceDays => switch (this) {
    TestFrequency.weekly => 3,
    TestFrequency.monthly => 7,
    TestFrequency.quarterly => 14,
  };
}

enum PhysicalMetricKind {
  // Flexibility
  frontSplitCm,
  sideSplitCm,
  kickHeightHead,
  kickHeightChest,
  legRaiseAngle,

  // Power
  roundhouseForceBack,
  roundhouseForceFront,
  sideKickForce,
  verticalJumpCm,
  broadJumpCm,

  // Speed
  roundhouseKicks10s,
  backKicks10s,
  sprint20mSec,
  reactionMs,

  // Endurance
  yoyoLevel,
  twoMinKickTotal,
  plankSec,

  // Strength
  singleLegSquatReps,
  hollowBodyHoldSec,
  pushUps60s,

  // Body composition
  bodyWeightKg,
  bodyFatPct,
  restingHr;

  String get labelKey => 'metric.$name';

  PhysicalCategory get category => switch (this) {
    PhysicalMetricKind.frontSplitCm ||
    PhysicalMetricKind.sideSplitCm ||
    PhysicalMetricKind.kickHeightHead ||
    PhysicalMetricKind.kickHeightChest ||
    PhysicalMetricKind.legRaiseAngle => PhysicalCategory.flexibility,
    PhysicalMetricKind.roundhouseForceBack ||
    PhysicalMetricKind.roundhouseForceFront ||
    PhysicalMetricKind.sideKickForce ||
    PhysicalMetricKind.verticalJumpCm ||
    PhysicalMetricKind.broadJumpCm => PhysicalCategory.power,
    PhysicalMetricKind.roundhouseKicks10s ||
    PhysicalMetricKind.backKicks10s ||
    PhysicalMetricKind.sprint20mSec ||
    PhysicalMetricKind.reactionMs => PhysicalCategory.speed,
    PhysicalMetricKind.yoyoLevel ||
    PhysicalMetricKind.twoMinKickTotal ||
    PhysicalMetricKind.plankSec => PhysicalCategory.endurance,
    PhysicalMetricKind.singleLegSquatReps ||
    PhysicalMetricKind.hollowBodyHoldSec ||
    PhysicalMetricKind.pushUps60s => PhysicalCategory.strength,
    PhysicalMetricKind.bodyWeightKg ||
    PhysicalMetricKind.bodyFatPct ||
    PhysicalMetricKind.restingHr => PhysicalCategory.bodyComposition,
  };

  TestFrequency get frequency => switch (this) {
    PhysicalMetricKind.frontSplitCm ||
    PhysicalMetricKind.sideSplitCm ||
    PhysicalMetricKind.kickHeightHead ||
    PhysicalMetricKind.kickHeightChest => TestFrequency.monthly,
    PhysicalMetricKind.legRaiseAngle => TestFrequency.quarterly,
    PhysicalMetricKind.roundhouseForceBack ||
    PhysicalMetricKind.roundhouseForceFront ||
    PhysicalMetricKind.sideKickForce => TestFrequency.quarterly,
    PhysicalMetricKind.verticalJumpCm ||
    PhysicalMetricKind.broadJumpCm => TestFrequency.quarterly,
    PhysicalMetricKind.roundhouseKicks10s ||
    PhysicalMetricKind.backKicks10s => TestFrequency.monthly,
    PhysicalMetricKind.sprint20mSec ||
    PhysicalMetricKind.reactionMs => TestFrequency.quarterly,
    PhysicalMetricKind.yoyoLevel => TestFrequency.quarterly,
    PhysicalMetricKind.twoMinKickTotal ||
    PhysicalMetricKind.plankSec => TestFrequency.monthly,
    PhysicalMetricKind.singleLegSquatReps ||
    PhysicalMetricKind.hollowBodyHoldSec ||
    PhysicalMetricKind.pushUps60s => TestFrequency.quarterly,
    PhysicalMetricKind.bodyWeightKg ||
    PhysicalMetricKind.restingHr => TestFrequency.weekly,
    PhysicalMetricKind.bodyFatPct => TestFrequency.monthly,
  };

  /// Display unit; empty string for pass/fail.
  String get unit => switch (this) {
    PhysicalMetricKind.frontSplitCm ||
    PhysicalMetricKind.sideSplitCm ||
    PhysicalMetricKind.verticalJumpCm ||
    PhysicalMetricKind.broadJumpCm => 'cm',
    PhysicalMetricKind.kickHeightHead ||
    PhysicalMetricKind.kickHeightChest => '',
    PhysicalMetricKind.legRaiseAngle => '°',
    PhysicalMetricKind.roundhouseForceBack ||
    PhysicalMetricKind.roundhouseForceFront ||
    PhysicalMetricKind.sideKickForce => 'kg',
    PhysicalMetricKind.roundhouseKicks10s ||
    PhysicalMetricKind.backKicks10s ||
    PhysicalMetricKind.twoMinKickTotal => 'kicks',
    PhysicalMetricKind.sprint20mSec ||
    PhysicalMetricKind.plankSec ||
    PhysicalMetricKind.hollowBodyHoldSec => 's',
    PhysicalMetricKind.reactionMs => 'ms',
    PhysicalMetricKind.yoyoLevel => 'lvl',
    PhysicalMetricKind.singleLegSquatReps ||
    PhysicalMetricKind.pushUps60s => 'reps',
    PhysicalMetricKind.bodyWeightKg => 'kg',
    PhysicalMetricKind.bodyFatPct => '%',
    PhysicalMetricKind.restingHr => 'bpm',
  };

  bool get isPassFail => switch (this) {
    PhysicalMetricKind.kickHeightHead ||
    PhysicalMetricKind.kickHeightChest => true,
    _ => false,
  };

  /// Recorded once per leg (left + right are separate rows).
  bool get isUnilateral => switch (this) {
    PhysicalMetricKind.singleLegSquatReps => true,
    _ => false,
  };

  /// Stepper/slider hints as (lower, upper, step).
  (double lower, double upper, double step) get inputRange => switch (this) {
    PhysicalMetricKind.frontSplitCm ||
    PhysicalMetricKind.sideSplitCm => (0, 60, 0.5),
    PhysicalMetricKind.kickHeightHead ||
    PhysicalMetricKind.kickHeightChest => (0, 1, 1),
    PhysicalMetricKind.legRaiseAngle => (0, 180, 1),
    PhysicalMetricKind.roundhouseForceBack ||
    PhysicalMetricKind.roundhouseForceFront ||
    PhysicalMetricKind.sideKickForce => (0, 600, 1),
    PhysicalMetricKind.verticalJumpCm => (0, 80, 1),
    PhysicalMetricKind.broadJumpCm => (0, 350, 1),
    PhysicalMetricKind.roundhouseKicks10s ||
    PhysicalMetricKind.backKicks10s => (0, 60, 1),
    PhysicalMetricKind.sprint20mSec => (2.0, 6.0, 0.01),
    PhysicalMetricKind.reactionMs => (100, 500, 1),
    PhysicalMetricKind.yoyoLevel => (1, 21, 1),
    PhysicalMetricKind.twoMinKickTotal => (0, 300, 1),
    PhysicalMetricKind.plankSec ||
    PhysicalMetricKind.hollowBodyHoldSec => (0, 300, 1),
    PhysicalMetricKind.singleLegSquatReps ||
    PhysicalMetricKind.pushUps60s => (0, 100, 1),
    PhysicalMetricKind.bodyWeightKg => (15, 140, 0.1),
    PhysicalMetricKind.bodyFatPct => (3, 50, 0.1),
    PhysicalMetricKind.restingHr => (30, 120, 1),
  };

  /// True if a higher raw number means a better result.
  bool get higherIsBetter => switch (this) {
    PhysicalMetricKind.sprint20mSec ||
    PhysicalMetricKind.reactionMs ||
    PhysicalMetricKind.frontSplitCm ||
    PhysicalMetricKind.sideSplitCm ||
    PhysicalMetricKind.bodyFatPct ||
    PhysicalMetricKind.restingHr => false,
    _ => true,
  };

  /// 0…1 normalisation against the input range.
  double normalized(double value) {
    final r = inputRange; // positional record: (lower $1, upper $2, step $3)
    if (r.$2 <= r.$1) return 0;
    final raw = (value - r.$1) / (r.$2 - r.$1);
    final clamped = raw.clamp(0.0, 1.0);
    return higherIsBetter ? clamped : 1 - clamped;
  }

  static PhysicalMetricKind fromJson(String raw) =>
      PhysicalMetricKind.values.firstWhere(
        (e) => e.name == raw,
        orElse: () => PhysicalMetricKind.bodyWeightKg,
      );
}

class PhysicalMetric {
  final EntityID id;
  final EntityID athleteId;
  final DateTime recordedAt;
  final EntityID recordedByCoachId;
  final PhysicalMetricKind kind;

  /// Raw measurement in the kind's unit. For pass/fail kinds: 0 = fail, 1 = pass.
  final double value;

  /// Set only for unilateral kinds (e.g. single-leg squat). null otherwise.
  final BodySide? leg;
  final String? notes;

  const PhysicalMetric({
    required this.id,
    required this.athleteId,
    required this.recordedAt,
    required this.recordedByCoachId,
    required this.kind,
    required this.value,
    this.leg,
    this.notes,
  });

  factory PhysicalMetric.create({
    EntityID? id,
    required EntityID athleteId,
    required DateTime recordedAt,
    required EntityID recordedByCoachId,
    required PhysicalMetricKind kind,
    required double value,
    BodySide? leg,
    String? notes,
  }) => PhysicalMetric(
    id: id ?? newEntityId(),
    athleteId: athleteId,
    recordedAt: recordedAt,
    recordedByCoachId: recordedByCoachId,
    kind: kind,
    value: value,
    leg: leg,
    notes: notes,
  );

  factory PhysicalMetric.fromJson(Map<String, dynamic> json) => PhysicalMetric(
    id: json['id'] as String,
    athleteId: json['athleteID'] as String,
    recordedAt: DateTime.parse(json['recordedAt'] as String),
    recordedByCoachId: json['recordedByCoachID'] as String,
    kind: PhysicalMetricKind.fromJson(json['kind'] as String),
    value: (json['value'] as num).toDouble(),
    leg: json['leg'] != null ? BodySide.fromJson(json['leg'] as String) : null,
    notes: json['notes'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'athleteID': athleteId,
    'recordedAt': recordedAt.toIso8601String(),
    'recordedByCoachID': recordedByCoachId,
    'kind': kind.name,
    'value': value,
    'leg': leg?.name,
    'notes': notes,
  };
}

extension PhysicalMetricListExt on List<PhysicalMetric> {
  /// Latest entry per (kind, leg) tuple. Drives the dashboard "current values".
  List<PhysicalMetric> latestPerKind() {
    final seen = <String, PhysicalMetric>{};
    final sorted = [...this]
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    for (final m in sorted) {
      final key = '${m.kind.name}|${m.leg?.name ?? '-'}';
      seen.putIfAbsent(key, () => m);
    }
    return seen.values.toList();
  }
}
