import 'package:flutter_test/flutter_test.dart';
import 'package:shjsdsc/core/blocs/grading_cubit.dart';
import 'package:shjsdsc/core/repository/demo_repository.dart';
import 'package:shjsdsc/core/services/grading_engine.dart';

void main() {
  group('GradingCubit (port of GradingStore)', () {
    test('loadAll surfaces seeded sessions sorted by date with progress', () async {
      final repo = DemoRepository();
      final cubit = GradingCubit(repo);
      await cubit.loadAll(await repo.branches());

      expect(cubit.state.status, GradingStatus.ready);
      expect(cubit.state.sessions.length, 3);
      // sorted ascending by scheduledAt
      final dates = cubit.state.sessions.map((s) => s.scheduledAt).toList();
      final sorted = [...dates]..sort();
      expect(dates, sorted);

      // No scores seeded → progress is 0 of candidate count.
      final first = cubit.state.sessions.first;
      final p = cubit.state.progress(first.id);
      expect(p.scored, 0);
      expect(p.total, first.candidateAthleteIds.length);
    });

    test('eligibility returns an evaluation against the next belt', () async {
      final repo = DemoRepository();
      final cubit = GradingCubit(repo);
      final athlete = (await repo.athletes()).first;
      final target = GradingEngine.nextBelt(athlete.currentBelt);

      final elig = await cubit.eligibility(athlete, target);
      expect(elig, isNotNull);
      expect(elig!.athleteId, athlete.id);
      expect(elig.targetBelt.rank.rankIndex,
          greaterThan(athlete.currentBelt.rank.rankIndex));
    });
  });
}
