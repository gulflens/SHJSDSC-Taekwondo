import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../models/branch.dart';
import '../models/entity_id.dart';
import '../repository/repository.dart';
import '../services/report_exporter.dart';
import '../services/score_engine.dart';

/// Port of `BranchesStore` (Core/Stores/BranchesStore.swift).
///
/// Reuses [BranchSummary] from `lib/core/services/report_exporter.dart` — the
/// same view-model type already defined there (rule 5: reuse, don't redefine).

enum BranchesStatus { initial, loading, ready, failed }

class BranchesState extends Equatable {
  final BranchesStatus status;

  /// One summary per branch, ordered by [BranchSummary.composite] descending.
  final List<BranchSummary> summaries;

  const BranchesState({
    this.status = BranchesStatus.initial,
    this.summaries = const [],
  });

  BranchesState copyWith({
    BranchesStatus? status,
    List<BranchSummary>? summaries,
  }) => BranchesState(
    status: status ?? this.status,
    summaries: summaries ?? this.summaries,
  );

  @override
  List<Object?> get props => [status, summaries];
}

class BranchesCubit extends Cubit<BranchesState> {
  final Repository _repo;

  BranchesCubit(this._repo) : super(const BranchesState());

  /// Loads all branches, computes composite scores from [scoresInBranch],
  /// and derives utilisation from branch capacity. Mirrors [BranchesStore.loadAll].
  Future<void> loadAll() async {
    emit(state.copyWith(status: BranchesStatus.loading));
    try {
      final branches = await _repo.branches();
      final out = <BranchSummary>[];
      for (final Branch b in branches) {
        final athletes = await _repo.athletesInBranch(b.id);
        final scores = await _repo.scoresInBranch(b.id);
        final comp = ScoreEngine.branchComposite(scores);
        final utilisation = b.capacity > 0 ? athletes.length / b.capacity : 0.0;
        out.add(
          BranchSummary(
            id: b.id,
            branch: b,
            composite: comp,
            grade: LetterGrade.fromScore(comp),
            athleteCount: athletes.length,
            utilisation: utilisation.clamp(0.0, 1.0),
          ),
        );
      }
      out.sort((a, b) => b.composite.compareTo(a.composite));
      emit(state.copyWith(status: BranchesStatus.ready, summaries: out));
    } catch (e) {
      // ignore: avoid_print
      print('BranchesCubit.loadAll: $e');
      emit(state.copyWith(status: BranchesStatus.failed));
    }
  }

  /// Convenience: the summary for a specific branch, or null.
  BranchSummary? summaryFor(EntityID branchId) {
    try {
      return state.summaries.firstWhere((s) => s.id == branchId);
    } catch (_) {
      return null;
    }
  }
}
