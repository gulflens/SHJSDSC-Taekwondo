import 'package:flutter_test/flutter_test.dart';
import 'package:shjsdsc/core/blocs/live_match_cubit.dart';
import 'package:shjsdsc/core/models/match.dart';
import 'package:shjsdsc/core/models/tournament.dart' show WeightCategory;
import 'package:shjsdsc/core/repository/demo_repository.dart';

void main() {
  group('LiveMatchCubit (port of LiveMatchStore)', () {
    test('records points, penalty awards opponent, undo reverts', () async {
      final repo = DemoRepository();
      final athlete = (await repo.athletes()).first;
      final cubit = LiveMatchCubit(repo);

      await cubit.startMatch(
        athlete: athlete,
        opponentName: 'Rival',
        weightCategory: WeightCategory.seniorsUnder68,
      );
      expect(cubit.state.status, LiveMatchStatus.running);
      expect(cubit.state.match!.ourScore, 0);

      await cubit.recordEvent(MatchSide.chung, ScoreAction.headKick); // +3 our
      expect(cubit.state.match!.ourScore, 3);

      await cubit.recordEvent(MatchSide.hong, ScoreAction.bodyKick); // +2 opp
      expect(cubit.state.match!.opponentScore, 2);

      // A penalty by chung awards a point to the opponent (WT rule).
      await cubit.recordEvent(MatchSide.chung, ScoreAction.penalty);
      expect(cubit.state.match!.opponentScore, 3);

      // Undo the chung penalty → opponent back to 2.
      cubit.undoLast(MatchSide.chung);
      expect(cubit.state.match!.opponentScore, 2);
      expect(cubit.state.match!.ourScore, 3);

      await cubit.close(); // cancels the round timer
    });

    test('finalize marks the match finished and records the winner', () async {
      final repo = DemoRepository();
      final athlete = (await repo.athletes()).first;
      final cubit = LiveMatchCubit(repo);
      await cubit.startMatch(
        athlete: athlete,
        opponentName: 'Rival',
        weightCategory: WeightCategory.seniorsUnder68,
      );
      await cubit.recordEvent(MatchSide.chung, ScoreAction.turnHeadKick); // +5

      final result = await cubit.finalize(MedalType.none);
      expect(cubit.state.status, LiveMatchStatus.finished);
      expect(cubit.state.isFinalized, isTrue);
      expect(result!.won, isTrue); // chung leads → our athlete won
      await cubit.close();
    });
  });
}
