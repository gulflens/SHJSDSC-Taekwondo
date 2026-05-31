import 'package:flutter_test/flutter_test.dart';
import 'package:shjsdsc/core/models/role.dart';
import 'package:shjsdsc/core/repository/demo_repository.dart';

void main() {
  group('Per-user scoping data', () {
    test('parent account links to resolvable athletes', () async {
      final repo = DemoRepository();
      final users = await repo.availableUsers();
      final parent =
          users.firstWhere((u) => u.role == Role.parent);
      expect(parent.linkedAthleteIds, isNotEmpty);
      for (final id in parent.linkedAthleteIds) {
        expect(await repo.athlete(id), isNotNull,
            reason: 'linked child $id must resolve');
      }
    });

    test('athlete account links to its own profile', () async {
      final repo = DemoRepository();
      final users = await repo.availableUsers();
      final athleteUser =
          users.firstWhere((u) => u.role == Role.athlete);
      expect(athleteUser.linkedAthleteIds, isNotEmpty);
      final me = await repo.athlete(athleteUser.linkedAthleteIds.first);
      expect(me, isNotNull);
    });
  });
}
