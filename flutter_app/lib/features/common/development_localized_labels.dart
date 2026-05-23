import '../../core/models/coaching_development.dart';
import '../../l10n/app_localizations.dart';

/// Bridges `DevelopmentLevel` to the generated [L10n] getters.
extension DevelopmentLevelLabel on DevelopmentLevel {
  String localized(L10n l) => switch (this) {
        DevelopmentLevel.athlete => l.devLevelAthlete,
        DevelopmentLevel.assistantCoach => l.devLevelAssistantCoach,
        DevelopmentLevel.juniorCoach => l.devLevelJuniorCoach,
        DevelopmentLevel.coach => l.devLevelCoach,
        DevelopmentLevel.headCoach => l.devLevelHeadCoach,
        DevelopmentLevel.technicalDirector => l.devLevelTechnicalDirector,
      };
}
