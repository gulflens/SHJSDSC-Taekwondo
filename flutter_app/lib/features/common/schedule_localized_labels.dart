import '../../core/models/schedule.dart';
import '../../l10n/app_localizations.dart';

/// Bridges `ClassDiscipline` + `AttendanceState` to the generated [L10n]
/// getters — keeps the `Core/` enums UI-free.

extension ClassDisciplineLabel on ClassDiscipline {
  String localized(L10n l) => switch (this) {
        ClassDiscipline.poomsae => l.disciplinePoomsae,
        ClassDiscipline.kyorugi => l.disciplineKyorugi,
        ClassDiscipline.fundamentals => l.disciplineFundamentals,
        ClassDiscipline.competition => l.disciplineCompetition,
        ClassDiscipline.fitness => l.disciplineFitness,
      };
}

extension AttendanceStateLabel on AttendanceState {
  String localized(L10n l) => switch (this) {
        AttendanceState.present => l.attendancePresent,
        AttendanceState.late => l.attendanceLate,
        AttendanceState.absent => l.attendanceAbsent,
        AttendanceState.excused => l.attendanceExcused,
      };
}
