import 'package:flutter_test/flutter_test.dart';
import 'package:shjsdsc/core/repository/demo_repository.dart';

void main() {
  test('seeded bracket is a complete 8-person single-elim won by ath-1', () async {
    final repo = DemoRepository();
    final brackets = await repo.brackets('trn-1');
    expect(brackets, hasLength(1));

    final matches = await repo.bracketMatches(brackets.first.id);
    expect(matches, hasLength(7)); // 4 + 2 + 1

    int roundCount(int r) => matches.where((m) => m.round == r).length;
    expect(roundCount(1), 4);
    expect(roundCount(2), 2);
    expect(roundCount(3), 1);

    final finalMatch = matches.firstWhere((m) => m.round == 3);
    expect(finalMatch.winnerId, 'ath-1'); // Rashid — matches his gold medal

    // Every match has a recorded winner that was one of its two competitors.
    for (final m in matches) {
      expect([m.athleteAId, m.athleteBId], contains(m.winnerId));
    }
  });
}
