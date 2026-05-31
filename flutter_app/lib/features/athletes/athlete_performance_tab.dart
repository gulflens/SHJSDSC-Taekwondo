import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/locator.dart';
import '../../core/blocs/performance_entry_cubit.dart';
import '../../core/models/entity_id.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../common/design_system.dart';

/// Port of `AthletePerformanceTab` (subset) — three 0–100 trend lines
/// (physical / technical / wellness) computed by [PerformanceEntryCubit]'s
/// trend helpers and drawn with fl_chart. The first chart usage in the app.
class AthletePerformanceTab extends StatelessWidget {
  final EntityID athleteId;
  const AthletePerformanceTab({super.key, required this.athleteId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PerformanceEntryCubit(getIt())..load(athleteId),
      child: const _PerformanceBody(),
    );
  }
}

class _PerformanceBody extends StatelessWidget {
  const _PerformanceBody();

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final scheme = Theme.of(context).colorScheme;
    return BlocBuilder<PerformanceEntryCubit, PerformanceEntryState>(
      builder: (context, state) {
        if (state.status == PerformanceEntryStatus.failed) {
          return Center(child: Text(l.loadFailed));
        }
        if (state.status != PerformanceEntryStatus.ready) {
          return const Center(child: CircularProgressIndicator());
        }
        final wellnessStreak = state.wellnessStreak();
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _TrendCard(
              title: l.perfPhysical,
              points: state.physicalTrend(),
              color: scheme.primary,
            ),
            const SizedBox(height: 16),
            _TrendCard(
              title: l.perfTechnical,
              points: state.technicalTrend(),
              color: AppColors.good,
            ),
            const SizedBox(height: 16),
            _TrendCard(
              title: l.perfWellness,
              points: state.wellnessTrend(),
              color: scheme.secondary,
              subtitle: wellnessStreak > 0
                  ? l.perfWellnessStreak(wellnessStreak)
                  : null,
            ),
          ],
        );
      },
    );
  }
}

class _TrendCard extends StatelessWidget {
  final String title;
  final List<TrendPoint> points;
  final Color color;
  final String? subtitle;

  const _TrendCard({
    required this.title,
    required this.points,
    required this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 16)),
              if (points.isNotEmpty)
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    l.perfLatest(points.last.value.toStringAsFixed(0)),
                    style: TextStyle(color: color, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
          ],
          const SizedBox(height: 16),
          if (points.length < 2)
            SizedBox(
              height: 80,
              child: Center(child: Text(l.perfNoData)),
            )
          else
            SizedBox(height: 140, child: _Chart(points: points, color: color)),
        ],
      ),
    );
  }
}

class _Chart extends StatelessWidget {
  final List<TrendPoint> points;
  final Color color;
  const _Chart({required this.points, required this.color});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final spots = <FlSpot>[
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].value),
    ];
    // Charts read left-to-right regardless of UI direction.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 100,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 25,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: scheme.outline.withValues(alpha: 0.15), strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 50,
                reservedSize: 28,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: TextStyle(color: scheme.outline, fontSize: 10),
                ),
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: color,
              barWidth: 3,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: color.withValues(alpha: 0.12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
