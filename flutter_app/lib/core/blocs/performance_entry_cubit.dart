import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../models/entity_id.dart';
import '../models/performance_entry.dart';
import '../models/physical_metric.dart';
import '../models/technical_skill.dart';
import '../repository/repository.dart';
import '../services/grading_engine.dart';

/// Port of Core/Stores/PerformanceEntryStore.swift.
///
/// Loads and mutates an athlete's per-entry performance data —
/// [PhysicalMetric], [TechnicalSkill], and [WellnessEntry] — for the
/// configured athlete ID. Trend helpers are exposed as pure functions on state
/// so the UI can call them without triggering a load.

// ──────────────────────────────────────────────────────────────────────────────
// TrendPoint — port of Swift TrendPoint (defined in PerformanceEntryStore.swift)
// ──────────────────────────────────────────────────────────────────────────────

class TrendPoint extends Equatable {
  final EntityID id;
  final DateTime date;
  final double value;

  TrendPoint({EntityID? id, required this.date, required this.value})
    : id = id ?? newEntityId();

  @override
  List<Object?> get props => [id, date, value];
}

// ──────────────────────────────────────────────────────────────────────────────
// State
// ──────────────────────────────────────────────────────────────────────────────

enum PerformanceEntryStatus { initial, loading, ready, failed }

class PerformanceEntryState extends Equatable {
  final PerformanceEntryStatus status;
  final EntityID? athleteId;
  final List<PhysicalMetric> physicalMetrics;
  final List<TechnicalSkill> technicalSkills;
  final List<WellnessEntry> wellness;

  /// True while a save/delete mutation is in-flight.
  final bool isMutating;

  const PerformanceEntryState({
    this.status = PerformanceEntryStatus.initial,
    this.athleteId,
    this.physicalMetrics = const [],
    this.technicalSkills = const [],
    this.wellness = const [],
    this.isMutating = false,
  });

  PerformanceEntryState copyWith({
    PerformanceEntryStatus? status,
    EntityID? athleteId,
    List<PhysicalMetric>? physicalMetrics,
    List<TechnicalSkill>? technicalSkills,
    List<WellnessEntry>? wellness,
    bool? isMutating,
  }) => PerformanceEntryState(
    status: status ?? this.status,
    athleteId: athleteId ?? this.athleteId,
    physicalMetrics: physicalMetrics ?? this.physicalMetrics,
    technicalSkills: technicalSkills ?? this.technicalSkills,
    wellness: wellness ?? this.wellness,
    isMutating: isMutating ?? this.isMutating,
  );

  // ── Trend helpers (port of the computed trend functions) ──────────────────

  /// Bucket physical metrics by recording day and emit a 0..100 composite per
  /// day (last [days] days). Days with no measurements produce no points.
  List<TrendPoint> physicalTrend({int days = 90}) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final recent = physicalMetrics.where((m) => m.recordedAt.isAfter(cutoff));
    final byDay = <DateTime, List<PhysicalMetric>>{};
    for (final m in recent) {
      final day = _startOfDay(m.recordedAt);
      byDay.putIfAbsent(day, () => []).add(m);
    }
    final points = byDay.entries.map((e) {
      final score = GradingEngine.physicalCompositeScore(e.value);
      return TrendPoint(date: e.key, value: score);
    }).toList();
    points.sort((a, b) => a.date.compareTo(b.date));
    return points;
  }

  /// Bucket technical skills by recording day; emit average (form+app)/2 × 10
  /// per day (last [days] days) so the trend line lives on the 0..100 scale.
  List<TrendPoint> technicalTrend({int days = 90}) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final recent = technicalSkills.where((s) => s.recordedAt.isAfter(cutoff));
    final byDay = <DateTime, List<TechnicalSkill>>{};
    for (final s in recent) {
      final day = _startOfDay(s.recordedAt);
      byDay.putIfAbsent(day, () => []).add(s);
    }
    final points = byDay.entries.map((e) {
      final avg =
          e.value.fold<double>(0, (sum, s) => sum + s.averageScore) /
          e.value.length;
      return TrendPoint(date: e.key, value: avg * 10);
    }).toList();
    points.sort((a, b) => a.date.compareTo(b.date));
    return points;
  }

  /// Wellness composite (0..100) per entry. Combines six signals on a 1..10
  /// scale — sleep, mood, motivation are higher-is-better; soreness, stress,
  /// RPE are inverted (higher = worse). Sleep is mapped to 0..1 against 9h.
  List<TrendPoint> wellnessTrend({int days = 90}) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final sorted = wellness.where((e) => e.recordedAt.isAfter(cutoff)).toList()
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    return sorted.map((e) {
      final sleep = (e.sleepHours / 9.0).clamp(0.0, 1.0);
      final mood = e.mood / 10.0;
      final motivation = e.motivation / 10.0;
      final soreness = 1.0 - (e.soreness - 1) / 9.0;
      final stress = 1.0 - (e.stress - 1) / 9.0;
      final rpe = 1.0 - (e.rpePreviousSession - 1) / 9.0;
      final value =
          (sleep + mood + motivation + soreness + stress + rpe) / 6.0 * 100;
      return TrendPoint(id: e.id, date: e.recordedAt, value: value);
    }).toList();
  }

  /// Number of consecutive days (from today backwards) on which a wellness
  /// entry was recorded.
  int wellnessStreak() {
    final days = wellness.map((e) => _startOfDay(e.recordedAt)).toSet();
    int streak = 0;
    var cursor = _startOfDay(DateTime.now());
    while (days.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  @override
  List<Object?> get props => [
    status,
    athleteId,
    physicalMetrics,
    technicalSkills,
    wellness,
    isMutating,
  ];
}

DateTime _startOfDay(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

// ──────────────────────────────────────────────────────────────────────────────
// Cubit
// ──────────────────────────────────────────────────────────────────────────────

class PerformanceEntryCubit extends Cubit<PerformanceEntryState> {
  final Repository _repo;

  PerformanceEntryCubit(this._repo) : super(const PerformanceEntryState());

  /// Load all entry data for [athleteId]. [windowDays] applies to wellness
  /// only — physical + technical are unwindowed (matches Swift behaviour).
  Future<void> load(EntityID athleteId, {int windowDays = 90}) async {
    emit(
      state.copyWith(
        status: PerformanceEntryStatus.loading,
        athleteId: athleteId,
      ),
    );
    final since = DateTime.now().subtract(Duration(days: windowDays));
    try {
      final physical = await _repo.physicalMetrics(athleteId);
      final technical = await _repo.technicalSkills(athleteId);
      final well = await _repo.wellness(athleteId, since);
      emit(
        state.copyWith(
          status: PerformanceEntryStatus.ready,
          athleteId: athleteId,
          physicalMetrics: physical,
          technicalSkills: technical,
          wellness: well,
        ),
      );
    } catch (e) {
      // ignore: avoid_print
      print('PerformanceEntryCubit.load: $e');
      emit(state.copyWith(status: PerformanceEntryStatus.failed));
    }
  }

  // ── Mutations — each saves then reloads ────────────────────────────────────

  Future<void> saveMetric(PhysicalMetric metric) async {
    emit(state.copyWith(isMutating: true));
    try {
      await _repo.upsertPhysicalMetric(metric);
      await load(metric.athleteId);
    } catch (e) {
      // ignore: avoid_print
      print('PerformanceEntryCubit.saveMetric: $e');
      emit(state.copyWith(isMutating: false));
    }
  }

  Future<void> deleteMetric(EntityID id, EntityID athleteId) async {
    emit(state.copyWith(isMutating: true));
    try {
      await _repo.deletePhysicalMetric(id);
      await load(athleteId);
    } catch (e) {
      // ignore: avoid_print
      print('PerformanceEntryCubit.deleteMetric: $e');
      emit(state.copyWith(isMutating: false));
    }
  }

  Future<void> saveSkill(TechnicalSkill skill) async {
    emit(state.copyWith(isMutating: true));
    try {
      await _repo.upsertTechnicalSkill(skill);
      await load(skill.athleteId);
    } catch (e) {
      // ignore: avoid_print
      print('PerformanceEntryCubit.saveSkill: $e');
      emit(state.copyWith(isMutating: false));
    }
  }

  Future<void> deleteSkill(EntityID id, EntityID athleteId) async {
    emit(state.copyWith(isMutating: true));
    try {
      await _repo.deleteTechnicalSkill(id);
      await load(athleteId);
    } catch (e) {
      // ignore: avoid_print
      print('PerformanceEntryCubit.deleteSkill: $e');
      emit(state.copyWith(isMutating: false));
    }
  }

  Future<void> saveWellness(WellnessEntry entry) async {
    emit(state.copyWith(isMutating: true));
    try {
      await _repo.upsertWellness(entry);
      await load(entry.athleteId);
    } catch (e) {
      // ignore: avoid_print
      print('PerformanceEntryCubit.saveWellness: $e');
      emit(state.copyWith(isMutating: false));
    }
  }
}
