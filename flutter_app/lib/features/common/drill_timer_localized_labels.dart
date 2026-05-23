import '../../core/models/drill_timer.dart';
import '../../l10n/app_localizations.dart';

/// Bridges `DrillTimerPhase` to the generated [L10n] getters.
extension DrillTimerPhaseLabel on DrillTimerPhase {
  String localized(L10n l) => switch (this) {
        DrillTimerPhase.prepare => l.phasePrepare,
        DrillTimerPhase.work => l.phaseWork,
        DrillTimerPhase.rest => l.phaseRest,
        DrillTimerPhase.roundBreak => l.phaseRoundBreak,
        DrillTimerPhase.finished => l.phaseFinished,
      };
}
