import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/locator.dart';
import '../../core/blocs/live_match_cubit.dart';
import '../../core/models/athlete.dart';
import '../../core/models/match.dart';
import '../../core/models/tournament.dart' show WeightCategory;
import '../../core/repository/repository.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../common/design_system.dart';
import '../common/score_action_labels.dart';

const _chungColor = Color(0xFF1F6FEB); // blue
const _hongColor = Color(0xFFE53935); // red

/// Port of the live-match setup (Features/Tournaments/LiveMatch/). Pick an
/// athlete + name the opponent, then launch the live scoreboard.
class LiveMatchSetupScreen extends StatefulWidget {
  const LiveMatchSetupScreen({super.key});

  @override
  State<LiveMatchSetupScreen> createState() => _LiveMatchSetupScreenState();
}

class _LiveMatchSetupScreenState extends State<LiveMatchSetupScreen> {
  late final Future<List<Athlete>> _athletes = getIt<Repository>().athletes();
  final _opponent = TextEditingController();
  Athlete? _selected;

  @override
  void dispose() {
    _opponent.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.lmSetupTitle)),
      body: FutureBuilder<List<Athlete>>(
        future: _athletes,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final athletes = snap.data!;
          _selected ??= athletes.isNotEmpty ? athletes.first : null;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<Athlete>(
                      initialValue: _selected,
                      decoration: const InputDecoration(border: InputBorder.none),
                      items: [
                        for (final a in athletes)
                          DropdownMenuItem(value: a, child: Text(a.fullName)),
                      ],
                      onChanged: (a) => setState(() => _selected = a),
                    ),
                    const Divider(),
                    TextField(
                      controller: _opponent,
                      decoration: InputDecoration(
                        labelText: l.lmOpponent,
                        hintText: l.lmOpponentHint,
                        border: InputBorder.none,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: (_selected != null && _opponent.text.trim().isNotEmpty)
                    ? () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => LiveMatchScoringScreen(
                              athlete: _selected!,
                              opponentName: _opponent.text.trim(),
                            ),
                          ),
                        )
                    : null,
                icon: const Icon(Icons.sports_kabaddi),
                label: Text(l.lmStart),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Port of `LiveMatchView` — the in-ring scoreboard driving [LiveMatchCubit].
class LiveMatchScoringScreen extends StatelessWidget {
  final Athlete athlete;
  final String opponentName;
  const LiveMatchScoringScreen({
    super.key,
    required this.athlete,
    required this.opponentName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LiveMatchCubit(getIt())
        ..startMatch(
          athlete: athlete,
          opponentName: opponentName,
          weightCategory: athlete.weightClass ?? WeightCategory.seniorsUnder68,
        ),
      child: _ScoringBody(athleteName: athlete.fullName, opponentName: opponentName),
    );
  }
}

class _ScoringBody extends StatelessWidget {
  final String athleteName;
  final String opponentName;
  const _ScoringBody({required this.athleteName, required this.opponentName});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    return BlocBuilder<LiveMatchCubit, LiveMatchState>(
      builder: (context, state) {
        final cubit = context.read<LiveMatchCubit>();
        final m = state.match;
        if (m == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return Scaffold(
          appBar: AppBar(title: Text(l.liveMatchTitle)),
          body: SafeArea(
            child: Column(
              children: [
                _Scoreboard(state: state, cubit: cubit),
                if (state.winner != null) _WinnerBanner(
                  state: state,
                  athleteName: athleteName,
                  opponentName: opponentName,
                ),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _SidePanel(
                          name: athleteName,
                          tag: l.lmBlue,
                          color: _chungColor,
                          side: MatchSide.chung,
                          cubit: cubit,
                          enabled: !state.isFinalized,
                        ),
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(
                        child: _SidePanel(
                          name: opponentName,
                          tag: l.lmRed,
                          color: _hongColor,
                          side: MatchSide.hong,
                          cubit: cubit,
                          enabled: !state.isFinalized,
                        ),
                      ),
                    ],
                  ),
                ),
                _BottomControls(state: state, cubit: cubit),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Scoreboard extends StatelessWidget {
  final LiveMatchState state;
  final LiveMatchCubit cubit;
  const _Scoreboard({required this.state, required this.cubit});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final m = state.match!;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(child: _ScoreBox(score: m.ourScore, color: _chungColor)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l.lmRoundFmt(state.currentRound, m.rounds),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(state.formattedTime,
                      style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          fontFeatures: [FontFeature.tabularFigures()])),
                ),
                IconButton(
                  onPressed: state.isFinalized ? null : cubit.togglePause,
                  icon: Icon(
                      state.isTimerRunning ? Icons.pause : Icons.play_arrow),
                ),
              ],
            ),
          ),
          Expanded(child: _ScoreBox(score: m.opponentScore, color: _hongColor)),
        ],
      ),
    );
  }
}

class _ScoreBox extends StatelessWidget {
  final int score;
  final Color color;
  const _ScoreBox({required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      alignment: Alignment.center,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Text('$score',
            style: TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.w800,
                color: color,
                fontFeatures: const [FontFeature.tabularFigures()])),
      ),
    );
  }
}

class _SidePanel extends StatelessWidget {
  final String name;
  final String tag;
  final Color color;
  final MatchSide side;
  final LiveMatchCubit cubit;
  final bool enabled;
  const _SidePanel({
    required this.name,
    required this.tag,
    required this.color,
    required this.side,
    required this.cubit,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    const actions = [
      ScoreAction.headKick,
      ScoreAction.bodyKick,
      ScoreAction.turnBodyKick,
      ScoreAction.turnHeadKick,
      ScoreAction.punch,
      ScoreAction.penalty,
    ];
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Text(name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.w700, color: color)),
          Text(tag, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          for (final a in actions)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    backgroundColor: a == ScoreAction.penalty
                        ? null
                        : color.withValues(alpha: 0.14),
                    foregroundColor: a == ScoreAction.penalty ? null : color,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: enabled ? () => cubit.recordEvent(side, a) : null,
                  child: Text(
                    a == ScoreAction.penalty
                        ? a.localized(l)
                        : '${a.localized(l)} +${a.points}',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          TextButton.icon(
            onPressed: enabled ? () => cubit.undoLast(side) : null,
            icon: const Icon(Icons.undo, size: 18),
            label: Text(l.lmUndo),
          ),
        ],
      ),
    );
  }
}

class _WinnerBanner extends StatelessWidget {
  final LiveMatchState state;
  final String athleteName;
  final String opponentName;
  const _WinnerBanner({
    required this.state,
    required this.athleteName,
    required this.opponentName,
  });

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final winnerName =
        state.winner == MatchSide.chung ? athleteName : opponentName;
    final color = state.winner == MatchSide.chung ? _chungColor : _hongColor;
    return Container(
      width: double.infinity,
      color: color.withValues(alpha: 0.14),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        l.lmWinnerFmt(winnerName),
        textAlign: TextAlign.center,
        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 16),
      ),
    );
  }
}

class _BottomControls extends StatelessWidget {
  final LiveMatchState state;
  final LiveMatchCubit cubit;
  const _BottomControls({required this.state, required this.cubit});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final m = state.match!;
    final canNext = state.currentRound < m.rounds && !state.isFinalized;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: state.isFinalized ? null : cubit.endRound,
              child: Text(l.lmEndRound),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              onPressed: canNext ? cubit.startNextRound : null,
              child: Text(l.lmNextRound),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FilledButton(
              onPressed: state.isFinalized
                  ? null
                  : () => cubit.finalize(MedalType.none),
              child: Text(l.lmFinalize),
            ),
          ),
        ],
      ),
    );
  }
}
