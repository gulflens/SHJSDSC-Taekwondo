import 'package:flutter_test/flutter_test.dart';
import 'package:shjsdsc/core/blocs/session_cubit.dart';
import 'package:shjsdsc/core/models/role.dart';
import 'package:shjsdsc/core/repository/demo_repository.dart';

void main() {
  test('signUp creates a parent account and signs in', () async {
    final repo = DemoRepository();
    final cubit = SessionCubit(repo);
    await cubit.load();
    await cubit.signOut();
    expect(cubit.state.isAuthenticated, isFalse);

    await cubit.signUp(
      fullName: 'New Parent',
      email: 'new.parent@demo',
      password: 'secret',
    );

    expect(cubit.state.isAuthenticated, isTrue);
    expect(cubit.state.currentUser!.fullName, 'New Parent');
    expect(cubit.state.currentUser!.role, Role.parent);
    expect(cubit.state.authError, isNull);

    // The new account is now among the available users.
    expect(
      (await repo.availableUsers()).any((u) => u.email == 'new.parent@demo'),
      isTrue,
    );
  });
}
