import '../models/athlete.dart';
import '../models/athlete_extras.dart';
import '../models/athlete_profile.dart';
import '../models/audit_log.dart';
import '../models/belt.dart';
import '../models/branch.dart';
import '../models/coach.dart';
import '../models/coach_extras.dart';
import '../models/coaching_development.dart';
import '../models/goal.dart';
import '../models/grading.dart';
import '../models/match.dart' show MedalType;
import '../models/operations.dart';
import '../models/performance_entry.dart';
import '../models/performance_score.dart';
import '../models/physical_metric.dart';
import '../models/role.dart';
import '../models/schedule.dart';
import '../models/technical_skill.dart';
import '../models/tournament.dart';
import '../models/user.dart';

/// Port of `SeedData.build()` (subset). Deterministic, realistic SSDSC content
/// for the Athletes slice: 4 branches, a demo user per role-experience, and a
/// roster of athletes with both English and Arabic names + performance scores.
///
/// Extended with coaches (Yassin Ibrahim + Dr. Ali Hassan) so the
/// CoachRepository is populated from day one.
///
/// Stable IDs (string literals, not random UUIDs) keep cross-references intact
/// and make the demo round-trippable, exactly like the Swift seed.
class SeedBundle {
  final List<Branch> branches;
  final List<User> users;
  final List<Athlete> athletes;
  final List<PerformanceScore> scores;
  final List<Coach> coaches;
  final List<ClassSession> sessions;
  final List<GradingSession> gradingSessions;
  final List<PhysicalMetric> physicalMetrics;
  final List<TechnicalSkill> technicalSkills;
  final List<WellnessEntry> wellness;
  final List<Announcement> announcements;
  final List<Certification> certifications;
  final List<AuditEntry> auditEntries;
  final List<Tournament> tournaments;
  final List<TournamentRegistration> registrations;
  final List<WeightCutEntry> weightCuts;
  final List<AttendanceRecord> attendance;
  final List<Bracket> brackets;
  final List<BracketMatch> bracketMatches;
  final List<Goal> goals;

  const SeedBundle({
    required this.branches,
    required this.users,
    required this.athletes,
    required this.scores,
    required this.coaches,
    required this.sessions,
    required this.gradingSessions,
    required this.physicalMetrics,
    required this.technicalSkills,
    required this.wellness,
    required this.announcements,
    required this.certifications,
    required this.auditEntries,
    required this.tournaments,
    required this.registrations,
    required this.weightCuts,
    required this.attendance,
    required this.brackets,
    required this.bracketMatches,
    required this.goals,
  });
}

class SeedData {
  SeedData._();

  // Stable branch IDs.
  static const _bRahmania = 'branch-rahmania';
  static const _bNasserya = 'branch-nasserya';
  static const _bIndustrial = 'branch-industrial18';
  static const _bNouf = 'branch-nouf';

  // Stable coach IDs — match user-coach / user-td from Users below.
  static const _coachYassin = 'coach-yassin';
  static const _coachAli = 'coach-ali';
  static const _coachKhalid = 'coach-khalid';
  static const _coachOmar = 'coach-omar';
  static const _coachSalem = 'coach-salem';

  static SeedBundle build() {
    final now = DateTime.now();
    DateTime ago(int days) => now.subtract(Duration(days: days));

    final branches = <Branch>[
      Branch(
        id: _bRahmania,
        code: 'RAH',
        name: 'Al Rahmania',
        nameAr: 'الرحمانية',
        area: 'Al Rahmania',
        capacity: 120,
        focus: 'Competition & Poomsae',
        isMain: true,
        foundedAt: DateTime(2010, 1, 1),
      ),
      Branch(
        id: _bNasserya,
        code: 'NAS',
        name: 'Al Nasserya',
        nameAr: 'الناصرية',
        area: 'Al Nasserya',
        capacity: 80,
        focus: 'Youth Development',
        foundedAt: DateTime(2013, 3, 1),
      ),
      Branch(
        id: _bIndustrial,
        code: 'IND',
        name: 'Industrial 18',
        nameAr: 'الصناعية ١٨',
        area: 'Industrial Area 18',
        capacity: 60,
        focus: 'Fundamentals',
        foundedAt: DateTime(2015, 9, 1),
      ),
      Branch(
        id: _bNouf,
        code: 'NOF',
        name: 'Al Nouf',
        nameAr: 'النوف',
        area: 'Al Nouf',
        capacity: 70,
        focus: 'Sparring',
        foundedAt: DateTime(2017, 5, 1),
      ),
    ];

    final users = <User>[
      const User(
        id: 'user-owner',
        fullName: 'Ayman Maklad',
        fullNameAr: 'أيمن مقلد',
        role: Role.developer,
        primaryBranchId: _bRahmania,
        avatarSeed: 'ayman',
        email: 'gulflens.studio@gmail.com',
      ),
      const User(
        id: 'user-td',
        fullName: 'Dr. Ali Hassan',
        fullNameAr: 'د. علي حسن',
        role: Role.technicalDirector,
        primaryBranchId: _bRahmania,
        avatarSeed: 'ali',
      ),
      const User(
        id: 'user-coach',
        fullName: 'Yassin Ibrahim',
        fullNameAr: 'ياسين إبراهيم',
        role: Role.coach,
        primaryBranchId: _bRahmania,
        avatarSeed: 'yassin',
      ),
      const User(
        id: 'user-bm',
        fullName: 'Mariam Al Suwaidi',
        fullNameAr: 'مريم السويدي',
        role: Role.branchManager,
        primaryBranchId: _bNasserya,
        avatarSeed: 'mariam',
      ),
      const User(
        id: 'user-athlete',
        fullName: 'Hamad Al Mansoori',
        fullNameAr: 'حمد المنصوري',
        role: Role.athlete,
        primaryBranchId: _bRahmania,
        avatarSeed: 'hamad',
        linkedAthleteIds: ['ath-3'],
      ),
      const User(
        id: 'user-parent',
        fullName: 'Aisha Al Shamsi',
        fullNameAr: 'عائشة الشامسي',
        role: Role.parent,
        primaryBranchId: _bNasserya,
        avatarSeed: 'aisha',
        // Parent of Hessa (Al Nasserya) and Sultan (Industrial 18).
        linkedAthleteIds: ['ath-4', 'ath-6'],
      ),
    ];

    // ── Coaches ──────────────────────────────────────────────────────────────
    // Built from the user-coach and user-td seed users. Required fields use
    // conservative but realistic values; optional dossier fields left null.

    final coaches = <Coach>[
      Coach(
        id: _coachYassin,
        fullName: 'Yassin Ibrahim',
        fullNameAr: 'ياسين إبراهيم',
        primaryBranchId: _bRahmania,
        danRank: 4,
        wtCoachLicenceLevel: 2,
        firstAidExpiry: DateTime(2026, 6, 1),
        safeguardingExpiry: DateTime(2026, 9, 1),
        contractType: ContractType.fullTime,
        hiredAt: DateTime(2016, 1, 15),
        avatarSeed: 'yassin',
        email: 'yassin@shjsdsc.ae',
        nationality: 'EG',
        employmentStatus: CoachEmploymentStatus.active,
        nationalTeamStatus: CoachProgramStatus.none,
        olympicProgramStatus: CoachProgramStatus.none,
        coachLevel: CoachLevel.senior,
        technicalLevel: 4,
        sparringLevel: 5,
        poomsaeLevel: 3,
        fitnessLevel: 4,
        weeklyHoursTarget: 30,
        cpdHoursThisYear: 12,
        kukkiwonCertNumber: 'KUK-2016-YI',
        wtCoachLicenceExpiry: DateTime(2025, 12, 31),
        bio: 'Head sparring coach with 8+ years at SHJSDSC.',
        bioAr: 'مدرب كيوروغي رئيسي منذ أكثر من ٨ سنوات.',
      ),
      Coach(
        id: _coachAli,
        fullName: 'Dr. Ali Hassan',
        fullNameAr: 'د. علي حسن',
        primaryBranchId: _bRahmania,
        danRank: 7,
        wtCoachLicenceLevel: 3,
        firstAidExpiry: DateTime(2027, 1, 1),
        safeguardingExpiry: DateTime(2027, 4, 1),
        contractType: ContractType.partTime,
        hiredAt: DateTime(2010, 9, 1),
        avatarSeed: 'ali',
        email: 'ali@shjsdsc.ae',
        nationality: 'AE',
        employmentStatus: CoachEmploymentStatus.active,
        nationalTeamStatus: CoachProgramStatus.leadStaff,
        olympicProgramStatus: CoachProgramStatus.leadStaff,
        coachLevel: CoachLevel.head,
        technicalLevel: 5,
        sparringLevel: 5,
        poomsaeLevel: 5,
        fitnessLevel: 4,
        weeklyHoursTarget: 20,
        cpdHoursThisYear: 24,
        kukkiwonCertNumber: 'KUK-2009-AH',
        wtCoachLicenceExpiry: DateTime(2026, 8, 31),
        bio: 'Technical Director and founding head coach.',
        bioAr: 'المدير الفني والمدرب الرئيسي المؤسس.',
      ),
      Coach(
        id: _coachKhalid,
        fullName: 'Khalid Al Beloushi',
        fullNameAr: 'خالد البلوشي',
        primaryBranchId: _bNasserya,
        danRank: 3,
        wtCoachLicenceLevel: 1,
        firstAidExpiry: DateTime(2026, 3, 1),
        safeguardingExpiry: DateTime(2026, 2, 1),
        contractType: ContractType.fullTime,
        hiredAt: DateTime(2018, 8, 1),
        avatarSeed: 'khalid',
        email: 'khalid@shjsdsc.ae',
        nationality: 'AE',
        employmentStatus: CoachEmploymentStatus.active,
        coachLevel: CoachLevel.junior,
        technicalLevel: 3,
        sparringLevel: 4,
        poomsaeLevel: 3,
        fitnessLevel: 4,
        weeklyHoursTarget: 28,
        cpdHoursThisYear: 8,
        kukkiwonCertNumber: 'KUK-2018-KB',
        bio: 'Youth development lead at Al Nasserya.',
        bioAr: 'مسؤول تطوير الناشئين في الناصرية.',
      ),
      Coach(
        id: _coachOmar,
        fullName: 'Omar Farouk',
        fullNameAr: 'عمر فاروق',
        primaryBranchId: _bIndustrial,
        danRank: 2,
        wtCoachLicenceLevel: 1,
        firstAidExpiry: DateTime(2025, 11, 1),
        safeguardingExpiry: DateTime(2026, 1, 15),
        contractType: ContractType.partTime,
        hiredAt: DateTime(2020, 2, 1),
        avatarSeed: 'omar',
        email: 'omar@shjsdsc.ae',
        nationality: 'EG',
        employmentStatus: CoachEmploymentStatus.active,
        coachLevel: CoachLevel.assistant,
        technicalLevel: 3,
        sparringLevel: 3,
        poomsaeLevel: 2,
        fitnessLevel: 3,
        weeklyHoursTarget: 18,
        cpdHoursThisYear: 6,
        bio: 'Fundamentals coach at Industrial 18.',
        bioAr: 'مدرب الأساسيات في الصناعية ١٨.',
      ),
      Coach(
        id: _coachSalem,
        fullName: 'Salem Al Ameri',
        fullNameAr: 'سالم العامري',
        primaryBranchId: _bNouf,
        danRank: 4,
        wtCoachLicenceLevel: 2,
        firstAidExpiry: DateTime(2026, 7, 1),
        safeguardingExpiry: DateTime(2026, 10, 1),
        contractType: ContractType.fullTime,
        hiredAt: DateTime(2017, 10, 1),
        avatarSeed: 'salem',
        email: 'salem@shjsdsc.ae',
        nationality: 'AE',
        employmentStatus: CoachEmploymentStatus.active,
        coachLevel: CoachLevel.senior,
        technicalLevel: 4,
        sparringLevel: 4,
        poomsaeLevel: 4,
        fitnessLevel: 3,
        weeklyHoursTarget: 30,
        cpdHoursThisYear: 14,
        kukkiwonCertNumber: 'KUK-2017-SA',
        wtCoachLicenceExpiry: DateTime(2026, 5, 31),
        bio: 'Sparring head coach at Al Nouf.',
        bioAr: 'مدرب القتال الرئيسي في النوف.',
      ),
    ];

    // ── Athletes ──────────────────────────────────────────────────────────────

    final roster = <_Seed>[
      _Seed(
        'ath-1',
        1001,
        'Rashid Al Ketbi',
        'راشد الكتبي',
        _bRahmania,
        _coachYassin,
        BeltColor.black,
        BeltKind.dan,
        1,
        62,
        AthleteStatus.competitionTeam,
        2009,
      ),
      _Seed(
        'ath-2',
        1002,
        'Ahmed Al Hammadi',
        'أحمد الحمادي',
        _bRahmania,
        _coachYassin,
        BeltColor.red,
        BeltKind.gup,
        2,
        58,
        AthleteStatus.readyToGrade,
        2010,
      ),
      _Seed(
        'ath-3',
        1003,
        'Hamad Al Mansoori',
        'حمد المنصوري',
        _bRahmania,
        _coachYassin,
        BeltColor.blue,
        BeltKind.gup,
        4,
        45,
        AthleteStatus.active,
        2012,
      ),
      _Seed(
        'ath-4',
        1004,
        'Hessa Al Shamsi',
        'حصة الشامسي',
        _bNasserya,
        _coachKhalid,
        BeltColor.green,
        BeltKind.gup,
        6,
        41,
        AthleteStatus.watch,
        2013,
      ),
      _Seed(
        'ath-5',
        1005,
        'Maitha Al Nuaimi',
        'ميثاء النعيمي',
        _bNasserya,
        _coachKhalid,
        BeltColor.black,
        BeltKind.dan,
        2,
        55,
        AthleteStatus.competitionTeam,
        2007,
      ),
      _Seed(
        'ath-6',
        1006,
        'Sultan Al Dhaheri',
        'سلطان الظاهري',
        _bIndustrial,
        _coachOmar,
        BeltColor.yellow,
        BeltKind.gup,
        8,
        33,
        AthleteStatus.active,
        2015,
      ),
      _Seed(
        'ath-7',
        1007,
        'Fatima Al Zaabi',
        'فاطمة الزعابي',
        _bIndustrial,
        _coachOmar,
        BeltColor.white,
        BeltKind.gup,
        10,
        28,
        AthleteStatus.rest,
        2017,
      ),
      _Seed(
        'ath-8',
        1008,
        'Khalifa Al Romaithi',
        'خليفة الرميثي',
        _bNouf,
        _coachSalem,
        BeltColor.red,
        BeltKind.poom,
        1,
        38,
        AthleteStatus.readyToGrade,
        2014,
      ),
    ];

    final athletes = <Athlete>[];
    final scores = <PerformanceScore>[];
    for (final s in roster) {
      athletes.add(
        Athlete(
          id: s.id,
          memberNumber: s.member,
          fullName: s.name,
          fullNameAr: s.nameAr,
          dateOfBirth: DateTime(s.birthYear, 4, 15),
          gender: s.name.contains(RegExp('Hessa|Maitha|Fatima'))
              ? Gender.female
              : Gender.male,
          branchId: s.branch,
          primaryCoachId: s.coach,
          joinedAt: ago(900),
          currentBelt: Belt(
            color: s.color,
            kind: s.kind,
            number: s.beltNo,
            awardedAt: ago(180),
          ),
          weightKg: s.weight,
          status: s.status,
          avatarSeed: s.id,
          heightCm: 150 + (s.member % 40),
          // Deterministic blood type (skips `unknown`) so every Medical tab has
          // vitals; richer dossiers are layered on showcase athletes below.
          bloodType: BloodType.values[s.member % 8],
        ),
      );
      scores.add(s.score());
    }

    // ── Coaching pathway: promote two athletes to assistant coaches ──────────
    // An assistant coach IS an athlete carrying a coaching dossier (SSDC
    // development pathway). Applied via JSON round-trip so the rest of the
    // athlete fields are preserved untouched.
    void promote(String id, AssistantCoachProfile profile) {
      final idx = athletes.indexWhere((a) => a.id == id);
      if (idx < 0) return;
      final json = athletes[idx].toJson();
      json['programRoles'] = ['athlete', 'assistantCoach', 'competitionTeam'];
      json['assistantCoach'] = profile.toJson();
      athletes[idx] = Athlete.fromJson(json);
    }

    promote(
      'ath-2', // Ahmed, mentored by Yassin at Al Rahmania
      AssistantCoachProfile(
        supervisingCoachId: _coachYassin,
        primaryBranchId: _bRahmania,
        developmentLevel: DevelopmentLevel.assistantCoach,
        startedCoachingAt: ago(400),
        assistedSessionCount: 48,
        evaluations: [
          CoachingEvaluation(
            id: 'eval-ahmed-1',
            date: ago(30),
            evaluatorCoachId: _coachYassin,
            evaluatorName: 'Yassin Ibrahim',
            overallScore: 4,
            reliability: 4,
            leadership: 4,
            notes: 'Reliable warm-up lead; growing rapport with cadets.',
          ),
        ],
      ),
    );
    promote(
      'ath-8', // Khalifa, mentored by Salem at Al Nouf
      AssistantCoachProfile(
        supervisingCoachId: _coachSalem,
        primaryBranchId: _bNouf,
        developmentLevel: DevelopmentLevel.juniorCoach,
        startedCoachingAt: ago(700),
        assistedSessionCount: 96,
        evaluations: [
          CoachingEvaluation(
            id: 'eval-khalifa-1',
            date: ago(20),
            evaluatorCoachId: _coachSalem,
            evaluatorName: 'Salem Al Ameri',
            overallScore: 5,
            reliability: 5,
            leadership: 4,
            notes: 'Runs sparring rounds independently. Ready for junior coach.',
          ),
        ],
      ),
    );

    // ── Medical dossiers on showcase athletes (JSON round-trip) ─────────────
    void medical(
      String id, {
      List<String> allergies = const [],
      List<String> conditions = const [],
      List<String> medications = const [],
      List<InjuryEntry> injuries = const [],
      List<WeightEntry> weights = const [],
      bool fitToTrain = true,
    }) {
      final idx = athletes.indexWhere((a) => a.id == id);
      if (idx < 0) return;
      final json = athletes[idx].toJson();
      json['allergies'] = allergies;
      json['medicalConditions'] = conditions;
      json['medications'] = medications;
      json['injuries'] = injuries.map((e) => e.toJson()).toList();
      json['weightHistory'] = weights.map((e) => e.toJson()).toList();
      json['fitToTrain'] = fitToTrain;
      athletes[idx] = Athlete.fromJson(json);
    }

    List<WeightEntry> weightSeries(String id, double start) => [
          for (var w = 0; w < 5; w++)
            WeightEntry(
              id: 'wt-$id-$w',
              recordedAt: ago(w * 14),
              weightKg: start - (4 - w) * 0.4,
            ),
        ];

    medical(
      'ath-1',
      allergies: const ['Penicillin'],
      conditions: const ['Mild asthma'],
      medications: const ['Salbutamol inhaler (PRN)'],
      weights: weightSeries('ath-1', 62),
      injuries: [
        InjuryEntry(
          id: 'inj-ath1-1',
          recordedAt: ago(120),
          description: 'Left ankle sprain',
          severity: InjurySeverity.moderate,
          returnToTrainAt: ago(95),
          notes: 'Full recovery; taped for sparring since.',
        ),
      ],
    );
    medical(
      'ath-3',
      allergies: const ['Peanuts'],
      weights: weightSeries('ath-3', 45),
      fitToTrain: false,
      injuries: [
        InjuryEntry(
          id: 'inj-ath3-1',
          recordedAt: ago(10),
          description: 'Right knee strain',
          severity: InjurySeverity.minor,
          notes: 'Rest 2 weeks; light technical work only.',
        ),
      ],
    );

    // ── Coach notes on showcase athletes (JSON round-trip) ──────────────────
    void notes(String id, List<CoachNote> list) {
      final idx = athletes.indexWhere((a) => a.id == id);
      if (idx < 0) return;
      final json = athletes[idx].toJson();
      json['coachNotes'] = list.map((n) => n.toJson()).toList();
      athletes[idx] = Athlete.fromJson(json);
    }

    notes('ath-1', [
      CoachNote(
        id: 'note-ath1-1',
        authorCoachId: _coachYassin,
        authorName: 'Yassin Ibrahim',
        date: ago(5),
        category: CoachNoteCategory.technical,
        body: 'Sharp turning kicks. Needs a faster reset after scoring.',
        isPinned: true,
      ),
      CoachNote(
        id: 'note-ath1-2',
        authorCoachId: _coachYassin,
        authorName: 'Yassin Ibrahim',
        date: ago(20),
        category: CoachNoteCategory.behavioural,
        body: 'Excellent leadership warming up the cadets group.',
      ),
      CoachNote(
        id: 'note-ath1-3',
        authorCoachId: _coachAli,
        authorName: 'Dr. Ali Hassan',
        date: ago(45),
        category: CoachNoteCategory.tactical,
        body: 'Manage the clock better when leading late in the round.',
      ),
    ]);
    notes('ath-3', [
      CoachNote(
        id: 'note-ath3-1',
        authorCoachId: _coachYassin,
        authorName: 'Yassin Ibrahim',
        date: ago(10),
        category: CoachNoteCategory.medical,
        body: 'On light duty — knee strain. Technical work only for 2 weeks.',
        isPinned: true,
      ),
      CoachNote(
        id: 'note-ath3-2',
        authorCoachId: _coachYassin,
        authorName: 'Yassin Ibrahim',
        date: ago(8),
        category: CoachNoteCategory.general,
        body: 'Improving steadily; ready to move up a training group soon.',
      ),
    ]);

    // ── Belt progression + emergency contacts on showcase athletes ──────────
    void extras(
      String id, {
      List<Belt> beltHistory = const [],
      List<EmergencyContact> contacts = const [],
    }) {
      final idx = athletes.indexWhere((a) => a.id == id);
      if (idx < 0) return;
      final json = athletes[idx].toJson();
      json['beltHistory'] = beltHistory.map((b) => b.toJson()).toList();
      json['emergencyContacts'] = contacts.map((c) => c.toJson()).toList();
      athletes[idx] = Athlete.fromJson(json);
    }

    extras(
      'ath-1',
      beltHistory: [
        Belt(color: BeltColor.white, kind: BeltKind.gup, number: 10, awardedAt: ago(1600)),
        Belt(color: BeltColor.green, kind: BeltKind.gup, number: 6, awardedAt: ago(1150)),
        Belt(color: BeltColor.blue, kind: BeltKind.gup, number: 4, awardedAt: ago(750)),
        Belt(color: BeltColor.red, kind: BeltKind.gup, number: 1, awardedAt: ago(400)),
      ],
      contacts: const [
        EmergencyContact(
            id: 'ec-ath1-1', name: 'Mona Al Ketbi', relationship: 'Mother', phone: '+971 50 123 4567'),
      ],
    );
    extras(
      'ath-3',
      contacts: const [
        EmergencyContact(
            id: 'ec-ath3-1', name: 'Saeed Al Mansoori', relationship: 'Father', phone: '+971 55 987 6543'),
      ],
    );

    // ── Documents on showcase athletes (JSON round-trip) ────────────────────
    void documents(String id, List<AthleteDocument> docs) {
      final idx = athletes.indexWhere((a) => a.id == id);
      if (idx < 0) return;
      final json = athletes[idx].toJson();
      json['documents'] = docs.map((d) => d.toJson()).toList();
      athletes[idx] = Athlete.fromJson(json);
    }

    documents('ath-1', [
      AthleteDocument(
        id: 'doc-ath1-1',
        kind: AthleteDocumentKind.emiratesID,
        issuedAt: ago(700),
        expiresAt: now.add(const Duration(days: 730)),
      ),
      AthleteDocument(
        id: 'doc-ath1-2',
        kind: AthleteDocumentKind.federationLicence,
        issuedAt: ago(340),
        expiresAt: now.add(const Duration(days: 20)), // expiring soon
      ),
      AthleteDocument(
        id: 'doc-ath1-3',
        kind: AthleteDocumentKind.medicalClearance,
        issuedAt: ago(60),
        expiresAt: now.add(const Duration(days: 200)),
      ),
    ]);
    documents('ath-3', [
      AthleteDocument(
        id: 'doc-ath3-1',
        kind: AthleteDocumentKind.emiratesID,
        issuedAt: ago(500),
        expiresAt: now.add(const Duration(days: 900)),
      ),
      AthleteDocument(
        id: 'doc-ath3-2',
        kind: AthleteDocumentKind.worldTaekwondoCard,
        issuedAt: ago(400),
        expiresAt: ago(10), // expired
      ),
    ]);

    // ── Goals ────────────────────────────────────────────────────────────────
    final goals = <Goal>[
      Goal(
        id: 'goal-ath1-1',
        athleteId: 'ath-1',
        title: 'Win gold at the UAE Junior Open',
        status: GoalStatus.completed,
        createdAt: ago(120),
        completedAt: ago(30),
      ),
      Goal(
        id: 'goal-ath1-2',
        athleteId: 'ath-1',
        title: 'Achieve 2nd Dan black belt',
        targetDate: now.add(const Duration(days: 240)),
        status: GoalStatus.active,
        createdAt: ago(60),
      ),
      Goal(
        id: 'goal-ath3-1',
        athleteId: 'ath-3',
        title: 'Move up to the competition team',
        targetDate: now.add(const Duration(days: 120)),
        status: GoalStatus.active,
        createdAt: ago(40),
      ),
    ];

    // ── Class sessions (today + next 2 days), one coach per branch ───────────
    final branchCoach = <String, String>{
      _bRahmania: _coachYassin,
      _bNasserya: _coachKhalid,
      _bIndustrial: _coachOmar,
      _bNouf: _coachSalem,
    };
    final today = DateTime(now.year, now.month, now.day);
    DateTime at(int dayOffset, int hour, int minute) =>
        today.add(Duration(days: dayOffset, hours: hour, minutes: minute));

    const dayPlan = <(int, int, ClassDiscipline, AgeGroup)>[
      (0, 17, ClassDiscipline.fundamentals, AgeGroup.cadets),
      (0, 18, ClassDiscipline.kyorugi, AgeGroup.juniors),
      (1, 17, ClassDiscipline.poomsae, AgeGroup.cadets),
    ];

    final sessions = <ClassSession>[];
    for (final b in branches) {
      final coachId = branchCoach[b.id] ?? _coachYassin;
      final enrolled =
          athletes.where((a) => a.branchId == b.id).map((a) => a.id).toList();
      var n = 0;
      for (final (dayOffset, hour, discipline, ageGroup) in dayPlan) {
        n++;
        sessions.add(ClassSession(
          id: 'sess-${b.code}-$n',
          title: '${b.name} ${discipline.name}',
          discipline: discipline,
          branchId: b.id,
          coachId: coachId,
          startsAt: at(dayOffset, hour, 30),
          endsAt: at(dayOffset, hour + 1, 30),
          capacity: 20,
          enrolledAthleteIds: enrolled,
          ageGroup: ageGroup,
        ));
      }
    }

    // ── Grading sessions ─────────────────────────────────────────────────────
    final gradingSessions = <GradingSession>[
      GradingSession(
        id: 'grade-rah-1',
        scheduledAt: at(0, 16, 0), // today
        branchId: _bRahmania,
        examinerCoachIds: const [_coachAli, _coachYassin],
        candidateAthleteIds: const ['ath-1'],
        status: GradingSessionStatus.inProgress,
      ),
      GradingSession(
        id: 'grade-rah-2',
        scheduledAt: at(7, 16, 0), // next week
        branchId: _bRahmania,
        examinerCoachIds: const [_coachAli],
        candidateAthleteIds: const ['ath-2', 'ath-3'],
        status: GradingSessionStatus.scheduled,
      ),
      GradingSession(
        id: 'grade-nouf-1',
        scheduledAt: at(10, 16, 0),
        branchId: _bNouf,
        examinerCoachIds: const [_coachSalem],
        candidateAthleteIds: const ['ath-8'],
        status: GradingSessionStatus.scheduled,
      ),
    ];

    // ── Performance entries (multi-week series for trend charts) ─────────────
    final perfAthletes = <(String, String)>[
      ('ath-1', _coachYassin),
      ('ath-2', _coachYassin),
      ('ath-3', _coachYassin),
      ('ath-8', _coachSalem),
    ];
    final physicalMetrics = <PhysicalMetric>[];
    final technicalSkills = <TechnicalSkill>[];
    final wellness = <WellnessEntry>[];
    final firstTechnique = TechniqueKind.values.first;
    for (final (aid, cid) in perfAthletes) {
      // 6 weekly captures; recent weeks (lower w) score higher.
      for (var w = 0; w < 6; w++) {
        final dt = ago(w * 7);
        final lift = 5 - w; // 0…5, larger = more recent
        physicalMetrics.add(PhysicalMetric(
          id: 'pm-$aid-plank-$w',
          athleteId: aid,
          recordedAt: dt,
          recordedByCoachId: cid,
          kind: PhysicalMetricKind.plankSec,
          value: 80 + lift * 12,
        ));
        physicalMetrics.add(PhysicalMetric(
          id: 'pm-$aid-rk-$w',
          athleteId: aid,
          recordedAt: dt,
          recordedByCoachId: cid,
          kind: PhysicalMetricKind.roundhouseKicks10s,
          value: 22 + lift * 2,
        ));
        technicalSkills.add(TechnicalSkill(
          id: 'ts-$aid-$w',
          athleteId: aid,
          recordedAt: dt,
          recordedByCoachId: cid,
          kind: firstTechnique,
          formScore: 5 + lift,
          applicationScore: 4 + lift,
        ));
      }
      // 10 recent daily wellness check-ins.
      for (var d = 0; d < 10; d++) {
        wellness.add(WellnessEntry(
          id: 'wl-$aid-$d',
          athleteId: aid,
          recordedAt: ago(d),
          sleepHours: 7 + (d % 3) * 0.5,
          mood: 6 + (d % 3),
          soreness: 3 + (d % 2),
          motivation: 7,
          stress: 4,
          rpePreviousSession: 5 + (d % 3),
        ));
      }
    }

    // ── Announcements ────────────────────────────────────────────────────────
    final announcements = <Announcement>[
      Announcement(
        id: 'ann-1',
        title: 'Spring Grading — Registration Open',
        titleAr: 'فتح التسجيل لاختبارات الترقية الربيعية',
        body: 'Belt-test registration is now open for all eligible athletes.',
        bodyAr: 'التسجيل لاختبار الأحزمة متاح الآن لجميع اللاعبين المؤهلين.',
        audience: AnnouncementAudience.all,
        publishedAt: ago(1),
        publishedByUserId: 'user-td',
        category: AnnouncementCategory.grading,
        authorName: 'Dr. Ali Hassan',
        requiresRsvp: true,
        rsvpDeadline: now.add(const Duration(days: 14)),
      ),
      Announcement(
        id: 'ann-2',
        title: 'UAE Junior Open — Team Selected',
        titleAr: 'بطولة الإمارات للناشئين — اختيار الفريق',
        body: 'The competition squad for the UAE Junior Open has been announced.',
        bodyAr: 'تم الإعلان عن فريق المنافسات لبطولة الإمارات للناشئين.',
        audience: AnnouncementAudience.athletes,
        publishedAt: ago(4),
        publishedByUserId: 'user-coach',
        category: AnnouncementCategory.tournament,
        authorName: 'Yassin Ibrahim',
      ),
      Announcement(
        id: 'ann-3',
        title: 'Ramadan Training Schedule',
        titleAr: 'جدول التدريب في رمضان',
        body: 'Adjusted class times apply during Ramadan. See your branch page.',
        bodyAr: 'تطبق أوقات حصص معدّلة خلال رمضان. راجع صفحة فرعك.',
        audience: AnnouncementAudience.parents,
        publishedAt: ago(7),
        publishedByUserId: 'user-bm',
        category: AnnouncementCategory.policy,
        authorName: 'Mariam Al Suwaidi',
      ),
      Announcement(
        id: 'ann-4',
        title: 'Al Nouf — Maintenance Closure',
        titleAr: 'النوف — إغلاق للصيانة',
        body: 'Al Nouf hall will be closed next weekend for floor maintenance.',
        bodyAr: 'سيُغلق فرع النوف نهاية الأسبوع القادم لصيانة الأرضية.',
        audience: AnnouncementAudience.all,
        publishedAt: ago(0),
        publishedByUserId: 'user-owner',
        status: AnnouncementStatus.scheduled,
        category: AnnouncementCategory.general,
        scheduledAt: now.add(const Duration(days: 5)),
        authorName: 'Ayman Maklad',
      ),
    ];

    // ── Certifications (mixed severities for the compliance dashboard) ───────
    Certification cert(
      String id,
      String coachId,
      CertificationKind kind,
      String issuer,
      int expiresInDays,
    ) => Certification(
      id: id,
      coachId: coachId,
      kind: kind,
      issuer: issuer,
      issuedAt: ago(365),
      expiresAt: now.add(Duration(days: expiresInDays)),
    );
    final certifications = <Certification>[
      cert('cert-1', _coachYassin, CertificationKind.firstAid, 'Emirates Red Crescent', -20), // expired
      cert('cert-2', _coachYassin, CertificationKind.safeguarding, 'UAE TF', 35), // expiring
      cert('cert-3', _coachYassin, CertificationKind.wtCoaching, 'World Taekwondo', 220), // ok
      cert('cert-4', _coachAli, CertificationKind.wtCoaching, 'World Taekwondo', 400),
      cert('cert-5', _coachAli, CertificationKind.doping, 'ITA', 300),
      cert('cert-6', _coachKhalid, CertificationKind.safeguarding, 'UAE TF', 50), // expiring
      cert('cert-7', _coachOmar, CertificationKind.firstAid, 'Emirates Red Crescent', -5), // expired
      cert('cert-8', _coachSalem, CertificationKind.refereeing, 'UAE TF', 150),
    ];

    // ── Audit log ────────────────────────────────────────────────────────────
    final auditEntries = <AuditEntry>[
      AuditEntry(
        id: 'audit-1',
        at: ago(0),
        actorUserId: 'user-coach',
        action: 'recorded attendance',
        targetEntity: 'session',
        targetId: 'sess-RAH-1',
      ),
      AuditEntry(
        id: 'audit-2',
        at: ago(1),
        actorUserId: 'user-td',
        action: 'updated grading session',
        targetEntity: 'gradingSession',
        targetId: 'grade-rah-1',
      ),
      AuditEntry(
        id: 'audit-3',
        at: ago(2),
        actorUserId: 'user-bm',
        action: 'published announcement',
        targetEntity: 'announcement',
        targetId: 'ann-3',
      ),
      AuditEntry(
        id: 'audit-4',
        at: ago(3),
        actorUserId: 'user-owner',
        action: 'edited branch profile',
        targetEntity: 'branch',
        targetId: _bNouf,
      ),
    ];

    // ── Tournaments + registrations + weight-cut ────────────────────────────
    final tournaments = <Tournament>[
      Tournament(
        id: 'trn-1',
        name: 'UAE Junior Open 2026',
        nameAr: 'بطولة الإمارات المفتوحة للناشئين ٢٠٢٦',
        hostingFederation: HostingFederation.uae,
        startsAt: ago(30),
        endsAt: ago(29),
        location: 'Abu Dhabi',
        locationAr: 'أبوظبي',
        isOfficial: true,
        level: EventLevel.national,
        weightCategoriesOffered: const [
          WeightCategory.juniorsUnder63,
          WeightCategory.seniorsUnder58,
        ],
      ),
      Tournament(
        id: 'trn-2',
        name: 'GCC Championship',
        nameAr: 'بطولة الخليج',
        hostingFederation: HostingFederation.gcc,
        startsAt: now.add(const Duration(days: 20)),
        endsAt: now.add(const Duration(days: 22)),
        location: 'Dubai',
        locationAr: 'دبي',
        isOfficial: true,
        level: EventLevel.regional,
        weightCategoriesOffered: const [
          WeightCategory.juniorsUnder63,
          WeightCategory.seniorsUnder58,
        ],
      ),
      Tournament(
        id: 'trn-3',
        name: 'Sharjah Club Open',
        nameAr: 'بطولة الشارقة للأندية',
        hostingFederation: HostingFederation.clubInternal,
        startsAt: now.add(const Duration(days: 45)),
        endsAt: now.add(const Duration(days: 45)),
        location: 'Sharjah',
        locationAr: 'الشارقة',
        isOfficial: false,
        level: EventLevel.local,
      ),
    ];

    final registrations = <TournamentRegistration>[
      TournamentRegistration(
        id: 'reg-1',
        tournamentId: 'trn-1',
        athleteId: 'ath-1',
        weightCategory: WeightCategory.juniorsUnder63,
        registeredAt: ago(40),
        status: RegistrationStatus.weighedIn,
        ageDivisionEntered: AgeGroup.juniors,
        bracketSize: 8,
        finalPosition: 1,
        medal: MedalType.gold,
      ),
      TournamentRegistration(
        id: 'reg-2',
        tournamentId: 'trn-1',
        athleteId: 'ath-5',
        weightCategory: WeightCategory.seniorsUnder58,
        registeredAt: ago(40),
        status: RegistrationStatus.weighedIn,
        ageDivisionEntered: AgeGroup.seniors,
        bracketSize: 8,
        finalPosition: 3,
        medal: MedalType.bronze,
      ),
      TournamentRegistration(
        id: 'reg-3',
        tournamentId: 'trn-2',
        athleteId: 'ath-1',
        weightCategory: WeightCategory.juniorsUnder63,
        registeredAt: ago(3),
      ),
      TournamentRegistration(
        id: 'reg-4',
        tournamentId: 'trn-2',
        athleteId: 'ath-5',
        weightCategory: WeightCategory.seniorsUnder58,
        registeredAt: ago(3),
      ),
    ];

    // reg-3 (ath-1) cutting toward 63 kg ahead of the GCC Championship.
    final weightCuts = <WeightCutEntry>[
      for (var i = 0; i < 5; i++)
        WeightCutEntry(
          id: 'wc-reg3-$i',
          registrationId: 'reg-3',
          recordedAt: ago(12 - i * 3),
          currentKg: 66.0 - i * 0.7,
          targetKg: 63.0,
        ),
    ];

    // ── Attendance history (6 weeks × 3/wk per athlete, ~80% present) ───────
    // Powers the Athlete Attendance tab + branch avgAttendancePct + grading
    // eligibility, which all read attendance records.
    final attendance = <AttendanceRecord>[];
    for (final a in athletes) {
      for (var w = 0; w < 6; w++) {
        for (var s = 0; s < 3; s++) {
          final roll = (a.memberNumber + w * 3 + s) % 10;
          final state = roll < 8
              ? AttendanceState.present
              : (roll == 8 ? AttendanceState.late : AttendanceState.absent);
          attendance.add(AttendanceRecord(
            id: 'att-${a.id}-$w-$s',
            sessionId: 'past-sess-${a.branchId}-$w-$s',
            athleteId: a.id,
            state: state,
            recordedAt: ago(w * 7 + s * 2),
            effortRating: state == AttendanceState.present
                ? 3 + ((a.memberNumber + w) % 3)
                : null,
          ));
        }
      }
    }

    // ── Bracket for the past UAE Junior Open (juniorsUnder63, 8 athletes) ────
    // Hand-authored single-elimination tree; champion = Rashid (ath-1),
    // consistent with his seeded gold medal at trn-1.
    final brackets = <Bracket>[
      Bracket(
        id: 'brk-trn1',
        tournamentId: 'trn-1',
        weightCategory: WeightCategory.juniorsUnder63,
        seeds: const [
          'ath-1', 'ath-8', 'ath-4', 'ath-5', //
          'ath-2', 'ath-7', 'ath-3', 'ath-6',
        ],
        generatedAt: ago(31),
      ),
    ];
    BracketMatch bm(int round, int pos, String a, String b, String winner) =>
        BracketMatch(
          id: 'bm-$round-$pos',
          bracketId: 'brk-trn1',
          round: round,
          position: pos,
          athleteAId: a,
          athleteBId: b,
          winnerId: winner,
        );
    final bracketMatches = <BracketMatch>[
      // Round 1 — quarterfinals
      bm(1, 0, 'ath-1', 'ath-8', 'ath-1'),
      bm(1, 1, 'ath-4', 'ath-5', 'ath-5'),
      bm(1, 2, 'ath-2', 'ath-7', 'ath-2'),
      bm(1, 3, 'ath-3', 'ath-6', 'ath-3'),
      // Round 2 — semifinals
      bm(2, 0, 'ath-1', 'ath-5', 'ath-1'),
      bm(2, 1, 'ath-2', 'ath-3', 'ath-2'),
      // Round 3 — final
      bm(3, 0, 'ath-1', 'ath-2', 'ath-1'),
    ];

    return SeedBundle(
      branches: branches,
      users: users,
      athletes: athletes,
      scores: scores,
      coaches: coaches,
      sessions: sessions,
      gradingSessions: gradingSessions,
      physicalMetrics: physicalMetrics,
      technicalSkills: technicalSkills,
      wellness: wellness,
      announcements: announcements,
      certifications: certifications,
      auditEntries: auditEntries,
      tournaments: tournaments,
      registrations: registrations,
      weightCuts: weightCuts,
      attendance: attendance,
      brackets: brackets,
      bracketMatches: bracketMatches,
      goals: goals,
    );
  }
}

class _Seed {
  final String id;
  final int member;
  final String name;
  final String nameAr;
  final String branch;
  final String? coach;
  final BeltColor color;
  final BeltKind kind;
  final int beltNo;
  final double weight;
  final AthleteStatus status;
  final int birthYear;

  _Seed(
    this.id,
    this.member,
    this.name,
    this.nameAr,
    this.branch,
    this.coach,
    this.color,
    this.kind,
    this.beltNo,
    this.weight,
    this.status,
    this.birthYear,
  );

  /// Deterministic-but-varied pillar scores derived from the member number.
  PerformanceScore score() {
    double v(int salt, double base) =>
        (base + ((member + salt) % 18) - 6).clamp(35, 99).toDouble();
    return PerformanceScore(
      id: 'score-$id',
      athleteId: id,
      competition: v(1, 78),
      technical: v(2, 82),
      physical: v(3, 75),
      adherence: v(4, 85),
      beltProgression: v(5, 70),
      wellness: v(6, 80),
      character: v(7, 88),
    );
  }
}
