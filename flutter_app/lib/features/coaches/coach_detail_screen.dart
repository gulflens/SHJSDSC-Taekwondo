import 'package:flutter/material.dart';

import '../../app/locator.dart';
import '../../core/models/coach.dart';
import '../../core/models/entity_id.dart';
import '../../core/repository/repository.dart';
import '../../l10n/app_localizations.dart';
import '../common/coach_localized_labels.dart';
import '../common/design_system.dart';
import 'coach_athletes_tab.dart';
import 'coach_certifications_tab.dart';
import 'coach_competitions_tab.dart';
import 'coach_list_cubit.dart';
import 'coach_list_screen.dart' show employmentColor;

/// Port of the CoachDetail container + Overview tab (subset) — twin of
/// `AthleteDetailScreen`. Hero header + the discipline-competency breakdown
/// (the real 1–5 `Coach` competencies) + certification summary.
class CoachDetailScreen extends StatefulWidget {
  final EntityID coachId;
  const CoachDetailScreen({super.key, required this.coachId});

  @override
  State<CoachDetailScreen> createState() => _CoachDetailScreenState();
}

class _CoachDetailScreenState extends State<CoachDetailScreen> {
  late final Future<CoachIntel?> _future = _load(getIt<Repository>(), widget.coachId);

  static Future<CoachIntel?> _load(Repository repo, EntityID id) async {
    final coach = await repo.coach(id);
    if (coach == null) return null;
    final roster = await repo.athletesForCoach(id);
    final branch = await repo.branch(coach.primaryBranchId);
    return CoachIntel(
      coach: coach,
      branchName: branch?.name ?? '—',
      branchNameAr: branch?.nameAr ?? '—',
      athleteCount: roster.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    return FutureBuilder<CoachIntel?>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Scaffold(body: Center(child: Text(l.loadFailed)));
          }
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        final intel = snapshot.data!;
        return DefaultTabController(
          length: 4,
          child: Scaffold(
            appBar: AppBar(
              title: Text(intel.coach.fullName),
              bottom: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: [
                  Tab(text: l.coachTabOverview),
                  Tab(text: l.coachTabAthletes),
                  Tab(text: l.coachTabCertifications),
                  Tab(text: l.coachTabCompetitions),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _Header(intel: intel),
                    const SizedBox(height: 16),
                    _CompetencyBreakdown(coach: intel.coach),
                    const SizedBox(height: 16),
                    _Certifications(coach: intel.coach),
                  ],
                ),
                CoachAthletesTab(coachId: intel.coach.id),
                CoachCertificationsTab(coachId: intel.coach.id),
                CoachCompetitionsTab(coachId: intel.coach.id),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final CoachIntel intel;
  const _Header({required this.intel});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final c = intel.coach;
    return SectionCard(
      child: Row(
        children: [
          CircleAvatar(
              radius: 34,
              child: Text(c.initials, style: const TextStyle(fontSize: 22))),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.fullName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 20)),
                Text(c.fullNameAr, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  StatusPill(
                    label: c.employmentStatus.localized(l),
                    color: employmentColor(c.employmentStatus, context),
                  ),
                  if (c.coachLevel != null)
                    StatusPill(
                      label: c.coachLevel!.localized(l),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  StatusPill(
                    label: '${l.coachDanRank(c.danRank)} · ${l.coachYearsExp(c.yearsOfExperience)}',
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  StatusPill(
                    label: l.coachAthletesCount(intel.athleteCount),
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ]),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GradeRing(composite: intel.composite, grade: intel.grade, size: 64),
        ],
      ),
    );
  }
}

/// Mirrors the Coach Performance tab's per-discipline competency (1–5).
class _CompetencyBreakdown extends StatelessWidget {
  final Coach coach;
  const _CompetencyBreakdown({required this.coach});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final rows = <(String, int?)>[
      (l.competencyTechnical, coach.technicalLevel),
      (l.competencySparring, coach.sparringLevel),
      (l.competencyPoomsae, coach.poomsaeLevel),
      (l.competencyFitness, coach.fitnessLevel),
    ];
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.coachOverview,
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          for (final (label, value) in rows) ...[
            Row(
              children: [
                SizedBox(width: 110, child: Text(label)),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: value == null ? 0 : (value / 5).clamp(0, 1),
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    value == null ? '—' : '$value/5',
                    style: const TextStyle(
                        fontFeatures: [FontFeature.tabularFigures()]),
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

class _Certifications extends StatelessWidget {
  final Coach coach;
  const _Certifications({required this.coach});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final next = coach.nextCertificationExpiry;
    return SectionCard(
      child: Row(
        children: [
          Icon(Icons.verified_outlined,
              color: Theme.of(context).colorScheme.secondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(next == null
                ? l.coachNoCerts
                : '${l.coachCertExpiry}: ${next.year}-${next.month.toString().padLeft(2, '0')}-${next.day.toString().padLeft(2, '0')}'),
          ),
        ],
      ),
    );
  }
}
