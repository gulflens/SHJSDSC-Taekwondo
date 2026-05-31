import 'branch_compliance.dart';
import 'branch_facility.dart';
import 'branch_financials.dart';
import 'branch_hours.dart';
import 'branch_inventory.dart';
import 'branch_media.dart';
import 'branch_milestone.dart';
import 'branch_pricing.dart';
import 'branch_program.dart';
import 'branch_safeguarding.dart';
import 'branch_social_links.dart';
import 'entity_id.dart';

/// Port of `BranchOperationalStatus` and `Branch` from
/// Core/Models/CoreEntities.swift (lines ~209-309), plus embedded Branch
/// dossier sub-types from Core/Models/Branch/*.swift.

/// Operational status of a branch. More granular than `isActive` —
/// surfaces maintenance windows and tournament-mode lockdowns at-a-glance.
enum BranchOperationalStatus {
  active,
  maintenance,
  tournamentMode,
  closed;

  String get labelKey => 'branch.status.$name';

  static BranchOperationalStatus fromJson(String raw) =>
      BranchOperationalStatus.values.firstWhere(
        (s) => s.name == raw,
        orElse: () => BranchOperationalStatus.active,
      );
}

class Branch {
  final EntityID id;
  final String code;
  final String name;
  final String nameAr;
  final String area;

  /// Max registered athletes the dojang is sized for.
  final int capacity;
  final EntityID? managerId;
  final String focus;

  // === Identity / contact ===
  final String streetAddress;
  final String streetAddressAr;
  final String emirate;
  final String country;
  final String? poBox;
  final double latitude;
  final double longitude;
  final String? googlePlaceId;
  final String phone;
  final String? whatsappBusiness;
  final String email;
  final DateTime foundedAt;
  final bool isActive;
  final String? brandHexColor;
  final String? taglineEn;
  final String? taglineAr;

  // === Operational hierarchy ===
  /// True for the federation's head branch. Exactly one branch should be main.
  final bool isMain;

  /// Day-to-day operational state. Distinct from [isActive] (hard on/off).
  final BranchOperationalStatus operationalStatus;

  // === Embedded dossier sub-types (nullable; loaded lazily / separately) ===
  final BranchCompliance? compliance;
  final BranchFacility? facility;
  final BranchFinancials? financials;
  final BranchHours? hours;
  final BranchInventory? inventory;
  final BranchMedia? media;
  final List<BranchMilestone> milestones;
  final BranchPricing? pricing;
  final List<BranchProgram> programs;
  final BranchSafeguarding? safeguarding;
  final BranchSocialLinks? socialLinks;

  const Branch({
    required this.id,
    required this.code,
    required this.name,
    required this.nameAr,
    required this.area,
    required this.capacity,
    this.managerId,
    required this.focus,
    this.streetAddress = '',
    this.streetAddressAr = '',
    this.emirate = 'Sharjah',
    this.country = 'AE',
    this.poBox,
    this.latitude = 0,
    this.longitude = 0,
    this.googlePlaceId,
    this.phone = '',
    this.whatsappBusiness,
    this.email = '',
    required this.foundedAt,
    this.isActive = true,
    this.brandHexColor,
    this.taglineEn,
    this.taglineAr,
    this.isMain = false,
    this.operationalStatus = BranchOperationalStatus.active,
    this.compliance,
    this.facility,
    this.financials,
    this.hours,
    this.inventory,
    this.media,
    this.milestones = const [],
    this.pricing,
    this.programs = const [],
    this.safeguarding,
    this.socialLinks,
  });

  factory Branch.fromJson(Map<String, dynamic> json) => Branch(
    id: json['id'] as String,
    code: json['code'] as String? ?? '',
    name: json['name'] as String,
    nameAr: json['nameAr'] as String,
    area: json['area'] as String? ?? '',
    capacity: json['capacity'] as int? ?? 0,
    managerId: json['managerID'] as String?,
    focus: json['focus'] as String? ?? '',
    streetAddress: json['streetAddress'] as String? ?? '',
    streetAddressAr: json['streetAddressAr'] as String? ?? '',
    emirate: json['emirate'] as String? ?? 'Sharjah',
    country: json['country'] as String? ?? 'AE',
    poBox: json['poBox'] as String?,
    latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
    longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
    googlePlaceId: json['googlePlaceID'] as String?,
    phone: json['phone'] as String? ?? '',
    whatsappBusiness: json['whatsappBusiness'] as String?,
    email: json['email'] as String? ?? '',
    foundedAt: json['foundedAt'] != null
        ? DateTime.parse(json['foundedAt'] as String)
        : DateTime.now(),
    isActive: json['isActive'] as bool? ?? true,
    brandHexColor: json['brandHexColor'] as String?,
    taglineEn: json['taglineEn'] as String?,
    taglineAr: json['taglineAr'] as String?,
    isMain: json['isMain'] as bool? ?? false,
    operationalStatus: BranchOperationalStatus.fromJson(
      json['operationalStatus'] as String? ?? 'active',
    ),
    compliance: json['compliance'] == null
        ? null
        : BranchCompliance.fromJson(json['compliance'] as Map<String, dynamic>),
    facility: json['facility'] == null
        ? null
        : BranchFacility.fromJson(json['facility'] as Map<String, dynamic>),
    financials: json['financials'] == null
        ? null
        : BranchFinancials.fromJson(json['financials'] as Map<String, dynamic>),
    hours: json['hours'] == null
        ? null
        : BranchHours.fromJson(json['hours'] as Map<String, dynamic>),
    inventory: json['inventory'] == null
        ? null
        : BranchInventory.fromJson(json['inventory'] as Map<String, dynamic>),
    media: json['media'] == null
        ? null
        : BranchMedia.fromJson(json['media'] as Map<String, dynamic>),
    milestones: ((json['milestones'] as List?) ?? [])
        .map((e) => BranchMilestone.fromJson(e as Map<String, dynamic>))
        .toList(),
    pricing: json['pricing'] == null
        ? null
        : BranchPricing.fromJson(json['pricing'] as Map<String, dynamic>),
    programs: ((json['programs'] as List?) ?? [])
        .map((e) => BranchProgram.fromJson(e as Map<String, dynamic>))
        .toList(),
    safeguarding: json['safeguarding'] == null
        ? null
        : BranchSafeguarding.fromJson(
            json['safeguarding'] as Map<String, dynamic>,
          ),
    socialLinks: json['socialLinks'] == null
        ? null
        : BranchSocialLinks.fromJson(
            json['socialLinks'] as Map<String, dynamic>,
          ),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'name': name,
    'nameAr': nameAr,
    'area': area,
    'capacity': capacity,
    'managerID': managerId,
    'focus': focus,
    'streetAddress': streetAddress,
    'streetAddressAr': streetAddressAr,
    'emirate': emirate,
    'country': country,
    'poBox': poBox,
    'latitude': latitude,
    'longitude': longitude,
    'googlePlaceID': googlePlaceId,
    'phone': phone,
    'whatsappBusiness': whatsappBusiness,
    'email': email,
    'foundedAt': foundedAt.toIso8601String(),
    'isActive': isActive,
    'brandHexColor': brandHexColor,
    'taglineEn': taglineEn,
    'taglineAr': taglineAr,
    'isMain': isMain,
    'operationalStatus': operationalStatus.name,
    'compliance': compliance?.toJson(),
    'facility': facility?.toJson(),
    'financials': financials?.toJson(),
    'hours': hours?.toJson(),
    'inventory': inventory?.toJson(),
    'media': media?.toJson(),
    'milestones': milestones.map((m) => m.toJson()).toList(),
    'pricing': pricing?.toJson(),
    'programs': programs.map((p) => p.toJson()).toList(),
    'safeguarding': safeguarding?.toJson(),
    'socialLinks': socialLinks?.toJson(),
  };
}
