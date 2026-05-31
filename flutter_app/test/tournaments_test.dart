import 'package:flutter_test/flutter_test.dart';
import 'package:shjsdsc/core/blocs/tournaments_cubit.dart';
import 'package:shjsdsc/core/blocs/weight_cut_cubit.dart';
import 'package:shjsdsc/core/repository/demo_repository.dart';

void main() {
  group('TournamentsCubit (port of TournamentsStore)', () {
    test('splits seeded tournaments into upcoming / past', () async {
      final cubit = TournamentsCubit(DemoRepository());
      await cubit.loadTournaments();

      expect(cubit.state.status, TournamentsStatus.ready);
      expect(cubit.state.all.length, 3);
      expect(cubit.state.past.length, 1); // trn-1 (30 days ago)
      expect(cubit.state.upcoming.length, 2); // trn-2, trn-3
      // upcoming sorted ascending
      final dates = cubit.state.upcoming.map((t) => t.startsAt).toList();
      final sorted = [...dates]..sort();
      expect(dates, sorted);
      expect(cubit.state.byId('trn-1')?.name, contains('Junior Open'));
    });
  });

  group('WeightCutCubit (port of WeightCutStore)', () {
    test('loads the weight-cut log with ascending trend and target', () async {
      final cubit = WeightCutCubit(DemoRepository());
      await cubit.load('reg-3');

      expect(cubit.state.status, WeightCutStatus.ready);
      expect(cubit.state.entries.length, 5);
      expect(cubit.state.targetKg, 63.0);

      final trend = cubit.state.trend;
      final dates = trend.map((p) => p.date).toList();
      final sorted = [...dates]..sort();
      expect(dates, sorted, reason: 'trend is chronological');
      // weight trends downward toward the target
      expect(trend.first.value, greaterThan(trend.last.value));
    });
  });
}
