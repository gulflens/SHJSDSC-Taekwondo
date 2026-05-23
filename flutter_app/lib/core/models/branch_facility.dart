import 'entity_id.dart';

/// Port of Core/Models/Branch/BranchFacility.swift.

class HallSpec {
  final String name;
  final double lengthM;
  final double widthM;
  final String? matSpec;
  final bool isCompetitionGrade;

  const HallSpec({
    required this.name,
    required this.lengthM,
    required this.widthM,
    this.matSpec,
    this.isCompetitionGrade = false,
  });

  double get areaSqm => lengthM * widthM;

  factory HallSpec.fromJson(Map<String, dynamic> json) => HallSpec(
    name: json['name'] as String,
    lengthM: (json['lengthM'] as num).toDouble(),
    widthM: (json['widthM'] as num).toDouble(),
    matSpec: json['matSpec'] as String?,
    isCompetitionGrade: json['isCompetitionGrade'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'lengthM': lengthM,
    'widthM': widthM,
    'matSpec': matSpec,
    'isCompetitionGrade': isCompetitionGrade,
  };
}

class BranchFacility {
  final EntityID id;
  final EntityID branchId;
  final double floorAreaSqm;
  final int hallCount;
  final List<HallSpec> hallDimensions;
  final bool hasMirrorWalls;
  final bool hasSoundSystem;
  final bool hasAc;
  final bool hasInstalledScoreboard;
  final bool hasPss;
  final String? pssBrand;
  final DateTime? pssLastCalibrationAt;
  final int changingRoomsM;
  final int changingRoomsF;
  final int spectatorSeats;
  final int parkingSpots;
  final bool hasPrayerRoom;
  final bool hasWudu;
  final String? floorPlanFileRef;
  final List<String> photoUrls;

  const BranchFacility({
    required this.id,
    required this.branchId,
    required this.floorAreaSqm,
    required this.hallCount,
    this.hallDimensions = const [],
    this.hasMirrorWalls = false,
    this.hasSoundSystem = false,
    this.hasAc = true,
    this.hasInstalledScoreboard = false,
    this.hasPss = false,
    this.pssBrand,
    this.pssLastCalibrationAt,
    this.changingRoomsM = 0,
    this.changingRoomsF = 0,
    this.spectatorSeats = 0,
    this.parkingSpots = 0,
    this.hasPrayerRoom = false,
    this.hasWudu = false,
    this.floorPlanFileRef,
    this.photoUrls = const [],
  });

  factory BranchFacility.fromJson(Map<String, dynamic> json) => BranchFacility(
    id: json['id'] as String,
    branchId: json['branchID'] as String,
    floorAreaSqm: (json['floorAreaSqm'] as num).toDouble(),
    hallCount: json['hallCount'] as int,
    hallDimensions: ((json['hallDimensions'] as List?) ?? [])
        .map((e) => HallSpec.fromJson(e as Map<String, dynamic>))
        .toList(),
    hasMirrorWalls: json['hasMirrorWalls'] as bool? ?? false,
    hasSoundSystem: json['hasSoundSystem'] as bool? ?? false,
    hasAc: json['hasAC'] as bool? ?? true,
    hasInstalledScoreboard: json['hasInstalledScoreboard'] as bool? ?? false,
    hasPss: json['hasPSS'] as bool? ?? false,
    pssBrand: json['pssBrand'] as String?,
    pssLastCalibrationAt: json['pssLastCalibrationAt'] == null
        ? null
        : DateTime.parse(json['pssLastCalibrationAt'] as String),
    changingRoomsM: json['changingRoomsM'] as int? ?? 0,
    changingRoomsF: json['changingRoomsF'] as int? ?? 0,
    spectatorSeats: json['spectatorSeats'] as int? ?? 0,
    parkingSpots: json['parkingSpots'] as int? ?? 0,
    hasPrayerRoom: json['hasPrayerRoom'] as bool? ?? false,
    hasWudu: json['hasWudu'] as bool? ?? false,
    floorPlanFileRef: json['floorPlanFileRef'] as String?,
    photoUrls: ((json['photoURLs'] as List?) ?? [])
        .map((e) => e as String)
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'branchID': branchId,
    'floorAreaSqm': floorAreaSqm,
    'hallCount': hallCount,
    'hallDimensions': hallDimensions.map((h) => h.toJson()).toList(),
    'hasMirrorWalls': hasMirrorWalls,
    'hasSoundSystem': hasSoundSystem,
    'hasAC': hasAc,
    'hasInstalledScoreboard': hasInstalledScoreboard,
    'hasPSS': hasPss,
    'pssBrand': pssBrand,
    'pssLastCalibrationAt': pssLastCalibrationAt?.toIso8601String(),
    'changingRoomsM': changingRoomsM,
    'changingRoomsF': changingRoomsF,
    'spectatorSeats': spectatorSeats,
    'parkingSpots': parkingSpots,
    'hasPrayerRoom': hasPrayerRoom,
    'hasWudu': hasWudu,
    'floorPlanFileRef': floorPlanFileRef,
    'photoURLs': photoUrls,
  };
}
