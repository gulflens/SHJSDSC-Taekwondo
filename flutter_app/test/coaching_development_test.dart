import 'package:flutter_test/flutter_test.dart';
import 'package:shjsdsc/core/models/coaching_development.dart';
import 'package:shjsdsc/core/repository/demo_repository.dart';

void main() {
  group('Coaching development (assistant-coach dossiers)', () {
    test('seeded assistant coaches carry a dossier + program role', () async {
      final repo = DemoRepository();
      final ahmed = (await repo.athlete('ath-2'))!;
      expect(ahmed.programRoles, contains(ProgramRole.assistantCoach));
      expect(ahmed.assistantCoach, isNotNull);
      expect(ahmed.assistantCoach!.developmentLevel,
          DevelopmentLevel.assistantCoach);
      // The athlete keeps every athlete capability (still has a belt etc).
      expect(ahmed.currentBelt, isNotNull);
    });

    test('promotion readiness is computed and ordered by progression', () async {
      final repo = DemoRepository();
      final ahmed = (await repo.athlete('ath-2'))!.assistantCoach!;
      final khalifa = (await repo.athlete('ath-8'))!.assistantCoach!;
      for (final p in [ahmed, khalifa]) {
        expect(p.promotionReadiness, inInclusiveRange(0, 1));
      }
      // Khalifa: junior coach, 96 sessions, eval 5 → more ready than Ahmed.
      expect(khalifa.promotionReadiness, greaterThan(ahmed.promotionReadiness));
    });

    test('only the promoted athletes are assistant coaches', () async {
      final repo = DemoRepository();
      final assistants =
          (await repo.athletes()).where((a) => a.assistantCoach != null);
      expect(assistants.map((a) => a.id), containsAll(['ath-2', 'ath-8']));
      expect(assistants.length, 2);
    });
  });
}
