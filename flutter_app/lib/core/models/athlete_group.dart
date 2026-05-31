import 'athlete.dart';
import 'entity_id.dart';

// Port of Core/Models/AthleteGroup.swift.

enum SquadPurpose {
  competition,
  trainingCamp,
  grading,
  notification,
  custom;

  String get labelKey => 'squad.purpose.$name';

  static SquadPurpose fromJson(String raw) => SquadPurpose.values.firstWhere(
    (s) => s.name == raw,
    orElse: () => SquadPurpose.custom,
  );
}

class AthleteGroup {
  final EntityID id;
  final String name;
  final String? nameAr;
  final SquadPurpose purpose;
  final EntityID createdByCoachId;
  final List<EntityID> athleteIds;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final EntityID? linkedTournamentId;
  final bool isArchived;
  final String? nationalityFilter;
  final AgeGroup? ageGroupFilter;
  final Gender? genderFilter;
  final String? notes;

  const AthleteGroup({
    required this.id,
    required this.name,
    this.nameAr,
    this.purpose = SquadPurpose.custom,
    required this.createdByCoachId,
    this.athleteIds = const [],
    required this.createdAt,
    this.expiresAt,
    this.linkedTournamentId,
    this.isArchived = false,
    this.nationalityFilter,
    this.ageGroupFilter,
    this.genderFilter,
    this.notes,
  });

  factory AthleteGroup.create({
    EntityID? id,
    required String name,
    String? nameAr,
    SquadPurpose purpose = SquadPurpose.custom,
    required EntityID createdByCoachId,
    List<EntityID> athleteIds = const [],
    DateTime? createdAt,
    DateTime? expiresAt,
    EntityID? linkedTournamentId,
    bool isArchived = false,
    String? nationalityFilter,
    AgeGroup? ageGroupFilter,
    Gender? genderFilter,
    String? notes,
  }) => AthleteGroup(
    id: id ?? newEntityId(),
    name: name,
    nameAr: nameAr,
    purpose: purpose,
    createdByCoachId: createdByCoachId,
    athleteIds: athleteIds,
    createdAt: createdAt ?? DateTime.now(),
    expiresAt: expiresAt,
    linkedTournamentId: linkedTournamentId,
    isArchived: isArchived,
    nationalityFilter: nationalityFilter,
    ageGroupFilter: ageGroupFilter,
    genderFilter: genderFilter,
    notes: notes,
  );

  /// True when [expiresAt] is set and is in the past.
  bool get isExpired {
    if (expiresAt == null) return false;
    return expiresAt!.isBefore(DateTime.now());
  }

  factory AthleteGroup.fromJson(Map<String, dynamic> json) => AthleteGroup(
    id: json['id'] as String,
    name: json['name'] as String,
    nameAr: json['nameAr'] as String?,
    purpose: SquadPurpose.fromJson(json['purpose'] as String? ?? 'custom'),
    createdByCoachId: json['createdByCoachID'] as String,
    athleteIds: ((json['athleteIDs'] as List?) ?? [])
        .map((e) => e as String)
        .toList(),
    createdAt: DateTime.parse(json['createdAt'] as String),
    expiresAt: json['expiresAt'] != null
        ? DateTime.parse(json['expiresAt'] as String)
        : null,
    linkedTournamentId: json['linkedTournamentID'] as String?,
    isArchived: json['isArchived'] as bool? ?? false,
    nationalityFilter: json['nationalityFilter'] as String?,
    ageGroupFilter: json['ageGroupFilter'] != null
        ? AgeGroup.values.firstWhere(
            (a) => a.name == json['ageGroupFilter'] as String,
            orElse: () => AgeGroup.seniors,
          )
        : null,
    genderFilter: json['genderFilter'] != null
        ? Gender.fromJson(json['genderFilter'] as String)
        : null,
    notes: json['notes'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'nameAr': nameAr,
    'purpose': purpose.name,
    'createdByCoachID': createdByCoachId,
    'athleteIDs': athleteIds,
    'createdAt': createdAt.toIso8601String(),
    'expiresAt': expiresAt?.toIso8601String(),
    'linkedTournamentID': linkedTournamentId,
    'isArchived': isArchived,
    'nationalityFilter': nationalityFilter,
    'ageGroupFilter': ageGroupFilter?.name,
    'genderFilter': genderFilter?.name,
    'notes': notes,
  };
}
