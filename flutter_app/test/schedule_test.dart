import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shjsdsc/core/blocs/live_class_cubit.dart';
import 'package:shjsdsc/core/blocs/schedule_cubit.dart';
import 'package:shjsdsc/core/models/schedule.dart';
import 'package:shjsdsc/core/repository/demo_repository.dart';

void main() {
  const mainBranch = 'branch-rahmania';

  group('ScheduleCubit (port of ScheduleStore)', () {
    blocTest<ScheduleCubit, ScheduleState>(
      'loadBranchDay returns the seeded sessions for today',
      build: () => ScheduleCubit(DemoRepository()),
      act: (c) => c.loadBranchDay(mainBranch, day: DateTime.now()),
      verify: (c) {
        expect(c.state.status, ScheduleStatus.ready);
        expect(c.state.sessionsToday, isNotEmpty);
        expect(
          c.state.sessionsToday.every((s) => s.branchId == mainBranch),
          isTrue,
        );
        // Lookups are populated so the view needs no second round-trip.
        expect(c.state.coachLookup, isNotEmpty);
      },
    );
  });

  group('LiveClassCubit (port of LiveClassStore)', () {
    test('loads roster, defaults to present, cycles, and saves a batch', () async {
      final repo = DemoRepository();
      final sessions = await repo.sessionsForBranch(mainBranch, DateTime.now());
      expect(sessions, isNotEmpty);
      final session = sessions.first;

      final cubit = LiveClassCubit(repo, session: session);
      await cubit.load();

      expect(cubit.state.status, LiveClassStatus.ready);
      expect(cubit.state.athletes, isNotEmpty);
      // Everyone defaults to present.
      expect(cubit.state.presentCount, cubit.state.athletes.length);

      // Cycle the first athlete present → late.
      final first = cubit.state.athletes.first;
      cubit.cycleState(first.id);
      expect(cubit.state.marks[first.id], AttendanceState.late);

      await cubit.save();
      expect(cubit.state.status, LiveClassStatus.saved);

      final saved = await repo.attendanceForSession(session.id);
      expect(saved.length, cubit.state.athletes.length);
    });
  });
}
