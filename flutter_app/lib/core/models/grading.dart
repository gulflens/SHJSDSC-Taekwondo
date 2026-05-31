// Port of Core/Models/Grading.swift.
// Pure data — no Flutter imports (logic-layer rule).

import 'belt.dart';
import 'entity_id.dart';

class GradingEligibility {
  final EntityID athleteId;
  final Belt currentBelt;
  final Belt targetBelt;
  final int monthsAtCurrent;
  final double attendancePct;
  final double latestTechnicalAvg;
  final double latestPhysicalComposite;
  final bool isEligible;
  final List<String> blockingReasons;

  const GradingEligibility({
    required this.athleteId,
    required this.currentBelt,
    required this.targetBelt,
    required this.monthsAtCurrent,
    required this.attendancePct,
    required this.latestTechnicalAvg,
    required this.latestPhysicalComposite,
    required this.isEligible,
    required this.blockingReasons,
  });

  factory GradingEligibility.fromJson(Map<String, dynamic> json) =>
      GradingEligibility(
        athleteId: json['athleteID'] as String,
        currentBelt: Belt.fromJson(json['currentBelt'] as Map<String, dynamic>),
        targetBelt: Belt.fromJson(json['targetBelt'] as Map<String, dynamic>),
        monthsAtCurrent: json['monthsAtCurrent'] as int,
        attendancePct: (json['attendancePct'] as num).toDouble(),
        latestTechnicalAvg: (json['latestTechnicalAvg'] as num).toDouble(),
        latestPhysicalComposite: (json['latestPhysicalComposite'] as num)
            .toDouble(),
        isEligible: json['isEligible'] as bool,
        blockingReasons: ((json['blockingReasons'] as List?) ?? [])
            .map((e) => e as String)
            .toList(),
      );

  Map<String, dynamic> toJson() => {
    'athleteID': athleteId,
    'currentBelt': currentBelt.toJson(),
    'targetBelt': targetBelt.toJson(),
    'monthsAtCurrent': monthsAtCurrent,
    'attendancePct': attendancePct,
    'latestTechnicalAvg': latestTechnicalAvg,
    'latestPhysicalComposite': latestPhysicalComposite,
    'isEligible': isEligible,
    'blockingReasons': blockingReasons,
  };
}

enum GradingSessionStatus {
  scheduled,
  inProgress,
  completed,
  cancelled;

  String get labelKey => 'grading.status.$name';

  static GradingSessionStatus fromJson(String raw) =>
      GradingSessionStatus.values.firstWhere(
        (e) => e.name == raw,
        orElse: () => GradingSessionStatus.scheduled,
      );
}

class GradingSession {
  final EntityID id;
  final DateTime scheduledAt;
  final EntityID branchId;
  final List<EntityID> examinerCoachIds;
  final List<EntityID> candidateAthleteIds;
  final GradingSessionStatus status;

  const GradingSession({
    required this.id,
    required this.scheduledAt,
    required this.branchId,
    required this.examinerCoachIds,
    required this.candidateAthleteIds,
    this.status = GradingSessionStatus.scheduled,
  });

  factory GradingSession.fromJson(Map<String, dynamic> json) => GradingSession(
    id: json['id'] as String,
    scheduledAt: DateTime.parse(json['scheduledAt'] as String),
    branchId: json['branchID'] as String,
    examinerCoachIds: ((json['examinerCoachIDs'] as List?) ?? [])
        .map((e) => e as String)
        .toList(),
    candidateAthleteIds: ((json['candidateAthleteIDs'] as List?) ?? [])
        .map((e) => e as String)
        .toList(),
    status: GradingSessionStatus.fromJson(
      json['status'] as String? ?? 'scheduled',
    ),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'scheduledAt': scheduledAt.toIso8601String(),
    'branchID': branchId,
    'examinerCoachIDs': examinerCoachIds,
    'candidateAthleteIDs': candidateAthleteIds,
    'status': status.name,
  };
}

enum GradingDecision {
  pass,
  fail,
  retry;

  String get labelKey => 'grading.decision.$name';

  static GradingDecision fromJson(String raw) => GradingDecision.values
      .firstWhere((e) => e.name == raw, orElse: () => GradingDecision.retry);
}

class GradingScore {
  final EntityID id;
  final EntityID sessionId;
  final EntityID athleteId;
  final EntityID examinerId;
  final int poomsae;
  final int kyorugi;
  final int kibon;
  final int breaking;
  final String? notes;
  final GradingDecision decision;

  const GradingScore({
    required this.id,
    required this.sessionId,
    required this.athleteId,
    required this.examinerId,
    required this.poomsae,
    required this.kyorugi,
    required this.kibon,
    required this.breaking,
    this.notes,
    required this.decision,
  });

  int get total => poomsae + kyorugi + kibon + breaking;

  factory GradingScore.fromJson(Map<String, dynamic> json) => GradingScore(
    id: json['id'] as String,
    sessionId: json['sessionID'] as String,
    athleteId: json['athleteID'] as String,
    examinerId: json['examinerID'] as String,
    poomsae: json['poomsae'] as int,
    kyorugi: json['kyorugi'] as int,
    kibon: json['kibon'] as int,
    breaking: json['breaking'] as int,
    notes: json['notes'] as String?,
    decision: GradingDecision.fromJson(json['decision'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'sessionID': sessionId,
    'athleteID': athleteId,
    'examinerID': examinerId,
    'poomsae': poomsae,
    'kyorugi': kyorugi,
    'kibon': kibon,
    'breaking': breaking,
    'notes': notes,
    'decision': decision.name,
  };
}

class GradingCertificate {
  final EntityID id;
  final EntityID athleteId;
  final Belt fromBelt;
  final Belt toBelt;
  final DateTime awardedAt;
  final EntityID sessionId;
  final List<EntityID> signedByCoachIds;

  const GradingCertificate({
    required this.id,
    required this.athleteId,
    required this.fromBelt,
    required this.toBelt,
    required this.awardedAt,
    required this.sessionId,
    required this.signedByCoachIds,
  });

  factory GradingCertificate.fromJson(Map<String, dynamic> json) =>
      GradingCertificate(
        id: json['id'] as String,
        athleteId: json['athleteID'] as String,
        fromBelt: Belt.fromJson(json['fromBelt'] as Map<String, dynamic>),
        toBelt: Belt.fromJson(json['toBelt'] as Map<String, dynamic>),
        awardedAt: DateTime.parse(json['awardedAt'] as String),
        sessionId: json['sessionID'] as String,
        signedByCoachIds: ((json['signedByCoachIDs'] as List?) ?? [])
            .map((e) => e as String)
            .toList(),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'athleteID': athleteId,
    'fromBelt': fromBelt.toJson(),
    'toBelt': toBelt.toJson(),
    'awardedAt': awardedAt.toIso8601String(),
    'sessionID': sessionId,
    'signedByCoachIDs': signedByCoachIds,
  };
}
