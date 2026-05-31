import 'entity_id.dart';

/// Port of Core/Models/Branch/BranchPricing.swift.

class Promotion {
  final EntityID id;
  final String titleEn;
  final String titleAr;
  final String descriptionEn;
  final String descriptionAr;
  final double? discountPct;
  final double? discountAed;
  final DateTime validFrom;
  final DateTime validUntil;
  final String? promoCode;

  const Promotion({
    required this.id,
    required this.titleEn,
    required this.titleAr,
    required this.descriptionEn,
    required this.descriptionAr,
    this.discountPct,
    this.discountAed,
    required this.validFrom,
    required this.validUntil,
    this.promoCode,
  });

  factory Promotion.fromJson(Map<String, dynamic> json) => Promotion(
    id: json['id'] as String,
    titleEn: json['titleEn'] as String,
    titleAr: json['titleAr'] as String,
    descriptionEn: json['descriptionEn'] as String,
    descriptionAr: json['descriptionAr'] as String,
    discountPct: (json['discountPct'] as num?)?.toDouble(),
    discountAed: (json['discountAED'] as num?)?.toDouble(),
    validFrom: DateTime.parse(json['validFrom'] as String),
    validUntil: DateTime.parse(json['validUntil'] as String),
    promoCode: json['promoCode'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'titleEn': titleEn,
    'titleAr': titleAr,
    'descriptionEn': descriptionEn,
    'descriptionAr': descriptionAr,
    'discountPct': discountPct,
    'discountAED': discountAed,
    'validFrom': validFrom.toIso8601String(),
    'validUntil': validUntil.toIso8601String(),
    'promoCode': promoCode,
  };
}

class BranchPricing {
  final EntityID id;
  final EntityID branchId;
  final double baseMonthlyFeeAed;
  final double trialClassFeeAed;
  final double registrationFeeAed;
  final double equipmentPackageFeeAed;
  final double siblingDiscountPct;
  final double annualPrepayDiscountPct;
  final List<Promotion> promotions;
  final DateTime effectiveFrom;

  const BranchPricing({
    required this.id,
    required this.branchId,
    required this.baseMonthlyFeeAed,
    required this.trialClassFeeAed,
    required this.registrationFeeAed,
    required this.equipmentPackageFeeAed,
    this.siblingDiscountPct = 0,
    this.annualPrepayDiscountPct = 0,
    this.promotions = const [],
    required this.effectiveFrom,
  });

  factory BranchPricing.fromJson(Map<String, dynamic> json) => BranchPricing(
    id: json['id'] as String,
    branchId: json['branchID'] as String,
    baseMonthlyFeeAed: (json['baseMonthlyFeeAED'] as num).toDouble(),
    trialClassFeeAed: (json['trialClassFeeAED'] as num).toDouble(),
    registrationFeeAed: (json['registrationFeeAED'] as num).toDouble(),
    equipmentPackageFeeAed: (json['equipmentPackageFeeAED'] as num).toDouble(),
    siblingDiscountPct: (json['siblingDiscountPct'] as num?)?.toDouble() ?? 0,
    annualPrepayDiscountPct:
        (json['annualPrepayDiscountPct'] as num?)?.toDouble() ?? 0,
    promotions: ((json['promotions'] as List?) ?? [])
        .map((e) => Promotion.fromJson(e as Map<String, dynamic>))
        .toList(),
    effectiveFrom: DateTime.parse(json['effectiveFrom'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'branchID': branchId,
    'baseMonthlyFeeAED': baseMonthlyFeeAed,
    'trialClassFeeAED': trialClassFeeAed,
    'registrationFeeAED': registrationFeeAed,
    'equipmentPackageFeeAED': equipmentPackageFeeAed,
    'siblingDiscountPct': siblingDiscountPct,
    'annualPrepayDiscountPct': annualPrepayDiscountPct,
    'promotions': promotions.map((p) => p.toJson()).toList(),
    'effectiveFrom': effectiveFrom.toIso8601String(),
  };
}
