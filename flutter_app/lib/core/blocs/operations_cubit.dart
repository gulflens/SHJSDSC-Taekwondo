import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../models/entity_id.dart';
import '../models/operations.dart';
import '../repository/repository.dart';

/// Port of `OperationsStore` (Core/Stores/OperationsStore.swift).
///
/// Manages announcements and their RSVP buckets. [load] accepts an optional
/// audience filter, matching the Swift `load(audience:)` default-param
/// signature. Computed helpers ([grouped], [unreadCount], [myResponse])
/// are ported as pure methods on [OperationsCubit] that derive from the
/// current state.

enum OperationsStatus { initial, loading, ready, failed }

class OperationsState extends Equatable {
  final OperationsStatus status;
  final List<Announcement> announcements;

  /// RSVPs keyed by announcement ID. Mirrors [OperationsStore.rsvpsByAnnouncement].
  final Map<EntityID, List<AnnouncementRSVP>> rsvpsByAnnouncement;

  const OperationsState({
    this.status = OperationsStatus.initial,
    this.announcements = const [],
    this.rsvpsByAnnouncement = const {},
  });

  OperationsState copyWith({
    OperationsStatus? status,
    List<Announcement>? announcements,
    Map<EntityID, List<AnnouncementRSVP>>? rsvpsByAnnouncement,
  }) => OperationsState(
    status: status ?? this.status,
    announcements: announcements ?? this.announcements,
    rsvpsByAnnouncement: rsvpsByAnnouncement ?? this.rsvpsByAnnouncement,
  );

  @override
  List<Object?> get props => [status, announcements, rsvpsByAnnouncement];
}

class OperationsCubit extends Cubit<OperationsState> {
  final Repository _repo;

  OperationsCubit(this._repo) : super(const OperationsState());

  /// Loads announcements for [audience] (null = all), then fetches RSVP
  /// lists for each announcement. Mirrors [OperationsStore.load(audience:)].
  Future<void> load({AnnouncementAudience? audience}) async {
    emit(state.copyWith(status: OperationsStatus.loading));
    try {
      final announcements = await _repo.announcements(audience);
      final bucket = <EntityID, List<AnnouncementRSVP>>{};
      for (final a in announcements) {
        bucket[a.id] = await _repo.rsvps(a.id);
      }
      emit(
        state.copyWith(
          status: OperationsStatus.ready,
          announcements: announcements,
          rsvpsByAnnouncement: bucket,
        ),
      );
    } catch (e) {
      // ignore: avoid_print
      print('OperationsCubit.load: $e');
      emit(state.copyWith(status: OperationsStatus.failed));
    }
  }

  /// Announcements grouped by calendar day, each group sorted newest-first.
  /// Mirrors [OperationsStore.grouped()].
  List<({DateTime date, List<Announcement> items})> grouped() {
    final groups = <DateTime, List<Announcement>>{};
    for (final a in state.announcements) {
      final day = DateTime(
        a.publishedAt.year,
        a.publishedAt.month,
        a.publishedAt.day,
      );
      (groups[day] ??= []).add(a);
    }
    final sorted = groups.entries.toList()
      ..sort((x, y) => y.key.compareTo(x.key));
    return sorted.map((e) {
      final items = e.value
        ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
      return (date: e.key, items: items);
    }).toList();
  }

  /// Demo proxy for unread count: announcements in the last 7 days that the
  /// user has not RSVPed to (when RSVP required) or any without RSVP requirement.
  /// Mirrors [OperationsStore.unreadCount(for:)].
  int unreadCount(EntityID userId) {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return state.announcements.where((a) {
      if (a.publishedAt.isBefore(cutoff)) return false;
      if (a.requiresRsvp) {
        final rsvps = state.rsvpsByAnnouncement[a.id] ?? [];
        return !rsvps.any((r) => r.userId == userId);
      }
      return true;
    }).length;
  }

  /// Returns the current user's RSVP response for an announcement, or null.
  /// Mirrors [OperationsStore.myResponse(announcementID:userID:)].
  RSVPResponse? myResponse(EntityID announcementId, EntityID userId) {
    final rsvps = state.rsvpsByAnnouncement[announcementId] ?? [];
    try {
      return rsvps.firstWhere((r) => r.userId == userId).response;
    } catch (_) {
      return null;
    }
  }

  /// Upserts an announcement then reloads. Mirrors [OperationsStore.publish].
  Future<void> publish(Announcement announcement) async {
    try {
      await _repo.upsertAnnouncement(announcement);
      await load();
    } catch (e) {
      // ignore: avoid_print
      print('OperationsCubit.publish: $e');
    }
  }

  /// Records an RSVP for [userId] on [announcementId] and refreshes only
  /// that announcement's RSVP list. Mirrors [OperationsStore.rsvp].
  Future<void> rsvp({
    required EntityID announcementId,
    required EntityID userId,
    required RSVPResponse response,
  }) async {
    final r = AnnouncementRSVP(
      id: newEntityId(),
      announcementId: announcementId,
      userId: userId,
      response: response,
      respondedAt: DateTime.now(),
    );
    try {
      await _repo.upsertRsvp(r);
      final updated = await _repo.rsvps(announcementId);
      final bucket = Map<EntityID, List<AnnouncementRSVP>>.from(
        state.rsvpsByAnnouncement,
      )..[announcementId] = updated;
      emit(state.copyWith(rsvpsByAnnouncement: bucket));
    } catch (e) {
      // ignore: avoid_print
      print('OperationsCubit.rsvp: $e');
    }
  }
}
