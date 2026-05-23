import '../../core/models/operations.dart';
import '../../l10n/app_localizations.dart';

/// Bridges the Operations enums to the generated [L10n] getters.

extension AnnouncementCategoryLabel on AnnouncementCategory {
  String localized(L10n l) => switch (this) {
        AnnouncementCategory.general => l.annCatGeneral,
        AnnouncementCategory.event => l.annCatEvent,
        AnnouncementCategory.registration => l.annCatRegistration,
        AnnouncementCategory.grading => l.annCatGrading,
        AnnouncementCategory.tournament => l.annCatTournament,
        AnnouncementCategory.policy => l.annCatPolicy,
        AnnouncementCategory.recognition => l.annCatRecognition,
      };
}

extension CertificationKindLabel on CertificationKind {
  String localized(L10n l) => switch (this) {
        CertificationKind.firstAid => l.certKindFirstAid,
        CertificationKind.safeguarding => l.certKindSafeguarding,
        CertificationKind.wtCoaching => l.certKindWtCoaching,
        CertificationKind.doping => l.certKindDoping,
        CertificationKind.refereeing => l.certKindRefereeing,
      };
}

extension CertificationSeverityLabel on CertificationSeverity {
  String localized(L10n l) => switch (this) {
        CertificationSeverity.ok => l.certOk,
        CertificationSeverity.expiring => l.certExpiring,
        CertificationSeverity.expired => l.certExpired,
      };
}
