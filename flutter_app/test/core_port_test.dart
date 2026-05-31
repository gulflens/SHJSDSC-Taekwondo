import 'package:flutter_test/flutter_test.dart';
import 'package:shjsdsc/core/models/athlete.dart';
import 'package:shjsdsc/core/models/athlete_profile.dart';
import 'package:shjsdsc/core/models/belt.dart';
import 'package:shjsdsc/core/models/coaching_development.dart';
import 'package:shjsdsc/core/repository/demo_repository.dart';
import 'package:shjsdsc/core/services/grading_engine.dart';
import 'package:shjsdsc/core/services/scoring_engine.dart';
import 'package:shjsdsc/core/models/match.dart';
import 'package:shjsdsc/core/models/tournament.dart';

void main() {
  group('Model JSON round-trip', () {
    test('Athlete full dossier survives toJson → fromJson', () {
      final original = Athlete(
        id: 'ath-x',
        memberNumber: 42,
        fullName: 'Test Athlete',
        fullNameAr: 'لاعب تجريبي',
        dateOfBirth: DateTime.utc(2010, 4, 15),
        gender: Gender.female,
        branchId: 'branch-1',
        primaryCoachId: 'coach-1',
        joinedAt: DateTime.utc(2020, 1, 1),
        currentBelt: Belt(
          color: BeltColor.blue,
          kind: BeltKind.gup,
          number: 4,
          awardedAt: DateTime.utc(2023, 6, 1),
        ),
        weightKg: 45.5,
        status: AthleteStatus.competitionTeam,
        avatarSeed: 'ath-x',
        bloodType: BloodType.aPositive,
        weightClass: WeightCategory.cadetsUnder45,
        gradingReadiness: 9, // clamps to 5
        programRoles: const {ProgramRole.athlete, ProgramRole.competitionTeam},
      );

      final restored = Athlete.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.gender, Gender.female);
      expect(restored.bloodType, BloodType.aPositive);
      expect(restored.bloodType!.rawValue, 'A+'); // custom raw value preserved
      expect(restored.weightClass, WeightCategory.cadetsUnder45);
      expect(restored.currentBelt.color, BeltColor.blue);
      expect(restored.status, AthleteStatus.competitionTeam);
      expect(restored.gradingReadiness, 5); // clamp survived
      expect(restored.programRoles, original.programRoles);
    });
  });

  group('GradingEngine (port of Core/Services/GradingEngine.swift)', () {
    test('nextBelt advances the gup ladder downward', () {
      final next = GradingEngine.nextBelt(
        Belt(
          color: BeltColor.blue,
          kind: BeltKind.gup,
          number: 4,
          awardedAt: DateTime.utc(2024, 1, 1),
        ),
      );
      // gup numbers count DOWN toward black belt.
      expect(next.kind == BeltKind.gup || next.kind == BeltKind.poom, isTrue);
      expect(next.rank.rankIndex, greaterThan(BeltRank(kind: BeltKind.gup, number: 4).rankIndex));
    });
  });

  group('ScoringEngine (port of Core/Services/ScoringEngine.swift)', () {
    test('applyEvent adds points to the scoring (chung = our) side', () {
      var match = Match(
        id: 'm1',
        tournamentName: 'Test Open',
        date: DateTime.utc(2026, 1, 1),
        ourAthleteId: 'a1',
        opponentName: 'Opponent',
        weightClassKg: 45,
        ourScore: 0,
        opponentScore: 0,
        won: false,
        medal: MedalType.none,
      );
      match = ScoringEngine.applyEvent(
        match,
        ScoreEvent(
          id: 'e1',
          matchId: 'm1',
          round: 1,
          atSecond: 5,
          side: MatchSide.chung,
          action: ScoreAction.headKick, // 3 points
        ),
      );
      expect(match.ourScore, 3);
      expect(match.events.length, 1);
    });
  });

  group('DemoRepository (port of DemoRepository.swift)', () {
    test('seed loads branches, athletes, coaches, scores', () async {
      final repo = DemoRepository();
      expect((await repo.branches()).length, 4);
      expect((await repo.athletes()).length, greaterThanOrEqualTo(8));
      expect((await repo.coaches()).length, greaterThanOrEqualTo(2));
      final main = (await repo.branches()).where((b) => b.isMain);
      expect(main.length, 1, reason: 'exactly one main branch');
    });

    test('athletesForCoach filters by primaryCoachId', () async {
      final repo = DemoRepository();
      final coach = (await repo.coaches()).first;
      final roster = await repo.athletesForCoach(coach.id);
      expect(roster.every((a) => a.primaryCoachId == coach.id), isTrue);
    });

    test('upsert + readback round-trips through the in-memory store', () async {
      final repo = DemoRepository();
      final a = (await repo.athletes()).first;
      final edited = Athlete.fromJson(a.toJson()..['fullName'] = 'Renamed');
      await repo.upsertAthlete(edited);
      expect((await repo.athlete(a.id))!.fullName, 'Renamed');
    });
  });
}
