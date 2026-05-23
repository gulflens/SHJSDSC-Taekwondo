import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shjsdsc/core/repository/demo_repository.dart';
import 'package:shjsdsc/features/coaches/coach_list_cubit.dart';

void main() {
  group('CoachListCubit (port of CoachListView store + CoachIntel)', () {
    blocTest<CoachListCubit, CoachListState>(
      'loads the seeded coaches sorted by composite desc',
      build: () => CoachListCubit(DemoRepository()),
      act: (c) => c.load(),
      verify: (c) {
        expect(c.state.status, CoachListStatus.ready);
        expect(c.state.all.length, greaterThanOrEqualTo(2));
        final composites = c.state.visible.map((i) => i.composite).toList();
        final sorted = [...composites]..sort((a, b) => b.compareTo(a));
        expect(composites, sorted, reason: 'visible should be sorted desc');
      },
    );

    blocTest<CoachListCubit, CoachListState>(
      'athleteCount is real (grouped by primaryCoachId)',
      build: () => CoachListCubit(DemoRepository()),
      act: (c) => c.load(),
      verify: (c) {
        // Yassin coaches several seeded athletes; the count must be > 0.
        final yassin = c.state.all
            .firstWhere((i) => i.coach.fullName.contains('Yassin'));
        expect(yassin.athleteCount, greaterThan(0));
      },
    );

    blocTest<CoachListCubit, CoachListState>(
      'search narrows the visible roster',
      build: () => CoachListCubit(DemoRepository()),
      act: (c) async {
        await c.load();
        c.search('Yassin');
      },
      verify: (c) {
        expect(c.state.visible.length, 1);
        expect(c.state.visible.first.coach.fullName, contains('Yassin'));
      },
    );

    test('composite blends competency + dan rank into 0…100', () {
      final repo = DemoRepository();
      final cubit = CoachListCubit(repo);
      return cubit.load().then((_) {
        for (final intel in cubit.state.all) {
          expect(intel.composite, inInclusiveRange(0, 100));
        }
      });
    });
  });
}
