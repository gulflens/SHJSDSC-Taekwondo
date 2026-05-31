import '../models/performance_score.dart';

/// 1:1 port of Core/Services/ScoreEngine.swift. Pure functions, no I/O — the
/// canonical example of how a `Core/Services` enum-of-statics maps to a Dart
/// class with static members.

class ScoreWeights {
  final double competition;
  final double technical;
  final double physical;
  final double adherence;
  final double beltProgression;
  final double wellness;
  final double character;

  const ScoreWeights({
    required this.competition,
    required this.technical,
    required this.physical,
    required this.adherence,
    required this.beltProgression,
    required this.wellness,
    required this.character,
  });

  static const standard = ScoreWeights(
    competition: 25,
    technical: 20,
    physical: 15,
    adherence: 15,
    beltProgression: 10,
    wellness: 10,
    character: 5,
  );

  static const competitionTeam = ScoreWeights(
    competition: 35,
    technical: 20,
    physical: 15,
    adherence: 10,
    beltProgression: 5,
    wellness: 10,
    character: 5,
  );

  static const cubs = ScoreWeights(
    competition: 5,
    technical: 35,
    physical: 20,
    adherence: 15,
    beltProgression: 10,
    wellness: 10,
    character: 5,
  );
}

enum LetterGrade {
  aPlus('A+'),
  a('A'),
  aMinus('A-'),
  bPlus('B+'),
  b('B'),
  bMinus('B-'),
  cPlus('C+'),
  c('C'),
  cMinus('C-'),
  dPlus('D+'),
  d('D'),
  f('F');

  final String label;
  const LetterGrade(this.label);

  static LetterGrade fromScore(double score) {
    if (score >= 95) return LetterGrade.aPlus;
    if (score >= 90) return LetterGrade.a;
    if (score >= 85) return LetterGrade.aMinus;
    if (score >= 80) return LetterGrade.bPlus;
    if (score >= 75) return LetterGrade.b;
    if (score >= 70) return LetterGrade.bMinus;
    if (score >= 65) return LetterGrade.cPlus;
    if (score >= 60) return LetterGrade.c;
    if (score >= 55) return LetterGrade.cMinus;
    if (score >= 50) return LetterGrade.dPlus;
    if (score >= 40) return LetterGrade.d;
    return LetterGrade.f;
  }
}

class ScoreEngine {
  ScoreEngine._();

  static double composite(
    PerformanceScore s, {
    ScoreWeights weights = ScoreWeights.standard,
  }) {
    final total =
        weights.competition +
        weights.technical +
        weights.physical +
        weights.adherence +
        weights.beltProgression +
        weights.wellness +
        weights.character;
    if (total <= 0) return 0;
    var weighted = 0.0;
    weighted += s.competition * weights.competition;
    weighted += s.technical * weights.technical;
    weighted += s.physical * weights.physical;
    weighted += s.adherence * weights.adherence;
    weighted += s.beltProgression * weights.beltProgression;
    weighted += s.wellness * weights.wellness;
    weighted += s.character * weights.character;
    return weighted / total;
  }

  static LetterGrade grade(
    PerformanceScore s, {
    ScoreWeights weights = ScoreWeights.standard,
  }) => LetterGrade.fromScore(composite(s, weights: weights));

  static double branchComposite(
    List<PerformanceScore> scores, {
    ScoreWeights weights = ScoreWeights.standard,
  }) {
    if (scores.isEmpty) return 0;
    final sum = scores.fold<double>(
      0,
      (acc, s) => acc + composite(s, weights: weights),
    );
    return sum / scores.length;
  }
}
