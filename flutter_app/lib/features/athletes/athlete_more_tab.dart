import 'package:flutter/material.dart';

import '../../app/locator.dart';
import '../../core/models/athlete.dart';
import '../../core/models/belt.dart';
import '../../core/models/goal.dart';
import '../../core/repository/repository.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../common/design_system.dart';
import '../common/goal_labels.dart';
import '../common/localized_labels.dart';

/// Port of `AthleteMoreTab` (subset) — belt progression, emergency contacts,
/// and goals. Belt history + contacts come off the embedded `Athlete`; goals
/// are loaded from the repository.
class AthleteMoreTab extends StatelessWidget {
  final Athlete athlete;
  const AthleteMoreTab({super.key, required this.athlete});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    // Progression = history (oldest→newest) then the current belt.
    final belts = [...athlete.beltHistory]
      ..sort((a, b) => a.awardedAt.compareTo(b.awardedAt));
    belts.add(athlete.currentBelt);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Section(
          title: l.moreBeltProgression,
          child: Column(
            children: [for (final b in belts) _BeltRow(belt: b)],
          ),
        ),
        const SizedBox(height: 12),
        _Section(
          title: l.moreEmergencyContacts,
          child: athlete.emergencyContacts.isEmpty
              ? Text(l.moreNone, style: Theme.of(context).textTheme.bodySmall)
              : Column(
                  children: [
                    for (final c in athlete.emergencyContacts)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.contact_phone_outlined),
                        title: Text(c.name),
                        subtitle: Text(c.relationship),
                        trailing: Directionality(
                          textDirection: TextDirection.ltr,
                          child: Text(c.phone,
                              style: Theme.of(context).textTheme.bodySmall),
                        ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 12),
        _GoalsSection(athleteId: athlete.id),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _BeltRow extends StatelessWidget {
  final Belt belt;
  const _BeltRow({required this.belt});

  Color get _dot {
    final h = belt.color.hex.replaceFirst('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final d = belt.awardedAt;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: _dot,
              shape: BoxShape.circle,
              border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(belt.color.localized(l))),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text('${d.year}',
                style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

class _GoalsSection extends StatelessWidget {
  final String athleteId;
  const _GoalsSection({required this.athleteId});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    return FutureBuilder<List<Goal>>(
      future: getIt<Repository>().goals(athleteId),
      builder: (context, snap) {
        final goals = snap.data ?? const [];
        return _Section(
          title: l.moreGoals,
          child: !snap.hasData
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(child: CircularProgressIndicator()),
                )
              : goals.isEmpty
                  ? Text(l.moreNone, style: Theme.of(context).textTheme.bodySmall)
                  : Column(
                      children: [for (final g in goals) _GoalRow(goal: g)],
                    ),
        );
      },
    );
  }
}

class _GoalRow extends StatelessWidget {
  final Goal goal;
  const _GoalRow({required this.goal});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final color = switch (goal.status) {
      GoalStatus.completed => AppColors.good,
      GoalStatus.active => Theme.of(context).colorScheme.primary,
      GoalStatus.abandoned => Theme.of(context).colorScheme.outline,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(goal.title)),
          const SizedBox(width: 8),
          StatusPill(label: goal.status.localized(l), color: color),
        ],
      ),
    );
  }
}
