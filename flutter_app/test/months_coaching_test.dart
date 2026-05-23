import 'package:flutter_test/flutter_test.dart';
import 'package:shjsdsc/core/models/coaching_development.dart';

void main() {
  group('AssistantCoachProfile.monthsCoaching (Swift parity)', () {
    final now = DateTime.now();

    AssistantCoachProfile started(DateTime at) =>
        AssistantCoachProfile(primaryBranchId: 'b', startedCoachingAt: at);

    test('zero on the start day', () {
      expect(started(DateTime(now.year, now.month, now.day)).monthsCoaching, 0);
    });

    test('whole months when the day-of-month has been reached', () {
      // Exactly one year ago, same day-of-month → 12 (no day-of-month penalty).
      expect(
        started(DateTime(now.year - 1, now.month, now.day)).monthsCoaching,
        12,
      );
    });

    test('day-of-month is honored (no over-count)', () {
      // Started one calendar month ago on the 28th. If today's day-of-month is
      // before the 28th, that month is incomplete → 0; otherwise → 1. This
      // directly exercises the `now.day < start.day` branch.
      final start = DateTime(now.year, now.month - 1, 28);
      final expected = now.day < 28 ? 0 : 1;
      expect(started(start).monthsCoaching, expected);
    });
  });
}
