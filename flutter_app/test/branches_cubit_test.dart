import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shjsdsc/core/blocs/branches_cubit.dart';
import 'package:shjsdsc/core/repository/demo_repository.dart';

void main() {
  group('BranchesCubit (port of BranchesStore)', () {
    blocTest<BranchesCubit, BranchesState>(
      'loadAll produces one summary per branch with exactly one main',
      build: () => BranchesCubit(DemoRepository()),
      act: (c) => c.loadAll(),
      verify: (c) {
        expect(c.state.status, BranchesStatus.ready);
        expect(c.state.summaries.length, 4);
        expect(c.state.summaries.where((s) => s.branch.isMain).length, 1);
        for (final s in c.state.summaries) {
          expect(s.composite, inInclusiveRange(0, 100));
          expect(s.utilisation, inInclusiveRange(0, 1));
        }
      },
    );

    blocTest<BranchesCubit, BranchesState>(
      'athleteCount per branch matches the roster',
      build: () => BranchesCubit(DemoRepository()),
      act: (c) => c.loadAll(),
      verify: (c) async {
        final repo = DemoRepository();
        for (final s in c.state.summaries) {
          final roster = await repo.athletesInBranch(s.branch.id);
          expect(s.athleteCount, roster.length);
        }
      },
    );
  });
}
