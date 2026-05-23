import '../../core/models/coach_extras.dart';
import '../../l10n/app_localizations.dart';

/// Bridges the coach-dossier enums to the generated [L10n] getters — the coach
/// counterpart of `localized_labels.dart`. Keeps the `Core/` enums UI-free.

extension CoachLevelLabel on CoachLevel {
  String localized(L10n l) => switch (this) {
        CoachLevel.assistant => l.coachLevelAssistant,
        CoachLevel.junior => l.coachLevelJunior,
        CoachLevel.senior => l.coachLevelSenior,
        CoachLevel.head => l.coachLevelHead,
        CoachLevel.national => l.coachLevelNational,
        CoachLevel.international => l.coachLevelInternational,
      };
}

extension CoachEmploymentStatusLabel on CoachEmploymentStatus {
  String localized(L10n l) => switch (this) {
        CoachEmploymentStatus.active => l.coachEmpActive,
        CoachEmploymentStatus.leave => l.coachEmpLeave,
        CoachEmploymentStatus.transferred => l.coachEmpTransferred,
        CoachEmploymentStatus.retired => l.coachEmpRetired,
        CoachEmploymentStatus.suspended => l.coachEmpSuspended,
      };
}
