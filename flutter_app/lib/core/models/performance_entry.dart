import 'entity_id.dart';

/// Port of Core/Models/PerformanceEntry.swift.

class WellnessEntry {
  final EntityID id;
  final EntityID athleteId;
  final DateTime recordedAt;
  final double sleepHours;

  /// 1…10 — higher = better mood.
  final int mood;

  /// 1…10 — higher = more sore.
  final int soreness;

  /// 1…10 — higher = more motivated.
  final int motivation;

  /// 1…10 — higher = more stressed.
  final int stress;

  /// 1…10 — Borg-style RPE for the most recent training session.
  final int rpePreviousSession;

  final String? notes;

  WellnessEntry({
    EntityID? id,
    required this.athleteId,
    required this.recordedAt,
    required this.sleepHours,
    required int mood,
    required int soreness,
    int motivation = 5,
    int stress = 5,
    required int rpePreviousSession,
    this.notes,
  }) : id = id ?? newEntityId(),
       mood = mood.clamp(1, 10),
       soreness = soreness.clamp(1, 10),
       motivation = motivation.clamp(1, 10),
       stress = stress.clamp(1, 10),
       rpePreviousSession = rpePreviousSession.clamp(1, 10);

  /// Backward-compat: rows pre-Pillar-5 (no motivation/stress columns) still
  /// load — missing fields fall back to 5.
  factory WellnessEntry.fromJson(Map<String, dynamic> json) => WellnessEntry(
    id: json['id'] as String,
    athleteId: json['athleteID'] as String,
    recordedAt: DateTime.parse(json['recordedAt'] as String),
    sleepHours: (json['sleepHours'] as num).toDouble(),
    mood: json['mood'] as int,
    soreness: json['soreness'] as int,
    motivation: json['motivation'] as int? ?? 5,
    stress: json['stress'] as int? ?? 5,
    rpePreviousSession: json['rpePreviousSession'] as int,
    notes: json['notes'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'athleteID': athleteId,
    'recordedAt': recordedAt.toIso8601String(),
    'sleepHours': sleepHours,
    'mood': mood,
    'soreness': soreness,
    'motivation': motivation,
    'stress': stress,
    'rpePreviousSession': rpePreviousSession,
    'notes': notes,
  };
}
