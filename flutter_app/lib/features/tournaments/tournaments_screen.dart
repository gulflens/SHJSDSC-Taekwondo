import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/locator.dart';
import '../../core/blocs/tournaments_cubit.dart';
import '../../core/models/tournament.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../common/design_system.dart';
import '../common/tournament_localized_labels.dart';
import 'tournament_detail_screen.dart';

/// Port of the Tournaments dashboard (Features/Tournaments/). Upcoming / Past
/// segmented list via the ported [TournamentsCubit]; tap → detail with
/// registrations + weight-cut. Bracket visualisation lands in a later stage.
class TournamentsScreen extends StatelessWidget {
  const TournamentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TournamentsCubit(getIt())..loadTournaments(),
      child: const _TournamentsBody(),
    );
  }
}

class _TournamentsBody extends StatefulWidget {
  const _TournamentsBody();

  @override
  State<_TournamentsBody> createState() => _TournamentsBodyState();
}

class _TournamentsBodyState extends State<_TournamentsBody> {
  bool _showPast = false;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.tournamentsTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: false, label: Text(l.tournUpcoming)),
                ButtonSegment(value: true, label: Text(l.tournPast)),
              ],
              selected: {_showPast},
              onSelectionChanged: (s) => setState(() => _showPast = s.first),
            ),
          ),
          Expanded(
            child: BlocBuilder<TournamentsCubit, TournamentsState>(
              builder: (context, state) {
                if (state.status == TournamentsStatus.failed) {
                  return Center(child: Text(l.loadFailed));
                }
                if (state.status != TournamentsStatus.ready) {
                  return const Center(child: CircularProgressIndicator());
                }
                final items = _showPast ? state.past : state.upcoming;
                if (items.isEmpty) {
                  return Center(child: Text(l.tournamentsEmpty));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) => _TournamentCard(t: items[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TournamentCard extends StatelessWidget {
  final Tournament t;
  const _TournamentCard({required this.t});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final scheme = Theme.of(context).colorScheme;
    final s = t.startsAt;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.card),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TournamentDetailScreen(tournamentId: t.id),
        ),
      ),
      child: SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(t.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16)),
                ),
                if (t.isOfficial)
                  StatusPill(label: l.tournOfficial, color: scheme.secondary),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 6, children: [
              StatusPill(
                  label: t.hostingFederation.name.toUpperCase(),
                  color: scheme.primary),
              if (t.level != null)
                StatusPill(
                    label: t.level!.localized(l), color: scheme.outline),
              StatusPill(label: t.location, color: scheme.outline),
            ]),
            const SizedBox(height: 8),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Text('${s.day}/${s.month}/${s.year}',
                  style: Theme.of(context).textTheme.bodySmall),
            ),
          ],
        ),
      ),
    );
  }
}
