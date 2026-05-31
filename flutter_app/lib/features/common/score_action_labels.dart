import '../../core/models/match.dart' show ScoreAction;
import '../../l10n/app_localizations.dart';

/// Bridges `ScoreAction` to the generated [L10n] getters.
extension ScoreActionLabel on ScoreAction {
  String localized(L10n l) => switch (this) {
        ScoreAction.headKick => l.scoreHeadKick,
        ScoreAction.bodyKick => l.scoreBodyKick,
        ScoreAction.turnBodyKick => l.scoreTurnBodyKick,
        ScoreAction.turnHeadKick => l.scoreTurnHeadKick,
        ScoreAction.punch => l.scorePunch,
        ScoreAction.penalty => l.scorePenalty,
      };
}
