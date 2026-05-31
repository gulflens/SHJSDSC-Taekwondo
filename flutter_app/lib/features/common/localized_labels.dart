import '../../core/models/athlete.dart';
import '../../core/models/belt.dart';
import '../../l10n/app_localizations.dart';

/// Bridges the `labelKey` strings the `Core/` models expose to the generated
/// [L10n] getters. The models stay UI-free (they only know key strings); this
/// view-layer extension resolves them — mirroring how the Swift views call
/// `Text(localizedKey:)` on `status.labelKey`.

extension AthleteStatusLabel on AthleteStatus {
  String localized(L10n l) => switch (this) {
        AthleteStatus.competitionTeam => l.statusCompetitionTeam,
        AthleteStatus.readyToGrade => l.statusReadyToGrade,
        AthleteStatus.watch => l.statusWatch,
        AthleteStatus.rest => l.statusRest,
        AthleteStatus.active => l.statusActive,
      };
}

extension BeltColorLabel on BeltColor {
  String localized(L10n l) => switch (this) {
        BeltColor.white => l.beltWhite,
        BeltColor.yellow => l.beltYellow,
        BeltColor.green => l.beltGreen,
        BeltColor.blue => l.beltBlue,
        BeltColor.red => l.beltRed,
        BeltColor.black => l.beltBlack,
      };
}

extension AgeGroupLabel on AgeGroup {
  String localized(L10n l) => switch (this) {
        AgeGroup.cubs => l.ageCubs,
        AgeGroup.kids => l.ageKids,
        AgeGroup.cadets => l.ageCadets,
        AgeGroup.juniors => l.ageJuniors,
        AgeGroup.seniors => l.ageSeniors,
        AgeGroup.masters => l.ageMasters,
      };
}
