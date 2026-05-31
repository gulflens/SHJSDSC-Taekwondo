import '../models/entity_id.dart';
import '../models/tournament.dart';

/// 1:1 port of Core/Services/BracketEngine.swift.
///
/// Single-elimination bracket generator and result recorder.
class BracketEngine {
  BracketEngine._();

  /// Generate single-elimination bracket matches from a seeded list of
  /// athlete IDs. Pads to the next power of 2 with byes; bye opponents
  /// auto-advance.
  static List<BracketMatch> generateSingleElimination({
    required EntityID bracketId,
    required List<EntityID> seeds,
  }) {
    if (seeds.isEmpty) return [];
    final n = nextPowerOfTwo(seeds.length);
    final padded = List<EntityID?>.from(seeds.map((s) => s as EntityID?));
    while (padded.length < n) {
      padded.add(null);
    }

    final positions = bracketPositions(n);
    final matches = <BracketMatch>[];
    var roundParticipants = positions.map((i) => padded[i]).toList();
    var round = 1;

    while (roundParticipants.length > 1) {
      final nextRound = <EntityID?>[];
      for (var pair = 0; pair < roundParticipants.length ~/ 2; pair++) {
        final a = roundParticipants[pair * 2];
        final b = roundParticipants[pair * 2 + 1];
        EntityID? winner;
        if (a != null && b == null) {
          winner = a;
        } else if (a == null && b != null) {
          winner = b;
        }
        matches.add(
          BracketMatch.create(
            bracketId: bracketId,
            round: round,
            position: pair,
            athleteAId: a,
            athleteBId: b,
            winnerId: winner,
            matchId: null,
          ),
        );
        nextRound.add(winner);
      }
      roundParticipants = nextRound;
      round++;
    }
    return matches;
  }

  /// Apply a fight result to the bracket, propagating the winner to the
  /// next round.
  static List<BracketMatch> recordResult({
    required List<BracketMatch> matches,
    required EntityID bracketId,
    required int round,
    required int position,
    required EntityID winnerId,
    EntityID? matchId,
  }) {
    final out = List<BracketMatch>.from(matches);
    final idx = out.indexWhere(
      (m) =>
          m.bracketId == bracketId &&
          m.round == round &&
          m.position == position,
    );
    if (idx < 0) return out;

    out[idx] = BracketMatch(
      id: out[idx].id,
      bracketId: out[idx].bracketId,
      round: out[idx].round,
      position: out[idx].position,
      athleteAId: out[idx].athleteAId,
      athleteBId: out[idx].athleteBId,
      winnerId: winnerId,
      matchId: matchId,
    );

    // Propagate to next round.
    final nextRound = round + 1;
    final nextPosition = position ~/ 2;
    final nextIdx = out.indexWhere(
      (m) =>
          m.bracketId == bracketId &&
          m.round == nextRound &&
          m.position == nextPosition,
    );
    if (nextIdx >= 0) {
      final nm = out[nextIdx];
      if (position % 2 == 0) {
        out[nextIdx] = BracketMatch(
          id: nm.id,
          bracketId: nm.bracketId,
          round: nm.round,
          position: nm.position,
          athleteAId: winnerId,
          athleteBId: nm.athleteBId,
          winnerId: nm.winnerId,
          matchId: nm.matchId,
        );
      } else {
        out[nextIdx] = BracketMatch(
          id: nm.id,
          bracketId: nm.bracketId,
          round: nm.round,
          position: nm.position,
          athleteAId: nm.athleteAId,
          athleteBId: winnerId,
          winnerId: nm.winnerId,
          matchId: nm.matchId,
        );
      }
    }
    return out;
  }

  static int nextPowerOfTwo(int n) {
    if (n <= 1) return 1;
    var v = 1;
    while (v < n) {
      v <<= 1;
    }
    return v;
  }

  /// Standard tournament-bracket position ordering.
  /// For size n=4 returns [0,3,1,2]; for n=8 returns [0,7,3,4,1,6,2,5].
  /// Top seed always lands in position 0; #2 always in the opposite half
  /// so they only meet in the final.
  static List<int> bracketPositions(int size) {
    if (size == 1) return [0];
    final half = bracketPositions(size ~/ 2);
    final result = <int>[];
    for (final p in half) {
      result.add(p);
      result.add(size - 1 - p);
    }
    return result;
  }
}
