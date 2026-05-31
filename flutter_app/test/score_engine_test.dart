import 'package:flutter_test/flutter_test.dart';
import 'package:shjsdsc/core/models/performance_score.dart';
import 'package:shjsdsc/core/services/score_engine.dart';

void main() {
  PerformanceScore flat(double v) => PerformanceScore(
        athleteId: 'a',
        competition: v,
        technical: v,
        physical: v,
        adherence: v,
        beltProgression: v,
        wellness: v,
        character: v,
      );

  group('ScoreEngine (port of Core/Services/ScoreEngine.swift)', () {
    test('flat pillars produce that same composite', () {
      expect(ScoreEngine.composite(flat(80)), closeTo(80, 0.0001));
    });

    test('weighted composite matches hand calc', () {
      final s = PerformanceScore(
        athleteId: 'a',
        competition: 90,
        technical: 80,
        physical: 70,
        adherence: 60,
        beltProgression: 50,
        wellness: 40,
        character: 30,
      );
      // standard weights: 25/20/15/15/10/10/5 (total 100)
      final expected = (90 * 25 +
              80 * 20 +
              70 * 15 +
              60 * 15 +
              50 * 10 +
              40 * 10 +
              30 * 5) /
          100;
      expect(ScoreEngine.composite(s), closeTo(expected, 0.0001));
    });

    test('letter-grade thresholds match the Swift table', () {
      expect(LetterGrade.fromScore(96), LetterGrade.aPlus);
      expect(LetterGrade.fromScore(92), LetterGrade.a);
      expect(LetterGrade.fromScore(80), LetterGrade.bPlus);
      expect(LetterGrade.fromScore(40), LetterGrade.d);
      expect(LetterGrade.fromScore(39), LetterGrade.f);
    });

    test('branchComposite averages per-athlete composites', () {
      expect(ScoreEngine.branchComposite([flat(60), flat(80)]),
          closeTo(70, 0.0001));
      expect(ScoreEngine.branchComposite([]), 0);
    });
  });
}
