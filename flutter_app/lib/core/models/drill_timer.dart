// Port of Core/Models/Training/DrillTimer.swift.
// Stage 1.8 — the from-scratch operational timer for the Drills hub.
// Pure data — no Flutter imports (logic-layer rule).

import 'entity_id.dart';

/// Phase the running timer is in. Drives colour, label, and audio.
enum DrillTimerPhase {
  prepare, // lead-in countdown before the first interval
  work,
  rest,
  roundBreak, // longer rest inserted between rounds
  finished;

  String get labelKey => 'timer.phase.$name';

  /// Work-like phases drive the "active" visual treatment.
  bool get isEffort => this == DrillTimerPhase.work;

  // tint/color getter is ported in the UI layer.

  static DrillTimerPhase fromJson(String raw) => DrillTimerPhase.values
      .firstWhere((e) => e.name == raw, orElse: () => DrillTimerPhase.prepare);
}

/// One interval in a session — a fixed span of work or rest.
class DrillTimerInterval {
  final EntityID id;
  final bool isWork;
  final int seconds;
  final String? label;
  final EntityID? drillId;

  DrillTimerInterval({
    required this.id,
    required this.isWork,
    required int seconds,
    this.label,
    this.drillId,
  }) : seconds = seconds < 1 ? 1 : seconds;

  factory DrillTimerInterval.create({
    required bool isWork,
    required int seconds,
    String? label,
    EntityID? drillId,
  }) => DrillTimerInterval(
    id: newEntityId(),
    isWork: isWork,
    seconds: seconds,
    label: label,
    drillId: drillId,
  );

  factory DrillTimerInterval.fromJson(Map<String, dynamic> json) =>
      DrillTimerInterval(
        id: json['id'] as String,
        isWork: json['isWork'] as bool,
        seconds: json['seconds'] as int,
        label: json['label'] as String?,
        drillId: json['drillID'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'isWork': isWork,
    'seconds': seconds,
    'label': label,
    'drillID': drillId,
  };
}

/// A complete timer configuration. Not persisted in Stage 1.8 — built fresh
/// from a preset or the in-app builder each session.
class DrillTimerSession {
  final EntityID id;
  final String name;
  final String nameAr;
  final int prepareSeconds;
  final List<DrillTimerInterval> intervals;
  final int rounds;
  final int roundBreakSeconds;

  /// Athlete groups for station rotation. Empty → grouping off.
  final List<String> athleteGroups;
  final DateTime createdAt;

  DrillTimerSession({
    required this.id,
    required this.name,
    this.nameAr = '',
    required int prepareSeconds,
    this.intervals = const [],
    required int rounds,
    required int roundBreakSeconds,
    this.athleteGroups = const [],
    required this.createdAt,
  }) : prepareSeconds = prepareSeconds < 0 ? 0 : prepareSeconds,
       rounds = rounds < 1 ? 1 : rounds,
       roundBreakSeconds = roundBreakSeconds < 0 ? 0 : roundBreakSeconds;

  /// Number of work intervals in a single round.
  int get workPerRound => intervals.where((i) => i.isWork).length;

  /// Total work intervals across every round.
  int get totalWorkIntervals => workPerRound * rounds;

  int get secondsPerRound => intervals.fold(0, (sum, i) => sum + i.seconds);

  /// Full wall-clock length including lead-in and round breaks.
  int get totalSeconds =>
      prepareSeconds +
      secondsPerRound * rounds +
      roundBreakSeconds * (rounds - 1 < 0 ? 0 : rounds - 1);

  bool get usesGroups => athleteGroups.isNotEmpty;

  factory DrillTimerSession.fromJson(Map<String, dynamic> json) =>
      DrillTimerSession(
        id: json['id'] as String,
        name: json['name'] as String,
        nameAr: json['nameAr'] as String? ?? '',
        prepareSeconds: json['prepareSeconds'] as int? ?? 10,
        intervals: ((json['intervals'] as List?) ?? [])
            .map((e) => DrillTimerInterval.fromJson(e as Map<String, dynamic>))
            .toList(),
        rounds: json['rounds'] as int? ?? 1,
        roundBreakSeconds: json['roundBreakSeconds'] as int? ?? 0,
        athleteGroups: ((json['athleteGroups'] as List?) ?? [])
            .map((e) => e as String)
            .toList(),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'nameAr': nameAr,
    'prepareSeconds': prepareSeconds,
    'intervals': intervals.map((i) => i.toJson()).toList(),
    'rounds': rounds,
    'roundBreakSeconds': roundBreakSeconds,
    'athleteGroups': athleteGroups,
    'createdAt': createdAt.toIso8601String(),
  };

  // MARK: - Presets

  /// Classic Tabata — 8 × (20s work / 10s rest).
  static DrillTimerSession tabata() => DrillTimerSession(
    id: newEntityId(),
    name: 'Tabata',
    nameAr: 'تاباتا',
    prepareSeconds: 10,
    intervals: [
      DrillTimerInterval.create(isWork: true, seconds: 20),
      DrillTimerInterval.create(isWork: false, seconds: 10),
    ],
    rounds: 8,
    roundBreakSeconds: 0,
    createdAt: DateTime.now(),
  );

  /// Sparring rounds — 3 × (3 min work / 1 min rest).
  /// Named `roundsPreset` (not `rounds`) to avoid colliding with the instance
  /// `rounds` field; the Swift static was `DrillTimerSession.rounds`.
  static DrillTimerSession roundsPreset() => DrillTimerSession(
    id: newEntityId(),
    name: 'Sparring Rounds',
    nameAr: 'جولات القتال',
    prepareSeconds: 15,
    intervals: [
      DrillTimerInterval.create(isWork: true, seconds: 180),
      DrillTimerInterval.create(isWork: false, seconds: 60),
    ],
    rounds: 3,
    roundBreakSeconds: 0,
    createdAt: DateTime.now(),
  );

  /// EMOM — 10 × 60s work, no rest.
  static DrillTimerSession emom() => DrillTimerSession(
    id: newEntityId(),
    name: 'EMOM',
    nameAr: 'كل دقيقة',
    prepareSeconds: 10,
    intervals: [DrillTimerInterval.create(isWork: true, seconds: 60)],
    rounds: 10,
    roundBreakSeconds: 0,
    createdAt: DateTime.now(),
  );

  /// Builds a simple work/rest interval session from raw numbers.
  static DrillTimerSession interval({
    required String name,
    required int work,
    required int rest,
    required int rounds,
    int prepare = 10,
    List<String> groups = const [],
  }) {
    final intervals = [DrillTimerInterval.create(isWork: true, seconds: work)];
    if (rest > 0) {
      intervals.add(DrillTimerInterval.create(isWork: false, seconds: rest));
    }
    return DrillTimerSession(
      id: newEntityId(),
      name: name,
      prepareSeconds: prepare,
      intervals: intervals,
      rounds: rounds,
      roundBreakSeconds: 0,
      athleteGroups: groups,
      createdAt: DateTime.now(),
    );
  }
}
