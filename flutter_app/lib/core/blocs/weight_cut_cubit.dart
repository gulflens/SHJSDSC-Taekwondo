import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../models/entity_id.dart';
import '../models/tournament.dart';
import '../repository/repository.dart';

/// Port of `WeightCutStore` (Core/Stores/WeightCutStore.swift).
///
/// Manages the weight-cut log for a single tournament registration. The
/// [trend] derived list and [targetKg] convenience getter mirror the Swift
/// computed properties and are computed directly on the state so the view
/// never needs a separate computation step.

enum WeightCutStatus { initial, loading, ready, failed }

class WeightCutState extends Equatable {
  final WeightCutStatus status;
  final List<WeightCutEntry> entries;

  const WeightCutState({
    this.status = WeightCutStatus.initial,
    this.entries = const [],
  });

  /// Chronological (ascending) list of (date, weight) pairs — mirrors Swift's
  /// `trend: [(date: Date, value: Double)]` computed property.
  List<({DateTime date, double value})> get trend {
    final sorted = [...entries]
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    return sorted.map((e) => (date: e.recordedAt, value: e.currentKg)).toList();
  }

  /// The target weight from the first logged entry, or null when the log is
  /// empty. Mirrors Swift's `targetKg: Double?`.
  double? get targetKg => entries.isEmpty ? null : entries.first.targetKg;

  WeightCutState copyWith({
    WeightCutStatus? status,
    List<WeightCutEntry>? entries,
  }) => WeightCutState(
    status: status ?? this.status,
    entries: entries ?? this.entries,
  );

  @override
  List<Object?> get props => [status, entries];
}

class WeightCutCubit extends Cubit<WeightCutState> {
  final Repository _repo;

  WeightCutCubit(this._repo) : super(const WeightCutState());

  /// Swift: `load(registrationID:)`. Fetches the full weight-cut history for
  /// a registration. Maps to [Repository.weightCutHistory].
  Future<void> load(EntityID registrationId) async {
    emit(state.copyWith(status: WeightCutStatus.loading));
    try {
      final entries = await _repo.weightCutHistory(registrationId);
      emit(state.copyWith(status: WeightCutStatus.ready, entries: entries));
    } catch (e) {
      // ignore: avoid_print
      print('WeightCutCubit.load: $e');
      emit(state.copyWith(status: WeightCutStatus.failed));
    }
  }

  /// Swift: `log(registrationID:currentKg:targetKg:notes:)`. Persists a new
  /// entry via [Repository.upsertWeightCut] then refreshes the list. Maps to
  /// the disambiguated Dart name [upsertWeightCut].
  Future<void> log({
    required EntityID registrationId,
    required double currentKg,
    required double targetKg,
    String? notes,
  }) async {
    final entry = WeightCutEntry.create(
      registrationId: registrationId,
      recordedAt: DateTime.now(),
      currentKg: currentKg,
      targetKg: targetKg,
      notes: notes,
    );
    try {
      await _repo.upsertWeightCut(entry);
      await load(registrationId);
    } catch (e) {
      // ignore: avoid_print
      print('WeightCutCubit.log: $e');
      emit(state.copyWith(status: WeightCutStatus.failed));
    }
  }
}
