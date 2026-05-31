import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/locator.dart';
import '../../core/blocs/branches_cubit.dart';
import '../../core/services/report_exporter.dart' show BranchSummary;
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../common/branch_localized_labels.dart';
import '../common/design_system.dart';
import 'branch_detail_screen.dart';

/// Port of `BranchesOverviewView` (Features/Branches/) — the federation
/// overview. Hero gradient KPI card + dominant main-branch card + secondaries
/// grid. Uses the already-ported [BranchesCubit] (BranchSummary list). The
/// org-chart hierarchy + comparison charts land in the full module stage.
class BranchesOverviewScreen extends StatelessWidget {
  const BranchesOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BranchesCubit(getIt())..loadAll(),
      child: const _BranchesBody(),
    );
  }
}

class _BranchesBody extends StatelessWidget {
  const _BranchesBody();

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.branchesTitle)),
      body: BlocBuilder<BranchesCubit, BranchesState>(
        builder: (context, state) {
          switch (state.status) {
            case BranchesStatus.initial:
            case BranchesStatus.loading:
              return const Center(child: CircularProgressIndicator());
            case BranchesStatus.failed:
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l.loadFailed),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => context.read<BranchesCubit>().loadAll(),
                      child: Text(l.actionRetry),
                    ),
                  ],
                ),
              );
            case BranchesStatus.ready:
              final summaries = state.summaries;
              final main = summaries.where((s) => s.branch.isMain).toList();
              final others =
                  summaries.where((s) => !s.branch.isMain).toList();
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _KpiHero(summaries: summaries),
                  const SizedBox(height: 16),
                  for (final s in main) ...[
                    _BranchCard(summary: s, dominant: true),
                    const SizedBox(height: 12),
                  ],
                  if (others.isNotEmpty)
                    GridView.count(
                      crossAxisCount:
                          MediaQuery.sizeOf(context).width >= 600 ? 2 : 1,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 2.4,
                      children: [
                        for (final s in others) _BranchCard(summary: s),
                      ],
                    ),
                ],
              );
          }
        },
      ),
    );
  }
}

/// Mirrors the hero gradient KPI card aggregating all branches.
class _KpiHero extends StatelessWidget {
  final List<BranchSummary> summaries;
  const _KpiHero({required this.summaries});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final scheme = Theme.of(context).colorScheme;
    final totalAthletes =
        summaries.fold<int>(0, (a, s) => a + s.athleteCount);
    final avg = summaries.isEmpty
        ? 0.0
        : summaries.fold<double>(0, (a, s) => a + s.composite) /
            summaries.length;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.hero),
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.primary.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _KpiCell(value: '${summaries.length}', label: l.branchesKpiBranches),
          _KpiCell(value: '$totalAthletes', label: l.branchesKpiAthletes),
          _KpiCell(value: avg.toStringAsFixed(0), label: l.branchesKpiAvgScore),
        ],
      ),
    );
  }
}

class _KpiCell extends StatelessWidget {
  final String value;
  final String label;
  const _KpiCell({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Directionality(
          textDirection: TextDirection.ltr,
          child: Text(value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                fontFeatures: [FontFeature.tabularFigures()],
              )),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12)),
      ],
    );
  }
}

/// Mirrors `BranchCard`; `dominant` enlarges the main branch.
class _BranchCard extends StatelessWidget {
  final BranchSummary summary;
  final bool dominant;
  const _BranchCard({required this.summary, this.dominant = false});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final b = summary.branch;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.card),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BranchDetailScreen(
            branchId: b.id,
            composite: summary.composite,
            grade: summary.grade,
          ),
        ),
      ),
      child: SectionCard(
        padding: EdgeInsets.all(dominant ? 18 : 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(b.name,
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: dominant ? 20 : 16)),
                      ),
                      if (b.isMain) ...[
                        const SizedBox(width: 8),
                        StatusPill(
                            label: l.branchMainBadge,
                            color: Theme.of(context).colorScheme.secondary),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(b.operationalStatus.localized(l),
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 6, children: [
                    StatusPill(
                      label: l.branchAthletesCount(summary.athleteCount),
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    StatusPill(
                      label:
                          '${l.branchUtilisation} ${(summary.utilisation * 100).toStringAsFixed(0)}%',
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ]),
                ],
              ),
            ),
            const SizedBox(width: 12),
            GradeRing(
              composite: summary.composite,
              grade: summary.grade,
              size: dominant ? 64 : 52,
            ),
          ],
        ),
      ),
    );
  }
}
