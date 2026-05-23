import 'entity_id.dart';

/// Port of Core/Models/TrainingLoadEntry.swift.

enum SessionType {
  technique,
  sparring,
  fitness,
  poomsae,
  mixed;

  String get labelKey => 'session_type.$name';

  String get systemIcon => switch (this) {
    SessionType.technique => 'figure.kickboxing',
    SessionType.sparring => 'figure.boxing',
    SessionType.fitness => 'figure.strengthtraining.traditional',
    SessionType.poomsae => 'figure.taichi',
    SessionType.mixed => 'circle.grid.2x2',
  };

  static SessionType fromJson(String raw) => SessionType.values.firstWhere(
    (e) => e.name == raw,
    orElse: () => SessionType.mixed,
  );
}

class TrainingLoadEntry {
  final EntityID id;
  final EntityID athleteId;

  /// Optional link to a ClassSession row when the entry corresponds to a
  /// scheduled session. Standalone entries (home practice, supplementary
  /// work) leave this null.
  final EntityID? sessionId;
  final DateTime recordedAt;
  final SessionType sessionType;
  final int durationMinutes;

  /// 1…10 — Borg-style perceived exertion.
  final int rpe;

  final String? notes;

  TrainingLoadEntry({
    EntityID? id,
    required this.athleteId,
    this.sessionId,
    required this.recordedAt,
    required this.sessionType,
    required int durationMinutes,
    required int rpe,
    this.notes,
  }) : id = id ?? newEntityId(),
       durationMinutes = durationMinutes < 0 ? 0 : durationMinutes,
       rpe = rpe.clamp(1, 10);

  /// Foster's session-RPE: duration (min) × RPE → arbitrary units (AU).
  double get sessionLoad => durationMinutes * rpe.toDouble();

  factory TrainingLoadEntry.fromJson(Map<String, dynamic> json) =>
      TrainingLoadEntry(
        id: json['id'] as String,
        athleteId: json['athleteID'] as String,
        sessionId: json['sessionID'] as String?,
        recordedAt: DateTime.parse(json['recordedAt'] as String),
        sessionType: SessionType.fromJson(json['sessionType'] as String),
        durationMinutes: json['durationMinutes'] as int,
        rpe: json['rpe'] as int,
        notes: json['notes'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'athleteID': athleteId,
    'sessionID': sessionId,
    'recordedAt': recordedAt.toIso8601String(),
    'sessionType': sessionType.name,
    'durationMinutes': durationMinutes,
    'rpe': rpe,
    'notes': notes,
  };
}

/// Risk classification from the acute:chronic workload ratio (ACWR).
/// The commonly cited "sweet spot" is 0.8–1.3; >1.5 is the danger zone.
/// Below 0.8 indicates undertraining (deconditioning risk).
///
/// NOTE: LoadRisk is NOT Codable in Swift — it is NOT given fromJson/toJson.
enum LoadRisk {
  undertrained,
  sweet,
  elevated,
  danger,
  unknown;

  String get labelKey => 'load_risk.$name';
}

extension TrainingLoadEntryListExt on List<TrainingLoadEntry> {
  /// Sum of session loads in the last [days] days ending at [asOf].
  double acuteLoad({DateTime? asOf, int days = 7}) {
    final date = asOf ?? DateTime.now();
    final cutoff = date.subtract(Duration(days: days));
    return where(
      (e) => e.recordedAt.isAfter(cutoff) && !e.recordedAt.isAfter(date),
    ).fold(0.0, (sum, e) => sum + e.sessionLoad);
  }

  /// Sum of session loads in the last [days] days (default 28).
  double chronicLoad({DateTime? asOf, int days = 28}) {
    final date = asOf ?? DateTime.now();
    final cutoff = date.subtract(Duration(days: days));
    return where(
      (e) => e.recordedAt.isAfter(cutoff) && !e.recordedAt.isAfter(date),
    ).fold(0.0, (sum, e) => sum + e.sessionLoad);
  }

  /// ACWR = (7-day weekly average) / (28-day weekly average).
  /// Returns null when chronic load is zero (insufficient history).
  double? acwr({DateTime? asOf}) {
    final date = asOf ?? DateTime.now();
    final acute = acuteLoad(asOf: date);
    final chronicWeekly = chronicLoad(asOf: date) / 4.0;
    if (chronicWeekly <= 0) return null;
    return acute / chronicWeekly;
  }

  LoadRisk loadRisk({DateTime? asOf}) {
    final r = acwr(asOf: asOf);
    if (r == null) return LoadRisk.unknown;
    if (r < 0.8) return LoadRisk.undertrained;
    if (r < 1.3) return LoadRisk.sweet;
    if (r < 1.5) return LoadRisk.elevated;
    return LoadRisk.danger;
  }
}
