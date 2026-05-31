import 'entity_id.dart';

/// Port of Core/Models/Branch/BranchMedia.swift.

class BranchMedia {
  final EntityID id;
  final EntityID branchId;
  final String? logoUrl;
  final String? heroPhotoUrl;
  final List<String> galleryUrls;
  final String? videoTourUrl;
  final String? floorPlanUrl;

  const BranchMedia({
    required this.id,
    required this.branchId,
    this.logoUrl,
    this.heroPhotoUrl,
    this.galleryUrls = const [],
    this.videoTourUrl,
    this.floorPlanUrl,
  });

  factory BranchMedia.fromJson(Map<String, dynamic> json) => BranchMedia(
    id: json['id'] as String,
    branchId: json['branchID'] as String,
    logoUrl: json['logoURL'] as String?,
    heroPhotoUrl: json['heroPhotoURL'] as String?,
    galleryUrls: ((json['galleryURLs'] as List?) ?? [])
        .map((e) => e as String)
        .toList(),
    videoTourUrl: json['videoTourURL'] as String?,
    floorPlanUrl: json['floorPlanURL'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'branchID': branchId,
    'logoURL': logoUrl,
    'heroPhotoURL': heroPhotoUrl,
    'galleryURLs': galleryUrls,
    'videoTourURL': videoTourUrl,
    'floorPlanURL': floorPlanUrl,
  };
}
