import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../core/models/branch.dart';
import '../../core/models/coach.dart';
import '../../core/models/entity_id.dart';
import '../../core/repository/repository.dart';
import '../../core/services/score_engine.dart' show LetterGrade;

/// Port of `CoachListView`'s store + `CoachIntel` (CoachIntelKit.swift), trimmed
/// to the list/detail slice — the twin of `AthleteIntel`. Dan rank, experience
/// and the four discipline competencies are REAL `Coach` data; the composite is
/// a deterministic blend of those (no analytics table), mirroring the Swift
/// `CoachIntel.make`. Assigned-athlete counts are real (grouped by
/// `primaryCoachID`).
class CoachIntel extends Equatable {
  final Coach coach;
  final String branchName;
  final String branchNameAr;
  final int athleteCount;

  const CoachIntel({
    required this.coach,
    required this.branchName,
    required this.branchNameAr,
    required this.athleteCount,
  });

  /// 1…5 competencies present on the coach, as a list (skips unrated pillars).
  List<int> get _competencies => [
        coach.technicalLevel,
        coach.sparringLevel,
        coach.poomsaeLevel,
        coach.fitnessLevel,
      ].whereType<int>().toList();

  /// 0…100 composite. Blends the averaged 1–5 competency (70%) with a dan-rank
  /// signal (30%, dan capped at 5 for the blend). Deterministic — no RNG.
  double get composite {
    final comp = _competencies;
    final compAvg = comp.isEmpty
        ? 0.0
        : comp.reduce((a, b) => a + b) / comp.length; // 1…5
    final danSignal = (coach.danRank.clamp(0, 5)) / 5.0; // 0…1
    final blended = (compAvg / 5.0) * 0.7 + danSignal * 0.3; // 0…1
    return (blended * 100).clamp(0, 100).toDouble();
  }

  LetterGrade get grade => LetterGrade.fromScore(composite);

  @override
  List<Object?> get props => [coach.id, branchName, athleteCount];
}

enum CoachListStatus { initial, loading, ready, failed }

class CoachListState extends Equatable {
  final CoachListStatus status;
  final List<CoachIntel> all;
  final String query;

  const CoachListState({
    this.status = CoachListStatus.initial,
    this.all = const [],
    this.query = '',
  });

  /// Filtered + sorted (composite desc) view the screen binds to.
  List<CoachIntel> get visible {
    final q = query.trim().toLowerCase();
    final list = q.isEmpty
        ? all
        : all.where((i) =>
            i.coach.fullName.toLowerCase().contains(q) ||
            i.coach.fullNameAr.contains(query.trim()));
    return list.toList()..sort((a, b) => b.composite.compareTo(a.composite));
  }

  CoachListState copyWith({
    CoachListStatus? status,
    List<CoachIntel>? all,
    String? query,
  }) =>
      CoachListState(
        status: status ?? this.status,
        all: all ?? this.all,
        query: query ?? this.query,
      );

  @override
  List<Object?> get props => [status, all, query];
}

class CoachListCubit extends Cubit<CoachListState> {
  final Repository _repo;

  /// Optional branch scope (mirrors the Swift `scope` API).
  final EntityID? branchScope;

  CoachListCubit(this._repo, {this.branchScope}) : super(const CoachListState());

  Future<void> load() async {
    emit(state.copyWith(status: CoachListStatus.loading));
    try {
      final coaches = branchScope == null
          ? await _repo.coaches()
          : await _repo.coachesInBranch(branchScope!);
      final branches = await _repo.branches();
      final branchById = {for (final Branch b in branches) b.id: b};

      final intel = <CoachIntel>[];
      for (final c in coaches) {
        final roster = await _repo.athletesForCoach(c.id);
        final branch = branchById[c.primaryBranchId];
        intel.add(CoachIntel(
          coach: c,
          branchName: branch?.name ?? '—',
          branchNameAr: branch?.nameAr ?? '—',
          athleteCount: roster.length,
        ));
      }
      emit(state.copyWith(status: CoachListStatus.ready, all: intel));
    } catch (e) {
      // ignore: avoid_print
      print('CoachListCubit.load: $e');
      emit(state.copyWith(status: CoachListStatus.failed));
    }
  }

  void search(String query) => emit(state.copyWith(query: query));
}
