import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/locator.dart';
import '../../app/role_router.dart';
import '../../core/models/athlete.dart';
import '../../core/models/entity_id.dart';
import '../../core/repository/repository.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../common/design_system.dart';
import '../common/localized_labels.dart';
import 'athlete_detail_screen.dart';
import 'athlete_list_cubit.dart';

/// Port of `AthleteListView` (Features/Athletes/AthleteListView.swift) — the
/// dashboard. This slice ports the header + search + roster cards; the
/// executive analytics row and two-panel iPad layout land in the full module
/// stage. Tapping a card pushes the detail (matching the iPhone push behaviour).
class AthleteListScreen extends StatelessWidget {
  /// When set, the roster is scoped to one branch (branch-manager experience).
  final EntityID? branchId;
  const AthleteListScreen({super.key, this.branchId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          AthleteListCubit(getIt<Repository>(), branchScope: branchId)..load(),
      child: const _AthleteListBody(),
    );
  }
}

class _AthleteListBody extends StatelessWidget {
  const _AthleteListBody();

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.athletesTitle),
        actions: [
          IconButton(
            tooltip: l.settingsRole,
            icon: const Icon(Icons.people_alt_outlined),
            onPressed: () => DemoRolePicker.show(context),
          ),
        ],
      ),
      body: BlocBuilder<AthleteListCubit, AthleteListState>(
        builder: (context, state) {
          switch (state.status) {
            case AthleteListStatus.initial:
            case AthleteListStatus.loading:
              return const Center(child: CircularProgressIndicator());
            case AthleteListStatus.failed:
              return _ErrorView(l: l, onRetry: () => context.read<AthleteListCubit>().load());
            case AthleteListStatus.ready:
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: TextField(
                      onChanged: context.read<AthleteListCubit>().search,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: l.athletesSearch,
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
                        ? Center(child: Text(l.athletesEmpty))
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: state.visible.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 12),
                            itemBuilder: (context, i) {
                              final intel = state.visible[i];
                              return _AthleteCard(intel: intel);
                            },
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

/// Mirrors `AthletePerformanceCard`.
class _AthleteCard extends StatelessWidget {
  final AthleteIntel intel;
  const _AthleteCard({required this.intel});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final a = intel.athlete;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.card),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => AthleteDetailScreen(athleteId: a.id)),
      ),
      child: SectionCard(
        child: Row(
          children: [
            CircleAvatar(radius: 26, child: Text(a.initials)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.fullName,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 2),
                  Text('${intel.branchName} · ${l.athleteMemberNo(a.memberNumber)}',
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      StatusPill(label: a.status.localized(l), color: statusColor(a.status, context)),
                      const SizedBox(width: 8),
                      StatusPill(
                          label: a.currentBelt.color.localized(l),
                          color: _hex(a.currentBelt.color.hex)),
                    ],
                  ),
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

class _ErrorView extends StatelessWidget {
  final L10n l;
  final VoidCallback onRetry;
  const _ErrorView({required this.l, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l.loadFailed),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: Text(l.actionRetry)),
          ],
        ),
      );
}

Color statusColor(AthleteStatus status, BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  return switch (status) {
    AthleteStatus.competitionTeam => scheme.primary,
    AthleteStatus.readyToGrade => AppColors.good,
    AthleteStatus.watch => AppColors.behind,
    AthleteStatus.rest => scheme.outline,
    AthleteStatus.active => scheme.secondary,
  };
}

Color _hex(String hex) {
  final h = hex.replaceFirst('#', '');
  return Color(int.parse('FF$h', radix: 16));
}
