import 'entity_id.dart';

/// Port of Core/Models/Branch/BranchMilestone.swift.

enum MilestoneCategory {
  founded,
  championshipWon,
  alumniAchievement,
  renovation,
  staffMilestone,
  recordSet,
  partnership;

  String get labelKey => 'milestone.$name';

  static MilestoneCategory fromJson(String raw) =>
      MilestoneCategory.values.firstWhere(
        (c) => c.name == raw,
        orElse: () => MilestoneCategory.founded,
      );
}

class BranchMilestone {
  final EntityID id;
  final EntityID branchId;
  final DateTime occurredAt;
  final String titleEn;
  final String titleAr;
  final String? descriptionEn;
  final String? descriptionAr;
  final MilestoneCategory category;

  const BranchMilestone({
    required this.id,
    required this.branchId,
    required this.occurredAt,
    required this.titleEn,
    required this.titleAr,
    this.descriptionEn,
    this.descriptionAr,
    required this.category,
  });

  factory BranchMilestone.fromJson(Map<String, dynamic> json) =>
      BranchMilestone(
        id: json['id'] as String,
        branchId: json['branchID'] as String,
        occurredAt: DateTime.parse(json['occurredAt'] as String),
        titleEn: json['titleEn'] as String,
        titleAr: json['titleAr'] as String,
        descriptionEn: json['descriptionEn'] as String?,
        descriptionAr: json['descriptionAr'] as String?,
        category: MilestoneCategory.fromJson(json['category'] as String),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'branchID': branchId,
    'occurredAt': occurredAt.toIso8601String(),
    'titleEn': titleEn,
    'titleAr': titleAr,
    'descriptionEn': descriptionEn,
    'descriptionAr': descriptionAr,
    'category': category.name,
  };
}
