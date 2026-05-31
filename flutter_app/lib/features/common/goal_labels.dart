import '../../core/models/goal.dart';
import '../../l10n/app_localizations.dart';

/// Bridges `GoalStatus` to the generated [L10n] getters.
extension GoalStatusLabel on GoalStatus {
  String localized(L10n l) => switch (this) {
        GoalStatus.active => l.goalActive,
        GoalStatus.completed => l.goalCompleted,
        GoalStatus.abandoned => l.goalAbandoned,
      };
}
