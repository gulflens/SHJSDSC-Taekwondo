import 'package:flutter_test/flutter_test.dart';
import 'package:shjsdsc/core/models/role.dart';

void main() {
  group('Role.experience (drives role-aware routing)', () {
    test('every role maps to exactly one experience', () {
      for (final r in Role.values) {
        expect(() => r.experience, returnsNormally);
      }
    });

    test('representative role → experience mappings match the Swift router', () {
      expect(Role.developer.experience, RoleExperience.developer);
      expect(Role.admin.experience, RoleExperience.admin);
      expect(Role.itSupport.experience, RoleExperience.admin);
      expect(Role.technicalDirector.experience, RoleExperience.technicalDirector);
      expect(Role.gradingExaminer.experience, RoleExperience.technicalDirector);
      expect(Role.branchManager.experience, RoleExperience.branchManager);
      expect(Role.coach.experience, RoleExperience.coach);
      expect(Role.physiotherapist.experience, RoleExperience.coach);
      expect(Role.analyst.experience, RoleExperience.analyst);
      expect(Role.athlete.experience, RoleExperience.athlete);
      expect(Role.alumni.experience, RoleExperience.athlete);
      expect(Role.parent.experience, RoleExperience.parent);
    });
  });
}
