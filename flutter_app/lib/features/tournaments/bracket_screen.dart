import 'package:flutter/material.dart';

import '../../app/locator.dart';
import '../../core/models/entity_id.dart';
import '../../core/models/tournament.dart';
import '../../core/repository/repository.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../common/design_system.dart';

/// Single-elimination bracket viewer for a tournament — rounds rendered as
/// horizontally-scrolling columns of match cards. Data from `brackets` +
/// `bracketMatches`; competitor names resolved from athletes.
class BracketScreen extends StatelessWidget {
  final EntityID tournamentId;
  const BracketScreen({super.key, required this.tournamentId});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.bracketTitle)),
      body: FutureBuilder<_Data?>(
        future: _load(getIt<Repository>()),
        builder: (context, snap) {
          if (!snap.hasData) {
            if (snap.connectionState == ConnectionState.done) {
              return Center(child: Text(l.bracketEmpty));
            }
            return const Center(child: CircularProgressIndicator());
          }
          final data = snap.data!;
          final rounds = data.rounds;
          final totalRounds = rounds.length;
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var r = 0; r < totalRounds; r++) ...[
                  _RoundColumn(
                    title: _roundLabel(l, rounds[r].first.round, totalRounds),
                    matches: rounds[r],
                    nameOf: data.nameOf,
                  ),
                  if (r < totalRounds - 1) const SizedBox(width: 12),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  String _roundLabel(L10n l, int round, int total) {
    if (round == total) return l.bracketFinal;
    if (round == total - 1) return l.bracketSemifinal;
    if (round == total - 2) return l.bracketQuarterfinal;
    return l.bracketRoundFmt(round);
  }

  Future<_Data?> _load(Repository repo) async {
    final brackets = await repo.brackets(tournamentId);
    if (brackets.isEmpty) return null;
    final matches = await repo.bracketMatches(brackets.first.id);
    if (matches.isEmpty) return null;
    final athletes = {for (final a in await repo.athletes()) a.id: a.fullName};
    // Group by round, ascending; sort each round by position.
    final byRound = <int, List<BracketMatch>>{};
    for (final m in matches) {
      byRound.putIfAbsent(m.round, () => []).add(m);
    }
    final rounds = (byRound.keys.toList()..sort())
        .map((r) => byRound[r]!..sort((a, b) => a.position.compareTo(b.position)))
        .toList();
    return _Data(rounds, (id) => id == null ? '—' : (athletes[id] ?? '—'));
  }
}

class _Data {
  final List<List<BracketMatch>> rounds;
  final String Function(EntityID?) nameOf;
  const _Data(this.rounds, this.nameOf);
}

class _RoundColumn extends StatelessWidget {
  final String title;
  final List<BracketMatch> matches;
  final String Function(EntityID?) nameOf;
  const _RoundColumn(
      {required this.title, required this.matches, required this.nameOf});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 8),
          for (final m in matches) ...[
            _MatchCard(match: m, nameOf: nameOf),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  final BracketMatch match;
  final String Function(EntityID?) nameOf;
  const _MatchCard({required this.match, required this.nameOf});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          _Competitor(
              name: nameOf(match.athleteAId),
              won: match.winnerId != null && match.winnerId == match.athleteAId),
          const Divider(height: 12),
          _Competitor(
              name: nameOf(match.athleteBId),
              won: match.winnerId != null && match.winnerId == match.athleteBId),
        ],
      ),
    );
  }
}

class _Competitor extends StatelessWidget {
  final String name;
  final bool won;
  const _Competitor({required this.name, required this.won});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: won ? FontWeight.w700 : FontWeight.w400,
              color: won ? scheme.primary : null,
            ),
          ),
        ),
        if (won) Icon(Icons.check, size: 16, color: AppColors.good),
      ],
    );
  }
}
