import 'entity_id.dart';

// Port of Core/Models/CoachingDevelopment.swift (Stage 1.15).
//
// SSDC's coaching structure is a *sports development pathway*, not a corporate
// hierarchy. An Assistant Coach is NOT a standalone staff entity — it is an
// active `Athlete` who additionally carries a coaching dossier. The duality is
// expressed entirely on `Athlete`:
//
//   athlete.programRoles.contains(ProgramRole.assistantCoach)  // wears the coaching hat
//   athlete.assistantCoach                                      // the coaching dossier
//
// Pure data only — no Flutter imports (logic-layer rule).
// Colour tints live in the UX layer (features/coaching/coaching_kit.dart).

// MARK: - Program roles

/// A program membership an athlete holds *in addition* to being an athlete.
/// Rendered as pastel chips in the athlete profile's Roles section. One user
/// can hold several at once — this is the multi-role pathway.
enum ProgramRole {
  athlete,
  assistantCoach,
  competitionTeam,
  eliteSquad,
  demoTeam;

  String get labelKey => 'programRole.$name';

  String get systemIcon => switch (this) {
    ProgramRole.athlete => 'figure.run',
    ProgramRole.assistantCoach => 'figure.taekwondo',
    ProgramRole.competitionTeam => 'flame.fill',
    ProgramRole.eliteSquad => 'star.circle.fill',
    ProgramRole.demoTeam => 'sparkles',
  };

  static ProgramRole fromJson(String raw) => ProgramRole.values.firstWhere(
    (r) => r.name == raw,
    orElse: () => ProgramRole.athlete,
  );

  /// Stable display order for chip rows — independent of `Set` iteration.
  /// Mirrors Swift's `ProgramRole.ordered(_:)`.
  static List<ProgramRole> ordered(Set<ProgramRole> roles) =>
      ProgramRole.values.where((r) => roles.contains(r)).toList();
}

// MARK: - Coaching permissions

/// A discrete action in the coaching workflow. Assistant coaches hold a
/// *subset* — the senior-coach actions in [restricted] are never granted at
/// this development tier.
enum CoachingPermission {
  // Allowed at the assistant-coach tier.
  takeAttendance,
  assistWarmUp,
  assistDrills,
  supportCompetitions,
  monitorKidsGroups,
  uploadSessionNotes,
  assistDuringClasses,
  // Restricted — senior-coach / management only.
  approveGrading,
  suspendAthlete,
  manageBranch,
  evaluateCoaches,
  systemAdministration;

  String get labelKey => 'coachingPermission.$name';

  String get systemIcon => switch (this) {
    CoachingPermission.takeAttendance => 'checklist',
    CoachingPermission.assistWarmUp => 'figure.cooldown',
    CoachingPermission.assistDrills => 'list.bullet.clipboard',
    CoachingPermission.supportCompetitions => 'trophy.fill',
    CoachingPermission.monitorKidsGroups => 'figure.2.and.child.holdinghands',
    CoachingPermission.uploadSessionNotes => 'square.and.pencil',
    CoachingPermission.assistDuringClasses => 'person.2.fill',
    CoachingPermission.approveGrading => 'medal.fill',
    CoachingPermission.suspendAthlete => 'nosign',
    CoachingPermission.manageBranch => 'building.2.fill',
    CoachingPermission.evaluateCoaches => 'person.crop.circle.badge.checkmark',
    CoachingPermission.systemAdministration => 'gearshape.fill',
  };

  /// Actions an assistant coach is allowed to be granted.
  static const List<CoachingPermission> assistantCoachGrantable = [
    CoachingPermission.takeAttendance,
    CoachingPermission.assistWarmUp,
    CoachingPermission.assistDrills,
    CoachingPermission.supportCompetitions,
    CoachingPermission.monitorKidsGroups,
    CoachingPermission.uploadSessionNotes,
    CoachingPermission.assistDuringClasses,
  ];

  /// Senior-coach / management actions an assistant coach can never hold.
  static const List<CoachingPermission> restricted = [
    CoachingPermission.approveGrading,
    CoachingPermission.suspendAthlete,
    CoachingPermission.manageBranch,
    CoachingPermission.evaluateCoaches,
    CoachingPermission.systemAdministration,
  ];

  bool get isRestricted => restricted.contains(this);

  static CoachingPermission fromJson(String raw) =>
      CoachingPermission.values.firstWhere(
        (c) => c.name == raw,
        orElse: () => CoachingPermission.takeAttendance,
      );
}

// MARK: - Development pipeline

/// A stage in the coaching-development pipeline. The pathway runs
/// athlete → assistantCoach → juniorCoach → coach → headCoach → technicalDirector.
enum DevelopmentLevel {
  athlete,
  assistantCoach,
  juniorCoach,
  coach,
  headCoach,
  technicalDirector;

  String get labelKey => 'developmentLevel.$name';

  String get systemIcon => switch (this) {
    DevelopmentLevel.athlete => 'figure.run',
    DevelopmentLevel.assistantCoach => 'hand.raised.fill',
    DevelopmentLevel.juniorCoach => 'figure.taekwondo',
    DevelopmentLevel.coach => 'figure.martial.arts',
    DevelopmentLevel.headCoach => 'star.fill',
    DevelopmentLevel.technicalDirector => 'checkmark.seal.fill',
  };

  /// 0-based position along the pipeline.
  int get stageIndex => DevelopmentLevel.values.indexOf(this);

  /// The next rung up the pathway, or null at the top.
  DevelopmentLevel? get next {
    final all = DevelopmentLevel.values;
    final i = all.indexOf(this);
    if (i < 0 || i + 1 >= all.length) return null;
    return all[i + 1];
  }

  static DevelopmentLevel fromJson(String raw) => DevelopmentLevel.values
      .firstWhere((d) => d.name == raw, orElse: () => DevelopmentLevel.athlete);
}

// MARK: - Coaching evaluation

/// A coaching evaluation recorded by a supervising coach for an assistant
/// coach. Scores are 1...5.
class CoachingEvaluation {
  final EntityID id;
  final DateTime date;
  final EntityID? evaluatorCoachId;
  final String evaluatorName;

  /// 1...5 — overall coaching performance.
  final int overallScore;

  /// 1...5 — reliability and dependability running sessions.
  final int reliability;

  /// 1...5 — leadership, communication, and rapport with athletes.
  final int leadership;
  final String notes;

  const CoachingEvaluation({
    required this.id,
    required this.date,
    this.evaluatorCoachId,
    required this.evaluatorName,
    required this.overallScore,
    required this.reliability,
    required this.leadership,
    this.notes = '',
  });

  factory CoachingEvaluation.create({
    EntityID? id,
    DateTime? date,
    EntityID? evaluatorCoachId,
    required String evaluatorName,
    required int overallScore,
    required int reliability,
    required int leadership,
    String notes = '',
  }) => CoachingEvaluation(
    id: id ?? newEntityId(),
    date: date ?? DateTime.now(),
    evaluatorCoachId: evaluatorCoachId,
    evaluatorName: evaluatorName,
    overallScore: overallScore.clamp(1, 5),
    reliability: reliability.clamp(1, 5),
    leadership: leadership.clamp(1, 5),
    notes: notes,
  );

  factory CoachingEvaluation.fromJson(Map<String, dynamic> json) =>
      CoachingEvaluation(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        evaluatorCoachId: json['evaluatorCoachID'] as String?,
        evaluatorName: json['evaluatorName'] as String,
        overallScore: (json['overallScore'] as int).clamp(1, 5),
        reliability: (json['reliability'] as int).clamp(1, 5),
        leadership: (json['leadership'] as int).clamp(1, 5),
        notes: json['notes'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'evaluatorCoachID': evaluatorCoachId,
    'evaluatorName': evaluatorName,
    'overallScore': overallScore,
    'reliability': reliability,
    'leadership': leadership,
    'notes': notes,
  };
}

// MARK: - Assistant-coach dossier

/// Coaching dossier embedded on an `Athlete` who also serves as an assistant
/// coach. Its presence — together with [ProgramRole.assistantCoach] in
/// `programRoles` — is what makes the athlete an assistant coach.
class AssistantCoachProfile {
  /// The senior coach mentoring this assistant coach.
  final EntityID? supervisingCoachId;

  /// Branch where the assistant coach principally helps.
  final EntityID primaryBranchId;

  /// Branches the assistant coach additionally supports.
  final List<EntityID> supportBranchIds;

  /// The coaching actions this assistant coach is cleared to perform.
  /// Restricted actions are automatically filtered out on construction.
  final Set<CoachingPermission> permissions;

  /// Current rung on the coaching-development pipeline.
  final DevelopmentLevel developmentLevel;

  /// Date the athlete began their coaching pathway.
  final DateTime startedCoachingAt;

  /// Sessions the assistant coach has helped run.
  final int assistedSessionCount;

  /// Coaching evaluations from supervising coaches — newest first by convention.
  final List<CoachingEvaluation> evaluations;

  AssistantCoachProfile({
    this.supervisingCoachId,
    required this.primaryBranchId,
    this.supportBranchIds = const [],
    Set<CoachingPermission>? permissions,
    this.developmentLevel = DevelopmentLevel.assistantCoach,
    required this.startedCoachingAt,
    int assistedSessionCount = 0,
    this.evaluations = const [],
  }) : permissions =
           (permissions ?? CoachingPermission.assistantCoachGrantable.toSet())
               .where((p) => !p.isRestricted)
               .toSet(),
       assistedSessionCount = assistedSessionCount < 0
           ? 0
           : assistedSessionCount;

  /// Mean overall evaluation score, 0...5. Null when never evaluated.
  double? get coachEvaluationScore {
    if (evaluations.isEmpty) return null;
    final total = evaluations.fold(0, (sum, e) => sum + e.overallScore);
    return total / evaluations.length;
  }

  /// Mean reliability score, 0...5. Null when never evaluated.
  double? get reliabilityScore {
    if (evaluations.isEmpty) return null;
    final total = evaluations.fold(0, (sum, e) => sum + e.reliability);
    return total / evaluations.length;
  }

  /// Mean leadership score, 0...5. Null when never evaluated.
  double? get leadershipScore {
    if (evaluations.isEmpty) return null;
    final total = evaluations.fold(0, (sum, e) => sum + e.leadership);
    return total / evaluations.length;
  }

  /// Whole months the athlete has been on the coaching pathway.
  int get monthsCoaching {
    final now = DateTime.now();
    return (now.year - startedCoachingAt.year) * 12 +
        (now.month - startedCoachingAt.month);
  }

  /// 0...1 readiness for promotion to the next development level. Blends the
  /// evaluation score (50%), assisted-session volume (30%), and how broad
  /// the granted permission set is (20%). Deterministic — no analytics table.
  double get promotionReadiness {
    final evalComponent = ((coachEvaluationScore ?? 0) / 5.0) * 0.5;
    final sessionComponent =
        (assistedSessionCount / 120.0).clamp(0.0, 1.0) * 0.3;
    final grantable = CoachingPermission.assistantCoachGrantable.length
        .toDouble();
    final permissionComponent =
        (grantable > 0 ? permissions.length / grantable : 0.0) * 0.2;
    return (evalComponent + sessionComponent + permissionComponent).clamp(
      0.0,
      1.0,
    );
  }

  factory AssistantCoachProfile.fromJson(Map<String, dynamic> json) =>
      AssistantCoachProfile(
        supervisingCoachId: json['supervisingCoachID'] as String?,
        primaryBranchId: json['primaryBranchID'] as String,
        supportBranchIds: ((json['supportBranchIDs'] as List?) ?? [])
            .cast<String>(),
        permissions: ((json['permissions'] as List?) ?? [])
            .cast<String>()
            .map(CoachingPermission.fromJson)
            .toSet(),
        developmentLevel: DevelopmentLevel.fromJson(
          json['developmentLevel'] as String? ?? 'assistantCoach',
        ),
        startedCoachingAt: DateTime.parse(json['startedCoachingAt'] as String),
        assistedSessionCount: json['assistedSessionCount'] as int? ?? 0,
        evaluations: ((json['evaluations'] as List?) ?? [])
            .map((e) => CoachingEvaluation.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
    'supervisingCoachID': supervisingCoachId,
    'primaryBranchID': primaryBranchId,
    'supportBranchIDs': supportBranchIds,
    'permissions': permissions.map((p) => p.name).toList(),
    'developmentLevel': developmentLevel.name,
    'startedCoachingAt': startedCoachingAt.toIso8601String(),
    'assistedSessionCount': assistedSessionCount,
    'evaluations': evaluations.map((e) => e.toJson()).toList(),
  };
}
