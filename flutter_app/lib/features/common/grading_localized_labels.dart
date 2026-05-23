import '../../core/models/grading.dart';
import '../../l10n/app_localizations.dart';

/// Bridges `GradingSessionStatus` to the generated [L10n] getters.
extension GradingSessionStatusLabel on GradingSessionStatus {
  String localized(L10n l) => switch (this) {
        GradingSessionStatus.scheduled => l.gradingStatusScheduled,
        GradingSessionStatus.inProgress => l.gradingStatusInProgress,
        GradingSessionStatus.completed => l.gradingStatusCompleted,
        GradingSessionStatus.cancelled => l.gradingStatusCancelled,
      };
}
