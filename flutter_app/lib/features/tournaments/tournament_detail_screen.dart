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
import 'bracket_screen.dart';

/// A registration row joined with the athlete's display name and weight-cut log.
class _RegRow {
  final TournamentRegistration registration;
  final String athleteName;
  final List<WeightCutEntry> weightCut;
  const _RegRow(this.registration, this.athleteName, this.weightCut);
}

class _Detail {
  final Tournament tournament;
  final List<_RegRow> rows;
  final bool hasBracket;
  const _Detail(this.tournament, this.rows, this.hasBracket);
}

/// Port of `TournamentDetailView` (subset) — header + registrations + weight-cut.
class TournamentDetailScreen extends StatefulWidget {
  final EntityID tournamentId;
  const TournamentDetailScreen({super.key, required this.tournamentId});

  @override
  State<TournamentDetailScreen> createState() => _TournamentDetailScreenState();
}

class _TournamentDetailScreenState extends State<TournamentDetailScreen> {
  late final Future<_Detail?> _future = _load();

  Future<_Detail?> _load() async {
    final repo = getIt<Repository>();
    final tournament = await repo.tournament(widget.tournamentId);
    if (tournament == null) return null;
    final regs = await repo.registrationsForTournament(widget.tournamentId);
    final rows = <_RegRow>[];
    for (final r in regs) {
      final athlete = await repo.athlete(r.athleteId);
      final wc = await repo.weightCutHistory(r.id);
      rows.add(_RegRow(r, athlete?.fullName ?? '—', wc));
    }
    final hasBracket = (await repo.brackets(widget.tournamentId)).isNotEmpty;
    return _Detail(tournament, rows, hasBracket);
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    return Scaffold(
      body: FutureBuilder<_Detail?>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            if (snap.connectionState == ConnectionState.done) {
              return Center(child: Text(l.loadFailed));
            }
            return const Center(child: CircularProgressIndicator());
          }
          final detail = snap.data!;
          final t = detail.tournament;
          return CustomScrollView(
            slivers: [
              SliverAppBar.large(title: Text(t.name), pinned: true),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList.list(children: [
                  _InfoCard(tournament: t),
                  if (detail.hasBracket) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              BracketScreen(tournamentId: t.id),
                        ),
                      ),
                      icon: const Icon(Icons.account_tree_outlined),
                      label: Text(l.bracketView),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(l.tournRegistrations,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 8),
                  if (detail.rows.isEmpty)
                    Text(l.tournNoRegistrations)
                  else
                    for (final row in detail.rows) ...[
                      _RegistrationCard(row: row),
                      const SizedBox(height: 8),
                    ],
                ]),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Tournament tournament;
  const _InfoCard({required this.tournament});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final scheme = Theme.of(context).colorScheme;
    final s = tournament.startsAt;
    final e = tournament.endsAt;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if ((tournament.nameAr ?? '').isNotEmpty)
            Text(tournament.nameAr!,
                style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 6, children: [
            StatusPill(
                label: tournament.hostingFederation.name.toUpperCase(),
                color: scheme.primary),
            if (tournament.level != null)
              StatusPill(
                  label: tournament.level!.localized(l), color: scheme.outline),
            if (tournament.isOfficial)
              StatusPill(label: l.tournOfficial, color: scheme.secondary),
            StatusPill(label: tournament.location, color: scheme.outline),
          ]),
          const SizedBox(height: 10),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              '${s.day}/${s.month}/${s.year} – ${e.day}/${e.month}/${e.year}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _RegistrationCard extends StatelessWidget {
  final _RegRow row;
  const _RegistrationCard({required this.row});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final scheme = Theme.of(context).colorScheme;
    final r = row.registration;
    final medalLabel = r.medal?.localized(l);
    final wc = [...row.weightCut]
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    return SectionCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(row.athleteName,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(r.weightCategory.shortLabel,
                          style: Theme.of(context).textTheme.bodySmall),
                    ),
                  ],
                ),
              ),
              if (r.finalPosition != null)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: StatusPill(
                      label: l.tournPosition(r.finalPosition!),
                      color: scheme.outline),
                ),
              if (medalLabel != null)
                StatusPill(label: medalLabel, color: _medalColor(r.medal!))
              else
                StatusPill(
                    label: r.status.localized(l), color: scheme.primary),
            ],
          ),
          if (wc.isNotEmpty) ...[
            const Divider(height: 20),
            _WeightCutLine(latest: wc.last),
          ],
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

class _WeightCutLine extends StatelessWidget {
  final WeightCutEntry latest;
  const _WeightCutLine({required this.latest});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final delta = latest.deltaKg;
    final color =
        delta <= 0 ? AppColors.good : (delta <= 1 ? AppColors.behind : AppColors.critical);
    return Row(
      children: [
        Icon(Icons.monitor_weight_outlined, size: 18, color: color),
        const SizedBox(width: 8),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Text(
            l.weightCutLine(
              latest.currentKg.toStringAsFixed(1),
              latest.targetKg.toStringAsFixed(1),
            ),
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        const Spacer(),
        if (delta > 0)
          Text(l.weightCutDelta(delta.toStringAsFixed(1)),
              style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
