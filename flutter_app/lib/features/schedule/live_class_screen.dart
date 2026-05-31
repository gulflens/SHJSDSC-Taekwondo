import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/locator.dart';
import '../../core/blocs/live_class_cubit.dart';
import '../../core/models/schedule.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../common/design_system.dart';
import '../common/schedule_localized_labels.dart';

/// Port of `LiveClassView` (attendance marking) — uses the ported
/// [LiveClassCubit]. Roster with tap-to-cycle attendance state, a present/absent
/// summary, mark-all, and a batched save.
class LiveClassScreen extends StatelessWidget {
  final ClassSession session;
  const LiveClassScreen({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LiveClassCubit(getIt(), session: session)..load(),
      child: _LiveClassBody(session: session),
    );
  }
}

class _LiveClassBody extends StatelessWidget {
  final ClassSession session;
  const _LiveClassBody({required this.session});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    return BlocConsumer<LiveClassCubit, LiveClassState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        if (state.status == LiveClassStatus.saved) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(l.attSaved)));
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        final cubit = context.read<LiveClassCubit>();
        return Scaffold(
          appBar: AppBar(
            title: Text(session.discipline.localized(l)),
            actions: [
              TextButton(
                onPressed: state.status == LiveClassStatus.saving
                    ? null
                    : cubit.save,
                child: Text(l.attSave),
              ),
            ],
          ),
          body: state.status == LiveClassStatus.loading ||
                  state.status == LiveClassStatus.initial
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    _SummaryBar(state: state),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.athletes.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final a = state.athletes[i];
                          final mark =
                              state.marks[a.id] ?? AttendanceState.present;
                          return SectionCard(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            child: Row(
                              children: [
                                CircleAvatar(radius: 18, child: Text(a.initials)),
                                const SizedBox(width: 12),
                                Expanded(child: Text(a.fullName)),
                                ActionChip(
                                  label: Text(mark.localized(l)),
                                  backgroundColor:
                                      attendanceColor(mark, context)
                                          .withValues(alpha: 0.14),
                                  labelStyle: TextStyle(
                                      color: attendanceColor(mark, context),
                                      fontWeight: FontWeight.w600),
                                  side: BorderSide.none,
                                  onPressed: () => cubit.cycleState(a.id),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _SummaryBar extends StatelessWidget {
  final LiveClassState state;
  const _SummaryBar({required this.state});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          StatusPill(
              label: l.attPresentCount(state.presentCount),
              color: AppColors.good),
          const SizedBox(width: 8),
          StatusPill(
              label: l.attAbsentCount(state.absentCount),
              color: AppColors.critical),
          const Spacer(),
          TextButton.icon(
            onPressed: context.read<LiveClassCubit>().markAllPresent,
            icon: const Icon(Icons.done_all, size: 18),
            label: Text(l.attMarkAll),
          ),
        ],
      ),
    );
  }
}

Color attendanceColor(AttendanceState s, BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  return switch (s) {
    AttendanceState.present => AppColors.good,
    AttendanceState.late => AppColors.behind,
    AttendanceState.absent => AppColors.critical,
    AttendanceState.excused => scheme.outline,
  };
}
