// Port of Core/Models/Training/TrainingPomodoro.swift.
// Pure data — no Flutter imports (logic-layer rule).

import 'entity_id.dart';

enum WorkRest {
  work,
  rest;

  String get labelKey => 'pomodoro.$name';

  static WorkRest fromJson(String raw) => WorkRest.values.firstWhere(
    (e) => e.name == raw,
    orElse: () => WorkRest.work,
  );
}

class PomodoroInterval {
  final EntityID id;
  final WorkRest kind;
  final int durationSeconds;

  const PomodoroInterval({
    required this.id,
    required this.kind,
    required this.durationSeconds,
  });

  factory PomodoroInterval.create({
    required WorkRest kind,
    required int durationSeconds,
  }) => PomodoroInterval(
    id: newEntityId(),
    kind: kind,
    durationSeconds: durationSeconds,
  );

  /// Snaps a candidate value to the nearest valid step for the given phase.
  /// Work intervals are 30s+ in 10s increments, rest intervals are 5s+ in
  /// 5s increments.
  static int snap(int raw, WorkRest kind) {
    switch (kind) {
      case WorkRest.work:
        final clamped = raw < 30 ? 30 : raw;
        return ((clamped - 30) ~/ 10) * 10 + 30;
      case WorkRest.rest:
        final clamped = raw < 5 ? 5 : raw;
        return ((clamped - 5) ~/ 5) * 5 + 5;
    }
  }

  factory PomodoroInterval.fromJson(Map<String, dynamic> json) =>
      PomodoroInterval(
        id: json['id'] as String,
        kind: WorkRest.fromJson(json['kind'] as String),
        durationSeconds: json['durationSeconds'] as int,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.name,
    'durationSeconds': durationSeconds,
  };
}

class PomodoroGroup {
  final EntityID id;
  final String? name;
  final String? nameAr;
  final int repetitions;
  final List<PomodoroInterval> intervals;

  PomodoroGroup({
    required this.id,
    this.name,
    this.nameAr,
    required int repetitions,
    this.intervals = const [],
  }) : repetitions = repetitions < 1 ? 1 : repetitions;

  factory PomodoroGroup.create({
    String? name,
    String? nameAr,
    int repetitions = 1,
    List<PomodoroInterval> intervals = const [],
  }) => PomodoroGroup(
    id: newEntityId(),
    name: name,
    nameAr: nameAr,
    repetitions: repetitions,
    intervals: intervals,
  );

  int get totalSecondsPerRound =>
      intervals.fold(0, (sum, i) => sum + i.durationSeconds);

  int get totalSeconds => totalSecondsPerRound * repetitions;

  factory PomodoroGroup.fromJson(Map<String, dynamic> json) => PomodoroGroup(
    id: json['id'] as String,
    name: json['name'] as String?,
    nameAr: json['nameAr'] as String?,
    repetitions: json['repetitions'] as int? ?? 1,
    intervals: ((json['intervals'] as List?) ?? [])
        .map((e) => PomodoroInterval.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'nameAr': nameAr,
    'repetitions': repetitions,
    'intervals': intervals.map((i) => i.toJson()).toList(),
  };
}

class TrainingPomodoro {
  final EntityID id;
  final String name;
  final String nameAr;
  final List<PomodoroGroup> groups;

  /// Length in seconds of the transition whistle. Validated 1...5.
  final double whistleSeconds;
  final EntityID? createdByCoachId;
  final DateTime createdAt;

  TrainingPomodoro({
    required this.id,
    required this.name,
    this.nameAr = '',
    this.groups = const [],
    required double whistleSeconds,
    this.createdByCoachId,
    required this.createdAt,
  }) : whistleSeconds = whistleSeconds.clamp(1.0, 5.0);

  int get totalSeconds => groups.fold(0, (sum, g) => sum + g.totalSeconds);

  factory TrainingPomodoro.fromJson(Map<String, dynamic> json) =>
      TrainingPomodoro(
        id: json['id'] as String,
        name: json['name'] as String,
        nameAr: json['nameAr'] as String? ?? '',
        groups: ((json['groups'] as List?) ?? [])
            .map((e) => PomodoroGroup.fromJson(e as Map<String, dynamic>))
            .toList(),
        whistleSeconds: (json['whistleSeconds'] as num?)?.toDouble() ?? 2.0,
        createdByCoachId: json['createdByCoachID'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'nameAr': nameAr,
    'groups': groups.map((g) => g.toJson()).toList(),
    'whistleSeconds': whistleSeconds,
    'createdByCoachID': createdByCoachId,
    'createdAt': createdAt.toIso8601String(),
  };
}
