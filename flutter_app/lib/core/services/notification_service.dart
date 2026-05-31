// 1:1 port of Core/Services/NotificationService.swift.
//
// Pure logic for building notification payloads and scheduling digests.
// Platform wiring (UNUserNotificationCenter / FCM) is deferred — see the
// TODO(platform) stubs below.

enum NotificationKind {
  tdSundayDigest,
  certExpiring,
  attendanceReminder,
  gradingScheduled,
  tournamentRegistration,
  liveMatchAlert;

  String get labelKey => 'notif.kind.$name';
  String get preferenceKey => 'notif.$name.enabled';
}

/// Minimal scheduler contract. Implement with the platform notification
/// package (e.g. `flutter_local_notifications`) in the platform stage.
abstract class NotificationScheduler {
  /// TODO(platform): implement with flutter_local_notifications or FCM.
  Future<bool> requestAuthorization();

  /// TODO(platform): schedule a local notification to fire at [fireAt].
  Future<void> scheduleLocal({
    required String id,
    required String title,
    required String body,
    required DateTime fireAt,
  });

  /// TODO(platform): cancel a previously scheduled notification.
  Future<void> cancel(String id);
}

/// Snapshot payload for the weekly TD digest notification.
class SundayDigest {
  final double scoresAvg;
  final int watchListCount;
  final int certsExpiring;
  final DateTime fireAt;

  const SundayDigest({
    required this.scoresAvg,
    required this.watchListCount,
    required this.certsExpiring,
    required this.fireAt,
  });
}

/// Pure builder for digest payloads — no I/O.
class DigestBuilder {
  DigestBuilder._();

  /// Compute the next Sunday at 08:00 local time strictly after [from].
  static DateTime nextSunday8am(DateTime from) {
    // weekday: 1=Monday … 7=Sunday in Dart's DateTime.
    var candidate = DateTime(from.year, from.month, from.day, 8, 0, 0);
    // Advance by one day first to ensure strictly after [from].
    candidate = candidate.add(const Duration(days: 1));
    // Keep stepping forward until we land on a Sunday (weekday == 7).
    while (candidate.weekday != DateTime.sunday) {
      candidate = candidate.add(const Duration(days: 1));
    }
    return candidate;
  }

  static SundayDigest buildSundayDigest({
    required DateTime date,
    required double scoresAvg,
    required int watchListCount,
    required int certsExpiring,
  }) => SundayDigest(
    scoresAvg: scoresAvg,
    watchListCount: watchListCount,
    certsExpiring: certsExpiring,
    fireAt: nextSunday8am(date),
  );
}
