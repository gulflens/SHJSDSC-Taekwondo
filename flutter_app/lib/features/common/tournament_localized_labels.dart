import '../../core/models/match.dart' show MedalType;
import '../../core/models/tournament.dart';
import '../../l10n/app_localizations.dart';

/// Bridges the Tournament enums to the generated [L10n] getters.

extension EventLevelLabel on EventLevel {
  String localized(L10n l) => switch (this) {
        EventLevel.local => l.eventLevelLocal,
        EventLevel.national => l.eventLevelNational,
        EventLevel.regional => l.eventLevelRegional,
        EventLevel.international => l.eventLevelInternational,
      };
}

extension RegistrationStatusLabel on RegistrationStatus {
  String localized(L10n l) => switch (this) {
        RegistrationStatus.registered => l.regRegistered,
        RegistrationStatus.weighedIn => l.regWeighedIn,
        RegistrationStatus.withdrawn => l.regWithdrawn,
        RegistrationStatus.disqualified => l.regDisqualified,
      };
}

extension MedalTypeLabel on MedalType {
  /// Returns null for [MedalType.none] so the UI can hide the chip.
  String? localized(L10n l) => switch (this) {
        MedalType.gold => l.medalGold,
        MedalType.silver => l.medalSilver,
        MedalType.bronze => l.medalBronze,
        MedalType.none => null,
      };
}
