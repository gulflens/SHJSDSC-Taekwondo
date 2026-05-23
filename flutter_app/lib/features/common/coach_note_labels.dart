import '../../core/models/athlete_extras.dart';
import '../../l10n/app_localizations.dart';

/// Bridges `CoachNoteCategory` to the generated [L10n] getters.
extension CoachNoteCategoryLabel on CoachNoteCategory {
  String localized(L10n l) => switch (this) {
        CoachNoteCategory.technical => l.noteCatTechnical,
        CoachNoteCategory.tactical => l.noteCatTactical,
        CoachNoteCategory.behavioural => l.noteCatBehavioural,
        CoachNoteCategory.medical => l.noteCatMedical,
        CoachNoteCategory.mental => l.noteCatMental,
        CoachNoteCategory.general => l.noteCatGeneral,
      };
}
