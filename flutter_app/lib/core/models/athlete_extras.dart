import 'entity_id.dart';

// Port of Core/Models/AthleteExtras.swift.
// Embedded collections that hang off Athlete — coach notes, documents, and a
// snapshot of cross-federation rankings.

enum CoachNoteCategory {
  technical,
  tactical,
  behavioural,
  medical,
  mental,
  general;

  String get labelKey => 'coach_note.category.$name';

  String get systemIcon => switch (this) {
    CoachNoteCategory.technical => 'figure.taichi',
    CoachNoteCategory.tactical => 'scope',
    CoachNoteCategory.behavioural => 'face.smiling',
    CoachNoteCategory.medical => 'cross.case.fill',
    CoachNoteCategory.mental => 'brain.head.profile',
    CoachNoteCategory.general => 'text.bubble',
  };

  static CoachNoteCategory fromJson(String raw) =>
      CoachNoteCategory.values.firstWhere(
        (c) => c.name == raw,
        orElse: () => CoachNoteCategory.general,
      );
}

class CoachNote {
  final EntityID id;
  final EntityID? authorCoachId;
  final String authorName;
  final DateTime date;
  final CoachNoteCategory category;
  final String body;
  final bool isPinned;

  const CoachNote({
    required this.id,
    this.authorCoachId,
    required this.authorName,
    required this.date,
    required this.category,
    required this.body,
    this.isPinned = false,
  });

  factory CoachNote.create({
    EntityID? id,
    EntityID? authorCoachId,
    required String authorName,
    DateTime? date,
    required CoachNoteCategory category,
    required String body,
    bool isPinned = false,
  }) => CoachNote(
    id: id ?? newEntityId(),
    authorCoachId: authorCoachId,
    authorName: authorName,
    date: date ?? DateTime.now(),
    category: category,
    body: body,
    isPinned: isPinned,
  );

  factory CoachNote.fromJson(Map<String, dynamic> json) => CoachNote(
    id: json['id'] as String,
    authorCoachId: json['authorCoachID'] as String?,
    authorName: json['authorName'] as String,
    date: DateTime.parse(json['date'] as String),
    category: CoachNoteCategory.fromJson(json['category'] as String),
    body: json['body'] as String,
    isPinned: json['isPinned'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'authorCoachID': authorCoachId,
    'authorName': authorName,
    'date': date.toIso8601String(),
    'category': category.name,
    'body': body,
    'isPinned': isPinned,
  };
}

enum AthleteDocumentKind {
  emiratesID,
  passport,
  federationLicence,
  worldTaekwondoCard,
  medicalClearance,
  imageRightsConsent,
  travelPermission,
  schoolID,
  other;

  String get labelKey => 'doc.kind.$name';

  String get systemIcon => switch (this) {
    AthleteDocumentKind.emiratesID => 'person.text.rectangle.fill',
    AthleteDocumentKind.passport => 'book.closed.fill',
    AthleteDocumentKind.federationLicence => 'rosette',
    AthleteDocumentKind.worldTaekwondoCard => 'globe',
    AthleteDocumentKind.medicalClearance => 'cross.case.fill',
    AthleteDocumentKind.imageRightsConsent => 'camera.fill',
    AthleteDocumentKind.travelPermission => 'airplane',
    AthleteDocumentKind.schoolID => 'graduationcap.fill',
    AthleteDocumentKind.other => 'doc.fill',
  };

  static AthleteDocumentKind fromJson(String raw) =>
      AthleteDocumentKind.values.firstWhere(
        (k) => k.name == raw,
        orElse: () => AthleteDocumentKind.other,
      );
}

enum AthleteDocumentStatus {
  valid,
  expiringSoon,
  expired,
  missing,
  pending;

  String get labelKey => 'doc.status.$name';

  static AthleteDocumentStatus fromJson(String raw) =>
      AthleteDocumentStatus.values.firstWhere(
        (s) => s.name == raw,
        orElse: () => AthleteDocumentStatus.missing,
      );
}

class AthleteDocument {
  final EntityID id;
  final AthleteDocumentKind kind;

  /// Free-form override; null falls back to [kind.labelKey].
  final String? label;
  final DateTime? issuedAt;
  final DateTime? expiresAt;
  final AthleteDocumentStatus status;

  /// Resolvable URL (Supabase Storage signed URL once Stage 5 ships).
  /// Null in demo mode — the row falls back to a placeholder icon + empty state.
  final String? fileUrl;
  final String? notes;

  const AthleteDocument({
    required this.id,
    required this.kind,
    this.label,
    this.issuedAt,
    this.expiresAt,
    this.status = AthleteDocumentStatus.missing,
    this.fileUrl,
    this.notes,
  });

  factory AthleteDocument.create({
    EntityID? id,
    required AthleteDocumentKind kind,
    String? label,
    DateTime? issuedAt,
    DateTime? expiresAt,
    AthleteDocumentStatus status = AthleteDocumentStatus.missing,
    String? fileUrl,
    String? notes,
  }) => AthleteDocument(
    id: id ?? newEntityId(),
    kind: kind,
    label: label,
    issuedAt: issuedAt,
    expiresAt: expiresAt,
    status: status,
    fileUrl: fileUrl,
    notes: notes,
  );

  factory AthleteDocument.fromJson(Map<String, dynamic> json) =>
      AthleteDocument(
        id: json['id'] as String,
        kind: AthleteDocumentKind.fromJson(json['kind'] as String),
        label: json['label'] as String?,
        issuedAt: json['issuedAt'] != null
            ? DateTime.parse(json['issuedAt'] as String)
            : null,
        expiresAt: json['expiresAt'] != null
            ? DateTime.parse(json['expiresAt'] as String)
            : null,
        status: AthleteDocumentStatus.fromJson(
          json['status'] as String? ?? 'missing',
        ),
        fileUrl: json['fileURL'] as String?,
        notes: json['notes'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.name,
    'label': label,
    'issuedAt': issuedAt?.toIso8601String(),
    'expiresAt': expiresAt?.toIso8601String(),
    'status': status.name,
    'fileURL': fileUrl,
    'notes': notes,
  };

  /// Derived status from expiry — pass [asOf] to keep this pure (no
  /// DateTime.now() side-effect in the model). Returns [AthleteDocumentStatus.valid]
  /// / [AthleteDocumentStatus.expiringSoon] (within 30 days) /
  /// [AthleteDocumentStatus.expired] based on [expiresAt], or falls back to
  /// the persisted [status] when no expiry is set.
  AthleteDocumentStatus derivedStatus({DateTime? asOf}) {
    final now = asOf ?? DateTime.now();
    if (expiresAt == null) return status;
    if (expiresAt!.isBefore(now)) return AthleteDocumentStatus.expired;
    final thirtyDays = const Duration(days: 30);
    if (expiresAt!.difference(now) < thirtyDays) {
      return AthleteDocumentStatus.expiringSoon;
    }
    return AthleteDocumentStatus.valid;
  }
}

/// Cross-federation ranking snapshot. Null fields render as "—" in the UI.
class AthleteRanking {
  /// Rank inside the athlete's own club / branch.
  final int? club;

  /// Rank inside the UAE Taekwondo Federation national list.
  final int? uae;

  /// World Taekwondo Federation Olympic-ranking points position.
  final int? world;

  /// Olympic qualification position (sport-specific quota slot index).
  final int? olympic;
  final DateTime asOf;

  const AthleteRanking({
    this.club,
    this.uae,
    this.world,
    this.olympic,
    required this.asOf,
  });

  factory AthleteRanking.create({
    int? club,
    int? uae,
    int? world,
    int? olympic,
    DateTime? asOf,
  }) => AthleteRanking(
    club: club,
    uae: uae,
    world: world,
    olympic: olympic,
    asOf: asOf ?? DateTime.now(),
  );

  factory AthleteRanking.fromJson(Map<String, dynamic> json) => AthleteRanking(
    club: json['club'] as int?,
    uae: json['uae'] as int?,
    world: json['world'] as int?,
    olympic: json['olympic'] as int?,
    asOf: DateTime.parse(json['asOf'] as String),
  );

  Map<String, dynamic> toJson() => {
    'club': club,
    'uae': uae,
    'world': world,
    'olympic': olympic,
    'asOf': asOf.toIso8601String(),
  };
}
