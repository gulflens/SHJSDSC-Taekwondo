import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/models/athlete.dart';
import '../../core/models/branch.dart';
import '../../core/models/entity_id.dart';
import '../../core/models/performance_score.dart';
import '../../core/repository/repository.dart';
import '../../core/services/score_engine.dart';

/// Port of `AthletesStore` (Core/Stores/AthletesStore.swift). A `@Observable
/// @MainActor` store becomes a Cubit emitting an immutable state. Composite
/// scores are computed on the fly via [ScoreEngine], exactly as the Swift
/// store does — the view never recomputes.

/// View-model row pairing an athlete with its derived score data — the Flutter
/// equivalent of `AthleteIntel` (AthleteIntelKit.swift), trimmed to the fields
/// the list + detail slice render.
class AthleteIntel extends Equatable {
  final Athlete athlete;
  final PerformanceScore? score;
  final String branchName;
  final String branchNameAr;

  const AthleteIntel({
    required this.athlete,
    required this.score,
    required this.branchName,
    required this.branchNameAr,
  });

  double get composite =>
      score == null ? 0 : ScoreEngine.composite(score!, weights: _weights);

  LetterGrade get grade => LetterGrade.fromScore(composite);

  ScoreWeights get _weights => athlete.status == AthleteStatus.competitionTeam
      ? ScoreWeights.competitionTeam
      : athlete.ageGroup == AgeGroup.cubs
          ? ScoreWeights.cubs
          : ScoreWeights.standard;

  @override
  List<Object?> get props => [athlete.id, score?.id, branchName];
}

enum AthleteListStatus { initial, loading, ready, failed }

class AthleteListState extends Equatable {
  final AthleteListStatus status;
  final List<AthleteIntel> all;
  final String query;

  const AthleteListState({
    this.status = AthleteListStatus.initial,
    this.all = const [],
    this.query = '',
  });

  /// Filtered + sorted view the screen binds to.
  List<AthleteIntel> get visible {
    final q = query.trim().toLowerCase();
    final list = q.isEmpty
        ? all
        : all.where((i) =>
            i.athlete.fullName.toLowerCase().contains(q) ||
            i.athlete.fullNameAr.contains(query.trim()) ||
            '${i.athlete.memberNumber}'.contains(q));
    return list.toList()..sort((a, b) => b.composite.compareTo(a.composite));
  }

  AthleteListState copyWith({
    AthleteListStatus? status,
    List<AthleteIntel>? all,
    String? query,
  }) =>
      AthleteListState(
        status: status ?? this.status,
        all: all ?? this.all,
        query: query ?? this.query,
      );

  @override
  List<Object?> get props => [status, all, query];
}

class AthleteListCubit extends Cubit<AthleteListState> {
  final Repository _repo;

  /// Optional scope — when set, loads only that branch's roster (mirrors the
  /// `scope` API on the Swift `AthleteListView`).
  final EntityID? branchScope;

  AthleteListCubit(this._repo, {this.branchScope})
      : super(const AthleteListState());

  Future<void> load() async {
    emit(state.copyWith(status: AthleteListStatus.loading));
    try {
      final athletes = branchScope == null
          ? await _repo.athletes()
          : await _repo.athletesInBranch(branchScope!);
      final branches = await _repo.branches();
      final branchById = {for (final Branch b in branches) b.id: b};

      final intel = <AthleteIntel>[];
      for (final a in athletes) {
        final score = await _repo.score(a.id);
        final branch = branchById[a.branchId];
        intel.add(AthleteIntel(
          athlete: a,
          score: score,
          branchName: branch?.name ?? '—',
          branchNameAr: branch?.nameAr ?? '—',
        ));
      }
      emit(state.copyWith(status: AthleteListStatus.ready, all: intel));
    } catch (e) {
      emit(state.copyWith(status: AthleteListStatus.failed));
    }
  }

  void search(String query) => emit(state.copyWith(query: query));
}
