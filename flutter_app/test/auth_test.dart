import 'package:flutter_test/flutter_test.dart';
import 'package:shjsdsc/core/blocs/session_cubit.dart';
import 'package:shjsdsc/core/repository/demo_repository.dart';

void main() {
  group('Auth flow (SessionCubit + DemoRepository AuthRepository)', () {
    test('demo starts authenticated', () async {
      final cubit = SessionCubit(DemoRepository());
      await cubit.load();
      expect(cubit.state.isAuthenticated, isTrue);
      expect(cubit.state.availableUsers, isNotEmpty);
    });

    test('signOut clears the session; signIn restores it', () async {
      final cubit = SessionCubit(DemoRepository());
      await cubit.load();

      await cubit.signOut();
      expect(cubit.state.isAuthenticated, isFalse);
      expect(cubit.state.currentUser, isNull);

      await cubit.signIn(email: 'anything@demo', password: 'x');
      expect(cubit.state.isAuthenticated, isTrue);
      expect(cubit.state.authError, isNull);
    });

    test('signIn matches a seeded user by email', () async {
      final cubit = SessionCubit(DemoRepository());
      await cubit.load();
      await cubit.signOut();
      await cubit.signIn(email: 'gulflens.studio@gmail.com', password: 'x');
      expect(cubit.state.currentUser!.id, 'user-owner');
    });
  });
}
