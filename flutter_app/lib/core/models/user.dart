import 'entity_id.dart';
import 'role.dart';

/// Port of `User` from Core/Models/CoreEntities.swift. Account-profile fields
/// (email/phone/notificationPrefs) are deferred to the account stage; the
/// decoder tolerates their absence, matching the Swift backward-compatible
/// `init(from:)`.
class User {
  final EntityID id;
  final String fullName;
  final String fullNameAr;
  final Role role;
  final EntityID? primaryBranchId;
  final String avatarSeed;
  final List<EntityID> linkedAthleteIds;
  final String? avatarUrl;
  final String? email;

  const User({
    required this.id,
    required this.fullName,
    required this.fullNameAr,
    required this.role,
    this.primaryBranchId,
    required this.avatarSeed,
    this.linkedAthleteIds = const [],
    this.avatarUrl,
    this.email,
  });

  String get initials {
    final parts = fullName.split(' ').where((p) => p.isNotEmpty).take(2);
    return parts.map((p) => p.substring(0, 1)).join().toUpperCase();
  }

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        fullName: json['fullName'] as String,
        fullNameAr: json['fullNameAr'] as String,
        role: Role.fromJson(json['role'] as String),
        primaryBranchId: json['primaryBranchID'] as String?,
        avatarSeed: json['avatarSeed'] as String? ?? '',
        linkedAthleteIds: ((json['linkedAthleteIDs'] as List?) ?? [])
            .map((e) => e as String)
            .toList(),
        avatarUrl: json['avatarURL'] as String?,
        email: json['email'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'fullNameAr': fullNameAr,
        'role': role.name,
        'primaryBranchID': primaryBranchId,
        'avatarSeed': avatarSeed,
        'linkedAthleteIDs': linkedAthleteIds,
        'avatarURL': avatarUrl,
        'email': email,
      };
}
