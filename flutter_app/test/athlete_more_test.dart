import 'package:flutter_test/flutter_test.dart';
import 'package:shjsdsc/core/models/goal.dart';
import 'package:shjsdsc/core/repository/demo_repository.dart';

void main() {
  test('showcase athlete has belt history + emergency contact', () async {
    final repo = DemoRepository();
    final a = (await repo.athlete('ath-1'))!;
    expect(a.beltHistory.length, 4);
    expect(a.emergencyContacts, isNotEmpty);
    // History is older than the current belt.
    for (final b in a.beltHistory) {
      expect(b.awardedAt.isBefore(a.currentBelt.awardedAt), isTrue);
    }
  });

  test('goals load per athlete with mixed status', () async {
    final repo = DemoRepository();
    final goals = await repo.goals('ath-1');
    expect(goals.length, 2);
    expect(goals.any((g) => g.status == GoalStatus.completed), isTrue);
    expect(goals.any((g) => g.status == GoalStatus.active), isTrue);

    expect(await repo.goals('ath-3'), hasLength(1));
    expect((await repo.goals('ath-7')), isEmpty);
  });
}
