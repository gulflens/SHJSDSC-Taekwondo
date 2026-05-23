import 'package:flutter_test/flutter_test.dart';
import 'package:shjsdsc/core/repository/demo_repository.dart';

void main() {
  test('athletesForCoach returns the seeded roster (Yassin → 3 athletes)', () async {
    final repo = DemoRepository();
    final roster = await repo.athletesForCoach('coach-yassin');
    expect(roster.map((a) => a.id), containsAll(['ath-1', 'ath-2', 'ath-3']));
    expect(roster.every((a) => a.primaryCoachId == 'coach-yassin'), isTrue);
  });

  test('a coach with no roster yields an empty list', () async {
    final repo = DemoRepository();
    expect(await repo.athletesForCoach('coach-does-not-exist'), isEmpty);
  });
}
