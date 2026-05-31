// Port of Core/Models/Schedule.swift.
// Pure data — no Flutter imports (logic-layer rule).

import 'athlete.dart' show AgeGroup; // AgeGroup is defined in athlete.dart
import 'entity_id.dart';

enum ClassDiscipline {
  poomsae,
  kyorugi,
  fundamentals,
  competition,
  fitness;

  String get labelKey => 'discipline.$name';

  static ClassDiscipline fromJson(String raw) =>
      ClassDiscipline.values.firstWhere(
        (e) => e.name == raw,
        orElse: () => ClassDiscipline.fundamentals,
      );
}

class ClassSession {
  final EntityID id;
  final String title;
  final ClassDiscipline discipline;
  final EntityID branchId;
  final EntityID coachId;
  final DateTime startsAt;
  final DateTime endsAt;
  final int capacity;
  final List<EntityID> enrolledAthleteIds;
  final AgeGroup ageGroup;

  const ClassSession({
    required this.id,
    required this.title,
    required this.discipline,
    required this.branchId,
    required this.coachId,
    required this.startsAt,
    required this.endsAt,
    required this.capacity,
    this.enrolledAthleteIds = const [],
    required this.ageGroup,
  });

  factory ClassSession.fromJson(Map<String, dynamic> json) => ClassSession(
    id: json['id'] as String,
    title: json['title'] as String,
    discipline: ClassDiscipline.fromJson(json['discipline'] as String),
    branchId: json['branchID'] as String,
    coachId: json['coachID'] as String,
    startsAt: DateTime.parse(json['startsAt'] as String),
    endsAt: DateTime.parse(json['endsAt'] as String),
    capacity: json['capacity'] as int,
    enrolledAthleteIds: ((json['enrolledAthleteIDs'] as List?) ?? [])
        .map((e) => e as String)
        .toList(),
    ageGroup: AgeGroup.values.firstWhere(
      (a) => a.name == (json['ageGroup'] as String? ?? 'seniors'),
      orElse: () => AgeGroup.seniors,
    ),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'discipline': discipline.name,
    'branchID': branchId,
    'coachID': coachId,
    'startsAt': startsAt.toIso8601String(),
    'endsAt': endsAt.toIso8601String(),
    'capacity': capacity,
    'enrolledAthleteIDs': enrolledAthleteIds,
    'ageGroup': ageGroup.name,
  };
}

enum AttendanceState {
  present,
  absent,
  late,
  excused;

  String get labelKey => 'attendance.$name';

  static AttendanceState fromJson(String raw) => AttendanceState.values
      .firstWhere((e) => e.name == raw, orElse: () => AttendanceState.absent);
}

class AttendanceRecord {
  final EntityID id;
  final EntityID sessionId;
  final EntityID athleteId;
  final AttendanceState state;
  final DateTime recordedAt;

  // Pillar 5: per-session coach engagement (each 1...5, optional).
  final int? warmupRating;
  final int? listeningRating;
  final int? effortRating;
  final int? respectRating;

  AttendanceRecord({
    required this.id,
    required this.sessionId,
    required this.athleteId,
    required this.state,
    required this.recordedAt,
    int? warmupRating,
    int? listeningRating,
    int? effortRating,
    int? respectRating,
  }) : warmupRating = warmupRating?.clamp(1, 5),
       listeningRating = listeningRating?.clamp(1, 5),
       effortRating = effortRating?.clamp(1, 5),
       respectRating = respectRating?.clamp(1, 5);

  /// Average of the 4 sub-ratings (1...5), null if none captured.
  double? get engagementAverage {
    final scores = [
      warmupRating,
      listeningRating,
      effortRating,
      respectRating,
    ].whereType<int>().toList();
    if (scores.isEmpty) return null;
    return scores.reduce((a, b) => a + b) / scores.length;
  }

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) =>
      AttendanceRecord(
        id: json['id'] as String,
        sessionId: json['sessionID'] as String,
        athleteId: json['athleteID'] as String,
        state: AttendanceState.fromJson(json['state'] as String),
        recordedAt: DateTime.parse(json['recordedAt'] as String),
        warmupRating: json['warmupRating'] as int?,
        listeningRating: json['listeningRating'] as int?,
        effortRating: json['effortRating'] as int?,
        respectRating: json['respectRating'] as int?,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'sessionID': sessionId,
    'athleteID': athleteId,
    'state': state.name,
    'recordedAt': recordedAt.toIso8601String(),
    'warmupRating': warmupRating,
    'listeningRating': listeningRating,
    'effortRating': effortRating,
    'respectRating': respectRating,
  };
}
