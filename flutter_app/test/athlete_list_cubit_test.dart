import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shjsdsc/core/repository/demo_repository.dart';
import 'package:shjsdsc/features/athletes/athlete_list_cubit.dart';

void main() {
  group('AthleteListCubit (port of AthletesStore)', () {
    blocTest<AthleteListCubit, AthleteListState>(
      'loads the seeded roster sorted by composite desc',
      build: () => AthleteListCubit(DemoRepository()),
      act: (c) => c.load(),
      verify: (c) {
        expect(c.state.status, AthleteListStatus.ready);
        expect(c.state.all, isNotEmpty);
        final composites = c.state.visible.map((i) => i.composite).toList();
        final sorted = [...composites]..sort((a, b) => b.compareTo(a));
        expect(composites, sorted, reason: 'visible should be sorted desc');
      },
    );

    blocTest<AthleteListCubit, AthleteListState>(
      'search narrows the visible roster',
      build: () => AthleteListCubit(DemoRepository()),
      act: (c) async {
        await c.load();
        c.search('Rashid');
      },
      verify: (c) {
        expect(c.state.visible.length, 1);
        expect(c.state.visible.first.athlete.fullName, contains('Rashid'));
      },
    );

    blocTest<AthleteListCubit, AthleteListState>(
      'branch scope only loads that branch',
      build: () => AthleteListCubit(DemoRepository(), branchScope: 'branch-nouf'),
      act: (c) => c.load(),
      verify: (c) {
        expect(c.state.all, isNotEmpty);
        expect(c.state.all.every((i) => i.athlete.branchId == 'branch-nouf'), isTrue);
      },
    );
  });
}
