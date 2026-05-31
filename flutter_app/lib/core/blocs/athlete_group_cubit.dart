import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../models/athlete_group.dart';
import '../models/entity_id.dart';
import '../repository/repository.dart';

/// Port of `AthleteGroupStore` (Core/Stores/AthleteGroupStore.swift).
///
/// Manages the full list of athlete groups (squads). Active and archived
/// slices are derived getters on [AthleteGroupState], matching the computed
/// properties on the Swift store.

enum AthleteGroupStatus { initial, loading, ready, failed }

class AthleteGroupState extends Equatable {
  final AthleteGroupStatus status;
  final List<AthleteGroup> groups;

  const AthleteGroupState({
    this.status = AthleteGroupStatus.initial,
    this.groups = const [],
  });

  /// Groups that are not archived and not expired — mirrors [AthleteGroupStore.activeGroups].
  List<AthleteGroup> get activeGroups =>
      groups.where((g) => !g.isArchived && !g.isExpired).toList();

  /// Groups that are archived or expired — mirrors [AthleteGroupStore.archivedGroups].
  List<AthleteGroup> get archivedGroups =>
      groups.where((g) => g.isArchived || g.isExpired).toList();

  AthleteGroupState copyWith({
    AthleteGroupStatus? status,
    List<AthleteGroup>? groups,
  }) => AthleteGroupState(
    status: status ?? this.status,
    groups: groups ?? this.groups,
  );

  @override
  List<Object?> get props => [status, groups];
}

class AthleteGroupCubit extends Cubit<AthleteGroupState> {
  final Repository _repo;

  AthleteGroupCubit(this._repo) : super(const AthleteGroupState());

  /// Fetches all groups from the repository. Mirrors [AthleteGroupStore.load].
  Future<void> load() async {
    emit(state.copyWith(status: AthleteGroupStatus.loading));
    try {
      final groups = await _repo.athleteGroups();
      emit(state.copyWith(status: AthleteGroupStatus.ready, groups: groups));
    } catch (e) {
      // ignore: avoid_print
      print('AthleteGroupCubit.load: $e');
      emit(state.copyWith(status: AthleteGroupStatus.failed));
    }
  }

  /// Upserts a group then reloads. Mirrors [AthleteGroupStore.save].
  Future<void> save(AthleteGroup group) async {
    try {
      await _repo.upsertGroup(group);
      await load();
    } catch (e) {
      // ignore: avoid_print
      print('AthleteGroupCubit.save: $e');
    }
  }

  /// Archives a group by setting [AthleteGroup.isArchived] = true.
  /// Mirrors [AthleteGroupStore.archive].
  Future<void> archive(AthleteGroup group) async {
    // AthleteGroup is immutable — rebuild with isArchived toggled.
    final updated = AthleteGroup(
      id: group.id,
      name: group.name,
      nameAr: group.nameAr,
      purpose: group.purpose,
      createdByCoachId: group.createdByCoachId,
      athleteIds: group.athleteIds,
      createdAt: group.createdAt,
      expiresAt: group.expiresAt,
      linkedTournamentId: group.linkedTournamentId,
      isArchived: true,
      nationalityFilter: group.nationalityFilter,
      ageGroupFilter: group.ageGroupFilter,
      genderFilter: group.genderFilter,
      notes: group.notes,
    );
    await save(updated);
  }

  /// Deletes a group by ID then reloads. Mirrors [AthleteGroupStore.delete].
  Future<void> delete(EntityID id) async {
    try {
      await _repo.deleteAthleteGroup(id);
      await load();
    } catch (e) {
      // ignore: avoid_print
      print('AthleteGroupCubit.delete: $e');
    }
  }
}
