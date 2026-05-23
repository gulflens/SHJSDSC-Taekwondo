import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/locator.dart';
import '../../core/blocs/grading_cubit.dart';
import '../../core/models/athlete.dart';
import '../../core/models/belt.dart';
import '../../core/models/grading.dart';
import '../../core/repository/repository.dart';
import '../../core/services/grading_engine.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../common/design_system.dart';
import '../common/grading_localized_labels.dart';
import '../common/localized_labels.dart';

/// Port of the Grading dashboard (Features/Grading/). Lists grading sessions
/// across branches via the ported [GradingCubit]; tap a session → candidate
/// roster with eligibility (computed by [GradingEngine] through the repository).
class GradingScreen extends StatelessWidget {
  const GradingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GradingCubit(getIt()),
      child: const _GradingBody(),
    );
  }
}

class _GradingBody extends StatefulWidget {
  const _GradingBody();

  @override
  State<_GradingBody> createState() => _GradingBodyState();
}

class _GradingBodyState extends State<_GradingBody> {
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final branches = await getIt<Repository>().branches();
    if (!mounted) return;
    await context.read<GradingCubit>().loadAll(branches);
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.gradingTitle)),
      body: BlocBuilder<GradingCubit, GradingState>(
        builder: (context, state) {
          if (state.status == GradingStatus.failed) {
            return Center(child: Text(l.loadFailed));
          }
          if (state.status != GradingStatus.ready) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.sessions.isEmpty) {
            return Center(child: Text(l.gradingEmpty));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: state.sessions.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final s = state.sessions[i];
              final p = state.progress(s.id);
              return _SessionCard(session: s, scored: p.scored, total: p.total);
            },
          );
        },
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final GradingSession session;
  final int scored;
  final int total;
  const _SessionCard(
      {required this.session, required this.scored, required this.total});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final d = session.scheduledAt;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.card),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => GradingSessionDetailScreen(session: session)),
      ),
      child: SectionCard(
        child: Row(
          children: [
            Directionality(
              textDirection: TextDirection.ltr,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${d.day}/${d.month}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          fontFeatures: [FontFeature.tabularFigures()])),
                  Text('${d.year}',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.gradingCandidates(session.candidateAthleteIds.length),
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text(l.gradingProgress(scored, total),
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            StatusPill(
              label: session.status.localized(l),
              color: _statusColor(session.status, context),
            ),
          ],
        ),
      ),
    );
  }
}

Color _statusColor(GradingSessionStatus s, BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  return switch (s) {
    GradingSessionStatus.scheduled => scheme.primary,
    GradingSessionStatus.inProgress => AppColors.behind,
    GradingSessionStatus.completed => AppColors.good,
    GradingSessionStatus.cancelled => scheme.outline,
  };
}

// ──────────────────────────────────────────────────────────────────────────────
// Session detail — candidate eligibility roster
// ──────────────────────────────────────────────────────────────────────────────

class _Candidate {
  final Athlete athlete;
  final Belt targetBelt;
  final GradingEligibility eligibility;
  const _Candidate(this.athlete, this.targetBelt, this.eligibility);
}

class GradingSessionDetailScreen extends StatefulWidget {
  final GradingSession session;
  const GradingSessionDetailScreen({super.key, required this.session});

  @override
  State<GradingSessionDetailScreen> createState() =>
      _GradingSessionDetailScreenState();
}

class _GradingSessionDetailScreenState
    extends State<GradingSessionDetailScreen> {
  late final Future<List<_Candidate>> _future = _load();

  Future<List<_Candidate>> _load() async {
    final repo = getIt<Repository>();
    final out = <_Candidate>[];
    for (final id in widget.session.candidateAthleteIds) {
      final athlete = await repo.athlete(id);
      if (athlete == null) continue;
      final target = GradingEngine.nextBelt(athlete.currentBelt);
      final elig = await repo.eligibility(athlete.id, target);
      out.add(_Candidate(athlete, target, elig));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.gradingTitle)),
      body: FutureBuilder<List<_Candidate>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final candidates = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: candidates.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _CandidateCard(candidate: candidates[i]),
          );
        },
      ),
    );
  }
}

class _CandidateCard extends StatelessWidget {
  final _Candidate candidate;
  const _CandidateCard({required this.candidate});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final a = candidate.athlete;
    final e = candidate.eligibility;
    final eligible = e.isEligible;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 22, child: Text(a.initials)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.fullName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 16)),
                    Text(
                      '${a.currentBelt.color.localized(l)} → ${candidate.targetBelt.color.localized(l)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              StatusPill(
                label: eligible ? l.gradingEligible : l.gradingNotEligible,
                color: eligible ? AppColors.good : AppColors.critical,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: l.gradingMonthsAtRank(e.monthsAtCurrent),
                ),
              ),
              Expanded(
                child: _MiniStat(
                  label: '${l.metricAttendance} ${e.attendancePct.toStringAsFixed(0)}%',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  const _MiniStat({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(fontWeight: FontWeight.w500));
  }
}
