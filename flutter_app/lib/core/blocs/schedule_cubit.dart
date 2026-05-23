import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../models/branch.dart';
import '../models/coach.dart';
import '../models/entity_id.dart';
import '../models/schedule.dart';
import '../repository/repository.dart';

/// Port of `ScheduleStore` (Core/Stores/ScheduleStore.swift).
///
/// A `@Observable @MainActor` store becomes a Cubit emitting an immutable
/// state. Lookup maps (coach + branch) are loaded alongside the sessions so
/// the view never needs a second round-trip.

enum ScheduleStatus { initial, loading, ready, failed }

class ScheduleState extends Equatable {
  final ScheduleStatus status;
  final List<ClassSession> sessionsToday;
  final Map<EntityID, Coach> coachLookup;
  final Map<EntityID, Branch> branchLookup;

  const ScheduleState({
    this.status = ScheduleStatus.initial,
    this.sessionsToday = const [],
    this.coachLookup = const {},
    this.branchLookup = const {},
  });

  ScheduleState copyWith({
    ScheduleStatus? status,
    List<ClassSession>? sessionsToday,
    Map<EntityID, Coach>? coachLookup,
    Map<EntityID, Branch>? branchLookup,
  }) => ScheduleState(
    status: status ?? this.status,
    sessionsToday: sessionsToday ?? this.sessionsToday,
    coachLookup: coachLookup ?? this.coachLookup,
    branchLookup: branchLookup ?? this.branchLookup,
  );

  @override
  List<Object?> get props => [status, sessionsToday, coachLookup, branchLookup];
}

class ScheduleCubit extends Cubit<ScheduleState> {
  final Repository _repo;

  ScheduleCubit(this._repo) : super(const ScheduleState());

  /// Swift: `loadCoachDay(coachID:day:)`. Loads sessions for a single coach on
  /// the given day (defaults to today).
  Future<void> loadCoachDay(EntityID coachId, {DateTime? day}) async {
    emit(state.copyWith(status: ScheduleStatus.loading));
    try {
      final sessions = await _repo.sessionsForCoach(
        coachId,
        day ?? DateTime.now(),
      );
      final (coachLookup, branchLookup) = await _loadLookups();
      emit(
        state.copyWith(
          status: ScheduleStatus.ready,
          sessionsToday: sessions,
          coachLookup: coachLookup,
          branchLookup: branchLookup,
        ),
      );
    } catch (e) {
      // ignore: avoid_print
      print('ScheduleCubit.loadCoachDay: $e');
      emit(state.copyWith(status: ScheduleStatus.failed));
    }
  }

  /// Swift: `loadBranchDay(branchID:day:)`. Loads sessions for an entire
  /// branch on the given day (defaults to today).
  Future<void> loadBranchDay(EntityID branchId, {DateTime? day}) async {
    emit(state.copyWith(status: ScheduleStatus.loading));
    try {
      final sessions = await _repo.sessionsForBranch(
        branchId,
        day ?? DateTime.now(),
      );
      final (coachLookup, branchLookup) = await _loadLookups();
      emit(
        state.copyWith(
          status: ScheduleStatus.ready,
          sessionsToday: sessions,
          coachLookup: coachLookup,
          branchLookup: branchLookup,
        ),
      );
    } catch (e) {
      // ignore: avoid_print
      print('ScheduleCubit.loadBranchDay: $e');
      emit(state.copyWith(status: ScheduleStatus.failed));
    }
  }

  /// Fetches coach + branch lookup tables in parallel.
  Future<(Map<EntityID, Coach>, Map<EntityID, Branch>)> _loadLookups() async {
    final coachesFuture = _repo.coaches();
    final branchesFuture = _repo.branches();
    final coaches = await coachesFuture;
    final branches = await branchesFuture;
    final coachLookup = {for (final c in coaches) c.id: c};
    final branchLookup = {for (final b in branches) b.id: b};
    return (coachLookup, branchLookup);
  }
}
