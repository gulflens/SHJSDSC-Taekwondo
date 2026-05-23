import 'package:flutter/material.dart';

import '../../app/locator.dart';
import '../../core/models/athlete.dart';
import '../../core/repository/repository.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../athletes/athlete_detail_screen.dart';
import '../common/design_system.dart';
import '../common/development_localized_labels.dart';

/// Port of `CoachingDevelopmentView` (subset) — the Technical Director's view of
/// the SSDC coaching pathway. An assistant coach is an [Athlete] carrying an
/// `assistantCoach` dossier; this lists them with pipeline rung, mentor,
/// branch, assisted sessions and promotion readiness. Tap → the athlete's
/// full profile.
class CoachingDevelopmentScreen extends StatelessWidget {
  const CoachingDevelopmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.developmentTitle)),
      body: FutureBuilder<List<_Row>>(
        future: _load(getIt<Repository>()),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final rows = snap.data!;
          if (rows.isEmpty) {
            return Center(child: Text(l.developmentEmpty));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: rows.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _AssistantCard(row: rows[i]),
          );
        },
      ),
    );
  }

  Future<List<_Row>> _load(Repository repo) async {
    final athletes = await repo.athletes();
    final assistants = athletes.where((a) => a.assistantCoach != null).toList();
    final branches = {for (final b in await repo.branches()) b.id: b.name};
    final coaches = {for (final c in await repo.coaches()) c.id: c.fullName};
    return assistants.map((a) {
      final p = a.assistantCoach!;
      return _Row(
        athlete: a,
        mentorName: coaches[p.supervisingCoachId] ?? '—',
        branchName: branches[p.primaryBranchId] ?? '—',
      );
    }).toList()
      ..sort((x, y) => y.athlete.assistantCoach!.promotionReadiness
          .compareTo(x.athlete.assistantCoach!.promotionReadiness));
  }
}

class _Row {
  final Athlete athlete;
  final String mentorName;
  final String branchName;
  const _Row(
      {required this.athlete,
      required this.mentorName,
      required this.branchName});
}

class _AssistantCard extends StatelessWidget {
  final _Row row;
  const _AssistantCard({required this.row});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final scheme = Theme.of(context).colorScheme;
    final a = row.athlete;
    final p = a.assistantCoach!;
    final readiness = (p.promotionReadiness * 100).round();
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AthleteDetailScreen(athleteId: a.id),
        ),
      ),
      child: SectionCard(
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
                      const SizedBox(height: 4),
                      StatusPill(
                        label: p.developmentLevel.localized(l),
                        color: scheme.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _Meta(
                      label: l.devMentor,
                      value: row.mentorName,
                      branch: row.branchName),
                ),
                _Readiness(pct: readiness),
              ],
            ),
            const SizedBox(height: 8),
            Text(l.devSessions(p.assistedSessionCount),
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  final String label;
  final String value;
  final String branch;
  const _Meta(
      {required this.label, required this.value, required this.branch});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: $value',
            style: const TextStyle(fontWeight: FontWeight.w500)),
        Text(branch, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _Readiness extends StatelessWidget {
  final int pct;
  const _Readiness({required this.pct});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final color = pct >= 70 ? AppColors.good : AppColors.behind;
    return Column(
      children: [
        Directionality(
          textDirection: TextDirection.ltr,
          child: Text('$pct%',
              style: TextStyle(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()])),
        ),
        Text(l.devReadiness, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
