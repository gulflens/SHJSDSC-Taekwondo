import 'entity_id.dart';

/// Port of Core/Models/Performance.swift — everything EXCEPT PerformanceScore,
/// which already lives in performance_score.dart.

enum MatchSide {
  chung,
  hong;

  static MatchSide fromJson(String raw) => MatchSide.values.firstWhere(
    (e) => e.name == raw,
    orElse: () => MatchSide.chung,
  );
}

enum ScoreAction {
  headKick,
  bodyKick,
  turnBodyKick,
  turnHeadKick,
  punch,
  penalty;

  int get points => switch (this) {
    ScoreAction.headKick => 3,
    ScoreAction.bodyKick => 2,
    ScoreAction.turnBodyKick => 4,
    ScoreAction.turnHeadKick => 5,
    ScoreAction.punch => 1,
    ScoreAction.penalty => 1,
  };

  String get labelKey => 'score.$name';

  static ScoreAction fromJson(String raw) => ScoreAction.values.firstWhere(
    (e) => e.name == raw,
    orElse: () => ScoreAction.punch,
  );
}

class ScoreEvent {
  final EntityID id;
  final EntityID matchId;
  final int round;
  final int atSecond;
  final MatchSide side;
  final ScoreAction action;

  const ScoreEvent({
    required this.id,
    required this.matchId,
    required this.round,
    required this.atSecond,
    required this.side,
    required this.action,
  });

  factory ScoreEvent.create({
    EntityID? id,
    required EntityID matchId,
    required int round,
    required int atSecond,
    required MatchSide side,
    required ScoreAction action,
  }) => ScoreEvent(
    id: id ?? newEntityId(),
    matchId: matchId,
    round: round,
    atSecond: atSecond,
    side: side,
    action: action,
  );

  factory ScoreEvent.fromJson(Map<String, dynamic> json) => ScoreEvent(
    id: json['id'] as String,
    matchId: json['matchID'] as String,
    round: json['round'] as int,
    atSecond: json['atSecond'] as int,
    side: MatchSide.fromJson(json['side'] as String),
    action: ScoreAction.fromJson(json['action'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'matchID': matchId,
    'round': round,
    'atSecond': atSecond,
    'side': side.name,
    'action': action.name,
  };
}

enum MedalType {
  gold,
  silver,
  bronze,
  none;

  String get labelKey => 'medal.$name';

  static MedalType fromJson(String raw) => MedalType.values.firstWhere(
    (e) => e.name == raw,
    orElse: () => MedalType.none,
  );
}

enum SparringContext {
  training,
  friendly,
  competition;

  String get labelKey => 'sparring.context.$name';

  static SparringContext fromJson(String raw) =>
      SparringContext.values.firstWhere(
        (e) => e.name == raw,
        orElse: () => SparringContext.competition,
      );
}

enum MatchType {
  bestOf3,
  bestOf5,
  goldenPoint,
  single;

  String get labelKey => 'match_type.$name';

  static MatchType fromJson(String raw) => MatchType.values.firstWhere(
    (e) => e.name == raw,
    orElse: () => MatchType.bestOf3,
  );
}

enum WinMethod {
  points,
  knockout,
  refereeStop,
  disqualification,
  withdrawal;

  String get labelKey => 'win_method.$name';

  static WinMethod fromJson(String raw) => WinMethod.values.firstWhere(
    (e) => e.name == raw,
    orElse: () => WinMethod.points,
  );
}

enum MatchOutcome {
  win,
  loss,
  draw;

  String get labelKey => 'match_outcome.$name';

  static MatchOutcome fromJson(String raw) => MatchOutcome.values.firstWhere(
    (e) => e.name == raw,
    orElse: () => MatchOutcome.loss,
  );
}

class Match {
  // === Identity ===
  final EntityID id;
  final String tournamentName;
  final EntityID? tournamentId;
  final DateTime date;
  final EntityID ourAthleteId;
  final EntityID? opponentAthleteId;
  final String? opponentName;
  final double weightClassKg;
  final int rounds;
  final int ourScore;
  final int opponentScore;
  final bool won;
  final MedalType medal;
  final List<ScoreEvent> events;

  // === Sparring metadata ===
  final SparringContext context;
  final MatchType? matchType;
  final WinMethod? winMethod;
  final MatchOutcome? outcome;
  final int? roundsWon;
  final int? roundsLost;

  // === Aggregate counts ===
  final int? kicksAttempted;
  final int? kicksLanded;
  final int? punchesAttempted;
  final int? punchesLanded;

  // === Points scored by technique ===
  final int? ourPunchPoints;
  final int? ourBodyKickPoints;
  final int? ourHeadKickPoints;
  final int? ourSpinningBodyPoints;
  final int? ourSpinningHeadPoints;

  // === Points conceded, same breakdown ===
  final int? oppPunchPoints;
  final int? oppBodyKickPoints;
  final int? oppHeadKickPoints;
  final int? oppSpinningBodyPoints;
  final int? oppSpinningHeadPoints;

  // === Discipline ===
  final int? penaltiesGiven;
  final int? penaltiesReceived;
  final int? knockdownsScored;
  final int? knockdownsReceived;

  // === Tactical ===
  final int? leadLegKicks;
  final int? backLegKicks;
  final int? openingAttacks;
  final int? counterAttacks;
  final List<String>? topTechniques;
  final String? combinations;
  final int? offenceSeconds;
  final int? defenceSeconds;
  final int? ringControlRating;
  final int? composureRating;
  final int? scoreManagementRating;
  final String? coachNotes;

  // === Pillar 5: post-competition mental review ===
  final int? preMatchNerves;
  final int? interRoundRecovery;
  final int? responseToLosingPoint;
  final int? responseToWinningPoint;

  const Match({
    required this.id,
    required this.tournamentName,
    this.tournamentId,
    required this.date,
    required this.ourAthleteId,
    this.opponentAthleteId,
    this.opponentName,
    required this.weightClassKg,
    this.rounds = 3,
    required this.ourScore,
    required this.opponentScore,
    required this.won,
    required this.medal,
    this.events = const [],
    this.context = SparringContext.competition,
    this.matchType,
    this.winMethod,
    this.outcome,
    this.roundsWon,
    this.roundsLost,
    this.kicksAttempted,
    this.kicksLanded,
    this.punchesAttempted,
    this.punchesLanded,
    this.ourPunchPoints,
    this.ourBodyKickPoints,
    this.ourHeadKickPoints,
    this.ourSpinningBodyPoints,
    this.ourSpinningHeadPoints,
    this.oppPunchPoints,
    this.oppBodyKickPoints,
    this.oppHeadKickPoints,
    this.oppSpinningBodyPoints,
    this.oppSpinningHeadPoints,
    this.penaltiesGiven,
    this.penaltiesReceived,
    this.knockdownsScored,
    this.knockdownsReceived,
    this.leadLegKicks,
    this.backLegKicks,
    this.openingAttacks,
    this.counterAttacks,
    this.topTechniques,
    this.combinations,
    this.offenceSeconds,
    this.defenceSeconds,
    this.ringControlRating,
    this.composureRating,
    this.scoreManagementRating,
    this.coachNotes,
    this.preMatchNerves,
    this.interRoundRecovery,
    this.responseToLosingPoint,
    this.responseToWinningPoint,
  });

  // === Derived helpers ===

  MatchOutcome get effectiveOutcome =>
      outcome ?? (won ? MatchOutcome.win : MatchOutcome.loss);

  /// 0…100, null if attempted is missing or zero.
  double? get kickAccuracy {
    final attempted = kicksAttempted;
    final landed = kicksLanded;
    if (attempted == null || attempted == 0 || landed == null) return null;
    return landed / attempted * 100;
  }

  double? get punchAccuracy {
    final attempted = punchesAttempted;
    final landed = punchesLanded;
    if (attempted == null || attempted == 0 || landed == null) return null;
    return landed / attempted * 100;
  }

  bool get hasDetailedSparringData =>
      kicksAttempted != null ||
      punchesAttempted != null ||
      ourPunchPoints != null ||
      ourBodyKickPoints != null ||
      ourHeadKickPoints != null ||
      ourSpinningBodyPoints != null ||
      ourSpinningHeadPoints != null ||
      ringControlRating != null ||
      composureRating != null ||
      scoreManagementRating != null ||
      (topTechniques?.isNotEmpty ?? false);

  factory Match.fromJson(Map<String, dynamic> json) => Match(
    id: json['id'] as String,
    tournamentName: json['tournamentName'] as String,
    tournamentId: json['tournamentID'] as String?,
    date: DateTime.parse(json['date'] as String),
    ourAthleteId: json['ourAthleteID'] as String,
    opponentAthleteId: json['opponentAthleteID'] as String?,
    opponentName: json['opponentName'] as String?,
    weightClassKg: (json['weightClassKg'] as num).toDouble(),
    rounds: json['rounds'] as int? ?? 3,
    ourScore: json['ourScore'] as int,
    opponentScore: json['opponentScore'] as int,
    won: json['won'] as bool,
    medal: MedalType.fromJson(json['medal'] as String),
    events: ((json['events'] as List?) ?? [])
        .map((e) => ScoreEvent.fromJson(e as Map<String, dynamic>))
        .toList(),
    context: SparringContext.fromJson(
      json['context'] as String? ?? 'competition',
    ),
    matchType: json['matchType'] != null
        ? MatchType.fromJson(json['matchType'] as String)
        : null,
    winMethod: json['winMethod'] != null
        ? WinMethod.fromJson(json['winMethod'] as String)
        : null,
    outcome: json['outcome'] != null
        ? MatchOutcome.fromJson(json['outcome'] as String)
        : null,
    roundsWon: json['roundsWon'] as int?,
    roundsLost: json['roundsLost'] as int?,
    kicksAttempted: json['kicksAttempted'] as int?,
    kicksLanded: json['kicksLanded'] as int?,
    punchesAttempted: json['punchesAttempted'] as int?,
    punchesLanded: json['punchesLanded'] as int?,
    ourPunchPoints: json['ourPunchPoints'] as int?,
    ourBodyKickPoints: json['ourBodyKickPoints'] as int?,
    ourHeadKickPoints: json['ourHeadKickPoints'] as int?,
    ourSpinningBodyPoints: json['ourSpinningBodyPoints'] as int?,
    ourSpinningHeadPoints: json['ourSpinningHeadPoints'] as int?,
    oppPunchPoints: json['oppPunchPoints'] as int?,
    oppBodyKickPoints: json['oppBodyKickPoints'] as int?,
    oppHeadKickPoints: json['oppHeadKickPoints'] as int?,
    oppSpinningBodyPoints: json['oppSpinningBodyPoints'] as int?,
    oppSpinningHeadPoints: json['oppSpinningHeadPoints'] as int?,
    penaltiesGiven: json['penaltiesGiven'] as int?,
    penaltiesReceived: json['penaltiesReceived'] as int?,
    knockdownsScored: json['knockdownsScored'] as int?,
    knockdownsReceived: json['knockdownsReceived'] as int?,
    leadLegKicks: json['leadLegKicks'] as int?,
    backLegKicks: json['backLegKicks'] as int?,
    openingAttacks: json['openingAttacks'] as int?,
    counterAttacks: json['counterAttacks'] as int?,
    topTechniques: (json['topTechniques'] as List?)
        ?.map((e) => e as String)
        .toList(),
    combinations: json['combinations'] as String?,
    offenceSeconds: json['offenceSeconds'] as int?,
    defenceSeconds: json['defenceSeconds'] as int?,
    ringControlRating: json['ringControlRating'] as int?,
    composureRating: json['composureRating'] as int?,
    scoreManagementRating: json['scoreManagementRating'] as int?,
    coachNotes: json['coachNotes'] as String?,
    preMatchNerves: json['preMatchNerves'] as int?,
    interRoundRecovery: json['interRoundRecovery'] as int?,
    responseToLosingPoint: json['responseToLosingPoint'] as int?,
    responseToWinningPoint: json['responseToWinningPoint'] as int?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'tournamentName': tournamentName,
    'tournamentID': tournamentId,
    'date': date.toIso8601String(),
    'ourAthleteID': ourAthleteId,
    'opponentAthleteID': opponentAthleteId,
    'opponentName': opponentName,
    'weightClassKg': weightClassKg,
    'rounds': rounds,
    'ourScore': ourScore,
    'opponentScore': opponentScore,
    'won': won,
    'medal': medal.name,
    'events': events.map((e) => e.toJson()).toList(),
    'context': context.name,
    'matchType': matchType?.name,
    'winMethod': winMethod?.name,
    'outcome': outcome?.name,
    'roundsWon': roundsWon,
    'roundsLost': roundsLost,
    'kicksAttempted': kicksAttempted,
    'kicksLanded': kicksLanded,
    'punchesAttempted': punchesAttempted,
    'punchesLanded': punchesLanded,
    'ourPunchPoints': ourPunchPoints,
    'ourBodyKickPoints': ourBodyKickPoints,
    'ourHeadKickPoints': ourHeadKickPoints,
    'ourSpinningBodyPoints': ourSpinningBodyPoints,
    'ourSpinningHeadPoints': ourSpinningHeadPoints,
    'oppPunchPoints': oppPunchPoints,
    'oppBodyKickPoints': oppBodyKickPoints,
    'oppHeadKickPoints': oppHeadKickPoints,
    'oppSpinningBodyPoints': oppSpinningBodyPoints,
    'oppSpinningHeadPoints': oppSpinningHeadPoints,
    'penaltiesGiven': penaltiesGiven,
    'penaltiesReceived': penaltiesReceived,
    'knockdownsScored': knockdownsScored,
    'knockdownsReceived': knockdownsReceived,
    'leadLegKicks': leadLegKicks,
    'backLegKicks': backLegKicks,
    'openingAttacks': openingAttacks,
    'counterAttacks': counterAttacks,
    'topTechniques': topTechniques,
    'combinations': combinations,
    'offenceSeconds': offenceSeconds,
    'defenceSeconds': defenceSeconds,
    'ringControlRating': ringControlRating,
    'composureRating': composureRating,
    'scoreManagementRating': scoreManagementRating,
    'coachNotes': coachNotes,
    'preMatchNerves': preMatchNerves,
    'interRoundRecovery': interRoundRecovery,
    'responseToLosingPoint': responseToLosingPoint,
    'responseToWinningPoint': responseToWinningPoint,
  };
}
