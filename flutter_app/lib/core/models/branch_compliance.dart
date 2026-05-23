import 'entity_id.dart';

/// Port of Core/Models/Branch/BranchCompliance.swift.

enum ComplianceStatus {
  ok,
  expiring,
  expired;

  String get labelKey => 'compliance.$name';

  static ComplianceStatus fromJson(String raw) => ComplianceStatus.values
      .firstWhere((s) => s.name == raw, orElse: () => ComplianceStatus.ok);
}

class BranchCompliance {
  final EntityID id;
  final EntityID branchId;
  final String? civilDefenceCertNumber;
  final DateTime? civilDefenceExpiry;
  final String? sharjahSportsCouncilRegNumber;
  final DateTime? sharjahSportsCouncilExpiry;
  final String? insurancePolicyNumber;
  final String? insuranceProvider;
  final DateTime? insuranceExpiry;
  final DateTime? lastHealthSafetyInspectionAt;
  final DateTime? lastEmergencyPlanReviewAt;
  final bool hasAed;
  final DateTime? aedLastServiceAt;
  final DateTime? firstAidKitLastCheckedAt;

  const BranchCompliance({
    required this.id,
    required this.branchId,
    this.civilDefenceCertNumber,
    this.civilDefenceExpiry,
    this.sharjahSportsCouncilRegNumber,
    this.sharjahSportsCouncilExpiry,
    this.insurancePolicyNumber,
    this.insuranceProvider,
    this.insuranceExpiry,
    this.lastHealthSafetyInspectionAt,
    this.lastEmergencyPlanReviewAt,
    this.hasAed = false,
    this.aedLastServiceAt,
    this.firstAidKitLastCheckedAt,
  });

  /// Aggregated severity across all tracked expiries. Any expired/missing
  /// required cert dominates "expiring", which dominates "ok".
  ComplianceStatus status({DateTime? now}) {
    final checkNow = now ?? DateTime.now();
    final required = [
      civilDefenceExpiry,
      sharjahSportsCouncilExpiry,
      insuranceExpiry,
    ];
    var anyExpired = false;
    var anyExpiring = false;
    for (final date in required) {
      if (date == null) {
        anyExpired = true;
        continue;
      }
      final days = date.difference(checkNow).inDays;
      if (days < 0) {
        anyExpired = true;
      } else if (days <= 30) {
        anyExpiring = true;
      }
    }
    if (anyExpired) return ComplianceStatus.expired;
    if (anyExpiring) return ComplianceStatus.expiring;
    return ComplianceStatus.ok;
  }

  factory BranchCompliance.fromJson(Map<String, dynamic> json) =>
      BranchCompliance(
        id: json['id'] as String,
        branchId: json['branchID'] as String,
        civilDefenceCertNumber: json['civilDefenceCertNumber'] as String?,
        civilDefenceExpiry: json['civilDefenceExpiry'] == null
            ? null
            : DateTime.parse(json['civilDefenceExpiry'] as String),
        sharjahSportsCouncilRegNumber:
            json['sharjahSportsCouncilRegNumber'] as String?,
        sharjahSportsCouncilExpiry: json['sharjahSportsCouncilExpiry'] == null
            ? null
            : DateTime.parse(json['sharjahSportsCouncilExpiry'] as String),
        insurancePolicyNumber: json['insurancePolicyNumber'] as String?,
        insuranceProvider: json['insuranceProvider'] as String?,
        insuranceExpiry: json['insuranceExpiry'] == null
            ? null
            : DateTime.parse(json['insuranceExpiry'] as String),
        lastHealthSafetyInspectionAt:
            json['lastHealthSafetyInspectionAt'] == null
            ? null
            : DateTime.parse(json['lastHealthSafetyInspectionAt'] as String),
        lastEmergencyPlanReviewAt: json['lastEmergencyPlanReviewAt'] == null
            ? null
            : DateTime.parse(json['lastEmergencyPlanReviewAt'] as String),
        hasAed: json['hasAED'] as bool? ?? false,
        aedLastServiceAt: json['aedLastServiceAt'] == null
            ? null
            : DateTime.parse(json['aedLastServiceAt'] as String),
        firstAidKitLastCheckedAt: json['firstAidKitLastCheckedAt'] == null
            ? null
            : DateTime.parse(json['firstAidKitLastCheckedAt'] as String),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'branchID': branchId,
    'civilDefenceCertNumber': civilDefenceCertNumber,
    'civilDefenceExpiry': civilDefenceExpiry?.toIso8601String(),
    'sharjahSportsCouncilRegNumber': sharjahSportsCouncilRegNumber,
    'sharjahSportsCouncilExpiry': sharjahSportsCouncilExpiry?.toIso8601String(),
    'insurancePolicyNumber': insurancePolicyNumber,
    'insuranceProvider': insuranceProvider,
    'insuranceExpiry': insuranceExpiry?.toIso8601String(),
    'lastHealthSafetyInspectionAt': lastHealthSafetyInspectionAt
        ?.toIso8601String(),
    'lastEmergencyPlanReviewAt': lastEmergencyPlanReviewAt?.toIso8601String(),
    'hasAED': hasAed,
    'aedLastServiceAt': aedLastServiceAt?.toIso8601String(),
    'firstAidKitLastCheckedAt': firstAidKitLastCheckedAt?.toIso8601String(),
  };
}
