import '../../core/models/branch.dart';
import '../../l10n/app_localizations.dart';

/// Bridges `BranchOperationalStatus` to the generated [L10n] getters — the
/// branch counterpart of `localized_labels.dart`. Keeps the `Core/` enum
/// UI-free.
extension BranchOperationalStatusLabel on BranchOperationalStatus {
  String localized(L10n l) => switch (this) {
        BranchOperationalStatus.active => l.branchStatusActive,
        BranchOperationalStatus.maintenance => l.branchStatusMaintenance,
        BranchOperationalStatus.tournamentMode => l.branchStatusTournamentMode,
        BranchOperationalStatus.closed => l.branchStatusClosed,
      };
}
