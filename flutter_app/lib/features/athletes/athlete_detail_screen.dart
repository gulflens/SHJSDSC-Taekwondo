import 'package:flutter/material.dart';

import '../../app/locator.dart';
import '../../core/models/athlete.dart';
import '../../core/models/entity_id.dart';
import '../../core/models/performance_score.dart';
import '../../core/repository/repository.dart';
import '../../core/services/score_engine.dart';
import '../../l10n/app_localizations.dart';
import '../common/design_system.dart';
import '../common/localized_labels.dart';
import 'athlete_attendance_tab.dart';
import 'athlete_competitions_tab.dart';
import 'athlete_documents_tab.dart';
import 'athlete_medical_tab.dart';
import 'athlete_more_tab.dart';
import 'athlete_notes_tab.dart';
import 'athlete_list_screen.dart' show statusColor;
import 'athlete_performance_tab.dart';

/// Port of the AthleteDetail container. The Swift module has nine tabs; this
/// ships Overview (hero + `PerformanceScore` pillars), Performance (physical /
/// technical / wellness trend charts) and Competitions (tournament history).
/// Remaining tabs are added one at a time.
class AthleteDetailScreen extends StatefulWidget {
  final EntityID athleteId;
  const AthleteDetailScreen({super.key, required this.athleteId});

  @override
  State<AthleteDetailScreen> createState() => _AthleteDetailScreenState();
}

class _AthleteDetailScreenState extends State<AthleteDetailScreen> {
  late final Future<(Athlete?, PerformanceScore?)> _future = _load(
    getIt<Repository>(),
    widget.athleteId,
  );

  static Future<(Athlete?, PerformanceScore?)> _load(
    Repository repo,
    EntityID id,
  ) async {
    final athlete = await repo.athlete(id);
    final score = await repo.score(id);
    return (athlete, score);
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    return FutureBuilder<(Athlete?, PerformanceScore?)>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final (athlete, score) = snapshot.data!;
        if (athlete == null) {
          return Scaffold(body: Center(child: Text(l.loadFailed)));
        }
        return DefaultTabController(
          length: 8,
          child: Scaffold(
            appBar: AppBar(
              title: Text(athlete.fullName),
              bottom: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: [
                  Tab(text: l.athleteTabOverview),
                  Tab(text: l.athleteTabPerformance),
                  Tab(text: l.athleteTabCompetitions),
                  Tab(text: l.athleteTabAttendance),
                  Tab(text: l.athleteTabMedical),
                  Tab(text: l.athleteTabNotes),
                  Tab(text: l.athleteTabDocuments),
                  Tab(text: l.athleteTabMore),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _Header(athlete: athlete, score: score),
                    const SizedBox(height: 16),
                    if (score != null) _PillarBreakdown(score: score),
                  ],
                ),
                AthletePerformanceTab(athleteId: athlete.id),
                AthleteCompetitionsTab(athleteId: athlete.id),
                AthleteAttendanceTab(athleteId: athlete.id),
                AthleteMedicalTab(athlete: athlete),
                AthleteNotesTab(athlete: athlete),
                AthleteDocumentsTab(athlete: athlete),
                AthleteMoreTab(athlete: athlete),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final Athlete athlete;
  final PerformanceScore? score;
  const _Header({required this.athlete, this.score});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final composite = score == null ? 0.0 : ScoreEngine.composite(score!);
    return SectionCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            child: Text(athlete.initials, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  athlete.fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
                Text(
                  athlete.fullNameAr,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    StatusPill(
                      label: athlete.status.localized(l),
                      color: statusColor(athlete.status, context),
                    ),
                    StatusPill(
                      label:
                          '${l.athleteAge(athlete.age)} · ${athlete.ageGroup.localized(l)}',
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    StatusPill(
                      label: l.athleteWeightFmt(
                        athlete.weightKg.toStringAsFixed(0),
                      ),
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GradeRing(
            composite: composite,
            grade: LetterGrade.fromScore(composite),
            size: 64,
          ),
        ],
      ),
    );
  }
}

/// Mirrors the Overview "Latest Performance" pillar breakdown.
class _PillarBreakdown extends StatelessWidget {
  final PerformanceScore score;
  const _PillarBreakdown({required this.score});

  @override
  Widget build(BuildContext context) {
    final rows = <(String, double)>[
      ('Competition', score.competition),
      ('Technical', score.technical),
      ('Physical', score.physical),
      ('Adherence', score.adherence),
      ('Belt Progression', score.beltProgression),
      ('Wellness', score.wellness),
      ('Character', score.character),
    ];
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            L10n.of(context).athleteOverview,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 12),
          for (final (label, value) in rows) ...[
            Row(
              children: [
                SizedBox(width: 130, child: Text(label)),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (value / 100).clamp(0, 1),
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    value.toStringAsFixed(0),
                    style: const TextStyle(
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
