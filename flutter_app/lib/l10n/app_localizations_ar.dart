// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class L10nAr extends L10n {
  L10nAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'تايكوندو شهامة';

  @override
  String get navAthletes => 'اللاعبون';

  @override
  String get settingsRole => 'الدور';

  @override
  String get actionCancel => 'إلغاء';

  @override
  String get actionRetry => 'إعادة المحاولة';

  @override
  String get loadFailed => 'تعذّر تحميل البيانات';

  @override
  String get athletesTitle => 'اللاعبون';

  @override
  String get athletesSearch => 'ابحث عن لاعب';

  @override
  String get athletesEmpty => 'لا يوجد لاعبون بعد';

  @override
  String get athleteCompositeScore => 'المؤشر العام';

  @override
  String get athleteOverview => 'نظرة عامة';

  @override
  String athleteMemberNo(int number) {
    return 'عضو رقم $number';
  }

  @override
  String athleteAge(int years) {
    return '$years سنة';
  }

  @override
  String athleteWeightFmt(String kg) {
    return '$kg كجم';
  }

  @override
  String get beltWhite => 'الحزام الأبيض';

  @override
  String get beltYellow => 'الحزام الأصفر';

  @override
  String get beltGreen => 'الحزام الأخضر';

  @override
  String get beltBlue => 'الحزام الأزرق';

  @override
  String get beltRed => 'الحزام الأحمر';

  @override
  String get beltBlack => 'الحزام الأسود';

  @override
  String get statusCompetitionTeam => 'فريق المنافسات';

  @override
  String get statusReadyToGrade => 'جاهز للترقية';

  @override
  String get statusWatch => 'تحت المتابعة';

  @override
  String get statusRest => 'راحة';

  @override
  String get statusActive => 'نشط';

  @override
  String get ageCubs => 'الأشبال';

  @override
  String get ageKids => 'الأطفال';

  @override
  String get ageCadets => 'الناشئون';

  @override
  String get ageJuniors => 'الشباب';

  @override
  String get ageSeniors => 'الكبار';

  @override
  String get ageMasters => 'المخضرمون';

  @override
  String get navCoaches => 'المدربون';

  @override
  String get coachesTitle => 'المدربون';

  @override
  String get coachesSearch => 'ابحث عن مدرب';

  @override
  String get coachesEmpty => 'لا يوجد مدربون بعد';

  @override
  String get coachOverview => 'الكفاءة';

  @override
  String get coachTabOverview => 'نظرة عامة';

  @override
  String get coachTabAthletes => 'اللاعبون';

  @override
  String get coachTabCertifications => 'الشهادات';

  @override
  String get coachTabCompetitions => 'المنافسات';

  @override
  String get coachCompEmpty => 'لا توجد نتائج منافسات';

  @override
  String get coachNoAthletes => 'لا يوجد لاعبون معيّنون';

  @override
  String coachDanRank(int dan) {
    return 'دان $dan';
  }

  @override
  String coachYearsExp(int years) {
    return '$years سنة خبرة';
  }

  @override
  String coachAthletesCount(int count) {
    return '$count لاعب';
  }

  @override
  String get coachCertExpiry => 'أقرب انتهاء شهادة';

  @override
  String get coachNoCerts => 'لا توجد شهادات مسجلة';

  @override
  String get coachLevelAssistant => 'مدرب مساعد';

  @override
  String get coachLevelJunior => 'مدرب مبتدئ';

  @override
  String get coachLevelSenior => 'مدرب أول';

  @override
  String get coachLevelHead => 'مدرب رئيسي';

  @override
  String get coachLevelNational => 'مدرب وطني';

  @override
  String get coachLevelInternational => 'مدرب دولي';

  @override
  String get coachEmpActive => 'نشط';

  @override
  String get coachEmpLeave => 'في إجازة';

  @override
  String get coachEmpTransferred => 'منقول';

  @override
  String get coachEmpRetired => 'متقاعد';

  @override
  String get coachEmpSuspended => 'موقوف';

  @override
  String get competencyTechnical => 'تقني';

  @override
  String get competencySparring => 'قتال';

  @override
  String get competencyPoomsae => 'بومسيه';

  @override
  String get competencyFitness => 'لياقة';

  @override
  String get navBranches => 'الفروع';

  @override
  String get branchesTitle => 'الفروع';

  @override
  String get branchesEmpty => 'لا توجد فروع بعد';

  @override
  String get branchMainBadge => 'الفرع الرئيسي';

  @override
  String branchAthletesCount(int count) {
    return '$count لاعب';
  }

  @override
  String branchCoachesCount(int count) {
    return '$count مدرب';
  }

  @override
  String get branchUtilisation => 'نسبة الإشغال';

  @override
  String get branchCapacity => 'السعة';

  @override
  String get branchOperations => 'العمليات';

  @override
  String get branchesKpiBranches => 'الفروع';

  @override
  String get branchesKpiAthletes => 'اللاعبون';

  @override
  String get branchesKpiAvgScore => 'متوسط المؤشر';

  @override
  String get metricRegistered => 'المسجلون';

  @override
  String get metricActive => 'النشطون';

  @override
  String get metricCompetitionTeam => 'فريق المنافسات';

  @override
  String get metricReadyToGrade => 'جاهز للترقية';

  @override
  String get metricAttendance => 'متوسط الحضور';

  @override
  String get metricSafeguarding => 'حماية سارية';

  @override
  String get metricSessionsWeek => 'حصص / أسبوع';

  @override
  String get metricCoaches => 'المدربون';

  @override
  String get branchStatusActive => 'نشط';

  @override
  String get branchStatusMaintenance => 'صيانة';

  @override
  String get branchStatusTournamentMode => 'وضع البطولة';

  @override
  String get branchStatusClosed => 'مغلق';

  @override
  String get navSchedule => 'الجدول';

  @override
  String get scheduleTitle => 'الجدول';

  @override
  String get scheduleEmpty => 'لا توجد حصص في هذا اليوم';

  @override
  String get scheduleToday => 'اليوم';

  @override
  String get scheduleTomorrow => 'غدًا';

  @override
  String get disciplinePoomsae => 'بومسيه';

  @override
  String get disciplineKyorugi => 'قتال';

  @override
  String get disciplineFundamentals => 'أساسيات';

  @override
  String get disciplineCompetition => 'منافسات';

  @override
  String get disciplineFitness => 'لياقة';

  @override
  String get attendanceTitle => 'الحضور';

  @override
  String get attendancePresent => 'حاضر';

  @override
  String get attendanceLate => 'متأخر';

  @override
  String get attendanceAbsent => 'غائب';

  @override
  String get attendanceExcused => 'بعذر';

  @override
  String get attMarkAll => 'تحديد الكل حاضر';

  @override
  String get attSave => 'حفظ';

  @override
  String get attSaved => 'تم حفظ الحضور';

  @override
  String attPresentCount(int count) {
    return '$count حاضر';
  }

  @override
  String attAbsentCount(int count) {
    return '$count غائب';
  }

  @override
  String sessionRoster(int enrolled, int capacity) {
    return '$enrolled/$capacity';
  }

  @override
  String get navMore => 'المزيد';

  @override
  String get moreTitle => 'المزيد';

  @override
  String get moreSwitchRole => 'تبديل الدور (تجريبي)';

  @override
  String get navGrading => 'الترقيات';

  @override
  String get gradingTitle => 'الترقيات';

  @override
  String get gradingEmpty => 'لا توجد جلسات ترقية';

  @override
  String get gradingStatusScheduled => 'مجدولة';

  @override
  String get gradingStatusInProgress => 'جارية';

  @override
  String get gradingStatusCompleted => 'مكتملة';

  @override
  String get gradingStatusCancelled => 'ملغاة';

  @override
  String gradingProgress(int scored, int total) {
    return '$scored/$total مقيَّم';
  }

  @override
  String gradingCandidates(int count) {
    return '$count مرشح';
  }

  @override
  String get gradingEligible => 'مؤهل';

  @override
  String get gradingNotEligible => 'غير مؤهل';

  @override
  String gradingMonthsAtRank(int months) {
    return '$months شهر في الرتبة';
  }

  @override
  String get gradingTargetBelt => 'الهدف';

  @override
  String get athleteTabOverview => 'نظرة عامة';

  @override
  String get athleteTabPerformance => 'الأداء';

  @override
  String get perfPhysical => 'البدني';

  @override
  String get perfTechnical => 'التقني';

  @override
  String get perfWellness => 'العافية';

  @override
  String get perfNoData => 'لا توجد بيانات بعد';

  @override
  String perfWellnessStreak(int days) {
    return 'سلسلة $days يوم';
  }

  @override
  String perfLatest(String value) {
    return 'الأحدث $value';
  }

  @override
  String get athleteTabCompetitions => 'المنافسات';

  @override
  String get athleteTabAttendance => 'الحضور';

  @override
  String get athleteTabMedical => 'طبي';

  @override
  String get athleteTabNotes => 'ملاحظات';

  @override
  String get athleteTabMore => 'المزيد';

  @override
  String get athleteTabDocuments => 'المستندات';

  @override
  String get docsEmpty => 'لا توجد مستندات';

  @override
  String get docStatusValid => 'سارية';

  @override
  String get docStatusExpiring => 'تنتهي قريبًا';

  @override
  String get docStatusExpired => 'منتهية';

  @override
  String get docStatusMissing => 'مفقودة';

  @override
  String get docStatusPending => 'قيد المراجعة';

  @override
  String get docKindEmiratesID => 'الهوية الإماراتية';

  @override
  String get docKindPassport => 'جواز السفر';

  @override
  String get docKindFederationLicence => 'رخصة الاتحاد';

  @override
  String get docKindWorldTaekwondoCard => 'بطاقة WT';

  @override
  String get docKindMedicalClearance => 'الموافقة الطبية';

  @override
  String get docKindImageRightsConsent => 'موافقة حقوق الصورة';

  @override
  String get docKindTravelPermission => 'إذن السفر';

  @override
  String get docKindSchoolID => 'هوية المدرسة';

  @override
  String get docKindOther => 'أخرى';

  @override
  String get moreBeltProgression => 'تدرّج الأحزمة';

  @override
  String get moreEmergencyContacts => 'جهات اتصال الطوارئ';

  @override
  String get moreGoals => 'الأهداف';

  @override
  String get moreNone => 'لا يوجد';

  @override
  String get goalActive => 'نشط';

  @override
  String get goalCompleted => 'مكتمل';

  @override
  String get goalAbandoned => 'متوقف';

  @override
  String get notesEmpty => 'لا توجد ملاحظات';

  @override
  String get notePinned => 'مثبّتة';

  @override
  String get noteCatTechnical => 'تقني';

  @override
  String get noteCatTactical => 'تكتيكي';

  @override
  String get noteCatBehavioural => 'سلوكي';

  @override
  String get noteCatMedical => 'طبي';

  @override
  String get noteCatMental => 'ذهني';

  @override
  String get noteCatGeneral => 'عام';

  @override
  String get medBloodType => 'فصيلة الدم';

  @override
  String get medHeight => 'الطول';

  @override
  String get medFitToTrain => 'مؤهل للتدريب';

  @override
  String get medNotFit => 'غير مؤهل';

  @override
  String get medAllergies => 'الحساسية';

  @override
  String get medConditions => 'الحالات الطبية';

  @override
  String get medMedications => 'الأدوية';

  @override
  String get medInjuries => 'سجل الإصابات';

  @override
  String get medWeightHistory => 'سجل الوزن';

  @override
  String get medNone => 'لا يوجد';

  @override
  String get injuryMinor => 'طفيفة';

  @override
  String get injuryModerate => 'متوسطة';

  @override
  String get injurySevere => 'شديدة';

  @override
  String get attRateLabel => 'نسبة الحضور';

  @override
  String get attEmpty => 'لا توجد سجلات حضور';

  @override
  String get compEmpty => 'لا توجد منافسات بعد';

  @override
  String get compEvents => 'المشاركات';

  @override
  String get compMedals => 'الميداليات';

  @override
  String get navAnnouncements => 'الإعلانات';

  @override
  String get announcementsTitle => 'الإعلانات';

  @override
  String get announcementsEmpty => 'لا توجد إعلانات';

  @override
  String get annCatGeneral => 'عام';

  @override
  String get annCatEvent => 'فعالية';

  @override
  String get annCatRegistration => 'تسجيل';

  @override
  String get annCatGrading => 'ترقية';

  @override
  String get annCatTournament => 'بطولة';

  @override
  String get annCatPolicy => 'سياسة';

  @override
  String get annCatRecognition => 'تكريم';

  @override
  String get annScheduled => 'مجدول';

  @override
  String get navCertifications => 'الشهادات';

  @override
  String get certificationsTitle => 'الشهادات';

  @override
  String get certificationsEmpty => 'لا توجد شهادات';

  @override
  String get certOk => 'سارية';

  @override
  String get certExpiring => 'تنتهي قريبًا';

  @override
  String get certExpired => 'منتهية';

  @override
  String certExpiresInDays(int days) {
    return 'خلال $days يوم';
  }

  @override
  String certExpiredAgo(int days) {
    return 'قبل $days يوم';
  }

  @override
  String get certKindFirstAid => 'إسعافات أولية';

  @override
  String get certKindSafeguarding => 'حماية';

  @override
  String get certKindWtCoaching => 'تدريب WT';

  @override
  String get certKindDoping => 'مكافحة المنشطات';

  @override
  String get certKindRefereeing => 'تحكيم';

  @override
  String get navAudit => 'سجل النشاط';

  @override
  String get auditTitle => 'سجل النشاط';

  @override
  String get auditEmpty => 'لا يوجد نشاط';

  @override
  String get navTournaments => 'البطولات';

  @override
  String get tournamentsTitle => 'البطولات';

  @override
  String get tournamentsEmpty => 'لا توجد بطولات';

  @override
  String get tournUpcoming => 'القادمة';

  @override
  String get tournPast => 'السابقة';

  @override
  String get tournOfficial => 'رسمية';

  @override
  String get tournRegistrations => 'التسجيلات';

  @override
  String get tournNoRegistrations => 'لا توجد تسجيلات';

  @override
  String tournPosition(int pos) {
    return 'المركز $pos';
  }

  @override
  String get eventLevelLocal => 'محلية';

  @override
  String get eventLevelNational => 'وطنية';

  @override
  String get eventLevelRegional => 'إقليمية';

  @override
  String get eventLevelInternational => 'دولية';

  @override
  String get regRegistered => 'مسجّل';

  @override
  String get regWeighedIn => 'تم الوزن';

  @override
  String get regWithdrawn => 'منسحب';

  @override
  String get regDisqualified => 'مُستبعد';

  @override
  String get medalGold => 'ذهبية';

  @override
  String get medalSilver => 'فضية';

  @override
  String get medalBronze => 'برونزية';

  @override
  String get weightCutTitle => 'خفض الوزن';

  @override
  String weightCutLine(String current, String target) {
    return '$current ← $target كجم';
  }

  @override
  String weightCutDelta(String delta) {
    return 'متبقٍ $delta كجم';
  }

  @override
  String get bracketTitle => 'المظلّة';

  @override
  String get bracketView => 'عرض المظلّة';

  @override
  String get bracketEmpty => 'لا توجد مظلّة لهذا الحدث';

  @override
  String get bracketFinal => 'النهائي';

  @override
  String get bracketSemifinal => 'نصف النهائي';

  @override
  String get bracketQuarterfinal => 'ربع النهائي';

  @override
  String bracketRoundFmt(int n) {
    return 'الجولة $n';
  }

  @override
  String get navDrillTimer => 'مؤقّت التمارين';

  @override
  String get drillTimerTitle => 'مؤقّت التمارين';

  @override
  String get presetTabata => 'تاباتا';

  @override
  String get presetTabataDesc => '٨ جولات · ٢٠ث عمل / ١٠ث راحة';

  @override
  String get presetRounds => 'جولات القتال';

  @override
  String get presetRoundsDesc => '٣ جولات · ٣ دقائق عمل / دقيقة راحة';

  @override
  String get presetEmom => 'كل دقيقة';

  @override
  String get presetEmomDesc => '١٠ جولات · كل دقيقة';

  @override
  String get timerStart => 'ابدأ';

  @override
  String timerRoundFmt(int round, int total) {
    return 'جولة $round/$total';
  }

  @override
  String timerDrillFmt(int n, int total) {
    return 'تمرين $n/$total';
  }

  @override
  String get phasePrepare => 'استعد';

  @override
  String get phaseWork => 'عمل';

  @override
  String get phaseRest => 'راحة';

  @override
  String get phaseRoundBreak => 'استراحة الجولة';

  @override
  String get phaseFinished => 'انتهى!';

  @override
  String get timerReset => 'إعادة';

  @override
  String get navLiveMatch => 'نزال مباشر';

  @override
  String get liveMatchTitle => 'نزال مباشر';

  @override
  String get lmSetupTitle => 'نزال جديد';

  @override
  String get lmOpponent => 'الخصم';

  @override
  String get lmOpponentHint => 'اسم الخصم';

  @override
  String get lmStart => 'ابدأ النزال';

  @override
  String get lmBlue => 'أزرق';

  @override
  String get lmRed => 'أحمر';

  @override
  String get lmUndo => 'تراجع';

  @override
  String get lmEndRound => 'إنهاء الجولة';

  @override
  String get lmNextRound => 'الجولة التالية';

  @override
  String get lmFinalize => 'إنهاء النزال';

  @override
  String lmRoundFmt(int round, int total) {
    return 'جولة $round/$total';
  }

  @override
  String lmWinnerFmt(String name) {
    return 'فوز $name';
  }

  @override
  String get scoreHeadKick => 'رأس';

  @override
  String get scoreBodyKick => 'جذع';

  @override
  String get scoreTurnBodyKick => 'دوران جذع';

  @override
  String get scoreTurnHeadKick => 'دوران رأس';

  @override
  String get scorePunch => 'لكمة';

  @override
  String get scorePenalty => 'عقوبة';

  @override
  String get authWelcome => 'مرحبًا';

  @override
  String get authSubtitle => 'سجّل الدخول إلى حسابك في شهامة';

  @override
  String get authEmail => 'البريد الإلكتروني';

  @override
  String get authPassword => 'كلمة المرور';

  @override
  String get authSignIn => 'تسجيل الدخول';

  @override
  String get navSignOut => 'تسجيل الخروج';

  @override
  String get authName => 'الاسم الكامل';

  @override
  String get authCreateAccount => 'إنشاء حساب';

  @override
  String get authSignUpTitle => 'أنشئ حسابك';

  @override
  String get authSignUp => 'إنشاء الحساب';

  @override
  String get authHaveAccount => 'لديك حساب بالفعل؟ سجّل الدخول';

  @override
  String get navDevelopment => 'التطوير';

  @override
  String get developmentTitle => 'تطوير المدربين';

  @override
  String get developmentEmpty => 'لا يوجد مدربون مساعدون بعد';

  @override
  String get devReadiness => 'الجاهزية';

  @override
  String get devMentor => 'المشرف';

  @override
  String devSessions(int count) {
    return '$count حصة';
  }

  @override
  String get devLevelAthlete => 'لاعب';

  @override
  String get devLevelAssistantCoach => 'مدرب مساعد';

  @override
  String get devLevelJuniorCoach => 'مدرب مبتدئ';

  @override
  String get devLevelCoach => 'مدرب';

  @override
  String get devLevelHeadCoach => 'مدرب رئيسي';

  @override
  String get devLevelTechnicalDirector => 'مدير فني';

  @override
  String get navProfile => 'ملفّي';

  @override
  String get navChildren => 'لاعبيّ';

  @override
  String get childrenTitle => 'لاعبيّ';

  @override
  String get familyNoProfile => 'لا يوجد ملف لاعب مرتبط بهذا الحساب';

  @override
  String get familyNoChildren => 'لا يوجد لاعبون مرتبطون بهذا الحساب';
}
