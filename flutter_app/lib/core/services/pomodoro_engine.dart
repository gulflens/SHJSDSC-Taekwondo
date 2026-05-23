import 'dart:async';

import '../models/training_pomodoro.dart';

/// 1:1 port of Core/Services/PomodoroEngine.swift.
///
/// Drives a [TrainingPomodoro] plan in real time. The engine is a pure-Dart
/// class (no Flutter imports). Consumers can subscribe to [snapshots] and
/// [phaseChanges] streams, or poll [snapshot] directly.
///
/// NOTE: Swift's engine is `@Observable @MainActor` — a UI-facing singleton.
/// In Flutter this maps to a plain class whose streams the cubit layer wraps.
/// The cubit/bloc layer (in lib/features/) is responsible for running on the
/// main isolate and dispatching to the widget tree.

/// Phase the engine reports. The view uses this for colour, label, and to
/// decide which audio loop to play.
sealed class PomodoroPhase {
  const PomodoroPhase();
}

class PomodoroPhaseIdle extends PomodoroPhase {
  const PomodoroPhaseIdle();
}

class PomodoroPhaseWork extends PomodoroPhase {
  const PomodoroPhaseWork();
}

class PomodoroPhaseRest extends PomodoroPhase {
  const PomodoroPhaseRest();
}

/// Transition whistle before the next work/rest phase.
class PomodoroPhaseWhistle extends PomodoroPhase {
  final WorkRest next;
  const PomodoroPhaseWhistle(this.next);

  @override
  bool operator ==(Object other) =>
      other is PomodoroPhaseWhistle && next == other.next;

  @override
  int get hashCode => Object.hash('whistle', next);
}

class PomodoroPhaseFinished extends PomodoroPhase {
  const PomodoroPhaseFinished();
}

/// Snapshot the engine emits on every tick. Push-only state — the run view
/// reads this and draws.
class PomodoroSnapshot {
  final PomodoroPhase phase;
  final double phaseSecondsRemaining;
  final double phaseTotalSeconds;
  final int groupIndex;
  final int roundIndex; // 0-based within the current group's repetitions
  final int intervalIndex; // 0-based within the current group's intervals
  final double elapsedTotalSeconds;
  final double totalSeconds;

  const PomodoroSnapshot({
    required this.phase,
    required this.phaseSecondsRemaining,
    required this.phaseTotalSeconds,
    required this.groupIndex,
    required this.roundIndex,
    required this.intervalIndex,
    required this.elapsedTotalSeconds,
    required this.totalSeconds,
  });

  static const idle = PomodoroSnapshot(
    phase: PomodoroPhaseIdle(),
    phaseSecondsRemaining: 0,
    phaseTotalSeconds: 0,
    groupIndex: 0,
    roundIndex: 0,
    intervalIndex: 0,
    elapsedTotalSeconds: 0,
    totalSeconds: 0,
  );

  PomodoroSnapshot copyWith({
    PomodoroPhase? phase,
    double? phaseSecondsRemaining,
    double? phaseTotalSeconds,
    int? groupIndex,
    int? roundIndex,
    int? intervalIndex,
    double? elapsedTotalSeconds,
    double? totalSeconds,
  }) => PomodoroSnapshot(
    phase: phase ?? this.phase,
    phaseSecondsRemaining: phaseSecondsRemaining ?? this.phaseSecondsRemaining,
    phaseTotalSeconds: phaseTotalSeconds ?? this.phaseTotalSeconds,
    groupIndex: groupIndex ?? this.groupIndex,
    roundIndex: roundIndex ?? this.roundIndex,
    intervalIndex: intervalIndex ?? this.intervalIndex,
    elapsedTotalSeconds: elapsedTotalSeconds ?? this.elapsedTotalSeconds,
    totalSeconds: totalSeconds ?? this.totalSeconds,
  );
}

class PomodoroEngine {
  PomodoroSnapshot _snapshot = PomodoroSnapshot.idle;
  bool _isRunning = false;
  TrainingPomodoro? _plan;

  final _snapshotController = StreamController<PomodoroSnapshot>.broadcast();
  final _phaseController = StreamController<PomodoroPhase>.broadcast();

  /// Stream of snapshots emitted on every tick (~10 Hz).
  Stream<PomodoroSnapshot> get snapshots => _snapshotController.stream;

  /// Stream of phase transitions only.
  Stream<PomodoroPhase> get phaseChanges => _phaseController.stream;

  /// Current snapshot — poll this if not subscribing to the stream.
  PomodoroSnapshot get snapshot => _snapshot;

  bool get isRunning => _isRunning;
  TrainingPomodoro? get plan => _plan;

  static const double _tickHz = 10;
  Timer? _ticker;

  void load(TrainingPomodoro plan) {
    stop();
    _plan = plan;
    _updateSnapshot(
      PomodoroSnapshot(
        phase: const PomodoroPhaseIdle(),
        phaseSecondsRemaining: 0,
        phaseTotalSeconds: 0,
        groupIndex: 0,
        roundIndex: 0,
        intervalIndex: 0,
        elapsedTotalSeconds: 0,
        totalSeconds: plan.totalSeconds.toDouble(),
      ),
    );
  }

  void start() {
    final plan = _plan;
    if (plan == null || plan.groups.isEmpty) return;
    _isRunning = true;
    _beginWhistle(_firstIntervalKind() ?? WorkRest.work);
    _spinTicker();
  }

  void togglePause() {
    if (_isRunning) {
      _isRunning = false;
      _ticker?.cancel();
      _ticker = null;
    } else {
      _isRunning = true;
      _spinTicker();
    }
  }

  void skipPhase() => _advanceToNextPhase();

  void skipToNextGroup() {
    final plan = _plan;
    if (plan == null) return;
    final nextGroupIdx = _snapshot.groupIndex + 1;
    if (nextGroupIdx < plan.groups.length) {
      final nextGroup = plan.groups[nextGroupIdx];
      _updateSnapshot(
        _snapshot.copyWith(
          groupIndex: nextGroupIdx,
          roundIndex: 0,
          intervalIndex: 0,
        ),
      );
      _beginWhistle(
        nextGroup.intervals.isNotEmpty
            ? nextGroup.intervals.first.kind
            : WorkRest.work,
      );
    } else {
      _finish();
    }
  }

  void skipToPreviousGroup() {
    final plan = _plan;
    if (plan == null || plan.groups.isEmpty) return;
    final prevGroupIdx = (_snapshot.groupIndex - 1).clamp(
      0,
      plan.groups.length - 1,
    );
    final group = plan.groups[prevGroupIdx];
    _updateSnapshot(
      _snapshot.copyWith(
        groupIndex: prevGroupIdx,
        roundIndex: 0,
        intervalIndex: 0,
      ),
    );
    _beginWhistle(
      group.intervals.isNotEmpty ? group.intervals.first.kind : WorkRest.work,
    );
  }

  void stop() {
    _isRunning = false;
    _ticker?.cancel();
    _ticker = null;
    _updateSnapshot(
      PomodoroSnapshot(
        phase: const PomodoroPhaseIdle(),
        phaseSecondsRemaining: 0,
        phaseTotalSeconds: 0,
        groupIndex: 0,
        roundIndex: 0,
        intervalIndex: 0,
        elapsedTotalSeconds: 0,
        totalSeconds: _snapshot.totalSeconds,
      ),
    );
  }

  void dispose() {
    stop();
    _snapshotController.close();
    _phaseController.close();
  }

  // ---------------------------------------------------------------------------
  // Phase logic

  WorkRest? _firstIntervalKind() =>
      _plan?.groups.firstOrNull?.intervals.firstOrNull?.kind;

  void _beginWhistle(WorkRest next) {
    final plan = _plan;
    if (plan == null) return;
    final newPhase = PomodoroPhaseWhistle(next);
    _updateSnapshot(
      _snapshot.copyWith(
        phase: newPhase,
        phaseTotalSeconds: plan.whistleSeconds,
        phaseSecondsRemaining: plan.whistleSeconds,
      ),
    );
    _phaseController.add(newPhase);
  }

  void _beginInterval(int groupIdx, int roundIdx, int intervalIdx) {
    final plan = _plan;
    if (plan == null || groupIdx >= plan.groups.length) {
      _finish();
      return;
    }
    final group = plan.groups[groupIdx];
    if (intervalIdx >= group.intervals.length) {
      // End of round in this group: bump round, or move to next group.
      if (roundIdx + 1 < group.repetitions) {
        _updateSnapshot(
          _snapshot.copyWith(
            groupIndex: groupIdx,
            roundIndex: roundIdx + 1,
            intervalIndex: 0,
          ),
        );
        _beginWhistle(
          group.intervals.isNotEmpty
              ? group.intervals.first.kind
              : WorkRest.work,
        );
      } else if (groupIdx + 1 < plan.groups.length) {
        final nextGroup = plan.groups[groupIdx + 1];
        _updateSnapshot(
          _snapshot.copyWith(
            groupIndex: groupIdx + 1,
            roundIndex: 0,
            intervalIndex: 0,
          ),
        );
        _beginWhistle(
          nextGroup.intervals.isNotEmpty
              ? nextGroup.intervals.first.kind
              : WorkRest.work,
        );
      } else {
        _finish();
      }
      return;
    }
    final interval = group.intervals[intervalIdx];
    final newPhase = interval.kind == WorkRest.work
        ? const PomodoroPhaseWork()
        : const PomodoroPhaseRest();
    _updateSnapshot(
      _snapshot.copyWith(
        phase: newPhase,
        phaseTotalSeconds: interval.durationSeconds.toDouble(),
        phaseSecondsRemaining: interval.durationSeconds.toDouble(),
        groupIndex: groupIdx,
        roundIndex: roundIdx,
        intervalIndex: intervalIdx,
      ),
    );
    _phaseController.add(newPhase);
  }

  void _advanceToNextPhase() {
    final plan = _plan;
    if (plan == null) return;
    final phase = _snapshot.phase;
    if (phase is PomodoroPhaseWhistle) {
      // Whistle ends; start the interval at the current cursor.
      _beginInterval(
        _snapshot.groupIndex,
        _snapshot.roundIndex,
        _snapshot.intervalIndex,
      );
    } else if (phase is PomodoroPhaseWork || phase is PomodoroPhaseRest) {
      final group = plan.groups[_snapshot.groupIndex];
      final nextIntervalIdx = _snapshot.intervalIndex + 1;
      if (nextIntervalIdx < group.intervals.length) {
        final upcoming = group.intervals[nextIntervalIdx].kind;
        _updateSnapshot(_snapshot.copyWith(intervalIndex: nextIntervalIdx));
        _beginWhistle(upcoming);
      } else if (_snapshot.roundIndex + 1 < group.repetitions) {
        final upcoming = group.intervals.isNotEmpty
            ? group.intervals.first.kind
            : WorkRest.work;
        _updateSnapshot(
          _snapshot.copyWith(
            roundIndex: _snapshot.roundIndex + 1,
            intervalIndex: 0,
          ),
        );
        _beginWhistle(upcoming);
      } else if (_snapshot.groupIndex + 1 < plan.groups.length) {
        final nextGroup = plan.groups[_snapshot.groupIndex + 1];
        final upcoming = nextGroup.intervals.isNotEmpty
            ? nextGroup.intervals.first.kind
            : WorkRest.work;
        _updateSnapshot(
          _snapshot.copyWith(
            groupIndex: _snapshot.groupIndex + 1,
            roundIndex: 0,
            intervalIndex: 0,
          ),
        );
        _beginWhistle(upcoming);
      } else {
        _finish();
      }
    }
    // idle / finished: no-op
  }

  void _finish() {
    const newPhase = PomodoroPhaseFinished();
    _updateSnapshot(
      _snapshot.copyWith(phase: newPhase, phaseSecondsRemaining: 0),
    );
    _isRunning = false;
    _ticker?.cancel();
    _ticker = null;
    _phaseController.add(newPhase);
  }

  // ---------------------------------------------------------------------------
  // Ticker

  void _spinTicker() {
    _ticker?.cancel();
    final interval = Duration(microseconds: (1_000_000 / _tickHz).round());
    _ticker = Timer.periodic(interval, (_) => _tick(1.0 / _tickHz));
  }

  void _tick(double seconds) {
    if (!_isRunning) return;
    final remaining = _snapshot.phaseSecondsRemaining - seconds;
    var elapsed = _snapshot.elapsedTotalSeconds;
    final phase = _snapshot.phase;
    if (phase is! PomodoroPhaseIdle &&
        phase is! PomodoroPhaseFinished &&
        phase is! PomodoroPhaseWhistle) {
      elapsed += seconds;
    }
    if (remaining <= 0) {
      _advanceToNextPhase();
      return;
    }
    _updateSnapshot(
      _snapshot.copyWith(
        phaseSecondsRemaining: remaining.clamp(0.0, double.infinity),
        elapsedTotalSeconds: elapsed,
      ),
    );
  }

  void _updateSnapshot(PomodoroSnapshot s) {
    _snapshot = s;
    _snapshotController.add(s);
  }
}
