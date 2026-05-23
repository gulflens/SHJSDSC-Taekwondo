import '../../core/models/athlete_extras.dart';
import '../../l10n/app_localizations.dart';

/// Bridges the athlete-document enums to the generated [L10n] getters.

extension AthleteDocumentKindLabel on AthleteDocumentKind {
  String localized(L10n l) => switch (this) {
        AthleteDocumentKind.emiratesID => l.docKindEmiratesID,
        AthleteDocumentKind.passport => l.docKindPassport,
        AthleteDocumentKind.federationLicence => l.docKindFederationLicence,
        AthleteDocumentKind.worldTaekwondoCard => l.docKindWorldTaekwondoCard,
        AthleteDocumentKind.medicalClearance => l.docKindMedicalClearance,
        AthleteDocumentKind.imageRightsConsent => l.docKindImageRightsConsent,
        AthleteDocumentKind.travelPermission => l.docKindTravelPermission,
        AthleteDocumentKind.schoolID => l.docKindSchoolID,
        AthleteDocumentKind.other => l.docKindOther,
      };
}

extension AthleteDocumentStatusLabel on AthleteDocumentStatus {
  String localized(L10n l) => switch (this) {
        AthleteDocumentStatus.valid => l.docStatusValid,
        AthleteDocumentStatus.expiringSoon => l.docStatusExpiring,
        AthleteDocumentStatus.expired => l.docStatusExpired,
        AthleteDocumentStatus.missing => l.docStatusMissing,
        AthleteDocumentStatus.pending => l.docStatusPending,
      };
}
