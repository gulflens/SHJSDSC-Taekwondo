import 'entity_id.dart';

// Port of Core/Models/AthleteProfile.swift.
// Profile-detail types layered onto Athlete. Kept in a sibling file so the
// core Athlete model stays readable.

/// Blood type enum. JSON values are the medical strings ("A+", "A-", …)
/// NOT the Dart case names — BloodType uses a custom raw-value mapping.
enum BloodType {
  aPositive,
  aNegative,
  bPositive,
  bNegative,
  oPositive,
  oNegative,
  abPositive,
  abNegative,
  unknown;

  /// The exact string stored in JSON / Swift rawValue.
  String get rawValue => switch (this) {
    BloodType.aPositive => 'A+',
    BloodType.aNegative => 'A-',
    BloodType.bPositive => 'B+',
    BloodType.bNegative => 'B-',
    BloodType.oPositive => 'O+',
    BloodType.oNegative => 'O-',
    BloodType.abPositive => 'AB+',
    BloodType.abNegative => 'AB-',
    BloodType.unknown => 'unknown',
  };

  String get labelKey => 'blood.$rawValue';

  String get display => this == BloodType.unknown ? '?' : rawValue;

  static BloodType fromJson(String raw) => BloodType.values.firstWhere(
    (b) => b.rawValue == raw,
    orElse: () => BloodType.unknown,
  );
}

enum DominantLeg {
  left,
  right;

  String get labelKey => 'dominant_leg.$name';

  static DominantLeg fromJson(String raw) => DominantLeg.values.firstWhere(
    (d) => d.name == raw,
    orElse: () => DominantLeg.right,
  );
}

enum Stance {
  open,
  closed,
  switchStance;

  String get labelKey => 'stance.$name';

  static Stance fromJson(String raw) =>
      Stance.values.firstWhere((s) => s.name == raw, orElse: () => Stance.open);
}

enum Specialty {
  kyorugi,
  poomsae,
  both;

  String get labelKey => 'specialty.$name';

  static Specialty fromJson(String raw) => Specialty.values.firstWhere(
    (s) => s.name == raw,
    orElse: () => Specialty.kyorugi,
  );
}

enum KyorugiTier {
  recreational,
  competitive,
  elite;

  String get labelKey => 'kyorugi_tier.$name';

  static KyorugiTier fromJson(String raw) => KyorugiTier.values.firstWhere(
    (k) => k.name == raw,
    orElse: () => KyorugiTier.recreational,
  );
}

enum InjurySeverity {
  minor,
  moderate,
  severe;

  String get labelKey => 'injury_severity.$name';

  static InjurySeverity fromJson(String raw) => InjurySeverity.values
      .firstWhere((i) => i.name == raw, orElse: () => InjurySeverity.minor);
}

class EmergencyContact {
  final EntityID id;
  final String name;
  final String relationship;
  final String phone;

  const EmergencyContact({
    required this.id,
    required this.name,
    required this.relationship,
    required this.phone,
  });

  factory EmergencyContact.create({
    EntityID? id,
    required String name,
    required String relationship,
    required String phone,
  }) => EmergencyContact(
    id: id ?? newEntityId(),
    name: name,
    relationship: relationship,
    phone: phone,
  );

  factory EmergencyContact.fromJson(Map<String, dynamic> json) =>
      EmergencyContact(
        id: json['id'] as String,
        name: json['name'] as String,
        relationship: json['relationship'] as String,
        phone: json['phone'] as String,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'relationship': relationship,
    'phone': phone,
  };
}

class WeightEntry {
  final EntityID id;
  final DateTime recordedAt;
  final double weightKg;

  const WeightEntry({
    required this.id,
    required this.recordedAt,
    required this.weightKg,
  });

  factory WeightEntry.create({
    EntityID? id,
    DateTime? recordedAt,
    required double weightKg,
  }) => WeightEntry(
    id: id ?? newEntityId(),
    recordedAt: recordedAt ?? DateTime.now(),
    weightKg: weightKg,
  );

  factory WeightEntry.fromJson(Map<String, dynamic> json) => WeightEntry(
    id: json['id'] as String,
    recordedAt: DateTime.parse(json['recordedAt'] as String),
    weightKg: (json['weightKg'] as num).toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'recordedAt': recordedAt.toIso8601String(),
    'weightKg': weightKg,
  };
}

class InjuryEntry {
  final EntityID id;
  final DateTime recordedAt;
  final String description;
  final InjurySeverity severity;
  final DateTime? returnToTrainAt;
  final String? notes;

  const InjuryEntry({
    required this.id,
    required this.recordedAt,
    required this.description,
    required this.severity,
    this.returnToTrainAt,
    this.notes,
  });

  factory InjuryEntry.create({
    EntityID? id,
    DateTime? recordedAt,
    required String description,
    required InjurySeverity severity,
    DateTime? returnToTrainAt,
    String? notes,
  }) => InjuryEntry(
    id: id ?? newEntityId(),
    recordedAt: recordedAt ?? DateTime.now(),
    description: description,
    severity: severity,
    returnToTrainAt: returnToTrainAt,
    notes: notes,
  );

  factory InjuryEntry.fromJson(Map<String, dynamic> json) => InjuryEntry(
    id: json['id'] as String,
    recordedAt: DateTime.parse(json['recordedAt'] as String),
    description: json['description'] as String,
    severity: InjurySeverity.fromJson(json['severity'] as String),
    returnToTrainAt: json['returnToTrainAt'] != null
        ? DateTime.parse(json['returnToTrainAt'] as String)
        : null,
    notes: json['notes'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'recordedAt': recordedAt.toIso8601String(),
    'description': description,
    'severity': severity.name,
    'returnToTrainAt': returnToTrainAt?.toIso8601String(),
    'notes': notes,
  };
}
