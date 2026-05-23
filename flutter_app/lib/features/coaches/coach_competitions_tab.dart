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

/// Port of `CoachCompetitionsTab` — aggregate competition results for all
/// athletes on the coach's roster. Medal KPI strip (total events / medals /
/// gold–silver–bronze breakdown) + per-event result cards newest-first.
class CoachCompetitionsTab extends StatefulWidget {
  final EntityID coachId;
  const CoachCompetitionsTab({super.key, required this.coachId});

  @override
  State<CoachCompetitionsTab> createState() => _CoachCompetitionsTabState();
}

class _Row {
  final TournamentRegistration reg;
  final String athleteName;
  final Tournament? tournament;
  const _Row(this.reg, this.athleteName, this.tournament);
}

class _CoachCompetitionsTabState extends State<CoachCompetitionsTab> {
  late final Future<List<_Row>> _future = _load();

  Future<List<_Row>> _load() async {
    final repo = getIt<Repository>();
    final athletes = await repo.athletesForCoach(widget.coachId);
    final rows = <_Row>[];
    for (final athlete in athletes) {
      final regs = await repo.registrationsForAthlete(athlete.id);
      for (final reg in regs) {
        rows.add(_Row(reg, athlete.fullName, await repo.tournament(reg.tournamentId)));
      }
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
          return Center(child: Text(l.coachCompEmpty));
        }
        final medals = rows.where((r) => _isMedal(r.reg.medal)).toList();
        final gold = medals.where((r) => r.reg.medal == MedalType.gold).length;
        final silver = medals.where((r) => r.reg.medal == MedalType.silver).length;
        final bronze = medals.where((r) => r.reg.medal == MedalType.bronze).length;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Kpis(
              events: rows.length,
              medals: medals.length,
              gold: gold,
              silver: silver,
              bronze: bronze,
            ),
            const SizedBox(height: 16),
            for (final r in rows) ...[
              _ResultCard(row: r),
              const SizedBox(height: 8),
            ],
          ],
        );
      },
    );
  }

  static bool _isMedal(MedalType? m) => m != null && m != MedalType.none;
}

// ---------------------------------------------------------------------------
// KPI strip
// ---------------------------------------------------------------------------

class _Kpis extends StatelessWidget {
  final int events;
  final int medals;
  final int gold;
  final int silver;
  final int bronze;

  const _Kpis({
    required this.events,
    required this.medals,
    required this.gold,
    required this.silver,
    required this.bronze,
  });

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
          _Kpi(
              value: gold,
              label: l.medalGold,
              color: const Color(0xFFD4AF37)),
          _Kpi(
              value: silver,
              label: l.medalSilver,
              color: const Color(0xFF9AA0A6)),
          _Kpi(
              value: bronze,
              label: l.medalBronze,
              color: const Color(0xFFCD7F32)),
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
          child: Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Result card
// ---------------------------------------------------------------------------

class _ResultCard extends StatelessWidget {
  final _Row row;
  const _ResultCard({required this.row});

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
                Text(
                  row.athleteName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  t?.name ?? '—',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 2),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    '${date.day}/${date.month}/${date.year}'
                    ' · ${reg.weightCategory.shortLabel}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (reg.finalPosition != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: StatusPill(
                label: l.tournPosition(reg.finalPosition!),
                color: scheme.outline,
              ),
            ),
          if (medalLabel != null)
            StatusPill(label: medalLabel, color: _medalColor(reg.medal!))
          else
            StatusPill(
                label: reg.status.localized(l), color: scheme.primary),
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
