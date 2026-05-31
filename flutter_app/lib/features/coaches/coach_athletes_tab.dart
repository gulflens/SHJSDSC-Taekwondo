import 'package:flutter/material.dart';

import '../../app/locator.dart';
import '../../core/models/athlete.dart';
import '../../core/models/entity_id.dart';
import '../../core/models/performance_score.dart';
import '../../core/repository/repository.dart';
import '../../core/services/score_engine.dart';
import '../../l10n/app_localizations.dart';
import '../athletes/athlete_detail_screen.dart';
import '../athletes/athlete_list_screen.dart' show statusColor;
import '../common/design_system.dart';
import '../common/localized_labels.dart';

/// Port of `CoachAthletesTab` (subset) — the coach's assigned roster, from
/// `athletesForCoach(coach.id)`. No User↔Coach gap: the coach detail already
/// has the `Coach`, so its id maps straight to `Athlete.primaryCoachID`.
class CoachAthletesTab extends StatefulWidget {
  final EntityID coachId;
  const CoachAthletesTab({super.key, required this.coachId});

  @override
  State<CoachAthletesTab> createState() => _CoachAthletesTabState();
}

class _CoachAthletesTabState extends State<CoachAthletesTab> {
  late final Future<List<(Athlete, PerformanceScore?)>> _future = _load();

  Future<List<(Athlete, PerformanceScore?)>> _load() async {
    final repo = getIt<Repository>();
    final athletes = await repo.athletesForCoach(widget.coachId);
    final out = <(Athlete, PerformanceScore?)>[];
    for (final a in athletes) {
      out.add((a, await repo.score(a.id)));
    }
    out.sort((x, y) {
      final cx = x.$2 == null ? 0.0 : ScoreEngine.composite(x.$2!);
      final cy = y.$2 == null ? 0.0 : ScoreEngine.composite(y.$2!);
      return cy.compareTo(cx);
    });
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    return FutureBuilder<List<(Athlete, PerformanceScore?)>>(
      future: _future,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final rows = snap.data!;
        if (rows.isEmpty) {
          return Center(child: Text(l.coachNoAthletes));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: rows.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, i) =>
              _RosterCard(athlete: rows[i].$1, score: rows[i].$2),
        );
      },
    );
  }
}

class _RosterCard extends StatelessWidget {
  final Athlete athlete;
  final PerformanceScore? score;
  const _RosterCard({required this.athlete, this.score});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final composite = score == null ? 0.0 : ScoreEngine.composite(score!);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AthleteDetailScreen(athleteId: athlete.id),
        ),
      ),
      child: SectionCard(
        child: Row(
          children: [
            CircleAvatar(radius: 24, child: Text(athlete.initials)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(athlete.fullName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 6),
                  StatusPill(
                    label: athlete.status.localized(l),
                    color: statusColor(athlete.status, context),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            GradeRing(
              composite: composite,
              grade: LetterGrade.fromScore(composite),
              size: 48,
            ),
          ],
        ),
      ),
    );
  }
}
