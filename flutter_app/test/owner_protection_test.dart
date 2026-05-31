import 'package:flutter_test/flutter_test.dart';
import 'package:shjsdsc/core/models/app_owner.dart';
import 'package:shjsdsc/core/models/role.dart';
import 'package:shjsdsc/core/models/user.dart';
import 'package:shjsdsc/core/repository/demo_repository.dart';
import 'package:shjsdsc/core/repository/repository.dart';

void main() {
  group('AppOwner.matches', () {
    test('case-insensitive and whitespace-tolerant', () {
      expect(AppOwner.matches('gulflens.studio@gmail.com'), isTrue);
      expect(AppOwner.matches('GULFLENS.STUDIO@GMAIL.COM'), isTrue);
      expect(AppOwner.matches('  gulflens.studio@gmail.com  '), isTrue);
      expect(AppOwner.matches('someone.else@gmail.com'), isFalse);
      expect(AppOwner.matches(null), isFalse);
    });
  });

  group('createAccount owner reservation', () {
    test('rejects the reserved owner email (incl. padded)', () async {
      final repo = DemoRepository();
      expect(
        () => repo.createAccount(
          email: ' gulflens.studio@gmail.com ',
          password: 'x',
          fullName: 'Mallory',
          fullNameAr: 'Mallory',
          role: Role.parent,
        ),
        throwsA(isA<OwnerEmailReservedException>()),
      );
    });

    test('allows a normal email', () async {
      final repo = DemoRepository();
      await repo.createAccount(
        email: 'newcoach@demo',
        password: 'x',
        fullName: 'New Coach',
        fullNameAr: 'New Coach',
        role: Role.coach,
      );
      expect((await repo.availableUsers()).any((u) => u.email == 'newcoach@demo'),
          isTrue);
    });
  });

  group('updateUser owner protection', () {
    test('re-pins the owner role + email (cannot demote/rename)', () async {
      final repo = DemoRepository();
      final owner = (await repo.availableUsers())
          .firstWhere((u) => u.email == AppOwner.email);
      // Attempt to demote + rename the owner.
      final tampered = User(
        id: owner.id,
        fullName: 'Hijacked',
        fullNameAr: 'Hijacked',
        role: Role.parent,
        avatarSeed: owner.avatarSeed,
        email: 'attacker@evil.com',
      );
      await repo.updateUser(tampered);
      final after = (await repo.user(owner.id))!;
      expect(after.role, Role.developer, reason: 'owner stays developer');
      expect(after.email, AppOwner.email, reason: 'owner email re-pinned');
    });

    test('rejects a non-owner claiming the reserved email', () async {
      final repo = DemoRepository();
      final athleteUser =
          (await repo.availableUsers()).firstWhere((u) => u.role == Role.athlete);
      final claim = User(
        id: athleteUser.id,
        fullName: athleteUser.fullName,
        fullNameAr: athleteUser.fullNameAr,
        role: athleteUser.role,
        avatarSeed: athleteUser.avatarSeed,
        email: AppOwner.email, // try to become a second owner
      );
      expect(() => repo.updateUser(claim),
          throwsA(isA<OwnerEmailReservedException>()));
    });
  });
}
