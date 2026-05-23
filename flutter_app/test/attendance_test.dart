import 'package:flutter_test/flutter_test.dart';
import 'package:shjsdsc/core/blocs/branch_profile_cubit.dart';
import 'package:shjsdsc/core/models/schedule.dart';
import 'package:shjsdsc/core/repository/demo_repository.dart';

void main() {
  final since = DateTime.now().subtract(const Duration(days: 90));

  test('attendanceForAthlete returns the seeded history (present-majority)', () async {
    final repo = DemoRepository();
    final records = await repo.attendanceForAthlete('ath-1', since);
    expect(records, isNotEmpty);
    final present = records
        .where((r) =>
            r.state == AttendanceState.present || r.state == AttendanceState.late)
        .length;
    // Seed weights ~80% present/late.
    expect(present / records.length, greaterThan(0.6));
  });

  test('seeded attendance lights up branch operations metrics', () async {
    final repo = DemoRepository();
    final cubit = BranchProfileCubit(repo);
    await cubit.load('branch-rahmania');
    expect(cubit.state.status, BranchProfileStatus.ready);
    // Previously 0 with no attendance seeded — now non-zero.
    expect(cubit.state.metrics.avgAttendancePct, greaterThan(0));
  });
}
