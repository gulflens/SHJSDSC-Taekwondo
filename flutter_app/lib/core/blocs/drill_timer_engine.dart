import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../models/drill_timer.dart';
import '../models/entity_id.dart';

/// Port of Core/Stores/DrillTimerEngine.swift.
///
/// Drives a [DrillTimerSession] in real time. The session is flattened once
/// into a plain [List<DrillStep>] timeline (rounds expanded, lead-in and
/// round breaks inserted, athlete groups assigned) and then walked by a
/// cursor as the timer ticks.
///
/// Implemented as a Cubit<[DrillTimerState]> with a [Timer.periodic] ticker
/// at ~20 Hz — identical cadence to the Swift engine. The timer is cancelled
/// in [close] so the class is correctly lifecycle-managed.

// ──────────────────────────────────────────────────────────────────────────────
// Step — one resolved timeline entry
// ──────────────────────────────────────────────────────────────────────────────

/// One resolved entry on the timeline. Port of [DrillTimerEngine.Step].
class DrillStep extends Equatable {
  final EntityID id;
  final DrillTimerPhase phase;
  final int seconds;
  final String? label;
  final EntityID? drillId;

  /// 1-based; 0 for the lead-in.
  final int roundIndex;
  final int totalRounds;
  final String? groupName;

  DrillStep({
    EntityID? id,
    required this.phase,
    required this.seconds,
    this.label,
    this.drillId,
    required this.roundIndex,
    required this.totalRounds,
    this.groupName,
  }) : id = id ?? newEntityId();

  @override
  List<Object?> get props => [
    id,
    phase,
    seconds,
    label,
    drillId,
    roundIndex,
    totalRounds,
    groupName,
  ];
}

// ──────────────────────────────────────────────────────────────────────────────
// State
// ──────────────────────────────────────────────────────────────────────────────

class DrillTimerState extends Equatable {
  final List<DrillStep> steps;
  final int index;

  /// Fractional seconds remaining in the current step.
  final double remaining;
  final bool isRunning;
  final bool isFinished;
  final String sessionName;
  final int totalRounds;

  const DrillTimerState({
    this.steps = const [],
    this.index = 0,
    this.remaining = 0,
    this.isRunning = false,
    this.isFinished = false,
    this.sessionName = '',
    this.totalRounds = 1,
  });

  // ── Derived helpers ────────────────────────────────────────────────────────

  DrillStep? get current =>
      (index >= 0 && index < steps.length) ? steps[index] : null;

  DrillStep? get next {
    final n = index + 1;
    return (n >= 0 && n < steps.length) ? steps[n] : null;
  }

  DrillTimerPhase get phase {
    if (isFinished) return DrillTimerPhase.finished;
    return current?.phase ?? DrillTimerPhase.prepare;
  }

  /// 0 → 1 progress through the current step.
  double get stepProgress {
    final cur = current;
    if (cur == null || cur.seconds <= 0) return 0;
    return (1 - remaining / cur.seconds).clamp(0.0, 1.0);
  }

  int get totalDuration => steps.fold(0, (sum, s) => sum + s.seconds);

  double get elapsedTotal {
    if (steps.isEmpty) return 0;
    if (isFinished) return totalDuration.toDouble();
    final before = steps.take(index).fold<int>(0, (sum, s) => sum + s.seconds);
    final inStep = current != null
        ? (current!.seconds.toDouble() - remaining).clamp(0.0, double.infinity)
        : 0.0;
    return before + inStep;
  }

  /// 1-based index of the current work step (e.g. "Drill 3 of 8").
  int get workStepNumber {
    if (index >= steps.length) return totalWorkSteps;
    return steps
        .take(index + 1)
        .where((s) => s.phase == DrillTimerPhase.work)
        .length;
  }

  int get totalWorkSteps =>
      steps.where((s) => s.phase == DrillTimerPhase.work).length;

  DrillTimerState copyWith({
    List<DrillStep>? steps,
    int? index,
    double? remaining,
    bool? isRunning,
    bool? isFinished,
    String? sessionName,
    int? totalRounds,
  }) => DrillTimerState(
    steps: steps ?? this.steps,
    index: index ?? this.index,
    remaining: remaining ?? this.remaining,
    isRunning: isRunning ?? this.isRunning,
    isFinished: isFinished ?? this.isFinished,
    sessionName: sessionName ?? this.sessionName,
    totalRounds: totalRounds ?? this.totalRounds,
  );

  @override
  List<Object?> get props => [
    steps,
    index,
    remaining,
    isRunning,
    isFinished,
    sessionName,
    totalRounds,
  ];
}

// ──────────────────────────────────────────────────────────────────────────────
// Cubit
// ──────────────────────────────────────────────────────────────────────────────

class DrillTimerEngineCubit extends Cubit<DrillTimerState> {
  /// Tick rate — 20 Hz, matching the Swift engine.
  static const double _tickHz = 20;
  static const double _tickInterval = 1.0 / _tickHz;

  Timer? _ticker;

  /// Tracks the last whole second at which [onTick] fired (avoids duplicates).
  int _lastAnnouncedSecond = -1;

  // ── Audio/haptic callbacks (optional, wired at the feature layer) ──────────

  /// Called when a new step becomes current — feature layer plays cue audio.
  void Function(DrillStep step)? onEnterStep;

  /// Called once per whole second of a step's countdown — last-three-second
  /// beeps hook here.
  void Function(int secondsRemaining)? onTick;

  /// Called once when the whole session completes.
  void Function()? onFinish;

  DrillTimerEngineCubit() : super(const DrillTimerState());

  // ── Loading ────────────────────────────────────────────────────────────────

  /// Flatten [session] into the step timeline and reset all running state.
  /// Mirrors [DrillTimerEngine.load].
  void load(DrillTimerSession session) {
    _stopTicker();
    _lastAnnouncedSecond = -1;

    final steps = _buildTimeline(session);
    emit(
      DrillTimerState(
        steps: steps,
        index: 0,
        remaining: steps.isNotEmpty ? steps.first.seconds.toDouble() : 0,
        isRunning: false,
        isFinished: false,
        sessionName: session.name,
        totalRounds: session.rounds,
      ),
    );
  }

  // ── Transport ──────────────────────────────────────────────────────────────

  /// Start from the first step.
  void start() {
    final steps = state.steps;
    if (steps.isEmpty) return;
    _lastAnnouncedSecond = -1;
    emit(
      state.copyWith(
        index: 0,
        remaining: steps.first.seconds.toDouble(),
        isRunning: true,
        isFinished: false,
      ),
    );
    _announceStep();
    _spinTicker();
  }

  /// Pause / resume toggle.
  void togglePause() {
    if (state.isFinished || state.steps.isEmpty) return;
    if (state.isRunning) {
      _stopTicker();
      emit(state.copyWith(isRunning: false));
    } else {
      emit(state.copyWith(isRunning: true));
      _spinTicker();
    }
  }

  /// Skip to the next step.
  void skipForward() {
    if (state.steps.isEmpty) return;
    _goTo(state.index + 1);
  }

  /// Restart the current step if it is already underway (> 1.5s elapsed);
  /// otherwise jump to the previous step — familiar media-player behaviour.
  void skipBackward() {
    final cur = state.current;
    if (state.steps.isEmpty || cur == null) return;
    if (cur.seconds.toDouble() - state.remaining > 1.5) {
      _lastAnnouncedSecond = -1;
      emit(state.copyWith(remaining: cur.seconds.toDouble()));
    } else {
      _goTo(state.index - 1);
    }
  }

  /// Add bonus time to the current step (+10 s control).
  void addTime(int seconds) {
    if (state.current == null) return;
    emit(state.copyWith(remaining: state.remaining + seconds));
  }

  /// Reset to the beginning without starting.
  void reset() {
    _stopTicker();
    _lastAnnouncedSecond = -1;
    emit(
      state.copyWith(
        index: 0,
        remaining: state.steps.isNotEmpty
            ? state.steps.first.seconds.toDouble()
            : 0,
        isRunning: false,
        isFinished: false,
      ),
    );
  }

  // ── Cubit lifecycle ────────────────────────────────────────────────────────

  @override
  Future<void> close() {
    _stopTicker(); // cancels the timer — satisfies the RULES requirement
    return super.close();
  }

  // ── Private: cursor ────────────────────────────────────────────────────────

  void _goTo(int newIndex) {
    if (state.steps.isEmpty) return;
    if (newIndex >= state.steps.length) {
      _finish();
      return;
    }
    final idx = newIndex.clamp(0, state.steps.length - 1);
    _lastAnnouncedSecond = -1;
    emit(
      state.copyWith(
        index: idx,
        remaining: state.steps[idx].seconds.toDouble(),
      ),
    );
    _announceStep();
  }

  void _finish() {
    _stopTicker();
    emit(state.copyWith(isRunning: false, isFinished: true, remaining: 0));
    onFinish?.call();
  }

  void _announceStep() {
    final step = state.current;
    if (step == null) return;
    _lastAnnouncedSecond = -1;
    onEnterStep?.call(step);
  }

  // ── Private: ticker ────────────────────────────────────────────────────────

  void _spinTicker() {
    _stopTicker();
    final interval = Duration(microseconds: (1_000_000 / _tickHz).round());
    _ticker = Timer.periodic(interval, (_) => _tick());
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  void _tick() {
    if (!state.isRunning || state.isFinished) return;
    final newRemaining = state.remaining - _tickInterval;

    // Whole-second announcement for audio beeps.
    final whole = newRemaining.ceil();
    if (whole != _lastAnnouncedSecond && whole >= 0) {
      _lastAnnouncedSecond = whole;
      onTick?.call(whole);
    }

    if (newRemaining <= 0) {
      _goTo(state.index + 1);
    } else {
      emit(state.copyWith(remaining: newRemaining));
    }
  }

  // ── Private: timeline builder ──────────────────────────────────────────────

  /// Flatten [session] into a linear [DrillStep] list, expanding rounds and
  /// inserting prepare / round-break steps. Faithful port of the Swift
  /// `DrillTimerEngine.load` flatten logic.
  static List<DrillStep> _buildTimeline(DrillTimerSession session) {
    final built = <DrillStep>[];

    String? group(int roundNumber) {
      final groups = session.athleteGroups;
      if (groups.isEmpty) return null;
      return groups[(roundNumber - 1) % groups.length];
    }

    if (session.prepareSeconds > 0) {
      built.add(
        DrillStep(
          phase: DrillTimerPhase.prepare,
          seconds: session.prepareSeconds,
          roundIndex: 1,
          totalRounds: session.rounds,
          groupName: group(1),
        ),
      );
    }

    for (var r = 1; r <= session.rounds; r++) {
      for (final interval in session.intervals) {
        built.add(
          DrillStep(
            phase: interval.isWork
                ? DrillTimerPhase.work
                : DrillTimerPhase.rest,
            seconds: interval.seconds,
            label: interval.label,
            drillId: interval.drillId,
            roundIndex: r,
            totalRounds: session.rounds,
            groupName: group(r),
          ),
        );
      }
      if (r < session.rounds && session.roundBreakSeconds > 0) {
        built.add(
          DrillStep(
            phase: DrillTimerPhase.roundBreak,
            seconds: session.roundBreakSeconds,
            roundIndex: r,
            totalRounds: session.rounds,
            groupName: group(r + 1),
          ),
        );
      }
    }

    return built;
  }
}
