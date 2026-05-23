import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/locator.dart';
import '../../core/blocs/schedule_cubit.dart';
import '../../core/models/entity_id.dart';
import '../../core/models/schedule.dart';
import '../../core/repository/repository.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../common/design_system.dart';
import '../common/schedule_localized_labels.dart';
import 'live_class_screen.dart';

/// Port of the Schedule day-view (Features/Schedule/). Shows one branch's
/// classes for a chosen day with a Today/Tomorrow/+2 stepper, using the ported
/// [ScheduleCubit]. Defaults to the federation's main branch; a branch picker
/// + week view land in the full module stage. Tap a class → attendance roster.
class ScheduleScreen extends StatelessWidget {
  /// When set, shows this branch's schedule; otherwise resolves the main branch.
  final EntityID? branchId;
  const ScheduleScreen({super.key, this.branchId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ScheduleCubit(getIt()),
      child: _ScheduleBody(branchId: branchId),
    );
  }
}

class _ScheduleBody extends StatefulWidget {
  final EntityID? branchId;
  const _ScheduleBody({this.branchId});

  @override
  State<_ScheduleBody> createState() => _ScheduleBodyState();
}

class _ScheduleBodyState extends State<_ScheduleBody> {
  int _dayOffset = 0;
  EntityID? _branchId;

  @override
  void initState() {
    super.initState();
    if (widget.branchId != null) {
      _branchId = widget.branchId;
      _load();
    } else {
      _resolveBranchAndLoad();
    }
  }

  Future<void> _resolveBranchAndLoad() async {
    final branches = await getIt<Repository>().branches();
    if (!mounted || branches.isEmpty) return;
    final main = branches.firstWhere((b) => b.isMain, orElse: () => branches.first);
    setState(() => _branchId = main.id);
    _load();
  }

  void _load() {
    if (_branchId == null) return;
    final day = DateTime.now().add(Duration(days: _dayOffset));
    context.read<ScheduleCubit>().loadBranchDay(_branchId!, day: day);
  }

  void _selectDay(int offset) {
    setState(() => _dayOffset = offset);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final now = DateTime.now();
    final d2 = now.add(const Duration(days: 2));
    return Scaffold(
      appBar: AppBar(title: Text(l.scheduleTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SegmentedButton<int>(
              segments: [
                ButtonSegment(value: 0, label: Text(l.scheduleToday)),
                ButtonSegment(value: 1, label: Text(l.scheduleTomorrow)),
                ButtonSegment(value: 2, label: Text('${d2.day}/${d2.month}')),
              ],
              selected: {_dayOffset},
              onSelectionChanged: (s) => _selectDay(s.first),
            ),
          ),
          Expanded(
            child: BlocBuilder<ScheduleCubit, ScheduleState>(
              builder: (context, state) {
                if (state.status == ScheduleStatus.failed) {
                  return Center(child: Text(l.loadFailed));
                }
                if (state.status != ScheduleStatus.ready) {
                  return const Center(child: CircularProgressIndicator());
                }
                final sessions = [...state.sessionsToday]
                  ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
                if (sessions.isEmpty) {
                  return Center(child: Text(l.scheduleEmpty));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: sessions.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) => _SessionCard(
                    session: sessions[i],
                    coachName: state.coachLookup[sessions[i].coachId]?.fullName ?? '—',
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final ClassSession session;
  final String coachName;
  const _SessionCard({required this.session, required this.coachName});

  String _hhmm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.card),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => LiveClassScreen(session: session)),
      ),
      child: SectionCard(
        child: Row(
          children: [
            // Time column (numbers stay LTR under Arabic).
            Directionality(
              textDirection: TextDirection.ltr,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_hhmm(session.startsAt),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontFeatures: [FontFeature.tabularFigures()])),
                  Text(_hhmm(session.endsAt),
                      style: TextStyle(
                          color: scheme.outline,
                          fontFeatures: const [FontFeature.tabularFigures()])),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(width: 3, height: 40, color: scheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(session.discipline.localized(l),
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(coachName, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            StatusPill(
              label: l.sessionRoster(session.enrolledAthleteIds.length, session.capacity),
              color: scheme.outline,
            ),
          ],
        ),
      ),
    );
  }
}
