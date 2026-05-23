import 'entity_id.dart';

/// Port of Core/Models/Branch/BranchFinancials.swift.

class BranchFinancials {
  final EntityID id;
  final EntityID branchId;

  /// First day of the calendar month this record covers.
  final DateTime month;
  final double revenueAed;
  final double rentAed;
  final double utilitiesAed;
  final double staffCostAed;
  final double equipmentAed;
  final double marketingAed;
  final double otherExpensesAed;
  final double outstandingFeesAed;
  final int activePaymentPlans;

  const BranchFinancials({
    required this.id,
    required this.branchId,
    required this.month,
    required this.revenueAed,
    required this.rentAed,
    required this.utilitiesAed,
    required this.staffCostAed,
    required this.equipmentAed,
    required this.marketingAed,
    required this.otherExpensesAed,
    this.outstandingFeesAed = 0,
    this.activePaymentPlans = 0,
  });

  double get totalExpensesAed =>
      rentAed +
      utilitiesAed +
      staffCostAed +
      equipmentAed +
      marketingAed +
      otherExpensesAed;

  double get netContributionAed => revenueAed - totalExpensesAed;

  factory BranchFinancials.fromJson(Map<String, dynamic> json) =>
      BranchFinancials(
        id: json['id'] as String,
        branchId: json['branchID'] as String,
        month: DateTime.parse(json['month'] as String),
        revenueAed: (json['revenueAED'] as num).toDouble(),
        rentAed: (json['rentAED'] as num).toDouble(),
        utilitiesAed: (json['utilitiesAED'] as num).toDouble(),
        staffCostAed: (json['staffCostAED'] as num).toDouble(),
        equipmentAed: (json['equipmentAED'] as num).toDouble(),
        marketingAed: (json['marketingAED'] as num).toDouble(),
        otherExpensesAed: (json['otherExpensesAED'] as num).toDouble(),
        outstandingFeesAed:
            (json['outstandingFeesAED'] as num?)?.toDouble() ?? 0,
        activePaymentPlans: json['activePaymentPlans'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'branchID': branchId,
    'month': month.toIso8601String(),
    'revenueAED': revenueAed,
    'rentAED': rentAed,
    'utilitiesAED': utilitiesAed,
    'staffCostAED': staffCostAed,
    'equipmentAED': equipmentAed,
    'marketingAED': marketingAed,
    'otherExpensesAED': otherExpensesAed,
    'outstandingFeesAED': outstandingFeesAed,
    'activePaymentPlans': activePaymentPlans,
  };
}
