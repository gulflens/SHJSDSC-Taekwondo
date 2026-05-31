import 'package:flutter_test/flutter_test.dart';
import 'package:shjsdsc/core/blocs/performance_entry_cubit.dart';
import 'package:shjsdsc/core/repository/demo_repository.dart';

void main() {
  group('PerformanceEntryCubit (port of PerformanceEntryStore)', () {
    test('loads the seeded series and derives 0–100 trends', () async {
      final repo = DemoRepository();
      final cubit = PerformanceEntryCubit(repo);
      await cubit.load('ath-1');

      final s = cubit.state;
      expect(s.status, PerformanceEntryStatus.ready);
      expect(s.physicalMetrics, isNotEmpty);
      expect(s.technicalSkills, isNotEmpty);
      expect(s.wellness, isNotEmpty);

      final physical = s.physicalTrend();
      expect(physical.length, greaterThanOrEqualTo(2));
      for (final p in physical) {
        expect(p.value, inInclusiveRange(0, 100));
      }
      // Points are chronological.
      final dates = physical.map((p) => p.date).toList();
      final sorted = [...dates]..sort();
      expect(dates, sorted);

      // Wellness was seeded for consecutive days including today.
      expect(cubit.state.wellnessStreak(), greaterThan(0));
    });

    test('athlete with no entries yields empty trends', () async {
      final repo = DemoRepository();
      final cubit = PerformanceEntryCubit(repo);
      await cubit.load('ath-5'); // not in the seeded perf set
      expect(cubit.state.status, PerformanceEntryStatus.ready);
      expect(cubit.state.physicalTrend(), isEmpty);
      expect(cubit.state.wellnessStreak(), 0);
    });
  });
}
