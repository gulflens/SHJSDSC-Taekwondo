// Port of Core/Models/Operations.swift.
// Pure data — no Flutter imports (logic-layer rule).

import 'announcement_dossier.dart';
import 'entity_id.dart';

export 'announcement_dossier.dart';

enum AnnouncementAudience {
  all,
  coaches,
  parents,
  athletes,
  branchManagers;

  String get labelKey => 'announcement.audience.$name';

  static AnnouncementAudience fromJson(String raw) => AnnouncementAudience
      .values
      .firstWhere((e) => e.name == raw, orElse: () => AnnouncementAudience.all);
}

class Announcement {
  final EntityID id;
  final EntityID? branchId;
  final String title;
  final String titleAr;
  final String body;
  final String bodyAr;
  final AnnouncementAudience audience;
  final DateTime publishedAt;
  final EntityID publishedByUserId;
  final bool requiresRsvp;
  final DateTime? rsvpDeadline;

  // Stage 1.9 — announcements dashboard
  final AnnouncementStatus status;
  final AnnouncementCategory category;
  final String? imageAssetName;
  final DateTime? scheduledAt;
  final List<AnnouncementAudience> audiences;
  final String? location;
  final DateTime? eventStart;
  final DateTime? eventEnd;
  final DateTime? registrationDeadline;
  final List<AnnouncementDelivery> delivery;
  final AnnouncementEngagement? engagement;
  final List<AnnouncementAttachment> attachments;
  final String? authorName;

  const Announcement({
    required this.id,
    this.branchId,
    required this.title,
    this.titleAr = '',
    this.body = '',
    this.bodyAr = '',
    required this.audience,
    required this.publishedAt,
    required this.publishedByUserId,
    this.requiresRsvp = false,
    this.rsvpDeadline,
    this.status = AnnouncementStatus.published,
    this.category = AnnouncementCategory.general,
    this.imageAssetName,
    this.scheduledAt,
    this.audiences = const [],
    this.location,
    this.eventStart,
    this.eventEnd,
    this.registrationDeadline,
    this.delivery = const [],
    this.engagement,
    this.attachments = const [],
    this.authorName,
  });

  /// Full audience list — falls back to the single [audience] for old rows.
  List<AnnouncementAudience> get effectiveAudiences =>
      audiences.isEmpty ? [audience] : audiences;

  /// The date the row and detail panel display.
  DateTime get displayDate {
    if (status == AnnouncementStatus.scheduled && scheduledAt != null) {
      return scheduledAt!;
    }
    return publishedAt;
  }

  factory Announcement.fromJson(Map<String, dynamic> json) => Announcement(
    id: json['id'] as String,
    branchId: json['branchID'] as String?,
    title: json['title'] as String,
    titleAr: json['titleAr'] as String? ?? '',
    body: json['body'] as String? ?? '',
    bodyAr: json['bodyAr'] as String? ?? '',
    audience: AnnouncementAudience.fromJson(
      json['audience'] as String? ?? 'all',
    ),
    publishedAt: DateTime.parse(json['publishedAt'] as String),
    publishedByUserId: json['publishedByUserID'] as String,
    requiresRsvp: json['requiresRSVP'] as bool? ?? false,
    rsvpDeadline: json['rsvpDeadline'] != null
        ? DateTime.parse(json['rsvpDeadline'] as String)
        : null,
    status: AnnouncementStatus.fromJson(
      json['status'] as String? ?? 'published',
    ),
    category: AnnouncementCategory.fromJson(
      json['category'] as String? ?? 'general',
    ),
    imageAssetName: json['imageAssetName'] as String?,
    scheduledAt: json['scheduledAt'] != null
        ? DateTime.parse(json['scheduledAt'] as String)
        : null,
    audiences: ((json['audiences'] as List?) ?? [])
        .map((e) => AnnouncementAudience.fromJson(e as String))
        .toList(),
    location: json['location'] as String?,
    eventStart: json['eventStart'] != null
        ? DateTime.parse(json['eventStart'] as String)
        : null,
    eventEnd: json['eventEnd'] != null
        ? DateTime.parse(json['eventEnd'] as String)
        : null,
    registrationDeadline: json['registrationDeadline'] != null
        ? DateTime.parse(json['registrationDeadline'] as String)
        : null,
    delivery: ((json['delivery'] as List?) ?? [])
        .map((e) => AnnouncementDelivery.fromJson(e as Map<String, dynamic>))
        .toList(),
    engagement: json['engagement'] != null
        ? AnnouncementEngagement.fromJson(
            json['engagement'] as Map<String, dynamic>,
          )
        : null,
    attachments: ((json['attachments'] as List?) ?? [])
        .map((e) => AnnouncementAttachment.fromJson(e as Map<String, dynamic>))
        .toList(),
    authorName: json['authorName'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'branchID': branchId,
    'title': title,
    'titleAr': titleAr,
    'body': body,
    'bodyAr': bodyAr,
    'audience': audience.name,
    'publishedAt': publishedAt.toIso8601String(),
    'publishedByUserID': publishedByUserId,
    'requiresRSVP': requiresRsvp,
    'rsvpDeadline': rsvpDeadline?.toIso8601String(),
    'status': status.name,
    'category': category.name,
    'imageAssetName': imageAssetName,
    'scheduledAt': scheduledAt?.toIso8601String(),
    'audiences': audiences.map((a) => a.name).toList(),
    'location': location,
    'eventStart': eventStart?.toIso8601String(),
    'eventEnd': eventEnd?.toIso8601String(),
    'registrationDeadline': registrationDeadline?.toIso8601String(),
    'delivery': delivery.map((d) => d.toJson()).toList(),
    'engagement': engagement?.toJson(),
    'attachments': attachments.map((a) => a.toJson()).toList(),
    'authorName': authorName,
  };
}

enum RSVPResponse {
  yes,
  no,
  maybe;

  String get labelKey => 'announcement.rsvp.$name';

  static RSVPResponse fromJson(String raw) => RSVPResponse.values.firstWhere(
    (e) => e.name == raw,
    orElse: () => RSVPResponse.maybe,
  );
}

class AnnouncementRSVP {
  final EntityID id;
  final EntityID announcementId;
  final EntityID userId;
  final RSVPResponse response;
  final DateTime respondedAt;

  const AnnouncementRSVP({
    required this.id,
    required this.announcementId,
    required this.userId,
    required this.response,
    required this.respondedAt,
  });

  factory AnnouncementRSVP.fromJson(Map<String, dynamic> json) =>
      AnnouncementRSVP(
        id: json['id'] as String,
        announcementId: json['announcementID'] as String,
        userId: json['userID'] as String,
        response: RSVPResponse.fromJson(json['response'] as String),
        respondedAt: DateTime.parse(json['respondedAt'] as String),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'announcementID': announcementId,
    'userID': userId,
    'response': response.name,
    'respondedAt': respondedAt.toIso8601String(),
  };
}

enum CertificationKind {
  firstAid,
  safeguarding,
  wtCoaching,
  doping,
  refereeing;

  String get labelKey => 'cert.$name';

  /// Grouping shown under the branch in the certifications table.
  String get categoryLabelKey => 'cert.category.$name';

  /// SF Symbol for the row's status icon tile.
  String get systemIcon => switch (this) {
    CertificationKind.firstAid => 'cross.case.fill',
    CertificationKind.safeguarding => 'shield.lefthalf.filled',
    CertificationKind.wtCoaching => 'rosette',
    CertificationKind.doping => 'drop.fill',
    CertificationKind.refereeing => 'flag.checkered',
  };

  static CertificationKind fromJson(String raw) =>
      CertificationKind.values.firstWhere(
        (e) => e.name == raw,
        orElse: () => CertificationKind.wtCoaching,
      );
}

/// Not Codable in Swift — plain enum, no fromJson/toJson.
enum CertificationSeverity {
  ok,
  expiring,
  expired;

  String get labelKey => 'cert.severity.$name';
}

class Certification {
  final EntityID id;
  final EntityID coachId;
  final CertificationKind kind;
  final String issuer;
  final DateTime issuedAt;
  final DateTime expiresAt;
  final String? fileRef;

  const Certification({
    required this.id,
    required this.coachId,
    required this.kind,
    required this.issuer,
    required this.issuedAt,
    required this.expiresAt,
    this.fileRef,
  });

  int get daysUntilExpiry => expiresAt.difference(DateTime.now()).inDays;

  CertificationSeverity get severity {
    final days = daysUntilExpiry;
    if (days < 0) return CertificationSeverity.expired;
    if (days < 60) return CertificationSeverity.expiring;
    return CertificationSeverity.ok;
  }

  factory Certification.fromJson(Map<String, dynamic> json) => Certification(
    id: json['id'] as String,
    coachId: json['coachID'] as String,
    kind: CertificationKind.fromJson(json['kind'] as String),
    issuer: json['issuer'] as String,
    issuedAt: DateTime.parse(json['issuedAt'] as String),
    expiresAt: DateTime.parse(json['expiresAt'] as String),
    fileRef: json['fileRef'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'coachID': coachId,
    'kind': kind.name,
    'issuer': issuer,
    'issuedAt': issuedAt.toIso8601String(),
    'expiresAt': expiresAt.toIso8601String(),
    'fileRef': fileRef,
  };
}
