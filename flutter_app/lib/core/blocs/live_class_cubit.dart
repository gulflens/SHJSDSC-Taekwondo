import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../models/athlete.dart';
import '../models/entity_id.dart';
import '../models/schedule.dart';
import '../repository/repository.dart';

/// Port of Core/Stores/LiveClassStore.swift.
///
/// Manages attendance marking and effort ratings for a single [ClassSession].
/// The store pre-populates attendance from any existing [AttendanceRecord]s,
/// defaults unmarked athletes to [AttendanceState.present], and saves the
/// full roster back to the repository in one batch on [save].

// ──────────────────────────────────────────────────────────────────────────────
// State
// ──────────────────────────────────────────────────────────────────────────────

enum LiveClassStatus { initial, loading, ready, saving, saved, failed }

class LiveClassState extends Equatable {
  final LiveClassStatus status;

  /// The session being attended. Set from the constructor; never changes.
  final ClassSession? session;

  /// Athletes enrolled in the session, sorted by name.
  final List<Athlete> athletes;

  /// Attendance mark per athlete ID.
  final Map<EntityID, AttendanceState> marks;

  /// Effort / engagement rating (1…5) per athlete ID.
  final Map<EntityID, int> ratings;

  const LiveClassState({
    this.status = LiveClassStatus.initial,
    this.session,
    this.athletes = const [],
    this.marks = const {},
    this.ratings = const {},
  });

  // ── Derived KPIs ────────────────────────────────────────────────────────────

  int get presentCount => athletes.fold(0, (acc, a) {
    final s = marks[a.id] ?? AttendanceState.present;
    return (s == AttendanceState.present || s == AttendanceState.late)
        ? acc + 1
        : acc;
  });

  int get absentCount => athletes.fold(0, (acc, a) {
    final s = marks[a.id] ?? AttendanceState.present;
    return (s == AttendanceState.absent || s == AttendanceState.excused)
        ? acc + 1
        : acc;
  });

  LiveClassState copyWith({
    LiveClassStatus? status,
    ClassSession? session,
    List<Athlete>? athletes,
    Map<EntityID, AttendanceState>? marks,
    Map<EntityID, int>? ratings,
  }) => LiveClassState(
    status: status ?? this.status,
    session: session ?? this.session,
    athletes: athletes ?? this.athletes,
    marks: marks ?? this.marks,
    ratings: ratings ?? this.ratings,
  );

  @override
  List<Object?> get props => [status, session?.id, athletes, marks, ratings];
}

// ──────────────────────────────────────────────────────────────────────────────
// Cubit
// ──────────────────────────────────────────────────────────────────────────────

class LiveClassCubit extends Cubit<LiveClassState> {
  final Repository _repo;
  final ClassSession session;

  LiveClassCubit(this._repo, {required this.session})
    : super(LiveClassState(session: session));

  /// Load enrolled athletes and pre-populate attendance from existing records.
  Future<void> load() async {
    emit(state.copyWith(status: LiveClassStatus.loading));
    try {
      final all = await _repo.athletes();
      final enrolled = session.enrolledAthleteIds.toSet();
      final athletes = all.where((a) => enrolled.contains(a.id)).toList()
        ..sort((a, b) => a.fullName.compareTo(b.fullName));

      final existing = await _repo.attendanceForSession(session.id);

      final marks = <EntityID, AttendanceState>{};
      final ratings = <EntityID, int>{};

      // Pre-populate from any saved records.
      for (final r in existing) {
        marks[r.athleteId] = r.state;
        final effort = r.effortRating;
        if (effort != null) ratings[r.athleteId] = effort;
      }

      // Default unmarked athletes to present.
      for (final a in athletes) {
        marks.putIfAbsent(a.id, () => AttendanceState.present);
      }

      emit(
        state.copyWith(
          status: LiveClassStatus.ready,
          athletes: athletes,
          marks: marks,
          ratings: ratings,
        ),
      );
    } catch (e) {
      // ignore: avoid_print
      print('LiveClassCubit.load: $e');
      emit(state.copyWith(status: LiveClassStatus.failed));
    }
  }

  // ── Attendance mutations ───────────────────────────────────────────────────

  void setState(AttendanceState attendanceState, EntityID athleteId) {
    final updated = Map<EntityID, AttendanceState>.from(state.marks)
      ..[athleteId] = attendanceState;
    emit(state.copyWith(marks: updated));
  }

  /// Cycles through present → late → absent → excused → present.
  void cycleState(EntityID athleteId) {
    const order = [
      AttendanceState.present,
      AttendanceState.late,
      AttendanceState.absent,
      AttendanceState.excused,
    ];
    final current = state.marks[athleteId] ?? AttendanceState.present;
    final idx = order.indexOf(current);
    final next = order[(idx + 1) % order.length];
    setState(next, athleteId);
  }

  void markAllPresent() {
    final updated = <EntityID, AttendanceState>{};
    for (final a in state.athletes) {
      updated[a.id] = AttendanceState.present;
    }
    emit(state.copyWith(marks: updated));
  }

  // ── Effort ratings ─────────────────────────────────────────────────────────

  void setRating(int rating, EntityID athleteId) {
    final clamped = rating.clamp(1, 5);
    final updated = Map<EntityID, int>.from(state.ratings)
      ..[athleteId] = clamped;
    emit(state.copyWith(ratings: updated));
  }

  // ── Persist ────────────────────────────────────────────────────────────────

  /// Save attendance for all enrolled athletes in a single batch upsert.
  Future<void> save() async {
    emit(state.copyWith(status: LiveClassStatus.saving));
    try {
      final records = state.athletes.map((a) {
        final existing = state.marks[a.id] ?? AttendanceState.present;
        return AttendanceRecord(
          id: newEntityId(),
          sessionId: session.id,
          athleteId: a.id,
          state: existing,
          recordedAt: DateTime.now(),
          effortRating: state.ratings[a.id],
        );
      }).toList();
      await _repo.upsertAttendanceBatch(records);
      emit(state.copyWith(status: LiveClassStatus.saved));
    } catch (e) {
      // ignore: avoid_print
      print('LiveClassCubit.save: $e');
      emit(state.copyWith(status: LiveClassStatus.failed));
    }
  }
}
