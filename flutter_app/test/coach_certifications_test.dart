import 'package:flutter_test/flutter_test.dart';
import 'package:shjsdsc/core/models/operations.dart';
import 'package:shjsdsc/core/repository/demo_repository.dart';

void main() {
  test('certificationsForCoach returns the coach\'s certs with a severity mix', () async {
    final repo = DemoRepository();
    final certs = await repo.certificationsForCoach('coach-yassin');
    expect(certs.length, 3);
    expect(certs.every((c) => c.coachId == 'coach-yassin'), isTrue);
    final severities = certs.map((c) => c.severity).toSet();
    expect(severities, contains(CertificationSeverity.expired));
    expect(severities, contains(CertificationSeverity.expiring));
  });
}
