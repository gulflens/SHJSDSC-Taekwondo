import 'entity_id.dart';

/// Port of Core/Models/Branch/BranchSafeguarding.swift.

class BranchSafeguarding {
  final EntityID id;
  final EntityID branchId;
  final EntityID? safeguardingOfficerCoachId;
  final DateTime? lastTeamTrainingAt;
  final String? policyDocumentUrl;

  /// 0..1, snapshot of staff safeguarding-cert validity.
  final double staffCheckCurrentPct;
  final int openIncidentCount;
  final DateTime? lastIncidentAt;

  const BranchSafeguarding({
    required this.id,
    required this.branchId,
    this.safeguardingOfficerCoachId,
    this.lastTeamTrainingAt,
    this.policyDocumentUrl,
    this.staffCheckCurrentPct = 0,
    this.openIncidentCount = 0,
    this.lastIncidentAt,
  });

  factory BranchSafeguarding.fromJson(Map<String, dynamic> json) =>
      BranchSafeguarding(
        id: json['id'] as String,
        branchId: json['branchID'] as String,
        safeguardingOfficerCoachId:
            json['safeguardingOfficerCoachID'] as String?,
        lastTeamTrainingAt: json['lastTeamTrainingAt'] == null
            ? null
            : DateTime.parse(json['lastTeamTrainingAt'] as String),
        policyDocumentUrl: json['policyDocumentURL'] as String?,
        staffCheckCurrentPct:
            (json['staffCheckCurrentPct'] as num?)?.toDouble() ?? 0,
        openIncidentCount: json['openIncidentCount'] as int? ?? 0,
        lastIncidentAt: json['lastIncidentAt'] == null
            ? null
            : DateTime.parse(json['lastIncidentAt'] as String),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'branchID': branchId,
    'safeguardingOfficerCoachID': safeguardingOfficerCoachId,
    'lastTeamTrainingAt': lastTeamTrainingAt?.toIso8601String(),
    'policyDocumentURL': policyDocumentUrl,
    'staffCheckCurrentPct': staffCheckCurrentPct,
    'openIncidentCount': openIncidentCount,
    'lastIncidentAt': lastIncidentAt?.toIso8601String(),
  };
}
