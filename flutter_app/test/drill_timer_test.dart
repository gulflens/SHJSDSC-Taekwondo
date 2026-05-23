import 'package:flutter_test/flutter_test.dart';
import 'package:shjsdsc/core/blocs/drill_timer_engine.dart';
import 'package:shjsdsc/core/models/drill_timer.dart';

void main() {
  group('DrillTimerEngineCubit (port of DrillTimerEngine)', () {
    test('tabata flattens to a prepare lead-in + 8 work steps', () {
      final cubit = DrillTimerEngineCubit()..load(DrillTimerSession.tabata());
      final s = cubit.state;
      expect(s.steps, isNotEmpty);
      expect(s.totalRounds, 8);
      expect(s.totalWorkSteps, 8); // 8 rounds × 1 work interval
      expect(s.steps.first.phase, DrillTimerPhase.prepare);
      expect(s.remaining, s.steps.first.seconds.toDouble());
      cubit.close();
    });

    test('skipForward walks the timeline to completion', () {
      final cubit = DrillTimerEngineCubit()..load(DrillTimerSession.tabata());
      final total = cubit.state.steps.length;
      for (var i = 0; i < total; i++) {
        cubit.skipForward();
      }
      expect(cubit.state.isFinished, isTrue);
      expect(cubit.state.phase, DrillTimerPhase.finished);
      cubit.close();
    });

    test('reset returns to a fresh, paused first step', () {
      final cubit = DrillTimerEngineCubit()..load(DrillTimerSession.roundsPreset());
      cubit.skipForward();
      cubit.skipForward();
      cubit.reset();
      expect(cubit.state.index, 0);
      expect(cubit.state.isRunning, isFalse);
      expect(cubit.state.isFinished, isFalse);
      expect(cubit.state.elapsedTotal, 0);
      cubit.close();
    });

    test('start sets running; close cancels the ticker', () async {
      final cubit = DrillTimerEngineCubit()..load(DrillTimerSession.emom());
      cubit.start();
      expect(cubit.state.isRunning, isTrue);
      await cubit.close(); // must cancel the periodic timer cleanly
    });
  });
}
