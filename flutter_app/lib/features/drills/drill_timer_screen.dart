import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/blocs/drill_timer_engine.dart';
import '../../core/models/drill_timer.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../common/design_system.dart';
import '../common/drill_timer_localized_labels.dart';

/// Port of `DrillTimerView` (setup) — preset picker that launches the live
/// run screen driven by the ported [DrillTimerEngineCubit]. No seed needed:
/// presets are built from the `DrillTimerSession` factory constructors.
class DrillTimerSetupScreen extends StatelessWidget {
  const DrillTimerSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final presets = <(String, String, DrillTimerSession Function())>[
      (l.presetTabata, l.presetTabataDesc, DrillTimerSession.tabata),
      (l.presetRounds, l.presetRoundsDesc, DrillTimerSession.roundsPreset),
      (l.presetEmom, l.presetEmomDesc, DrillTimerSession.emom),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l.drillTimerTitle)),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: presets.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final (name, desc, build) = presets[i];
          return InkWell(
            borderRadius: BorderRadius.circular(AppRadius.card),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => DrillTimerRunScreen(session: build()),
              ),
            ),
            child: SectionCard(
              child: Row(
                children: [
                  Icon(Icons.timer_outlined,
                      color: Theme.of(context).colorScheme.primary, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 16)),
                        const SizedBox(height: 2),
                        Text(desc,
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  const Icon(Icons.play_circle_fill, size: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Port of `DrillTimerRunView` — the live operational timer. Phase-tinted
/// canvas, countdown ring, round/drill context, transport controls.
class DrillTimerRunScreen extends StatelessWidget {
  final DrillTimerSession session;
  const DrillTimerRunScreen({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DrillTimerEngineCubit()..load(session),
      child: _RunBody(sessionName: session.name),
    );
  }
}

class _RunBody extends StatelessWidget {
  final String sessionName;
  const _RunBody({required this.sessionName});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    return BlocBuilder<DrillTimerEngineCubit, DrillTimerState>(
      builder: (context, state) {
        final cubit = context.read<DrillTimerEngineCubit>();
        final phase = state.phase;
        final tint = phaseColor(phase, context);
        return Scaffold(
          backgroundColor: tint.withValues(alpha: 0.08),
          appBar: AppBar(
            title: Text(sessionName),
            backgroundColor: Colors.transparent,
          ),
          body: SafeArea(
            child: Column(
              children: [
                const Spacer(),
                Text(
                  phase.localized(l),
                  style: TextStyle(
                      color: tint,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2),
                ),
                const SizedBox(height: 24),
                _CountdownRing(state: state, tint: tint),
                const SizedBox(height: 24),
                _Context(state: state),
                const Spacer(),
                _Transport(cubit: cubit, state: state),
                const SizedBox(height: 12),
                _SecondaryControls(cubit: cubit, state: state),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CountdownRing extends StatelessWidget {
  final DrillTimerState state;
  final Color tint;
  const _CountdownRing({required this.state, required this.tint});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final secs = state.remaining.ceil().clamp(0, 1 << 30);
    final mm = (secs ~/ 60).toString().padLeft(2, '0');
    final ss = (secs % 60).toString().padLeft(2, '0');
    return SizedBox(
      width: 240,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 240,
            height: 240,
            child: CircularProgressIndicator(
              value: state.isFinished ? 1 : state.stepProgress,
              strokeWidth: 14,
              backgroundColor: scheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(tint),
              strokeCap: StrokeCap.round,
            ),
          ),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              state.isFinished ? '00:00' : '$mm:$ss',
              style: TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.w700,
                color: tint,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Context extends StatelessWidget {
  final DrillTimerState state;
  const _Context({required this.state});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final cur = state.current;
    if (cur == null) return const SizedBox.shrink();
    return Column(
      children: [
        Text(l.timerRoundFmt(cur.roundIndex, cur.totalRounds),
            style: const TextStyle(fontWeight: FontWeight.w600)),
        if (state.totalWorkSteps > 0)
          Text(l.timerDrillFmt(state.workStepNumber, state.totalWorkSteps),
              style: Theme.of(context).textTheme.bodySmall),
        if ((cur.label ?? '').isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(cur.label!, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ],
    );
  }
}

class _Transport extends StatelessWidget {
  final DrillTimerEngineCubit cubit;
  final DrillTimerState state;
  const _Transport({required this.cubit, required this.state});

  void _primary() {
    if (state.isFinished) {
      cubit.reset();
    } else if (state.isRunning) {
      cubit.togglePause();
    } else if (state.elapsedTotal == 0) {
      cubit.start();
    } else {
      cubit.togglePause();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final IconData primaryIcon = state.isFinished
        ? Icons.replay
        : (state.isRunning ? Icons.pause : Icons.play_arrow);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton.filledTonal(
          iconSize: 28,
          onPressed: cubit.skipBackward,
          icon: const Icon(Icons.skip_previous),
        ),
        const SizedBox(width: 20),
        FloatingActionButton.large(
          backgroundColor: scheme.primary,
          onPressed: _primary,
          child: Icon(primaryIcon, size: 40),
        ),
        const SizedBox(width: 20),
        IconButton.filledTonal(
          iconSize: 28,
          onPressed: cubit.skipForward,
          icon: const Icon(Icons.skip_next),
        ),
      ],
    );
  }
}

class _SecondaryControls extends StatelessWidget {
  final DrillTimerEngineCubit cubit;
  final DrillTimerState state;
  const _SecondaryControls({required this.cubit, required this.state});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton.icon(
          onPressed: () => cubit.addTime(10),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('10s'),
        ),
        const SizedBox(width: 24),
        TextButton.icon(
          onPressed: cubit.reset,
          icon: const Icon(Icons.restart_alt, size: 18),
          label: Text(l.timerReset),
        ),
      ],
    );
  }
}

/// Phase tint — the color getter lives in the UI layer (kept out of `Core/`).
Color phaseColor(DrillTimerPhase phase, BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  return switch (phase) {
    DrillTimerPhase.prepare => AppColors.behind,
    DrillTimerPhase.work => scheme.primary,
    DrillTimerPhase.rest => AppColors.good,
    DrillTimerPhase.roundBreak => AppColors.behind,
    DrillTimerPhase.finished => scheme.outline,
  };
}
