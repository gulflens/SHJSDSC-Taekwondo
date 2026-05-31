// Port of Core/Models/CoachExtras.swift.
// Embedded enums + structs that hang off Coach for the federation-grade
// profile redesign (Stage 1.6). Mirrors the Athlete dossier pattern — no new
// Repository methods, keeps the Android port mechanical.

enum CoachLevel {
  assistant,
  junior,
  senior,
  head,
  national,
  international;

  String get labelKey => 'coach.level.$name';

  static CoachLevel fromJson(String raw) => CoachLevel.values.firstWhere(
    (c) => c.name == raw,
    orElse: () => CoachLevel.assistant,
  );
}

enum CoachLicenseLevel {
  poom2,
  poom1,
  dan1,
  dan2,
  dan3,
  dan4,
  dan5plus;

  String get labelKey => 'coach.license.$name';

  static CoachLicenseLevel fromJson(String raw) => CoachLicenseLevel.values
      .firstWhere((c) => c.name == raw, orElse: () => CoachLicenseLevel.dan1);
}

enum CoachSpecialisation {
  kyorugi,
  poomsae,
  technical,
  fitness,
  sparring,
  multi;

  String get labelKey => 'coach.specialisation.$name';

  String get systemIcon => switch (this) {
    CoachSpecialisation.kyorugi => 'figure.martial.arts',
    CoachSpecialisation.poomsae => 'figure.mind.and.body',
    CoachSpecialisation.technical => 'figure.taichi',
    CoachSpecialisation.fitness => 'figure.run',
    CoachSpecialisation.sparring => 'figure.boxing',
    CoachSpecialisation.multi => 'circle.grid.3x3.fill',
  };

  static CoachSpecialisation fromJson(String raw) =>
      CoachSpecialisation.values.firstWhere(
        (c) => c.name == raw,
        orElse: () => CoachSpecialisation.multi,
      );
}

enum CoachEmploymentStatus {
  active,
  leave,
  transferred,
  retired,
  suspended;

  String get labelKey => 'coach.employment.$name';

  static CoachEmploymentStatus fromJson(String raw) =>
      CoachEmploymentStatus.values.firstWhere(
        (c) => c.name == raw,
        orElse: () => CoachEmploymentStatus.active,
      );
}

enum CoachProgramStatus {
  none,
  candidate,
  supportStaff,
  member,
  leadStaff;

  String get labelKey => 'coach.program.$name';

  static CoachProgramStatus fromJson(String raw) => CoachProgramStatus.values
      .firstWhere((c) => c.name == raw, orElse: () => CoachProgramStatus.none);
}

/// Cross-federation ranking snapshot for a coach. Null fields render as "—".
class CoachRanking {
  /// Internal rank inside SSDC (across all coaches).
  final int? club;

  /// UAE Taekwondo Federation coach standing.
  final int? uae;

  /// World Taekwondo recognition tier label (e.g. "Class A", "Class B").
  /// String — WT publishes tiers, not numeric ranks.
  final String? worldTier;

  final DateTime asOf;

  const CoachRanking({this.club, this.uae, this.worldTier, required this.asOf});

  factory CoachRanking.create({
    int? club,
    int? uae,
    String? worldTier,
    DateTime? asOf,
  }) => CoachRanking(
    club: club,
    uae: uae,
    worldTier: worldTier,
    asOf: asOf ?? DateTime.now(),
  );

  factory CoachRanking.fromJson(Map<String, dynamic> json) => CoachRanking(
    club: json['club'] as int?,
    uae: json['uae'] as int?,
    worldTier: json['worldTier'] as String?,
    asOf: DateTime.parse(json['asOf'] as String),
  );

  Map<String, dynamic> toJson() => {
    'club': club,
    'uae': uae,
    'worldTier': worldTier,
    'asOf': asOf.toIso8601String(),
  };
}
