import 'athlete.dart' show AgeGroup;
import 'branch_hours.dart' show DayOfWeek;
import 'entity_id.dart';
import 'schedule.dart' show ClassDiscipline;

/// Port of Core/Models/Branch/BranchProgram.swift.
///
/// External references:
///   - `AgeGroup` — imported from athlete.dart.
///   - `DayOfWeek` — imported from branch_hours.dart.
///   - `ClassDiscipline` — imported from schedule.dart (authoritative).

class BranchProgram {
  final EntityID id;
  final EntityID branchId;
  final String? nameKey;
  final String? customName;
  final String? customNameAr;
  final String descriptionEn;
  final String descriptionAr;
  final AgeGroup ageGroup;
  final List<ClassDiscipline> disciplines;
  final List<DayOfWeek> schedulePattern;
  final String startTime;
  final String endTime;
  final int capacity;
  final int currentEnrolment;
  final double monthlyFeeAed;
  final double? trialClassFeeAed;
  final double? registrationFeeAed;
  final double? equipmentPackageFeeAed;
  final double? siblingDiscountPct;
  final double? annualPrepayDiscountPct;
  final bool isActive;
  final bool isWomenOnly;

  const BranchProgram({
    required this.id,
    required this.branchId,
    this.nameKey,
    this.customName,
    this.customNameAr,
    required this.descriptionEn,
    required this.descriptionAr,
    required this.ageGroup,
    required this.disciplines,
    required this.schedulePattern,
    required this.startTime,
    required this.endTime,
    required this.capacity,
    this.currentEnrolment = 0,
    required this.monthlyFeeAed,
    this.trialClassFeeAed,
    this.registrationFeeAed,
    this.equipmentPackageFeeAed,
    this.siblingDiscountPct,
    this.annualPrepayDiscountPct,
    this.isActive = true,
    this.isWomenOnly = false,
  });

  factory BranchProgram.fromJson(Map<String, dynamic> json) => BranchProgram(
    id: json['id'] as String,
    branchId: json['branchID'] as String,
    nameKey: json['nameKey'] as String?,
    customName: json['customName'] as String?,
    customNameAr: json['customNameAr'] as String?,
    descriptionEn: json['descriptionEn'] as String,
    descriptionAr: json['descriptionAr'] as String,
    ageGroup: AgeGroup.values.firstWhere(
      (a) => a.name == (json['ageGroup'] as String? ?? ''),
      orElse: () => AgeGroup.seniors,
    ),
    disciplines: ((json['disciplines'] as List?) ?? [])
        .map((e) => ClassDiscipline.fromJson(e as String))
        .toList(),
    schedulePattern: ((json['schedulePattern'] as List?) ?? [])
        .map((e) => DayOfWeek.fromJson(e as int))
        .toList(),
    startTime: json['startTime'] as String,
    endTime: json['endTime'] as String,
    capacity: json['capacity'] as int,
    currentEnrolment: json['currentEnrolment'] as int? ?? 0,
    monthlyFeeAed: (json['monthlyFeeAED'] as num).toDouble(),
    trialClassFeeAed: (json['trialClassFeeAED'] as num?)?.toDouble(),
    registrationFeeAed: (json['registrationFeeAED'] as num?)?.toDouble(),
    equipmentPackageFeeAed: (json['equipmentPackageFeeAED'] as num?)
        ?.toDouble(),
    siblingDiscountPct: (json['siblingDiscountPct'] as num?)?.toDouble(),
    annualPrepayDiscountPct: (json['annualPrepayDiscountPct'] as num?)
        ?.toDouble(),
    isActive: json['isActive'] as bool? ?? true,
    isWomenOnly: json['isWomenOnly'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'branchID': branchId,
    'nameKey': nameKey,
    'customName': customName,
    'customNameAr': customNameAr,
    'descriptionEn': descriptionEn,
    'descriptionAr': descriptionAr,
    'ageGroup': ageGroup.name,
    'disciplines': disciplines.map((d) => d.name).toList(),
    'schedulePattern': schedulePattern.map((d) => d.rawValue).toList(),
    'startTime': startTime,
    'endTime': endTime,
    'capacity': capacity,
    'currentEnrolment': currentEnrolment,
    'monthlyFeeAED': monthlyFeeAed,
    'trialClassFeeAED': trialClassFeeAed,
    'registrationFeeAED': registrationFeeAed,
    'equipmentPackageFeeAED': equipmentPackageFeeAed,
    'siblingDiscountPct': siblingDiscountPct,
    'annualPrepayDiscountPct': annualPrepayDiscountPct,
    'isActive': isActive,
    'isWomenOnly': isWomenOnly,
  };
}
