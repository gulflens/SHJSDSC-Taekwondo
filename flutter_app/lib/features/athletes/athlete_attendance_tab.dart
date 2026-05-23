import 'package:flutter/material.dart';

import '../../app/locator.dart';
import '../../core/models/entity_id.dart';
import '../../core/models/schedule.dart';
import '../../core/repository/repository.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../common/design_system.dart';
import '../common/schedule_localized_labels.dart';
import '../schedule/live_class_screen.dart' show attendanceColor;

/// Port of `AthleteAttendanceTab` (subset) — attendance-rate KPI + recent
/// records, from `attendanceForAthlete`. The same seeded records feed the
/// branch operations metrics and grading eligibility.
class AthleteAttendanceTab extends StatefulWidget {
  final EntityID athleteId;
  const AthleteAttendanceTab({super.key, required this.athleteId});

  @override
  State<AthleteAttendanceTab> createState() => _AthleteAttendanceTabState();
}

class _AthleteAttendanceTabState extends State<AthleteAttendanceTab> {
  late final Future<List<AttendanceRecord>> _future = getIt<Repository>()
      .attendanceForAthlete(
        widget.athleteId,
        DateTime.now().subtract(const Duration(days: 90)),
      );

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    return FutureBuilder<List<AttendanceRecord>>(
      future: _future,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final records = [...snap.data!]
          ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
        if (records.isEmpty) {
          return Center(child: Text(l.attEmpty));
        }
        bool counted(AttendanceState s) =>
            s == AttendanceState.present || s == AttendanceState.late;
        final present = records.where((r) => counted(r.state)).length;
        final absent = records.length - present;
        final rate = (present / records.length * 100).round();
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Kpis(rate: rate, present: present, absent: absent),
            const SizedBox(height: 16),
            for (final r in records) ...[
              _RecordRow(record: r),
              const SizedBox(height: 8),
            ],
          ],
        );
      },
    );
  }
}

class _Kpis extends StatelessWidget {
  final int rate;
  final int present;
  final int absent;
  const _Kpis({required this.rate, required this.present, required this.absent});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    return SectionCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Kpi(text: '$rate%', label: l.attRateLabel, color: AppColors.good),
          _Kpi(
              text: '$present',
              label: l.attendancePresent,
              color: Theme.of(context).colorScheme.primary),
          _Kpi(text: '$absent', label: l.attendanceAbsent, color: AppColors.critical),
        ],
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  final String text;
  final String label;
  final Color color;
  const _Kpi({required this.text, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Directionality(
          textDirection: TextDirection.ltr,
          child: Text(text,
              style: TextStyle(
                  color: color,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()])),
        ),
        const SizedBox(height: 2),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _RecordRow extends StatelessWidget {
  final AttendanceRecord record;
  const _RecordRow({required this.record});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final d = record.recordedAt;
    return SectionCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text('${d.day}/${d.month}',
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontFeatures: [FontFeature.tabularFigures()])),
          ),
          const Spacer(),
          StatusPill(
            label: record.state.localized(l),
            color: attendanceColor(record.state, context),
          ),
        ],
      ),
    );
  }
}
