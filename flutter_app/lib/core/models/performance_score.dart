import 'entity_id.dart';

/// Port of `PerformanceScore` from Core/Models/Performance.swift.
/// The seven raw pillars feed [ScoreEngine.composite].
class PerformanceScore {
  final EntityID id;
  final EntityID athleteId;
  final double competition;
  final double technical;
  final double physical;
  final double adherence;
  final double beltProgression;
  final double wellness;
  final double character;
  final DateTime calculatedAt;

  PerformanceScore({
    EntityID? id,
    required this.athleteId,
    required this.competition,
    required this.technical,
    required this.physical,
    required this.adherence,
    required this.beltProgression,
    required this.wellness,
    required this.character,
    DateTime? calculatedAt,
  })  : id = id ?? newEntityId(),
        calculatedAt = calculatedAt ?? DateTime.now();

  factory PerformanceScore.fromJson(Map<String, dynamic> json) => PerformanceScore(
        id: json['id'] as String,
        athleteId: json['athleteID'] as String,
        competition: (json['competition'] as num).toDouble(),
        technical: (json['technical'] as num).toDouble(),
        physical: (json['physical'] as num).toDouble(),
        adherence: (json['adherence'] as num).toDouble(),
        beltProgression: (json['beltProgression'] as num).toDouble(),
        wellness: (json['wellness'] as num).toDouble(),
        character: (json['character'] as num).toDouble(),
        calculatedAt: DateTime.parse(json['calculatedAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'athleteID': athleteId,
        'competition': competition,
        'technical': technical,
        'physical': physical,
        'adherence': adherence,
        'beltProgression': beltProgression,
        'wellness': wellness,
        'character': character,
        'calculatedAt': calculatedAt.toIso8601String(),
      };
}
