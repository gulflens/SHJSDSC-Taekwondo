import 'package:flutter_test/flutter_test.dart';
import 'package:shjsdsc/core/repository/demo_repository.dart';

void main() {
  group('Medical dossier seeding', () {
    test('every athlete has baseline vitals (blood type)', () async {
      final repo = DemoRepository();
      for (final a in await repo.athletes()) {
        expect(a.bloodType, isNotNull);
        expect(a.heightCm, isNotNull);
      }
    });

    test('showcase athlete carries a full dossier', () async {
      final repo = DemoRepository();
      final a = (await repo.athlete('ath-1'))!;
      expect(a.allergies, contains('Penicillin'));
      expect(a.injuries, isNotEmpty);
      expect(a.weightHistory.length, 5);
      expect(a.fitToTrain, isTrue);
    });

    test('an athlete can be flagged not cleared to train', () async {
      final repo = DemoRepository();
      final a = (await repo.athlete('ath-3'))!;
      expect(a.fitToTrain, isFalse);
      expect(a.injuries, isNotEmpty);
    });
  });
}
