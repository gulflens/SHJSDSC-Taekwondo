import 'athlete.dart' show Gender;
import 'athlete_extras.dart' show CoachNote;
import 'athlete_profile.dart' show BloodType;
import 'coach_extras.dart';
import 'entity_id.dart';

// Port of Core/Models/Coach.swift.
//
// Cross-file references resolved:
//   Gender     → athlete.dart (already ported)
//   BloodType  → athlete_profile.dart (already ported)
//   CoachNote  → athlete_extras.dart (already ported — same shape, different context)
//   CoachRanking, CoachLevel, CoachLicenseLevel, CoachSpecialisation,
//   CoachEmploymentStatus, CoachProgramStatus → coach_extras.dart

enum ContractType {
  fullTime,
  partTime,
  contractor;

  String get labelKey => 'contract.$name';

  static ContractType fromJson(String raw) => ContractType.values.firstWhere(
    (c) => c.name == raw,
    orElse: () => ContractType.fullTime,
  );
}

class Coach {
  final EntityID id;
  final String fullName;
  final String fullNameAr;
  final EntityID primaryBranchId;
  final List<EntityID> secondaryBranchIds;
  final int danRank;
  final int wtCoachLicenceLevel;
  final DateTime firstAidExpiry;
  final DateTime safeguardingExpiry;
  final ContractType contractType;
  final DateTime hiredAt;
  final String avatarSeed;
  final String? avatarUrl;

  // === Credentials ===
  final String? kukkiwonCertNumber;
  final DateTime? kukkiwonIssuedAt;
  final DateTime? wtCoachLicenceExpiry;
  final int? poomsaeRefereeLevel;
  final DateTime? poomsaeRefereeExpiry;
  final int? kyorugiRefereeLevel;
  final DateTime? kyorugiRefereeExpiry;
  final DateTime? antiDopingExpiry;

  // === Assignment ===
  final int? weeklyHoursTarget;
  final bool onCall;
  final String? bio;
  final String? bioAr;

  // === Performance (snapshot) ===
  final double cpdHoursThisYear;
  final double? parentSatisfactionAvg;
  final double? peerReviewAvg;

  // === Identity (Stage 1.6) ===
  final DateTime? dateOfBirth;
  final Gender? gender;
  final String nationality;
  final String? mobileNumber;
  final String? email;
  final String? emiratesId;
  final String? passportNumber;
  final BloodType? bloodType;

  /// UAE Taekwondo Federation coach ID.
  final String? federationCoachId;

  /// World Taekwondo coach licence ID (distinct from [wtCoachLicenceLevel]).
  final String? worldTaekwondoCoachId;

  // === Coaching role + status (Stage 1.6) ===
  final CoachLevel? coachLevel;
  final CoachLicenseLevel? licenseLevel;
  final CoachSpecialisation? specialisation;
  final CoachEmploymentStatus employmentStatus;
  final CoachProgramStatus nationalTeamStatus;
  final CoachProgramStatus olympicProgramStatus;

  // === Discipline-specific competency (Stage 1.6) ===
  /// 1...5 self-or-HQ-rated competency in each pillar. null = not rated.
  final int? technicalLevel;
  final int? sparringLevel;
  final int? poomsaeLevel;
  final int? fitnessLevel;

  // === Profile dossier (Stage 1.6) ===
  /// Coach-on-coach notes (peer reviews, HQ feedback, mentorship log).
  final List<CoachNote> coachNotes;

  /// Latest ranking snapshot across club / UAE / WT.
  final CoachRanking? ranking;

  Coach({
    required this.id,
    required this.fullName,
    required this.fullNameAr,
    required this.primaryBranchId,
    this.secondaryBranchIds = const [],
    required this.danRank,
    required this.wtCoachLicenceLevel,
    required this.firstAidExpiry,
    required this.safeguardingExpiry,
    required this.contractType,
    required this.hiredAt,
    required this.avatarSeed,
    this.avatarUrl,
    this.kukkiwonCertNumber,
    this.kukkiwonIssuedAt,
    this.wtCoachLicenceExpiry,
    this.poomsaeRefereeLevel,
    this.poomsaeRefereeExpiry,
    this.kyorugiRefereeLevel,
    this.kyorugiRefereeExpiry,
    this.antiDopingExpiry,
    this.weeklyHoursTarget,
    this.onCall = false,
    this.bio,
    this.bioAr,
    this.cpdHoursThisYear = 0,
    this.parentSatisfactionAvg,
    this.peerReviewAvg,
    this.dateOfBirth,
    this.gender,
    this.nationality = 'AE',
    this.mobileNumber,
    this.email,
    this.emiratesId,
    this.passportNumber,
    this.bloodType,
    this.federationCoachId,
    this.worldTaekwondoCoachId,
    this.coachLevel,
    this.licenseLevel,
    this.specialisation,
    this.employmentStatus = CoachEmploymentStatus.active,
    this.nationalTeamStatus = CoachProgramStatus.none,
    this.olympicProgramStatus = CoachProgramStatus.none,
    int? technicalLevel,
    int? sparringLevel,
    int? poomsaeLevel,
    int? fitnessLevel,
    this.coachNotes = const [],
    this.ranking,
  }) : technicalLevel = technicalLevel?.clamp(1, 5),
       sparringLevel = sparringLevel?.clamp(1, 5),
       poomsaeLevel = poomsaeLevel?.clamp(1, 5),
       fitnessLevel = fitnessLevel?.clamp(1, 5);

  /// Whole years from [hiredAt] to today — used for the "Years of experience" chip.
  int get yearsOfExperience {
    final now = DateTime.now();
    var years = now.year - hiredAt.year;
    if (now.month < hiredAt.month ||
        (now.month == hiredAt.month && now.day < hiredAt.day)) {
      years -= 1;
    }
    return years < 0 ? 0 : years;
  }

  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    var years = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      years -= 1;
    }
    return years;
  }

  String get initials {
    final parts = fullName
        .split(' ')
        .where((p) => p.isNotEmpty)
        .take(2)
        .toList();
    return parts.map((p) => p.substring(0, 1)).join().toUpperCase();
  }

  /// Localisation keys for fields HQ recommends but a coach may be missing.
  /// Empty result = profile is "complete enough".
  List<String> get missingProfileFields {
    final missing = <String>[];
    if ((kukkiwonCertNumber ?? '').isEmpty) {
      missing.add('coach.missing.kukkiwon');
    }
    if (wtCoachLicenceExpiry == null) {
      missing.add('coach.missing.wt_licence_expiry');
    }
    if (poomsaeRefereeLevel == null) {
      missing.add('coach.missing.poomsae_referee');
    }
    if (kyorugiRefereeLevel == null) {
      missing.add('coach.missing.kyorugi_referee');
    }
    if (antiDopingExpiry == null) missing.add('coach.missing.anti_doping');
    if (weeklyHoursTarget == null) missing.add('coach.missing.weekly_hours');
    if ((bio ?? '').isEmpty) missing.add('coach.missing.bio');
    if ((avatarUrl ?? '').isEmpty) missing.add('coach.missing.photo');
    return missing;
  }

  /// 0...1, equally weighted across recommended fields.
  double get profileCompleteness {
    const totalChecked = 8.0;
    final missingCount = missingProfileFields.length.toDouble();
    return ((totalChecked - missingCount) / totalChecked).clamp(0.0, 1.0);
  }

  /// Earliest expiry across the coach's certifications. Null if no certs.
  DateTime? get nextCertificationExpiry {
    final dates = <DateTime>[
      firstAidExpiry,
      safeguardingExpiry,
      ?wtCoachLicenceExpiry,
      ?antiDopingExpiry,
      ?poomsaeRefereeExpiry,
      ?kyorugiRefereeExpiry,
    ];
    if (dates.isEmpty) return null;
    dates.sort();
    return dates.first;
  }

  factory Coach.fromJson(Map<String, dynamic> json) => Coach(
    id: json['id'] as String,
    fullName: json['fullName'] as String,
    fullNameAr: json['fullNameAr'] as String,
    primaryBranchId: json['primaryBranchID'] as String,
    secondaryBranchIds: ((json['secondaryBranchIDs'] as List?) ?? [])
        .cast<String>(),
    danRank: json['danRank'] as int,
    wtCoachLicenceLevel: json['wtCoachLicenceLevel'] as int,
    firstAidExpiry: DateTime.parse(json['firstAidExpiry'] as String),
    safeguardingExpiry: DateTime.parse(json['safeguardingExpiry'] as String),
    contractType: ContractType.fromJson(
      json['contractType'] as String? ?? 'fullTime',
    ),
    hiredAt: DateTime.parse(json['hiredAt'] as String),
    avatarSeed: json['avatarSeed'] as String? ?? '',
    avatarUrl: json['avatarURL'] as String?,
    kukkiwonCertNumber: json['kukkiwonCertNumber'] as String?,
    kukkiwonIssuedAt: json['kukkiwonIssuedAt'] != null
        ? DateTime.parse(json['kukkiwonIssuedAt'] as String)
        : null,
    wtCoachLicenceExpiry: json['wtCoachLicenceExpiry'] != null
        ? DateTime.parse(json['wtCoachLicenceExpiry'] as String)
        : null,
    poomsaeRefereeLevel: json['poomsaeRefereeLevel'] as int?,
    poomsaeRefereeExpiry: json['poomsaeRefereeExpiry'] != null
        ? DateTime.parse(json['poomsaeRefereeExpiry'] as String)
        : null,
    kyorugiRefereeLevel: json['kyorugiRefereeLevel'] as int?,
    kyorugiRefereeExpiry: json['kyorugiRefereeExpiry'] != null
        ? DateTime.parse(json['kyorugiRefereeExpiry'] as String)
        : null,
    antiDopingExpiry: json['antiDopingExpiry'] != null
        ? DateTime.parse(json['antiDopingExpiry'] as String)
        : null,
    weeklyHoursTarget: json['weeklyHoursTarget'] as int?,
    onCall: json['onCall'] as bool? ?? false,
    bio: json['bio'] as String?,
    bioAr: json['bioAr'] as String?,
    cpdHoursThisYear: (json['cpdHoursThisYear'] as num?)?.toDouble() ?? 0.0,
    parentSatisfactionAvg: (json['parentSatisfactionAvg'] as num?)?.toDouble(),
    peerReviewAvg: (json['peerReviewAvg'] as num?)?.toDouble(),
    dateOfBirth: json['dateOfBirth'] != null
        ? DateTime.parse(json['dateOfBirth'] as String)
        : null,
    gender: json['gender'] != null
        ? Gender.fromJson(json['gender'] as String)
        : null,
    nationality: json['nationality'] as String? ?? 'AE',
    mobileNumber: json['mobileNumber'] as String?,
    email: json['email'] as String?,
    emiratesId: json['emiratesID'] as String?,
    passportNumber: json['passportNumber'] as String?,
    bloodType: json['bloodType'] != null
        ? BloodType.fromJson(json['bloodType'] as String)
        : null,
    federationCoachId: json['federationCoachID'] as String?,
    worldTaekwondoCoachId: json['worldTaekwondoCoachID'] as String?,
    coachLevel: json['coachLevel'] != null
        ? CoachLevel.fromJson(json['coachLevel'] as String)
        : null,
    licenseLevel: json['licenseLevel'] != null
        ? CoachLicenseLevel.fromJson(json['licenseLevel'] as String)
        : null,
    specialisation: json['specialisation'] != null
        ? CoachSpecialisation.fromJson(json['specialisation'] as String)
        : null,
    employmentStatus: CoachEmploymentStatus.fromJson(
      json['employmentStatus'] as String? ?? 'active',
    ),
    nationalTeamStatus: CoachProgramStatus.fromJson(
      json['nationalTeamStatus'] as String? ?? 'none',
    ),
    olympicProgramStatus: CoachProgramStatus.fromJson(
      json['olympicProgramStatus'] as String? ?? 'none',
    ),
    technicalLevel: json['technicalLevel'] as int?,
    sparringLevel: json['sparringLevel'] as int?,
    poomsaeLevel: json['poomsaeLevel'] as int?,
    fitnessLevel: json['fitnessLevel'] as int?,
    coachNotes: ((json['coachNotes'] as List?) ?? [])
        .map((e) => CoachNote.fromJson(e as Map<String, dynamic>))
        .toList(),
    ranking: json['ranking'] != null
        ? CoachRanking.fromJson(json['ranking'] as Map<String, dynamic>)
        : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'fullName': fullName,
    'fullNameAr': fullNameAr,
    'primaryBranchID': primaryBranchId,
    'secondaryBranchIDs': secondaryBranchIds,
    'danRank': danRank,
    'wtCoachLicenceLevel': wtCoachLicenceLevel,
    'firstAidExpiry': firstAidExpiry.toIso8601String(),
    'safeguardingExpiry': safeguardingExpiry.toIso8601String(),
    'contractType': contractType.name,
    'hiredAt': hiredAt.toIso8601String(),
    'avatarSeed': avatarSeed,
    'avatarURL': avatarUrl,
    'kukkiwonCertNumber': kukkiwonCertNumber,
    'kukkiwonIssuedAt': kukkiwonIssuedAt?.toIso8601String(),
    'wtCoachLicenceExpiry': wtCoachLicenceExpiry?.toIso8601String(),
    'poomsaeRefereeLevel': poomsaeRefereeLevel,
    'poomsaeRefereeExpiry': poomsaeRefereeExpiry?.toIso8601String(),
    'kyorugiRefereeLevel': kyorugiRefereeLevel,
    'kyorugiRefereeExpiry': kyorugiRefereeExpiry?.toIso8601String(),
    'antiDopingExpiry': antiDopingExpiry?.toIso8601String(),
    'weeklyHoursTarget': weeklyHoursTarget,
    'onCall': onCall,
    'bio': bio,
    'bioAr': bioAr,
    'cpdHoursThisYear': cpdHoursThisYear,
    'parentSatisfactionAvg': parentSatisfactionAvg,
    'peerReviewAvg': peerReviewAvg,
    'dateOfBirth': dateOfBirth?.toIso8601String(),
    'gender': gender?.name,
    'nationality': nationality,
    'mobileNumber': mobileNumber,
    'email': email,
    'emiratesID': emiratesId,
    'passportNumber': passportNumber,
    'bloodType': bloodType?.rawValue,
    'federationCoachID': federationCoachId,
    'worldTaekwondoCoachID': worldTaekwondoCoachId,
    'coachLevel': coachLevel?.name,
    'licenseLevel': licenseLevel?.name,
    'specialisation': specialisation?.name,
    'employmentStatus': employmentStatus.name,
    'nationalTeamStatus': nationalTeamStatus.name,
    'olympicProgramStatus': olympicProgramStatus.name,
    'technicalLevel': technicalLevel,
    'sparringLevel': sparringLevel,
    'poomsaeLevel': poomsaeLevel,
    'fitnessLevel': fitnessLevel,
    'coachNotes': coachNotes.map((n) => n.toJson()).toList(),
    'ranking': ranking?.toJson(),
  };
}
