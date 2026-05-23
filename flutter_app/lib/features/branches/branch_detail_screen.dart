import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/locator.dart';
import '../../core/blocs/branch_profile_cubit.dart';
import '../../core/models/entity_id.dart';
import '../../core/services/branch_metrics.dart';
import '../../core/services/score_engine.dart' show LetterGrade;
import '../../l10n/app_localizations.dart';
import '../common/branch_localized_labels.dart';
import '../common/design_system.dart';

/// Port of `BranchProfileView`'s Overview tab (subset) — header + operational
/// console. Uses the already-ported [BranchProfileCubit] (full dossier +
/// [BranchOperationalMetrics]). The composite/grade ring value is passed from
/// the overview (already computed there) to avoid recomputation.
class BranchDetailScreen extends StatelessWidget {
  final EntityID branchId;
  final double composite;
  final LetterGrade grade;

  const BranchDetailScreen({
    super.key,
    required this.branchId,
    required this.composite,
    required this.grade,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BranchProfileCubit(getIt())..load(branchId),
      child: _BranchDetailBody(composite: composite, grade: grade),
    );
  }
}

class _BranchDetailBody extends StatelessWidget {
  final double composite;
  final LetterGrade grade;
  const _BranchDetailBody({required this.composite, required this.grade});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    return Scaffold(
      body: BlocBuilder<BranchProfileCubit, BranchProfileState>(
        builder: (context, state) {
          if (state.status == BranchProfileStatus.failed) {
            return Center(child: Text(l.loadFailed));
          }
          if (state.branch == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final b = state.branch!;
          return CustomScrollView(
            slivers: [
              SliverAppBar.large(title: Text(b.name), pinned: true),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList.list(children: [
                  _Header(
                    name: b.name,
                    nameAr: b.nameAr,
                    statusLabel: b.operationalStatus.localized(l),
                    focus: b.focus,
                    isMain: b.isMain,
                    composite: composite,
                    grade: grade,
                  ),
                  const SizedBox(height: 16),
                  _OperationsCard(metrics: state.metrics),
                ]),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String name;
  final String nameAr;
  final String statusLabel;
  final String focus;
  final bool isMain;
  final double composite;
  final LetterGrade grade;

  const _Header({
    required this.name,
    required this.nameAr,
    required this.statusLabel,
    required this.focus,
    required this.isMain,
    required this.composite,
    required this.grade,
  });

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    return SectionCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 20)),
                Text(nameAr, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  if (isMain)
                    StatusPill(
                        label: l.branchMainBadge,
                        color: Theme.of(context).colorScheme.secondary),
                  StatusPill(
                      label: statusLabel,
                      color: Theme.of(context).colorScheme.primary),
                  if (focus.isNotEmpty)
                    StatusPill(
                        label: focus,
                        color: Theme.of(context).colorScheme.outline),
                ]),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GradeRing(composite: composite, grade: grade, size: 64),
        ],
      ),
    );
  }
}

/// Mirrors the branch operations KPI strip from the operational console.
class _OperationsCard extends StatelessWidget {
  final BranchOperationalMetrics metrics;
  const _OperationsCard({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final rows = <(String, String)>[
      (l.metricRegistered, '${metrics.registeredCount}'),
      (l.metricActive, '${metrics.activeCount}'),
      (l.branchUtilisation, '${metrics.utilisationPct.toStringAsFixed(0)}%'),
      (l.metricCompetitionTeam, '${metrics.competitionTeamCount}'),
      (l.metricReadyToGrade, '${metrics.readyToGradeCount}'),
      (l.metricAttendance, '${metrics.avgAttendancePct.toStringAsFixed(0)}%'),
      (l.metricSessionsWeek, '${metrics.sessionsPerWeek}'),
      (l.metricCoaches, '${metrics.totalCoaches}'),
      (l.metricSafeguarding,
          '${metrics.coachesWithCurrentSafeguardingPct.toStringAsFixed(0)}%'),
    ];
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.branchOperations,
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          for (final (label, value) in rows) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodyMedium),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(value,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontFeatures: [FontFeature.tabularFigures()])),
                ),
              ],
            ),
            const Divider(height: 16),
          ],
        ],
      ),
    );
  }
}
