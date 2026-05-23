// Port of Core/Models/ImprovementPlan.swift.
// Pure data — no Flutter imports (logic-layer rule).

import 'belt.dart';
import 'drill_dossier.dart';
import 'entity_id.dart';

// MARK: - Drill library

enum DrillCategory {
  technique,
  sparring,
  flexibility,
  conditioning,
  poomsae,
  footwork,
  strength;

  String get labelKey => 'drill_category.$name';

  String get systemIcon => switch (this) {
    DrillCategory.technique => 'figure.kickboxing',
    DrillCategory.sparring => 'figure.boxing',
    DrillCategory.flexibility => 'figure.flexibility',
    DrillCategory.conditioning => 'figure.run',
    DrillCategory.poomsae => 'figure.taichi',
    DrillCategory.footwork => 'shoe.fill',
    DrillCategory.strength => 'dumbbell.fill',
  };

  static DrillCategory fromJson(String raw) => DrillCategory.values.firstWhere(
    (e) => e.name == raw,
    orElse: () => DrillCategory.technique,
  );
}

enum DrillDifficulty {
  beginner,
  intermediate,
  advanced;

  String get labelKey => 'drill_difficulty.$name';

  static DrillDifficulty fromJson(String raw) => DrillDifficulty.values
      .firstWhere((e) => e.name == raw, orElse: () => DrillDifficulty.beginner);
}

class DrillLibraryEntry {
  final EntityID id;
  final String name;
  final String? nameAr;
  final DrillCategory category;
  final String summary;
  final String? videoUrl;
  final int? durationMinutes;

  /// Tags this drill addresses — should match a metric/technique/poomsae
  /// raw value from Pillars 1–4 so the auto-flag pipeline can suggest drills
  /// for flagged weaknesses by exact-match.
  final List<String> addressesWeaknessTags;
  final BeltRank? minBelt;
  final BeltRank? maxBelt;
  final List<String> equipmentRequired;
  final DrillDifficulty? difficulty;

  // Stage 1.8 — drill dossier
  final List<String> tags;
  final int? intensity;
  final List<String> instructions;
  final String? coachingTip;
  final List<DrillEquipmentItem> equipment;
  final List<String> muscleFocus;
  final DrillMetrics? metrics;
  final List<DrillVariation> variations;
  final String? notes;
  final List<EntityID> relatedDrillIds;
  final String? imageAssetName;
  final int? videoDurationSeconds;

  const DrillLibraryEntry({
    required this.id,
    required this.name,
    this.nameAr,
    required this.category,
    this.summary = '',
    this.videoUrl,
    this.durationMinutes,
    this.addressesWeaknessTags = const [],
    this.minBelt,
    this.maxBelt,
    this.equipmentRequired = const [],
    this.difficulty,
    this.tags = const [],
    this.intensity,
    this.instructions = const [],
    this.coachingTip,
    this.equipment = const [],
    this.muscleFocus = const [],
    this.metrics,
    this.variations = const [],
    this.notes,
    this.relatedDrillIds = const [],
    this.imageAssetName,
    this.videoDurationSeconds,
  });

  /// True when [belt] falls within (minBelt, maxBelt) — either bound null
  /// means the drill is unbounded on that side.
  bool isAvailable(Belt belt) {
    final r = belt.rank;
    if (minBelt != null && r < minBelt!) return false;
    if (maxBelt != null && r > maxBelt!) return false;
    return true;
  }

  factory DrillLibraryEntry.fromJson(
    Map<String, dynamic> json,
  ) => DrillLibraryEntry(
    id: json['id'] as String,
    name: json['name'] as String,
    nameAr: json['nameAr'] as String?,
    category: DrillCategory.fromJson(json['category'] as String),
    summary: json['summary'] as String? ?? '',
    videoUrl: json['videoURL'] as String?,
    durationMinutes: json['durationMinutes'] as int?,
    addressesWeaknessTags: ((json['addressesWeaknessTags'] as List?) ?? [])
        .map((e) => e as String)
        .toList(),
    minBelt: json['minBelt'] != null
        ? BeltRank(
            kind: BeltKind.fromJson(
              (json['minBelt'] as Map<String, dynamic>)['kind'] as String,
            ),
            number: (json['minBelt'] as Map<String, dynamic>)['number'] as int,
          )
        : null,
    maxBelt: json['maxBelt'] != null
        ? BeltRank(
            kind: BeltKind.fromJson(
              (json['maxBelt'] as Map<String, dynamic>)['kind'] as String,
            ),
            number: (json['maxBelt'] as Map<String, dynamic>)['number'] as int,
          )
        : null,
    equipmentRequired: ((json['equipmentRequired'] as List?) ?? [])
        .map((e) => e as String)
        .toList(),
    difficulty: json['difficulty'] != null
        ? DrillDifficulty.fromJson(json['difficulty'] as String)
        : null,
    tags: ((json['tags'] as List?) ?? []).map((e) => e as String).toList(),
    intensity: json['intensity'] as int?,
    instructions: ((json['instructions'] as List?) ?? [])
        .map((e) => e as String)
        .toList(),
    coachingTip: json['coachingTip'] as String?,
    equipment: ((json['equipment'] as List?) ?? [])
        .map((e) => DrillEquipmentItem.fromJson(e as Map<String, dynamic>))
        .toList(),
    muscleFocus: ((json['muscleFocus'] as List?) ?? [])
        .map((e) => e as String)
        .toList(),
    metrics: json['metrics'] != null
        ? DrillMetrics.fromJson(json['metrics'] as Map<String, dynamic>)
        : null,
    variations: ((json['variations'] as List?) ?? [])
        .map((e) => DrillVariation.fromJson(e as Map<String, dynamic>))
        .toList(),
    notes: json['notes'] as String?,
    relatedDrillIds: ((json['relatedDrillIDs'] as List?) ?? [])
        .map((e) => e as String)
        .toList(),
    imageAssetName: json['imageAssetName'] as String?,
    videoDurationSeconds: json['videoDurationSeconds'] as int?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'nameAr': nameAr,
    'category': category.name,
    'summary': summary,
    'videoURL': videoUrl,
    'durationMinutes': durationMinutes,
    'addressesWeaknessTags': addressesWeaknessTags,
    'minBelt': minBelt != null
        ? {'kind': minBelt!.kind.name, 'number': minBelt!.number}
        : null,
    'maxBelt': maxBelt != null
        ? {'kind': maxBelt!.kind.name, 'number': maxBelt!.number}
        : null,
    'equipmentRequired': equipmentRequired,
    'difficulty': difficulty?.name,
    'tags': tags,
    'intensity': intensity,
    'instructions': instructions,
    'coachingTip': coachingTip,
    'equipment': equipment.map((e) => e.toJson()).toList(),
    'muscleFocus': muscleFocus,
    'metrics': metrics?.toJson(),
    'variations': variations.map((v) => v.toJson()).toList(),
    'notes': notes,
    'relatedDrillIDs': relatedDrillIds,
    'imageAssetName': imageAssetName,
    'videoDurationSeconds': videoDurationSeconds,
  };
}

// MARK: - Weakness (value type, not persisted as a row — embedded in plans)

enum WeaknessSeverity {
  low,
  medium,
  high;

  String get labelKey => 'weakness_severity.$name';

  static WeaknessSeverity fromJson(String raw) => WeaknessSeverity.values
      .firstWhere((e) => e.name == raw, orElse: () => WeaknessSeverity.low);
}

enum WeaknessSource {
  peer,
  manual;

  String get labelKey => 'weakness_source.$name';

  static WeaknessSource fromJson(String raw) => WeaknessSource.values
      .firstWhere((e) => e.name == raw, orElse: () => WeaknessSource.manual);
}

class Weakness {
  /// Stable identifier for the underlying signal (e.g. PhysicalMetricKind raw
  /// value, TechniqueKind raw value, or a free-form key for manual entries).
  final String kind;

  /// Human-readable label key OR free-form text. Display layer chooses.
  final String label;
  final WeaknessSeverity severity;
  final WeaknessSource source;

  const Weakness({
    required this.kind,
    required this.label,
    required this.severity,
    required this.source,
  });

  /// Mirrors Swift's computed `id` property.
  String get id => '${source.name}.$kind';

  factory Weakness.fromJson(Map<String, dynamic> json) => Weakness(
    kind: json['kind'] as String,
    label: json['label'] as String,
    severity: WeaknessSeverity.fromJson(json['severity'] as String? ?? 'low'),
    source: WeaknessSource.fromJson(json['source'] as String? ?? 'manual'),
  );

  Map<String, dynamic> toJson() => {
    'kind': kind,
    'label': label,
    'severity': severity.name,
    'source': source.name,
  };
}

// MARK: - Plan

enum PlanStatus {
  active,
  completed,
  archived;

  String get labelKey => 'plan_status.$name';

  static PlanStatus fromJson(String raw) => PlanStatus.values.firstWhere(
    (e) => e.name == raw,
    orElse: () => PlanStatus.active,
  );
}

class ImprovementPlan {
  final EntityID id;
  final EntityID athleteId;
  final DateTime createdAt;
  final EntityID? createdByCoachId;
  final List<Weakness> weaknesses;
  final List<EntityID> recommendedDrillIds;
  final String notes;
  final DateTime? targetDate;
  final DateTime? reviewDate;
  final PlanStatus status;

  const ImprovementPlan({
    required this.id,
    required this.athleteId,
    required this.createdAt,
    this.createdByCoachId,
    this.weaknesses = const [],
    this.recommendedDrillIds = const [],
    this.notes = '',
    this.targetDate,
    this.reviewDate,
    this.status = PlanStatus.active,
  });

  bool get isReviewDue {
    if (status != PlanStatus.active || reviewDate == null) return false;
    return reviewDate!.isBefore(DateTime.now());
  }

  factory ImprovementPlan.fromJson(Map<String, dynamic> json) =>
      ImprovementPlan(
        id: json['id'] as String,
        athleteId: json['athleteID'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        createdByCoachId: json['createdByCoachID'] as String?,
        weaknesses: ((json['weaknesses'] as List?) ?? [])
            .map((e) => Weakness.fromJson(e as Map<String, dynamic>))
            .toList(),
        recommendedDrillIds: ((json['recommendedDrillIDs'] as List?) ?? [])
            .map((e) => e as String)
            .toList(),
        notes: json['notes'] as String? ?? '',
        targetDate: json['targetDate'] != null
            ? DateTime.parse(json['targetDate'] as String)
            : null,
        reviewDate: json['reviewDate'] != null
            ? DateTime.parse(json['reviewDate'] as String)
            : null,
        status: PlanStatus.fromJson(json['status'] as String? ?? 'active'),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'athleteID': athleteId,
    'createdAt': createdAt.toIso8601String(),
    'createdByCoachID': createdByCoachId,
    'weaknesses': weaknesses.map((w) => w.toJson()).toList(),
    'recommendedDrillIDs': recommendedDrillIds,
    'notes': notes,
    'targetDate': targetDate?.toIso8601String(),
    'reviewDate': reviewDate?.toIso8601String(),
    'status': status.name,
  };
}
