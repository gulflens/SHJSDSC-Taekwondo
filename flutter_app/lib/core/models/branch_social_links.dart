import 'entity_id.dart';

/// Port of Core/Models/Branch/BranchSocialLinks.swift.

class BranchSocialLinks {
  final EntityID id;
  final EntityID branchId;
  final String? whatsappParentsLink;
  final String? whatsappAthletesLink;
  final String? telegramChannelLink;
  final String? instagramHandle;
  final String? tiktokHandle;
  final String? youtubeChannelUrl;
  final String? websiteUrl;

  const BranchSocialLinks({
    required this.id,
    required this.branchId,
    this.whatsappParentsLink,
    this.whatsappAthletesLink,
    this.telegramChannelLink,
    this.instagramHandle,
    this.tiktokHandle,
    this.youtubeChannelUrl,
    this.websiteUrl,
  });

  factory BranchSocialLinks.fromJson(Map<String, dynamic> json) =>
      BranchSocialLinks(
        id: json['id'] as String,
        branchId: json['branchID'] as String,
        whatsappParentsLink: json['whatsappParentsLink'] as String?,
        whatsappAthletesLink: json['whatsappAthletesLink'] as String?,
        telegramChannelLink: json['telegramChannelLink'] as String?,
        instagramHandle: json['instagramHandle'] as String?,
        tiktokHandle: json['tiktokHandle'] as String?,
        youtubeChannelUrl: json['youtubeChannelURL'] as String?,
        websiteUrl: json['websiteURL'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'branchID': branchId,
    'whatsappParentsLink': whatsappParentsLink,
    'whatsappAthletesLink': whatsappAthletesLink,
    'telegramChannelLink': telegramChannelLink,
    'instagramHandle': instagramHandle,
    'tiktokHandle': tiktokHandle,
    'youtubeChannelURL': youtubeChannelUrl,
    'websiteURL': websiteUrl,
  };
}
