import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../models/entity_id.dart';
import '../models/tournament.dart';
import '../repository/repository.dart';

/// Port of `TournamentsStore` (Core/Stores/TournamentsStore.swift).
///
/// Holds the full tournament list and exposes derived [upcoming] / [past]
/// views — mirroring the computed properties on the Swift store. The
/// [byId] lookup is a pure method on the state so callers can find a
/// tournament without a second load.

enum TournamentsStatus { initial, loading, ready, failed }

class TournamentsState extends Equatable {
  final TournamentsStatus status;
  final List<Tournament> all;

  const TournamentsState({
    this.status = TournamentsStatus.initial,
    this.all = const [],
  });

  /// Tournaments that have not yet started, sorted ascending by start date.
  List<Tournament> get upcoming {
    final now = DateTime.now();
    return all.where((t) => !t.startsAt.isBefore(now)).toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
  }

  /// Tournaments whose end date is in the past, sorted descending (newest
  /// past event first). Mirrors Swift's `past` computed property.
  List<Tournament> get past {
    final now = DateTime.now();
    return all.where((t) => t.endsAt.isBefore(now)).toList()
      ..sort((a, b) => b.startsAt.compareTo(a.startsAt));
  }

  /// Look up a tournament by ID. Returns null when not found, matching
  /// Swift's `byID(_:)` method.
  Tournament? byId(EntityID id) => all.cast<Tournament?>().firstWhere(
    (t) => t?.id == id,
    orElse: () => null,
  );

  TournamentsState copyWith({
    TournamentsStatus? status,
    List<Tournament>? all,
  }) => TournamentsState(status: status ?? this.status, all: all ?? this.all);

  @override
  List<Object?> get props => [status, all];
}

class TournamentsCubit extends Cubit<TournamentsState> {
  final Repository _repo;

  TournamentsCubit(this._repo) : super(const TournamentsState());

  /// Swift: `loadTournaments()`. Fetches all tournaments from the repository.
  Future<void> loadTournaments() async {
    emit(state.copyWith(status: TournamentsStatus.loading));
    try {
      final tournaments = await _repo.tournaments();
      emit(state.copyWith(status: TournamentsStatus.ready, all: tournaments));
    } catch (e) {
      // ignore: avoid_print
      print('TournamentsCubit.loadTournaments: $e');
      emit(state.copyWith(status: TournamentsStatus.failed));
    }
  }
}
