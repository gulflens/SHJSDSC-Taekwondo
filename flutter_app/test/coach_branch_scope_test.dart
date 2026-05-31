import 'package:flutter_test/flutter_test.dart';
import 'package:shjsdsc/core/repository/demo_repository.dart';
import 'package:shjsdsc/features/coaches/coach_list_cubit.dart';

void main() {
  test('CoachListCubit branchScope loads only that branch\'s coaches', () async {
    final repo = DemoRepository();
    final scoped = CoachListCubit(repo, branchScope: 'branch-rahmania');
    await scoped.load();
    expect(scoped.state.all, isNotEmpty);
    expect(
      scoped.state.all.every((i) => i.coach.primaryBranchId == 'branch-rahmania'),
      isTrue,
    );

    final all = CoachListCubit(repo);
    await all.load();
    expect(scoped.state.all.length, lessThan(all.state.all.length),
        reason: 'scoped roster is a subset of the full roster');
  });
}
