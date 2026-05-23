import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../models/athlete.dart';
import '../models/entity_id.dart';
import '../models/match.dart';
import '../models/tournament.dart';
import '../repository/repository.dart';
import '../services/scoring_engine.dart';

/// Port of Core/Stores/LiveMatchStore.swift.
///
/// Drives a live WT-style taekwondo match: round timer (1-second granularity
/// via [Timer.periodic]), score-event recording, undo, and finalization.
/// [ScoringEngine] is reused for all scoring logic — no reimplementation.

// ──────────────────────────────────────────────────────────────────────────────
// State
// ──────────────────────────────────────────────────────────────────────────────

enum LiveMatchStatus { idle, running, finished }

class LiveMatchState extends Equatable {
  final LiveMatchStatus status;
  final Match? match;
  final int currentRound;
  final int roundTimeRemainingSec;
  final bool isTimerRunning;
  final MatchSide? winner;
  final bool isFinalized;

  static const int roundDurationSec = 120;

  const LiveMatchState({
    this.status = LiveMatchStatus.idle,
    this.match,
    this.currentRound = 1,
    this.roundTimeRemainingSec = roundDurationSec,
    this.isTimerRunning = false,
    this.winner,
    this.isFinalized = false,
  });

  /// "m:ss" formatted string for the in-ring scoreboard.
  String get formattedTime {
    final m = roundTimeRemainingSec ~/ 60;
    final s = roundTimeRemainingSec % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  LiveMatchState copyWith({
    LiveMatchStatus? status,
    Match? match,
    int? currentRound,
    int? roundTimeRemainingSec,
    bool? isTimerRunning,
    MatchSide? winner,
    bool clearWinner = false,
    bool? isFinalized,
  }) => LiveMatchState(
    status: status ?? this.status,
    match: match ?? this.match,
    currentRound: currentRound ?? this.currentRound,
    roundTimeRemainingSec: roundTimeRemainingSec ?? this.roundTimeRemainingSec,
    isTimerRunning: isTimerRunning ?? this.isTimerRunning,
    winner: clearWinner ? null : (winner ?? this.winner),
    isFinalized: isFinalized ?? this.isFinalized,
  );

  @override
  List<Object?> get props => [
    status,
    match?.id,
    match?.ourScore,
    match?.opponentScore,
    match?.events.length,
    currentRound,
    roundTimeRemainingSec,
    isTimerRunning,
    winner,
    isFinalized,
  ];
}

// ──────────────────────────────────────────────────────────────────────────────
// Cubit
// ──────────────────────────────────────────────────────────────────────────────

class LiveMatchCubit extends Cubit<LiveMatchState> {
  final Repository _repo;

  Timer? _ticker;
  StreamSubscription<ScoreEvent>? _eventSub;

  LiveMatchCubit(this._repo) : super(const LiveMatchState());

  // ── Match lifecycle ────────────────────────────────────────────────────────

  /// Create and start a new match. Mirrors [LiveMatchStore.startMatch].
  Future<void> startMatch({
    required Athlete athlete,
    required String opponentName,
    required WeightCategory weightCategory,
    Tournament? tournament,
    int rounds = 3,
  }) async {
    final m = Match(
      id: newEntityId(),
      tournamentName: tournament?.name ?? 'Practice Match',
      tournamentId: tournament?.id,
      date: DateTime.now(),
      ourAthleteId: athlete.id,
      opponentName: opponentName,
      weightClassKg: weightCategory.range.$2?.toDouble() ?? 100.0,
      rounds: rounds,
      ourScore: 0,
      opponentScore: 0,
      won: false,
      medal: MedalType.none,
    );

    emit(
      LiveMatchState(
        status: LiveMatchStatus.running,
        match: m,
        currentRound: 1,
        roundTimeRemainingSec: LiveMatchState.roundDurationSec,
        winner: null,
        isFinalized: false,
      ),
    );

    try {
      await _repo.startMatch(m);
    } catch (e) {
      // ignore: avoid_print
      print('LiveMatchCubit.startMatch: $e');
    }

    _subscribeToRemoteEvents(m.id);
    _startTimer();
  }

  // ── Scoring ────────────────────────────────────────────────────────────────

  /// Record a scoring action for [side] and persist it. Uses [ScoringEngine]
  /// to update the match totals; checks for match-over condition.
  Future<void> recordEvent(MatchSide side, ScoreAction action) async {
    final m = state.match;
    if (m == null || state.isFinalized) return;

    final event = ScoreEvent.create(
      matchId: m.id,
      round: state.currentRound,
      atSecond: LiveMatchState.roundDurationSec - state.roundTimeRemainingSec,
      side: side,
      action: action,
    );
    final updated = ScoringEngine.applyEvent(m, event);
    emit(state.copyWith(match: updated));

    try {
      await _repo.recordEvent(event);
    } catch (e) {
      // ignore: avoid_print
      print('LiveMatchCubit.recordEvent: $e');
    }

    if (ScoringEngine.isMatchOver(updated, state.currentRound)) {
      final w = ScoringEngine.declareWinner(updated);
      _stopTimer();
      emit(state.copyWith(winner: w));
    }
  }

  /// Apply an event received via the realtime channel — idempotent: duplicate
  /// event IDs (our own echo) are silently ignored.
  void applyRemoteEvent(ScoreEvent event) {
    final m = state.match;
    if (m == null || m.id != event.matchId || state.isFinalized) return;
    if (m.events.any((e) => e.id == event.id)) return;
    final updated = ScoringEngine.applyEvent(m, event);
    emit(state.copyWith(match: updated));
    if (ScoringEngine.isMatchOver(updated, state.currentRound)) {
      final w = ScoringEngine.declareWinner(updated);
      emit(state.copyWith(winner: w));
    }
  }

  /// Remove the last event recorded for [side] and subtract its points.
  void undoLast(MatchSide side) {
    var m = state.match;
    if (m == null || state.isFinalized) return;

    final lastIdx = m.events.lastIndexWhere((e) => e.side == side);
    if (lastIdx == -1) return;

    final removed = m.events[lastIdx];
    final events = [...m.events]..removeAt(lastIdx);
    final pts = removed.action.points;

    var ourScore = m.ourScore;
    var oppScore = m.opponentScore;

    if (removed.action == ScoreAction.penalty) {
      switch (removed.side) {
        case MatchSide.chung:
          oppScore = (oppScore - pts).clamp(0, 9999);
          break;
        case MatchSide.hong:
          ourScore = (ourScore - pts).clamp(0, 9999);
          break;
      }
    } else {
      switch (removed.side) {
        case MatchSide.chung:
          ourScore = (ourScore - pts).clamp(0, 9999);
          break;
        case MatchSide.hong:
          oppScore = (oppScore - pts).clamp(0, 9999);
          break;
      }
    }

    m = Match(
      id: m.id,
      tournamentName: m.tournamentName,
      tournamentId: m.tournamentId,
      date: m.date,
      ourAthleteId: m.ourAthleteId,
      opponentAthleteId: m.opponentAthleteId,
      opponentName: m.opponentName,
      weightClassKg: m.weightClassKg,
      rounds: m.rounds,
      ourScore: ourScore,
      opponentScore: oppScore,
      won: m.won,
      medal: m.medal,
      events: events,
      context: m.context,
      matchType: m.matchType,
      winMethod: m.winMethod,
      outcome: m.outcome,
      roundsWon: m.roundsWon,
      roundsLost: m.roundsLost,
      kicksAttempted: m.kicksAttempted,
      kicksLanded: m.kicksLanded,
      punchesAttempted: m.punchesAttempted,
      punchesLanded: m.punchesLanded,
      ourPunchPoints: m.ourPunchPoints,
      ourBodyKickPoints: m.ourBodyKickPoints,
      ourHeadKickPoints: m.ourHeadKickPoints,
      ourSpinningBodyPoints: m.ourSpinningBodyPoints,
      ourSpinningHeadPoints: m.ourSpinningHeadPoints,
      oppPunchPoints: m.oppPunchPoints,
      oppBodyKickPoints: m.oppBodyKickPoints,
      oppHeadKickPoints: m.oppHeadKickPoints,
      oppSpinningBodyPoints: m.oppSpinningBodyPoints,
      oppSpinningHeadPoints: m.oppSpinningHeadPoints,
      penaltiesGiven: m.penaltiesGiven,
      penaltiesReceived: m.penaltiesReceived,
      knockdownsScored: m.knockdownsScored,
      knockdownsReceived: m.knockdownsReceived,
      leadLegKicks: m.leadLegKicks,
      backLegKicks: m.backLegKicks,
      openingAttacks: m.openingAttacks,
      counterAttacks: m.counterAttacks,
      topTechniques: m.topTechniques,
      combinations: m.combinations,
      offenceSeconds: m.offenceSeconds,
      defenceSeconds: m.defenceSeconds,
      ringControlRating: m.ringControlRating,
      composureRating: m.composureRating,
      scoreManagementRating: m.scoreManagementRating,
      coachNotes: m.coachNotes,
      preMatchNerves: m.preMatchNerves,
      interRoundRecovery: m.interRoundRecovery,
      responseToLosingPoint: m.responseToLosingPoint,
      responseToWinningPoint: m.responseToWinningPoint,
    );

    emit(state.copyWith(match: m, clearWinner: true));
  }

  // ── Round control ──────────────────────────────────────────────────────────

  /// End the current round, persist it, and determine winner if all rounds
  /// are complete.
  Future<void> endRound() async {
    final m = state.match;
    if (m == null || state.isFinalized) return;
    _stopTimer();
    try {
      await _repo.endRound(m.id);
    } catch (e) {
      // ignore: avoid_print
      print('LiveMatchCubit.endRound: $e');
    }
    if (state.currentRound >= m.rounds) {
      final w = ScoringEngine.declareWinner(m);
      emit(state.copyWith(winner: w));
    }
  }

  /// Advance to the next round (coach taps "Next Round" between rounds).
  void startNextRound() {
    final m = state.match;
    if (m == null || state.isFinalized) return;
    if (state.currentRound < m.rounds) {
      emit(
        state.copyWith(
          currentRound: state.currentRound + 1,
          roundTimeRemainingSec: LiveMatchState.roundDurationSec,
          clearWinner: true,
        ),
      );
      _startTimer();
    }
  }

  // ── Timer control ──────────────────────────────────────────────────────────

  void togglePause() {
    if (state.isTimerRunning) {
      _stopTimer();
    } else {
      _startTimer();
    }
  }

  // ── Finalize ───────────────────────────────────────────────────────────────

  /// Mark the match result and persist. Returns the updated [Match].
  Future<Match?> finalize(MedalType medal) async {
    var m = state.match;
    if (m == null) return null;

    final w = state.winner ?? ScoringEngine.declareWinner(m);
    m = Match(
      id: m.id,
      tournamentName: m.tournamentName,
      tournamentId: m.tournamentId,
      date: m.date,
      ourAthleteId: m.ourAthleteId,
      opponentAthleteId: m.opponentAthleteId,
      opponentName: m.opponentName,
      weightClassKg: m.weightClassKg,
      rounds: m.rounds,
      ourScore: m.ourScore,
      opponentScore: m.opponentScore,
      won: w == MatchSide.chung,
      medal: medal,
      events: m.events,
      context: m.context,
      matchType: m.matchType,
      winMethod: m.winMethod,
      outcome: m.outcome,
      roundsWon: m.roundsWon,
      roundsLost: m.roundsLost,
      kicksAttempted: m.kicksAttempted,
      kicksLanded: m.kicksLanded,
      punchesAttempted: m.punchesAttempted,
      punchesLanded: m.punchesLanded,
      ourPunchPoints: m.ourPunchPoints,
      ourBodyKickPoints: m.ourBodyKickPoints,
      ourHeadKickPoints: m.ourHeadKickPoints,
      ourSpinningBodyPoints: m.ourSpinningBodyPoints,
      ourSpinningHeadPoints: m.ourSpinningHeadPoints,
      oppPunchPoints: m.oppPunchPoints,
      oppBodyKickPoints: m.oppBodyKickPoints,
      oppHeadKickPoints: m.oppHeadKickPoints,
      oppSpinningBodyPoints: m.oppSpinningBodyPoints,
      oppSpinningHeadPoints: m.oppSpinningHeadPoints,
      penaltiesGiven: m.penaltiesGiven,
      penaltiesReceived: m.penaltiesReceived,
      knockdownsScored: m.knockdownsScored,
      knockdownsReceived: m.knockdownsReceived,
      leadLegKicks: m.leadLegKicks,
      backLegKicks: m.backLegKicks,
      openingAttacks: m.openingAttacks,
      counterAttacks: m.counterAttacks,
      topTechniques: m.topTechniques,
      combinations: m.combinations,
      offenceSeconds: m.offenceSeconds,
      defenceSeconds: m.defenceSeconds,
      ringControlRating: m.ringControlRating,
      composureRating: m.composureRating,
      scoreManagementRating: m.scoreManagementRating,
      coachNotes: m.coachNotes,
      preMatchNerves: m.preMatchNerves,
      interRoundRecovery: m.interRoundRecovery,
      responseToLosingPoint: m.responseToLosingPoint,
      responseToWinningPoint: m.responseToWinningPoint,
    );

    try {
      await _repo.finalizeMatch(m);
    } catch (e) {
      // ignore: avoid_print
      print('LiveMatchCubit.finalize: $e');
    }

    _stopTimer();
    emit(
      state.copyWith(
        status: LiveMatchStatus.finished,
        match: m,
        isFinalized: true,
      ),
    );
    return m;
  }

  // ── Private: timer ────────────────────────────────────────────────────────

  void _startTimer() {
    _stopTimer();
    if (state.roundTimeRemainingSec <= 0 || state.isFinalized) return;
    emit(state.copyWith(isTimerRunning: true));
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _stopTimer() {
    _ticker?.cancel();
    _ticker = null;
    if (state.isTimerRunning) {
      emit(state.copyWith(isTimerRunning: false));
    }
  }

  void _tick() {
    if (!state.isTimerRunning || state.isFinalized) return;
    final next = state.roundTimeRemainingSec - 1;
    if (next <= 0) {
      emit(state.copyWith(roundTimeRemainingSec: 0));
      endRound(); // async — fire and forget
    } else {
      emit(state.copyWith(roundTimeRemainingSec: next));
    }
  }

  // ── Private: realtime ─────────────────────────────────────────────────────

  void _subscribeToRemoteEvents(EntityID matchId) {
    _eventSub?.cancel();
    _eventSub = _repo
        .scoreEventStream(matchId)
        .listen(
          applyRemoteEvent,
          onError: (Object e) {
            // ignore: avoid_print
            print('LiveMatchCubit.eventStream: $e');
          },
        );
  }

  @override
  Future<void> close() {
    _stopTimer();
    _ticker?.cancel();
    _eventSub?.cancel();
    return super.close();
  }
}
