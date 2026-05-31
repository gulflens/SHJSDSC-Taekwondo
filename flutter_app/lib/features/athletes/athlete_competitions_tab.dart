import 'package:flutter/material.dart';

import '../../app/locator.dart';
import '../../core/models/entity_id.dart';
import '../../core/models/match.dart' show MedalType;
import '../../core/models/tournament.dart';
import '../../core/repository/repository.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../common/design_system.dart';
import '../common/tournament_localized_labels.dart';

/// Port of `AthleteCompetitionsTab` (subset) — the athlete's tournament history
/// joined from `registrationsForAthlete` + the tournament records. Medal KPI
/// strip + per-event cards.
class AthleteCompetitionsTab extends StatefulWidget {
  final EntityID athleteId;
  const AthleteCompetitionsTab({super.key, required this.athleteId});

  @override
  State<AthleteCompetitionsTab> createState() => _AthleteCompetitionsTabState();
}

class _Row {
  final TournamentRegistration reg;
  final Tournament? tournament;
  const _Row(this.reg, this.tournament);
}

class _AthleteCompetitionsTabState extends State<AthleteCompetitionsTab> {
  late final Future<List<_Row>> _future = _load();

  Future<List<_Row>> _load() async {
    final repo = getIt<Repository>();
    final regs = await repo.registrationsForAthlete(widget.athleteId);
    final rows = <_Row>[];
    for (final r in regs) {
      rows.add(_Row(r, await repo.tournament(r.tournamentId)));
    }
    rows.sort((a, b) {
      final da = a.tournament?.startsAt ?? a.reg.registeredAt;
      final db = b.tournament?.startsAt ?? b.reg.registeredAt;
      return db.compareTo(da); // newest first
    });
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    return FutureBuilder<List<_Row>>(
      future: _future,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final rows = snap.data!;
        if (rows.isEmpty) {
          return Center(child: Text(l.compEmpty));
        }
        final medals = rows.where((r) => _isMedal(r.reg.medal)).length;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Kpis(events: rows.length, medals: medals),
            const SizedBox(height: 16),
            for (final r in rows) ...[
              _EventCard(row: r),
              const SizedBox(height: 8),
            ],
          ],
        );
      },
    );
  }

  static bool _isMedal(MedalType? m) =>
      m != null && m != MedalType.none;
}

class _Kpis extends StatelessWidget {
  final int events;
  final int medals;
  const _Kpis({required this.events, required this.medals});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final scheme = Theme.of(context).colorScheme;
    return SectionCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Kpi(value: events, label: l.compEvents, color: scheme.primary),
          _Kpi(value: medals, label: l.compMedals, color: AppColors.good),
        ],
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  final int value;
  final String label;
  final Color color;
  const _Kpi({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Directionality(
          textDirection: TextDirection.ltr,
          child: Text('$value',
              style: TextStyle(
                  color: color,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()])),
        ),
        const SizedBox(height: 2),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _EventCard extends StatelessWidget {
  final _Row row;
  const _EventCard({required this.row});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final scheme = Theme.of(context).colorScheme;
    final t = row.tournament;
    final reg = row.reg;
    final date = t?.startsAt ?? reg.registeredAt;
    final medalLabel = reg.medal?.localized(l);
    return SectionCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t?.name ?? '—',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    '${date.day}/${date.month}/${date.year} · ${reg.weightCategory.shortLabel}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          if (reg.finalPosition != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: StatusPill(
                  label: l.tournPosition(reg.finalPosition!),
                  color: scheme.outline),
            ),
          if (medalLabel != null)
            StatusPill(label: medalLabel, color: _medalColor(reg.medal!))
          else
            StatusPill(label: reg.status.localized(l), color: scheme.primary),
        ],
      ),
    );
  }

  Color _medalColor(MedalType m) => switch (m) {
        MedalType.gold => const Color(0xFFD4AF37),
        MedalType.silver => const Color(0xFF9AA0A6),
        MedalType.bronze => const Color(0xFFCD7F32),
        MedalType.none => Colors.transparent,
      };
}
