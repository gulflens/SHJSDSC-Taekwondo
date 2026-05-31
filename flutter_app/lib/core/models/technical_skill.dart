import 'entity_id.dart';

/// Port of Core/Models/TechnicalSkill.swift.

enum TechniqueCategory {
  basicKicks,
  spinningJumpingKicks,
  handTechniques,
  footwork,
  defensive;

  String get labelKey => 'technique_category.$name';

  String get systemIcon => switch (this) {
    TechniqueCategory.basicKicks => 'figure.kickboxing',
    TechniqueCategory.spinningJumpingKicks => 'arrow.triangle.2.circlepath',
    TechniqueCategory.handTechniques => 'hand.raised.fill',
    TechniqueCategory.footwork => 'shoe.fill',
    TechniqueCategory.defensive => 'shield.fill',
  };
}

enum TechniqueKind {
  // Basic kicks (9)
  frontKick,
  roundhouseBack,
  roundhouseFront,
  sideKick,
  backKick,
  axeKick,
  hookKick,
  pushKick,
  crescentKick,

  // Spinning / jumping kicks (8)
  spinningHookKick,
  spinningBackKick,
  tornadoKick,
  jumpingBackKick,
  jumpingRoundhouse,
  scissorKick,
  twimyoDollyo,
  kick540,

  // Hand techniques (4)
  jabPunch,
  crossPunch,
  backFistStrike,
  knifeHandStrike,

  // Footwork (6)
  switchStep,
  slideStep,
  pushStep,
  cutStep,
  pivot,
  skipStep,

  // Defensive (6)
  blockHigh,
  blockMiddle,
  blockLow,
  parry,
  evasionLeanBack,
  clinchAndBreak;

  String get labelKey => 'technique.$name';

  TechniqueCategory get category => switch (this) {
    TechniqueKind.frontKick ||
    TechniqueKind.roundhouseBack ||
    TechniqueKind.roundhouseFront ||
    TechniqueKind.sideKick ||
    TechniqueKind.backKick ||
    TechniqueKind.axeKick ||
    TechniqueKind.hookKick ||
    TechniqueKind.pushKick ||
    TechniqueKind.crescentKick => TechniqueCategory.basicKicks,
    TechniqueKind.spinningHookKick ||
    TechniqueKind.spinningBackKick ||
    TechniqueKind.tornadoKick ||
    TechniqueKind.jumpingBackKick ||
    TechniqueKind.jumpingRoundhouse ||
    TechniqueKind.scissorKick ||
    TechniqueKind.twimyoDollyo ||
    TechniqueKind.kick540 => TechniqueCategory.spinningJumpingKicks,
    TechniqueKind.jabPunch ||
    TechniqueKind.crossPunch ||
    TechniqueKind.backFistStrike ||
    TechniqueKind.knifeHandStrike => TechniqueCategory.handTechniques,
    TechniqueKind.switchStep ||
    TechniqueKind.slideStep ||
    TechniqueKind.pushStep ||
    TechniqueKind.cutStep ||
    TechniqueKind.pivot ||
    TechniqueKind.skipStep => TechniqueCategory.footwork,
    TechniqueKind.blockHigh ||
    TechniqueKind.blockMiddle ||
    TechniqueKind.blockLow ||
    TechniqueKind.parry ||
    TechniqueKind.evasionLeanBack ||
    TechniqueKind.clinchAndBreak => TechniqueCategory.defensive,
  };

  static TechniqueKind fromJson(String raw) => TechniqueKind.values.firstWhere(
    (e) => e.name == raw,
    orElse: () => TechniqueKind.frontKick,
  );
}

class TechnicalSkill {
  final EntityID id;
  final EntityID athleteId;
  final DateTime recordedAt;
  final EntityID recordedByCoachId;
  final TechniqueKind kind;

  /// 1…10 — how cleanly the technique is executed in isolation.
  final int formScore;

  /// 1…10 — how effectively the technique is used in sparring/scenarios.
  final int applicationScore;

  final String? videoUrl;
  final String? notes;

  TechnicalSkill({
    EntityID? id,
    required this.athleteId,
    required this.recordedAt,
    required this.recordedByCoachId,
    required this.kind,
    required int formScore,
    required int applicationScore,
    this.videoUrl,
    this.notes,
  }) : id = id ?? newEntityId(),
       formScore = formScore.clamp(1, 10),
       applicationScore = applicationScore.clamp(1, 10);

  /// Mean of form + application, 1…10.
  double get averageScore => (formScore + applicationScore) / 2.0;

  factory TechnicalSkill.fromJson(Map<String, dynamic> json) => TechnicalSkill(
    id: json['id'] as String,
    athleteId: json['athleteID'] as String,
    recordedAt: DateTime.parse(json['recordedAt'] as String),
    recordedByCoachId: json['recordedByCoachID'] as String,
    kind: TechniqueKind.fromJson(json['kind'] as String),
    formScore: json['formScore'] as int,
    applicationScore: json['applicationScore'] as int,
    videoUrl: json['videoURL'] as String?,
    notes: json['notes'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'athleteID': athleteId,
    'recordedAt': recordedAt.toIso8601String(),
    'recordedByCoachID': recordedByCoachId,
    'kind': kind.name,
    'formScore': formScore,
    'applicationScore': applicationScore,
    'videoURL': videoUrl,
    'notes': notes,
  };
}

extension TechnicalSkillListExt on List<TechnicalSkill> {
  /// Latest skill capture per kind. Drives the dashboard "current scores".
  List<TechnicalSkill> latestPerKind() {
    final seen = <TechniqueKind, TechnicalSkill>{};
    final sorted = [...this]
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    for (final s in sorted) {
      seen.putIfAbsent(s.kind, () => s);
    }
    return seen.values.toList();
  }

  /// Average of (form+app)/2 across the latest capture of each assessed kind.
  /// Returns 0 when no skills have been captured.
  double get latestAverageScore {
    final latest = latestPerKind();
    if (latest.isEmpty) return 0;
    final sum = latest.fold<double>(0, (acc, s) => acc + s.averageScore);
    return sum / latest.length;
  }
}
