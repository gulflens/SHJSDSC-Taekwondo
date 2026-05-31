import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../models/audit_log.dart';
import '../models/entity_id.dart';
import '../models/user.dart';
import '../repository/repository.dart';

/// Port of `AuditStore` (Core/Stores/AuditStore.swift).
///
/// Loads audit log entries filtered by actor and/or time window, then
/// resolves the actor [User] objects for display. Filters are stored on the
/// cubit (not on the state) because changing them always triggers a reload —
/// matching the `@Observable var` filter properties on the Swift store.

enum AuditStatus { initial, loading, ready, failed }

class AuditState extends Equatable {
  final AuditStatus status;

  /// Filtered entries, as returned by the repository.
  final List<AuditEntry> entries;

  /// Actor [User] objects keyed by [EntityID], for row display.
  final Map<EntityID, User> userLookup;

  const AuditState({
    this.status = AuditStatus.initial,
    this.entries = const [],
    this.userLookup = const {},
  });

  AuditState copyWith({
    AuditStatus? status,
    List<AuditEntry>? entries,
    Map<EntityID, User>? userLookup,
  }) => AuditState(
    status: status ?? this.status,
    entries: entries ?? this.entries,
    userLookup: userLookup ?? this.userLookup,
  );

  @override
  List<Object?> get props => [status, entries, userLookup];
}

class AuditCubit extends Cubit<AuditState> {
  final Repository _repo;

  /// Optional actor filter. Set before calling [load]. Mirrors
  /// [AuditStore.actorFilter].
  EntityID? actorFilter;

  /// Optional earliest-date filter. Set before calling [load]. Mirrors
  /// [AuditStore.sinceFilter].
  DateTime? sinceFilter;

  AuditCubit(this._repo) : super(const AuditState());

  /// Fetches entries matching [actorFilter] / [sinceFilter], then resolves
  /// the [User] record for every distinct actor. Mirrors [AuditStore.load].
  Future<void> load() async {
    emit(state.copyWith(status: AuditStatus.loading));
    try {
      final entries = await _repo.entriesForActor(
        actorId: actorFilter,
        since: sinceFilter,
      );

      // Resolve unique actor users for the display layer.
      final actorIds = entries.map((e) => e.actorUserId).toSet();
      final lookup = <EntityID, User>{};
      for (final id in actorIds) {
        final u = await _repo.user(id);
        if (u != null) lookup[id] = u;
      }

      emit(
        state.copyWith(
          status: AuditStatus.ready,
          entries: entries,
          userLookup: lookup,
        ),
      );
    } catch (e) {
      // ignore: avoid_print
      print('AuditCubit.load: $e');
      emit(state.copyWith(status: AuditStatus.failed));
    }
  }

  /// Convenience: update [actorFilter] and reload.
  Future<void> filterByActor(EntityID? actorId) async {
    actorFilter = actorId;
    await load();
  }

  /// Convenience: update [sinceFilter] and reload.
  Future<void> filterSince(DateTime? since) async {
    sinceFilter = since;
    await load();
  }

  /// Log a new entry and reload to reflect it. Useful for manual log writes
  /// within the same session.
  Future<void> log(AuditEntry entry) async {
    try {
      await _repo.log(entry);
      await load();
    } catch (e) {
      // ignore: avoid_print
      print('AuditCubit.log: $e');
    }
  }
}
