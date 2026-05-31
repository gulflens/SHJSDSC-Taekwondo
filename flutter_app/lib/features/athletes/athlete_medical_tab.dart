import 'package:flutter/material.dart';

import '../../core/models/athlete.dart';
import '../../core/models/athlete_profile.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../common/design_system.dart';
import '../common/medical_localized_labels.dart';

/// Port of `AthleteMedicalTab` (subset) — vitals + chip lists + injury log +
/// weight history, all read from the embedded `Athlete` medical fields (no
/// extra fetch).
class AthleteMedicalTab extends StatelessWidget {
  final Athlete athlete;
  const AthleteMedicalTab({super.key, required this.athlete});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionCard(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _Vital(
                label: l.medBloodType,
                value: athlete.bloodType?.rawValue ?? '—',
              ),
              _Vital(
                label: l.medHeight,
                value: athlete.heightCm == null
                    ? '—'
                    : '${athlete.heightCm!.toStringAsFixed(0)} cm',
              ),
              Column(
                children: [
                  StatusPill(
                    label: athlete.fitToTrain ? l.medFitToTrain : l.medNotFit,
                    color: athlete.fitToTrain ? AppColors.good : AppColors.critical,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _ChipSection(title: l.medAllergies, items: athlete.allergies, tint: AppColors.behind),
        _ChipSection(title: l.medConditions, items: athlete.medicalConditions, tint: scheme.primary),
        _ChipSection(title: l.medMedications, items: athlete.medications, tint: scheme.secondary),
        const SizedBox(height: 8),
        _InjuryLog(athlete: athlete),
        const SizedBox(height: 16),
        _WeightHistory(athlete: athlete),
      ],
    );
  }
}

class _Vital extends StatelessWidget {
  final String label;
  final String value;
  const _Vital({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Directionality(
          textDirection: TextDirection.ltr,
          child: Text(value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 2),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _ChipSection extends StatelessWidget {
  final String title;
  final List<String> items;
  final Color tint;
  const _ChipSection(
      {required this.title, required this.items, required this.tint});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 8),
            if (items.isEmpty)
              Text(l.medNone, style: Theme.of(context).textTheme.bodySmall)
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final item in items) StatusPill(label: item, color: tint),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _InjuryLog extends StatelessWidget {
  final Athlete athlete;
  const _InjuryLog({required this.athlete});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final injuries = [...athlete.injuries]
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.medInjuries,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 8),
          if (injuries.isEmpty)
            Text(l.medNone, style: Theme.of(context).textTheme.bodySmall)
          else
            for (final inj in injuries) ...[
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(inj.description,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        if ((inj.notes ?? '').isNotEmpty)
                          Text(inj.notes!,
                              style: Theme.of(context).textTheme.bodySmall),
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Text(
                            '${inj.recordedAt.day}/${inj.recordedAt.month}/${inj.recordedAt.year}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusPill(
                    label: inj.severity.localized(l),
                    color: _sevColor(inj.severity),
                  ),
                ],
              ),
              const Divider(height: 16),
            ],
        ],
      ),
    );
  }

  Color _sevColor(InjurySeverity severity) => switch (severity) {
        InjurySeverity.minor => AppColors.good,
        InjurySeverity.moderate => AppColors.behind,
        InjurySeverity.severe => AppColors.critical,
      };
}

class _WeightHistory extends StatelessWidget {
  final Athlete athlete;
  const _WeightHistory({required this.athlete});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final entries = [...athlete.weightHistory]
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.medWeightHistory,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 8),
          if (entries.isEmpty)
            Text(l.medNone, style: Theme.of(context).textTheme.bodySmall)
          else
            for (final e in entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${e.recordedAt.day}/${e.recordedAt.month}/${e.recordedAt.year}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text('${e.weightKg.toStringAsFixed(1)} kg',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontFeatures: [FontFeature.tabularFigures()])),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
