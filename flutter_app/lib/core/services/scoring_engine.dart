import '../models/match.dart';

/// 1:1 port of Core/Services/ScoringEngine.swift.
///
/// Live-match scoring engine — distinct from [ScoreEngine] which deals with
/// composite performance scores. Handles WT-style point accrual, including
/// the "penalty awards the *opposite* side a point" rule.
class ScoringEngine {
  ScoringEngine._();

  static Match applyEvent(Match match, ScoreEvent event) {
    final events = [...match.events, event];
    final pts = event.action.points;
    var ourScore = match.ourScore;
    var oppScore = match.opponentScore;

    if (event.action == ScoreAction.penalty) {
      switch (event.side) {
        case MatchSide.chung:
          oppScore += pts;
          break;
        case MatchSide.hong:
          ourScore += pts;
          break;
      }
    } else {
      switch (event.side) {
        case MatchSide.chung:
          ourScore += pts;
          break;
        case MatchSide.hong:
          oppScore += pts;
          break;
      }
    }

    return Match(
      id: match.id,
      tournamentName: match.tournamentName,
      tournamentId: match.tournamentId,
      date: match.date,
      ourAthleteId: match.ourAthleteId,
      opponentAthleteId: match.opponentAthleteId,
      opponentName: match.opponentName,
      weightClassKg: match.weightClassKg,
      rounds: match.rounds,
      ourScore: ourScore,
      opponentScore: oppScore,
      won: match.won,
      medal: match.medal,
      events: events,
      context: match.context,
      matchType: match.matchType,
      winMethod: match.winMethod,
      outcome: match.outcome,
      roundsWon: match.roundsWon,
      roundsLost: match.roundsLost,
      kicksAttempted: match.kicksAttempted,
      kicksLanded: match.kicksLanded,
      punchesAttempted: match.punchesAttempted,
      punchesLanded: match.punchesLanded,
      ourPunchPoints: match.ourPunchPoints,
      ourBodyKickPoints: match.ourBodyKickPoints,
      ourHeadKickPoints: match.ourHeadKickPoints,
      ourSpinningBodyPoints: match.ourSpinningBodyPoints,
      ourSpinningHeadPoints: match.ourSpinningHeadPoints,
      oppPunchPoints: match.oppPunchPoints,
      oppBodyKickPoints: match.oppBodyKickPoints,
      oppHeadKickPoints: match.oppHeadKickPoints,
      oppSpinningBodyPoints: match.oppSpinningBodyPoints,
      oppSpinningHeadPoints: match.oppSpinningHeadPoints,
      penaltiesGiven: match.penaltiesGiven,
      penaltiesReceived: match.penaltiesReceived,
      knockdownsScored: match.knockdownsScored,
      knockdownsReceived: match.knockdownsReceived,
      leadLegKicks: match.leadLegKicks,
      backLegKicks: match.backLegKicks,
      openingAttacks: match.openingAttacks,
      counterAttacks: match.counterAttacks,
      topTechniques: match.topTechniques,
      combinations: match.combinations,
      offenceSeconds: match.offenceSeconds,
      defenceSeconds: match.defenceSeconds,
      ringControlRating: match.ringControlRating,
      composureRating: match.composureRating,
      scoreManagementRating: match.scoreManagementRating,
      coachNotes: match.coachNotes,
      preMatchNerves: match.preMatchNerves,
      interRoundRecovery: match.interRoundRecovery,
      responseToLosingPoint: match.responseToLosingPoint,
      responseToWinningPoint: match.responseToWinningPoint,
    );
  }

  /// Match is over when all rounds have been completed or the PSS gap
  /// reaches 12.
  static bool isMatchOver(Match match, int currentRound) {
    if (currentRound > match.rounds) return true;
    if ((match.ourScore - match.opponentScore).abs() >= 12) return true;
    return false;
  }

  static MatchSide? declareWinner(Match match) {
    if (match.ourScore > match.opponentScore) return MatchSide.chung;
    if (match.opponentScore > match.ourScore) return MatchSide.hong;
    return null;
  }
}
