import 'package:flutter_test/flutter_test.dart';
import 'package:shjsdsc/core/blocs/audit_cubit.dart';
import 'package:shjsdsc/core/blocs/certifications_cubit.dart';
import 'package:shjsdsc/core/blocs/operations_cubit.dart';
import 'package:shjsdsc/core/models/operations.dart';
import 'package:shjsdsc/core/repository/demo_repository.dart';

void main() {
  group('Operations cubits', () {
    test('OperationsCubit loads seeded announcements', () async {
      final cubit = OperationsCubit(DemoRepository());
      await cubit.load();
      expect(cubit.state.status, OperationsStatus.ready);
      expect(cubit.state.announcements.length, 4);
    });

    test('CertificationsCubit surfaces severity buckets', () async {
      final cubit = CertificationsCubit(DemoRepository());
      await cubit.loadAll();
      expect(cubit.state.status, CertificationsStatus.ready);
      final certs = cubit.state.certifications;
      expect(certs.length, 8);
      final expired = certs
          .where((c) => c.severity == CertificationSeverity.expired)
          .length;
      final expiring = certs
          .where((c) => c.severity == CertificationSeverity.expiring)
          .length;
      expect(expired, greaterThanOrEqualTo(2));
      expect(expiring, greaterThanOrEqualTo(2));
    });

    test('AuditCubit loads entries and resolves actor users', () async {
      final cubit = AuditCubit(DemoRepository());
      await cubit.load();
      expect(cubit.state.status, AuditStatus.ready);
      expect(cubit.state.entries, isNotEmpty);
      // Every entry's actor is resolvable for display.
      for (final e in cubit.state.entries) {
        expect(cubit.state.userLookup.containsKey(e.actorUserId), isTrue);
      }
    });
  });
}
