import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../models/athlete.dart';
import '../models/entity_id.dart';
import '../models/grading.dart';
import '../repository/repository.dart';
import '../services/grading_engine.dart';

/// View-model pairing an athlete with its pre-computed grading eligibility.
///
/// Port of `PromotionReadinessEntry` (Core/Stores/PromotionReadinessStore.swift).
/// Defined here because it is specific to this slice and no other cubit
/// currently needs it.
class PromotionReadinessEntry extends Equatable {
  final Athlete athlete;
  final GradingEligibility eligibility;

  EntityID get id => athlete.id;

  const PromotionReadinessEntry({
    required this.athlete,
    required this.eligibility,
  });

  @override
  List<Object?> get props => [athlete.id, eligibility.isEligible];
}

/// Port of `PromotionReadinessStore` (Core/Stores/PromotionReadinessStore.swift).
///
/// Surfaces athletes assigned to a coach whose attendance / technical /
/// physical / time-at-rank thresholds have all been met. Drives the
/// "promotion readiness" card on the coach home dashboard.
///
/// Uses [GradingEngine.nextBelt] (service layer, pure Dart) and the
/// repository's [eligibility] method (disambiguated name from Swift's
/// `eligibility(athleteID:targetBelt:)`).

enum PromotionReadinessStatus { initial, loading, ready, failed }

class PromotionReadinessState extends Equatable {
  final PromotionReadinessStatus status;
  final List<PromotionReadinessEntry> entries;

  const PromotionReadinessState({
    this.status = PromotionReadinessStatus.initial,
    this.entries = const [],
  });

  PromotionReadinessState copyWith({
    PromotionReadinessStatus? status,
    List<PromotionReadinessEntry>? entries,
  }) => PromotionReadinessState(
    status: status ?? this.status,
    entries: entries ?? this.entries,
  );

  @override
  List<Object?> get props => [status, entries];
}

class PromotionReadinessCubit extends Cubit<PromotionReadinessState> {
  final Repository _repo;

  PromotionReadinessCubit(this._repo) : super(const PromotionReadinessState());

  /// Swift: `load(coachID:)`. Evaluates every athlete assigned to the coach
  /// and keeps only those who are eligible for the next belt.
  ///
  /// Eligible entries are sorted by descending attendance percentage then
  /// ascending full name — mirroring the Swift sort closure.
  Future<void> load(EntityID coachId) async {
    emit(state.copyWith(status: PromotionReadinessStatus.loading));
    try {
      final athletes = await _repo.athletesForCoach(coachId);
      final found = <PromotionReadinessEntry>[];

      for (final athlete in athletes) {
        final target = GradingEngine.nextBelt(athlete.currentBelt);
        // If nextBelt returns the same belt the athlete is already at the top
        // of the ladder — skip.
        if (target.color == athlete.currentBelt.color &&
            target.kind == athlete.currentBelt.kind &&
            target.number == athlete.currentBelt.number) {
          continue;
        }
        // Maps to Swift's `repository.eligibility(athleteID:targetBelt:)`.
        final eligibility = await _repo.eligibility(athlete.id, target);
        if (!eligibility.isEligible) continue;
        found.add(
          PromotionReadinessEntry(athlete: athlete, eligibility: eligibility),
        );
      }

      found.sort((lhs, rhs) {
        if (lhs.eligibility.attendancePct != rhs.eligibility.attendancePct) {
          return rhs.eligibility.attendancePct.compareTo(
            lhs.eligibility.attendancePct,
          );
        }
        return lhs.athlete.fullName.compareTo(rhs.athlete.fullName);
      });

      emit(
        state.copyWith(status: PromotionReadinessStatus.ready, entries: found),
      );
    } catch (e) {
      // ignore: avoid_print
      print('PromotionReadinessCubit.load: $e');
      emit(
        state.copyWith(
          status: PromotionReadinessStatus.failed,
          entries: const [],
        ),
      );
    }
  }
}
