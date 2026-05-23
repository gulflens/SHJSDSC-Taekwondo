import 'athlete.dart';
import 'entity_id.dart';
import 'match.dart';

/// Port of Core/Models/Tournament.swift.

enum WeightCategory {
  cubsUnder28,
  cubsUnder32,
  cubsUnder36,
  cubsOver36,
  cadetsUnder37,
  cadetsUnder45,
  cadetsUnder53,
  cadetsUnder61,
  cadetsOver61,
  juniorsUnder48,
  juniorsUnder55,
  juniorsUnder63,
  juniorsUnder73,
  juniorsOver73,
  seniorsUnder58,
  seniorsUnder68,
  seniorsUnder80,
  seniorsHeavy;

  /// (lower, upper) — null means unbounded on that side.
  (double? lower, double? upper) get range => switch (this) {
    WeightCategory.cubsUnder28 => (null, 28),
    WeightCategory.cubsUnder32 => (28, 32),
    WeightCategory.cubsUnder36 => (32, 36),
    WeightCategory.cubsOver36 => (36, null),
    WeightCategory.cadetsUnder37 => (null, 37),
    WeightCategory.cadetsUnder45 => (37, 45),
    WeightCategory.cadetsUnder53 => (45, 53),
    WeightCategory.cadetsUnder61 => (53, 61),
    WeightCategory.cadetsOver61 => (61, null),
    WeightCategory.juniorsUnder48 => (null, 48),
    WeightCategory.juniorsUnder55 => (48, 55),
    WeightCategory.juniorsUnder63 => (55, 63),
    WeightCategory.juniorsUnder73 => (63, 73),
    WeightCategory.juniorsOver73 => (73, null),
    WeightCategory.seniorsUnder58 => (null, 58),
    WeightCategory.seniorsUnder68 => (58, 68),
    WeightCategory.seniorsUnder80 => (68, 80),
    WeightCategory.seniorsHeavy => (80, null),
  };

  AgeGroup get ageGroup => switch (this) {
    WeightCategory.cubsUnder28 ||
    WeightCategory.cubsUnder32 ||
    WeightCategory.cubsUnder36 ||
    WeightCategory.cubsOver36 => AgeGroup.cubs,
    WeightCategory.cadetsUnder37 ||
    WeightCategory.cadetsUnder45 ||
    WeightCategory.cadetsUnder53 ||
    WeightCategory.cadetsUnder61 ||
    WeightCategory.cadetsOver61 => AgeGroup.cadets,
    WeightCategory.juniorsUnder48 ||
    WeightCategory.juniorsUnder55 ||
    WeightCategory.juniorsUnder63 ||
    WeightCategory.juniorsUnder73 ||
    WeightCategory.juniorsOver73 => AgeGroup.juniors,
    WeightCategory.seniorsUnder58 ||
    WeightCategory.seniorsUnder68 ||
    WeightCategory.seniorsUnder80 ||
    WeightCategory.seniorsHeavy => AgeGroup.seniors,
  };

  String get labelKey => 'weight.$name';

  String get shortLabel {
    final r = range;
    final lower = r.$1;
    final upper = r.$2;
    if (upper != null && lower == null) return '−${upper.toInt()}kg';
    if (lower != null && upper == null) return '+${lower.toInt()}kg';
    if (lower != null && upper != null) {
      return '${lower.toInt()}–${upper.toInt()}kg';
    }
    return name;
  }

  /// Closest matching category given an athlete's age group + weight.
  static WeightCategory? suggested(Athlete athlete) {
    final groupForCompetition = athlete.ageGroup == AgeGroup.kids
        ? AgeGroup.cubs
        : athlete.ageGroup;
    final weight = athlete.weightKg;
    for (final wc in WeightCategory.values) {
      if (wc.ageGroup != groupForCompetition) continue;
      final r = wc.range;
      final lowerOk = r.$1 == null || weight > r.$1!;
      final upperOk = r.$2 == null || weight <= r.$2!;
      if (lowerOk && upperOk) return wc;
    }
    return null;
  }

  static WeightCategory fromJson(String raw) =>
      WeightCategory.values.firstWhere(
        (e) => e.name == raw,
        orElse: () => WeightCategory.seniorsHeavy,
      );
}

enum HostingFederation {
  wtf,
  gcc,
  uae,
  clubInternal;

  String get labelKey => 'federation.$name';

  static HostingFederation fromJson(String raw) =>
      HostingFederation.values.firstWhere(
        (e) => e.name == raw,
        orElse: () => HostingFederation.clubInternal,
      );
}

/// Geographic / political reach of an event.
enum EventLevel {
  local,
  national,
  regional,
  international;

  String get labelKey => 'event_level.$name';

  /// Escalates with reach; used for level pills in the UI.
  int get rank => switch (this) {
    EventLevel.local => 1,
    EventLevel.national => 2,
    EventLevel.regional => 3,
    EventLevel.international => 4,
  };

  static EventLevel fromJson(String raw) => EventLevel.values.firstWhere(
    (e) => e.name == raw,
    orElse: () => EventLevel.local,
  );
}

class Tournament {
  final EntityID id;
  final String name;
  final String? nameAr;
  final HostingFederation hostingFederation;
  final DateTime startsAt;
  final DateTime endsAt;
  final String location;
  final String? locationAr;
  final bool isOfficial;
  final List<WeightCategory> weightCategoriesOffered;

  /// Reach — local / national / regional / international.
  final EventLevel? level;

  /// Free-form name of the sanctioning body when more granular than
  /// [hostingFederation].
  final String? sanctioningBody;

  const Tournament({
    required this.id,
    required this.name,
    this.nameAr,
    required this.hostingFederation,
    required this.startsAt,
    required this.endsAt,
    required this.location,
    this.locationAr,
    required this.isOfficial,
    this.weightCategoriesOffered = const [],
    this.level,
    this.sanctioningBody,
  });

  factory Tournament.create({
    EntityID? id,
    required String name,
    String? nameAr,
    required HostingFederation hostingFederation,
    required DateTime startsAt,
    required DateTime endsAt,
    required String location,
    String? locationAr,
    required bool isOfficial,
    List<WeightCategory> weightCategoriesOffered = const [],
    EventLevel? level,
    String? sanctioningBody,
  }) => Tournament(
    id: id ?? newEntityId(),
    name: name,
    nameAr: nameAr,
    hostingFederation: hostingFederation,
    startsAt: startsAt,
    endsAt: endsAt,
    location: location,
    locationAr: locationAr,
    isOfficial: isOfficial,
    weightCategoriesOffered: weightCategoriesOffered,
    level: level,
    sanctioningBody: sanctioningBody,
  );

  factory Tournament.fromJson(Map<String, dynamic> json) => Tournament(
    id: json['id'] as String,
    name: json['name'] as String,
    nameAr: json['nameAr'] as String?,
    hostingFederation: HostingFederation.fromJson(
      json['hostingFederation'] as String,
    ),
    startsAt: DateTime.parse(json['startsAt'] as String),
    endsAt: DateTime.parse(json['endsAt'] as String),
    location: json['location'] as String,
    locationAr: json['locationAr'] as String?,
    isOfficial: json['isOfficial'] as bool,
    weightCategoriesOffered: ((json['weightCategoriesOffered'] as List?) ?? [])
        .map((e) => WeightCategory.fromJson(e as String))
        .toList(),
    level: json['level'] != null
        ? EventLevel.fromJson(json['level'] as String)
        : null,
    sanctioningBody: json['sanctioningBody'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'nameAr': nameAr,
    'hostingFederation': hostingFederation.name,
    'startsAt': startsAt.toIso8601String(),
    'endsAt': endsAt.toIso8601String(),
    'location': location,
    'locationAr': locationAr,
    'isOfficial': isOfficial,
    'weightCategoriesOffered': weightCategoriesOffered
        .map((w) => w.name)
        .toList(),
    'level': level?.name,
    'sanctioningBody': sanctioningBody,
  };
}

enum RegistrationStatus {
  registered,
  weighedIn,
  withdrawn,
  disqualified;

  String get labelKey => 'registration.$name';

  static RegistrationStatus fromJson(String raw) =>
      RegistrationStatus.values.firstWhere(
        (e) => e.name == raw,
        orElse: () => RegistrationStatus.registered,
      );
}

class TournamentRegistration {
  final EntityID id;
  final EntityID tournamentId;
  final EntityID athleteId;
  final WeightCategory weightCategory;
  final int? seedRank;
  final DateTime registeredAt;
  final RegistrationStatus status;

  // === per-event result ===
  final AgeGroup? ageDivisionEntered;
  final int? bracketSize;
  final int? finalPosition;
  final MedalType? medal;

  TournamentRegistration({
    EntityID? id,
    required this.tournamentId,
    required this.athleteId,
    required this.weightCategory,
    this.seedRank,
    DateTime? registeredAt,
    this.status = RegistrationStatus.registered,
    this.ageDivisionEntered,
    this.bracketSize,
    this.finalPosition,
    this.medal,
  }) : id = id ?? newEntityId(),
       registeredAt = registeredAt ?? DateTime.now();

  factory TournamentRegistration.fromJson(Map<String, dynamic> json) =>
      TournamentRegistration(
        id: json['id'] as String,
        tournamentId: json['tournamentID'] as String,
        athleteId: json['athleteID'] as String,
        weightCategory: WeightCategory.fromJson(
          json['weightCategory'] as String,
        ),
        seedRank: json['seedRank'] as int?,
        registeredAt: DateTime.parse(json['registeredAt'] as String),
        status: RegistrationStatus.fromJson(
          json['status'] as String? ?? 'registered',
        ),
        ageDivisionEntered: json['ageDivisionEntered'] != null
            ? AgeGroup.fromJson(json['ageDivisionEntered'] as String)
            : null,
        bracketSize: json['bracketSize'] as int?,
        finalPosition: json['finalPosition'] as int?,
        medal: json['medal'] != null
            ? MedalType.fromJson(json['medal'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'tournamentID': tournamentId,
    'athleteID': athleteId,
    'weightCategory': weightCategory.name,
    'seedRank': seedRank,
    'registeredAt': registeredAt.toIso8601String(),
    'status': status.name,
    'ageDivisionEntered': ageDivisionEntered?.name,
    'bracketSize': bracketSize,
    'finalPosition': finalPosition,
    'medal': medal?.name,
  };
}

class WeightCutEntry {
  final EntityID id;
  final EntityID registrationId;
  final DateTime recordedAt;
  final double currentKg;
  final double targetKg;
  final String? notes;

  const WeightCutEntry({
    required this.id,
    required this.registrationId,
    required this.recordedAt,
    required this.currentKg,
    required this.targetKg,
    this.notes,
  });

  factory WeightCutEntry.create({
    EntityID? id,
    required EntityID registrationId,
    required DateTime recordedAt,
    required double currentKg,
    required double targetKg,
    String? notes,
  }) => WeightCutEntry(
    id: id ?? newEntityId(),
    registrationId: registrationId,
    recordedAt: recordedAt,
    currentKg: currentKg,
    targetKg: targetKg,
    notes: notes,
  );

  double get deltaKg => currentKg - targetKg;

  int daysToCompetition(DateTime competitionDate) {
    return competitionDate.difference(recordedAt).inDays;
  }

  factory WeightCutEntry.fromJson(Map<String, dynamic> json) => WeightCutEntry(
    id: json['id'] as String,
    registrationId: json['registrationID'] as String,
    recordedAt: DateTime.parse(json['recordedAt'] as String),
    currentKg: (json['currentKg'] as num).toDouble(),
    targetKg: (json['targetKg'] as num).toDouble(),
    notes: json['notes'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'registrationID': registrationId,
    'recordedAt': recordedAt.toIso8601String(),
    'currentKg': currentKg,
    'targetKg': targetKg,
    'notes': notes,
  };
}

class Bracket {
  final EntityID id;
  final EntityID tournamentId;
  final WeightCategory weightCategory;
  final List<EntityID> seeds;
  final DateTime generatedAt;

  const Bracket({
    required this.id,
    required this.tournamentId,
    required this.weightCategory,
    required this.seeds,
    required this.generatedAt,
  });

  factory Bracket.create({
    EntityID? id,
    required EntityID tournamentId,
    required WeightCategory weightCategory,
    required List<EntityID> seeds,
    DateTime? generatedAt,
  }) => Bracket(
    id: id ?? newEntityId(),
    tournamentId: tournamentId,
    weightCategory: weightCategory,
    seeds: seeds,
    generatedAt: generatedAt ?? DateTime.now(),
  );

  factory Bracket.fromJson(Map<String, dynamic> json) => Bracket(
    id: json['id'] as String,
    tournamentId: json['tournamentID'] as String,
    weightCategory: WeightCategory.fromJson(json['weightCategory'] as String),
    seeds: ((json['seeds'] as List?) ?? []).map((e) => e as String).toList(),
    generatedAt: DateTime.parse(json['generatedAt'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'tournamentID': tournamentId,
    'weightCategory': weightCategory.name,
    'seeds': seeds,
    'generatedAt': generatedAt.toIso8601String(),
  };
}

class BracketMatch {
  final EntityID id;
  final EntityID bracketId;
  final int round;
  final int position;
  final EntityID? athleteAId;
  final EntityID? athleteBId;
  final EntityID? winnerId;
  final EntityID? matchId;

  const BracketMatch({
    required this.id,
    required this.bracketId,
    required this.round,
    required this.position,
    this.athleteAId,
    this.athleteBId,
    this.winnerId,
    this.matchId,
  });

  factory BracketMatch.create({
    EntityID? id,
    required EntityID bracketId,
    required int round,
    required int position,
    EntityID? athleteAId,
    EntityID? athleteBId,
    EntityID? winnerId,
    EntityID? matchId,
  }) => BracketMatch(
    id: id ?? newEntityId(),
    bracketId: bracketId,
    round: round,
    position: position,
    athleteAId: athleteAId,
    athleteBId: athleteBId,
    winnerId: winnerId,
    matchId: matchId,
  );

  factory BracketMatch.fromJson(Map<String, dynamic> json) => BracketMatch(
    id: json['id'] as String,
    bracketId: json['bracketID'] as String,
    round: json['round'] as int,
    position: json['position'] as int,
    athleteAId: json['athleteAID'] as String?,
    athleteBId: json['athleteBID'] as String?,
    winnerId: json['winnerID'] as String?,
    matchId: json['matchID'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'bracketID': bracketId,
    'round': round,
    'position': position,
    'athleteAID': athleteAId,
    'athleteBID': athleteBId,
    'winnerID': winnerId,
    'matchID': matchId,
  };
}
