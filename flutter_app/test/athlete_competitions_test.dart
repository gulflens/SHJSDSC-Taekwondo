import 'package:flutter_test/flutter_test.dart';
import 'package:shjsdsc/core/models/match.dart' show MedalType;
import 'package:shjsdsc/core/repository/demo_repository.dart';

void main() {
  group('Athlete competitions data', () {
    test('registrationsForAthlete returns the seeded medal results', () async {
      final repo = DemoRepository();
      final regs = await repo.registrationsForAthlete('ath-1');
      expect(regs, isNotEmpty);
      // Rashid took gold at the seeded UAE Junior Open.
      final gold = regs.where((r) => r.medal == MedalType.gold);
      expect(gold, isNotEmpty);
      // Each registration's tournament resolves for the event card.
      for (final r in regs) {
        expect(await repo.tournament(r.tournamentId), isNotNull);
      }
    });

    test('an athlete with no entries returns an empty list', () async {
      final repo = DemoRepository();
      expect(await repo.registrationsForAthlete('ath-7'), isEmpty);
    });
  });
}
