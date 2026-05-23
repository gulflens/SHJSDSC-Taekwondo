import '../../core/models/athlete_profile.dart';
import '../../l10n/app_localizations.dart';

/// Bridges `InjurySeverity` to the generated [L10n] getters.
extension InjurySeverityLabel on InjurySeverity {
  String localized(L10n l) => switch (this) {
        InjurySeverity.minor => l.injuryMinor,
        InjurySeverity.moderate => l.injuryModerate,
        InjurySeverity.severe => l.injurySevere,
      };
}
