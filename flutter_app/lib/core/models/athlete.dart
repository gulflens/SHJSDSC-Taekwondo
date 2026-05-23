import 'athlete_extras.dart';
import 'athlete_profile.dart';
import 'belt.dart';
import 'coaching_development.dart';
import 'entity_id.dart';
import 'poomsae_assessment.dart' show PoomsaeForm;
import 'tournament.dart' show WeightCategory;

/// Port of Core/Models/Athlete.swift — full dossier.
///
/// Embeds the same per-athlete records the Swift struct does (emergency
/// contacts, injuries, weight history, coach notes, documents, ranking,
/// assistant-coach profile) as nested Codable fields. Decoding is tolerant of
/// missing keys (defaults applied) so Supabase rows and older seed data stay
/// forward-compatible — mirroring Swift's synthesised-Codable-with-defaults.

enum Gender {
  male,
  female;

  static Gender fromJson(String raw) =>
      Gender.values.firstWhere((g) => g.name == raw, orElse: () => Gender.male);
}

enum AgeGroup {
  cubs,
  kids,
  cadets,
  juniors,
  seniors,
  masters;

  String get labelKey => 'age.$name';

  static AgeGroup fromAge(int age) {
    if (age < 10) return AgeGroup.cubs;
    if (age <= 11) return AgeGroup.kids;
    if (age <= 14) return AgeGroup.cadets;
    if (age <= 17) return AgeGroup.juniors;
    if (age <= 39) return AgeGroup.seniors;
    return AgeGroup.masters;
  }

  static AgeGroup fromJson(String raw) => AgeGroup.values
      .firstWhere((e) => e.name == raw, orElse: () => AgeGroup.seniors);
}

enum AthleteStatus {
  competitionTeam,
  readyToGrade,
  watch,
  rest,
  active;

  String get labelKey => 'status.$name';

  static AthleteStatus fromJson(String raw) => AthleteStatus.values
      .firstWhere((s) => s.name == raw, orElse: () => AthleteStatus.active);
}

class Athlete {
  final EntityID id;
  final int memberNumber;
  final String fullName;
  final String fullNameAr;
  final DateTime dateOfBirth;
  final Gender gender;
  final String nationality;
  final String? emiratesID;
  final EntityID branchId;
  final EntityID? primaryCoachId;
  final DateTime joinedAt;
  final Belt currentBelt;
  final List<Belt> beltHistory;
  final double weightKg;
  final AthleteStatus status;
  final String avatarSeed;
  final String? avatarUrl;

  // === Identity ===
  final String? passportNumber;
  final BloodType? bloodType;
  final String? federationLicenceNumber;
  final String? worldTaekwondoID;

  // === Family / consent ===
  final List<EntityID> parentUserIDs;
  final List<EmergencyContact> emergencyContacts;
  final String? school;
  final bool imageRightsConsent;
  final DateTime? imageRightsConsentDate;
  final bool travelPermission;
  final DateTime? travelPermissionDate;

  // === Medical ===
  final double? heightCm;
  final List<WeightEntry> weightHistory;
  final List<String> allergies;
  final List<String> medicalConditions;
  final List<String> medications;
  final bool fitToTrain;
  final List<InjuryEntry> injuries;

  // === Technical ===
  final WeightCategory? weightClass;
  final DominantLeg? dominantLeg;
  final Stance? dominantStance;
  final Specialty? specialty;
  final int? yearsTraining;
  final String? poomsaeSyllabus;
  final EntityID? trainingGroupID;
  final Set<PoomsaeForm> poomsaeKnown;

  // === Grading ===
  final int? gradingReadiness; // clamped 1…5
  final DateTime? nextGradingTargetDate;

  // === Profile dossier ===
  final List<CoachNote> coachNotes;
  final List<AthleteDocument> documents;
  final AthleteRanking? ranking;

  // === Coaching pathway (Stage 1.15) ===
  final Set<ProgramRole> programRoles;
  final AssistantCoachProfile? assistantCoach;

  Athlete({
    required this.id,
    required this.memberNumber,
    required this.fullName,
    required this.fullNameAr,
    required this.dateOfBirth,
    this.gender = Gender.male,
    this.nationality = 'AE',
    this.emiratesID,
    required this.branchId,
    this.primaryCoachId,
    required this.joinedAt,
    required this.currentBelt,
    this.beltHistory = const [],
    required this.weightKg,
    required this.status,
    required this.avatarSeed,
    this.avatarUrl,
    this.passportNumber,
    this.bloodType,
    this.federationLicenceNumber,
    this.worldTaekwondoID,
    this.parentUserIDs = const [],
    this.emergencyContacts = const [],
    this.school,
    this.imageRightsConsent = false,
    this.imageRightsConsentDate,
    this.travelPermission = false,
    this.travelPermissionDate,
    this.heightCm,
    this.weightHistory = const [],
    this.allergies = const [],
    this.medicalConditions = const [],
    this.medications = const [],
    this.fitToTrain = true,
    this.injuries = const [],
    this.weightClass,
    this.dominantLeg,
    this.dominantStance,
    this.specialty,
    this.yearsTraining,
    this.poomsaeSyllabus,
    this.trainingGroupID,
    this.poomsaeKnown = const {},
    int? gradingReadiness,
    this.nextGradingTargetDate,
    this.coachNotes = const [],
    this.documents = const [],
    this.ranking,
    this.programRoles = const {ProgramRole.athlete},
    this.assistantCoach,
  }) : gradingReadiness =
            gradingReadiness == null ? null : (gradingReadiness.clamp(1, 5));

  /// Whole months between when the current belt was awarded and now.
  int get monthsAtCurrentRank {
    final now = DateTime.now();
    return (now.year - currentBelt.awardedAt.year) * 12 +
        (now.month - currentBelt.awardedAt.month);
  }

  int get age {
    final now = DateTime.now();
    var years = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      years -= 1;
    }
    return years;
  }

  AgeGroup get ageGroup => AgeGroup.fromAge(age);

  String get initials {
    final parts = fullName.split(' ').where((p) => p.isNotEmpty).take(2);
    return parts.map((p) => p.substring(0, 1)).join().toUpperCase();
  }

  /// Localization keys for recommended-but-missing fields. Empty = complete
  /// enough. Drives the AthleteDetail warning banner.
  List<String> get missingProfileFields {
    final missing = <String>[];
    if ((emiratesID ?? '').isEmpty && (passportNumber ?? '').isEmpty) {
      missing.add('athlete.missing.id_document');
    }
    if (bloodType == null) missing.add('athlete.missing.blood_type');
    if ((federationLicenceNumber ?? '').isEmpty) {
      missing.add('athlete.missing.federation_licence');
    }
    if ((avatarUrl ?? '').isEmpty) missing.add('athlete.missing.photo');
    if (emergencyContacts.isEmpty) {
      missing.add('athlete.missing.emergency_contact');
    }
    if ((school ?? '').isEmpty) missing.add('athlete.missing.school');
    if (heightCm == null) missing.add('athlete.missing.height');
    if (!imageRightsConsent) missing.add('athlete.missing.image_rights');
    if (!travelPermission) missing.add('athlete.missing.travel_permission');
    return missing;
  }

  /// 0…1, equally weighted across the recommended fields.
  double get profileCompleteness {
    const totalChecked = 9.0;
    final missingCount = missingProfileFields.length.toDouble();
    return ((totalChecked - missingCount) / totalChecked).clamp(0.0, 1.0);
  }

  factory Athlete.fromJson(Map<String, dynamic> json) => Athlete(
        id: json['id'] as String,
        memberNumber: json['memberNumber'] as int,
        fullName: json['fullName'] as String,
        fullNameAr: json['fullNameAr'] as String,
        dateOfBirth: DateTime.parse(json['dateOfBirth'] as String),
        gender: Gender.fromJson(json['gender'] as String? ?? 'male'),
        nationality: json['nationality'] as String? ?? 'AE',
        emiratesID: json['emiratesID'] as String?,
        branchId: json['branchID'] as String,
        primaryCoachId: json['primaryCoachID'] as String?,
        joinedAt: DateTime.parse(json['joinedAt'] as String),
        currentBelt: Belt.fromJson(json['currentBelt'] as Map<String, dynamic>),
        beltHistory: ((json['beltHistory'] as List?) ?? [])
            .map((e) => Belt.fromJson(e as Map<String, dynamic>))
            .toList(),
        weightKg: (json['weightKg'] as num).toDouble(),
        status: AthleteStatus.fromJson(json['status'] as String? ?? 'active'),
        avatarSeed: json['avatarSeed'] as String? ?? '',
        avatarUrl: json['avatarURL'] as String?,
        passportNumber: json['passportNumber'] as String?,
        bloodType: json['bloodType'] == null
            ? null
            : BloodType.fromJson(json['bloodType'] as String),
        federationLicenceNumber: json['federationLicenceNumber'] as String?,
        worldTaekwondoID: json['worldTaekwondoID'] as String?,
        parentUserIDs: ((json['parentUserIDs'] as List?) ?? [])
            .map((e) => e as String)
            .toList(),
        emergencyContacts: ((json['emergencyContacts'] as List?) ?? [])
            .map((e) => EmergencyContact.fromJson(e as Map<String, dynamic>))
            .toList(),
        school: json['school'] as String?,
        imageRightsConsent: json['imageRightsConsent'] as bool? ?? false,
        imageRightsConsentDate: json['imageRightsConsentDate'] == null
            ? null
            : DateTime.parse(json['imageRightsConsentDate'] as String),
        travelPermission: json['travelPermission'] as bool? ?? false,
        travelPermissionDate: json['travelPermissionDate'] == null
            ? null
            : DateTime.parse(json['travelPermissionDate'] as String),
        heightCm: (json['heightCm'] as num?)?.toDouble(),
        weightHistory: ((json['weightHistory'] as List?) ?? [])
            .map((e) => WeightEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        allergies:
            ((json['allergies'] as List?) ?? []).map((e) => e as String).toList(),
        medicalConditions: ((json['medicalConditions'] as List?) ?? [])
            .map((e) => e as String)
            .toList(),
        medications: ((json['medications'] as List?) ?? [])
            .map((e) => e as String)
            .toList(),
        fitToTrain: json['fitToTrain'] as bool? ?? true,
        injuries: ((json['injuries'] as List?) ?? [])
            .map((e) => InjuryEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        weightClass: json['weightClass'] == null
            ? null
            : WeightCategory.fromJson(json['weightClass'] as String),
        dominantLeg: json['dominantLeg'] == null
            ? null
            : DominantLeg.fromJson(json['dominantLeg'] as String),
        dominantStance: json['dominantStance'] == null
            ? null
            : Stance.fromJson(json['dominantStance'] as String),
        specialty: json['specialty'] == null
            ? null
            : Specialty.fromJson(json['specialty'] as String),
        yearsTraining: json['yearsTraining'] as int?,
        poomsaeSyllabus: json['poomsaeSyllabus'] as String?,
        trainingGroupID: json['trainingGroupID'] as String?,
        poomsaeKnown: ((json['poomsaeKnown'] as List?) ?? [])
            .map((e) => PoomsaeForm.fromJson(e as String))
            .toSet(),
        gradingReadiness: json['gradingReadiness'] as int?,
        nextGradingTargetDate: json['nextGradingTargetDate'] == null
            ? null
            : DateTime.parse(json['nextGradingTargetDate'] as String),
        coachNotes: ((json['coachNotes'] as List?) ?? [])
            .map((e) => CoachNote.fromJson(e as Map<String, dynamic>))
            .toList(),
        documents: ((json['documents'] as List?) ?? [])
            .map((e) => AthleteDocument.fromJson(e as Map<String, dynamic>))
            .toList(),
        ranking: json['ranking'] == null
            ? null
            : AthleteRanking.fromJson(json['ranking'] as Map<String, dynamic>),
        programRoles: json['programRoles'] == null
            ? const {ProgramRole.athlete}
            : (json['programRoles'] as List)
                .map((e) => ProgramRole.fromJson(e as String))
                .toSet(),
        assistantCoach: json['assistantCoach'] == null
            ? null
            : AssistantCoachProfile.fromJson(
                json['assistantCoach'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'memberNumber': memberNumber,
        'fullName': fullName,
        'fullNameAr': fullNameAr,
        'dateOfBirth': dateOfBirth.toIso8601String(),
        'gender': gender.name,
        'nationality': nationality,
        'emiratesID': emiratesID,
        'branchID': branchId,
        'primaryCoachID': primaryCoachId,
        'joinedAt': joinedAt.toIso8601String(),
        'currentBelt': currentBelt.toJson(),
        'beltHistory': beltHistory.map((b) => b.toJson()).toList(),
        'weightKg': weightKg,
        'status': status.name,
        'avatarSeed': avatarSeed,
        'avatarURL': avatarUrl,
        'passportNumber': passportNumber,
        'bloodType': bloodType?.rawValue,
        'federationLicenceNumber': federationLicenceNumber,
        'worldTaekwondoID': worldTaekwondoID,
        'parentUserIDs': parentUserIDs,
        'emergencyContacts': emergencyContacts.map((e) => e.toJson()).toList(),
        'school': school,
        'imageRightsConsent': imageRightsConsent,
        'imageRightsConsentDate': imageRightsConsentDate?.toIso8601String(),
        'travelPermission': travelPermission,
        'travelPermissionDate': travelPermissionDate?.toIso8601String(),
        'heightCm': heightCm,
        'weightHistory': weightHistory.map((e) => e.toJson()).toList(),
        'allergies': allergies,
        'medicalConditions': medicalConditions,
        'medications': medications,
        'fitToTrain': fitToTrain,
        'injuries': injuries.map((e) => e.toJson()).toList(),
        'weightClass': weightClass?.name,
        'dominantLeg': dominantLeg?.name,
        'dominantStance': dominantStance?.name,
        'specialty': specialty?.name,
        'yearsTraining': yearsTraining,
        'poomsaeSyllabus': poomsaeSyllabus,
        'trainingGroupID': trainingGroupID,
        'poomsaeKnown': poomsaeKnown.map((e) => e.name).toList(),
        'gradingReadiness': gradingReadiness,
        'nextGradingTargetDate': nextGradingTargetDate?.toIso8601String(),
        'coachNotes': coachNotes.map((e) => e.toJson()).toList(),
        'documents': documents.map((e) => e.toJson()).toList(),
        'ranking': ranking?.toJson(),
        'programRoles': programRoles.map((e) => e.name).toList(),
        'assistantCoach': assistantCoach?.toJson(),
      };
}
