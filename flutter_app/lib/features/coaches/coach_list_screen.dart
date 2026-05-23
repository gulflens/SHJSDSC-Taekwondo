import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/locator.dart';
import '../../core/models/coach_extras.dart';
import '../../core/models/entity_id.dart';
import '../../core/repository/repository.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../common/coach_localized_labels.dart';
import '../common/design_system.dart';
import 'coach_detail_screen.dart';
import 'coach_list_cubit.dart';

/// Port of `CoachListView` (Features/Coaches/CoachListView.swift) — the twin of
/// `AthleteListScreen`. Header + search + roster cards; the executive analytics
/// row and two-panel iPad layout land in the full module stage.
class CoachListScreen extends StatelessWidget {
  /// When set, scoped to one branch (branch-manager experience).
  final EntityID? branchId;
  const CoachListScreen({super.key, this.branchId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          CoachListCubit(getIt<Repository>(), branchScope: branchId)..load(),
      child: const _CoachListBody(),
    );
  }
}

class _CoachListBody extends StatelessWidget {
  const _CoachListBody();

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.coachesTitle)),
      body: BlocBuilder<CoachListCubit, CoachListState>(
        builder: (context, state) {
          switch (state.status) {
            case CoachListStatus.initial:
            case CoachListStatus.loading:
              return const Center(child: CircularProgressIndicator());
            case CoachListStatus.failed:
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l.loadFailed),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => context.read<CoachListCubit>().load(),
                      child: Text(l.actionRetry),
                    ),
                  ],
                ),
              );
            case CoachListStatus.ready:
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: TextField(
                      onChanged: context.read<CoachListCubit>().search,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: l.coachesSearch,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.chip),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: state.visible.isEmpty
                        ? Center(child: Text(l.coachesEmpty))
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: state.visible.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 12),
                            itemBuilder: (context, i) =>
                                _CoachCard(intel: state.visible[i]),
                          ),
                  ),
                ],
              );
          }
        },
      ),
    );
  }
}

/// Mirrors `CoachPerformanceCard`.
class _CoachCard extends StatelessWidget {
  final CoachIntel intel;
  const _CoachCard({required this.intel});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final c = intel.coach;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.card),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => CoachDetailScreen(coachId: c.id)),
      ),
      child: SectionCard(
        child: Row(
          children: [
            CircleAvatar(radius: 26, child: Text(c.initials)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.fullName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(
                    '${intel.branchName} · ${l.coachDanRank(c.danRank)} · ${l.coachYearsExp(c.yearsOfExperience)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 6, children: [
                    StatusPill(
                      label: c.employmentStatus.localized(l),
                      color: employmentColor(c.employmentStatus, context),
                    ),
                    if (c.coachLevel != null)
                      StatusPill(
                        label: c.coachLevel!.localized(l),
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    StatusPill(
                      label: l.coachAthletesCount(intel.athleteCount),
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ]),
                ],
              ),
            ),
            const SizedBox(width: 12),
            GradeRing(composite: intel.composite, grade: intel.grade, size: 56),
          ],
        ),
      ),
    );
  }
}

Color employmentColor(CoachEmploymentStatus status, BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  return switch (status) {
    CoachEmploymentStatus.active => AppColors.good,
    CoachEmploymentStatus.leave => AppColors.behind,
    CoachEmploymentStatus.transferred => scheme.primary,
    CoachEmploymentStatus.retired => scheme.outline,
    CoachEmploymentStatus.suspended => AppColors.critical,
  };
}
