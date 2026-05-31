// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class L10nEn extends L10n {
  L10nEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'SHJSDSC Taekwondo';

  @override
  String get navAthletes => 'Athletes';

  @override
  String get settingsRole => 'Role';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionRetry => 'Retry';

  @override
  String get loadFailed => 'Couldn\'t load data';

  @override
  String get athletesTitle => 'Athletes';

  @override
  String get athletesSearch => 'Search athletes';

  @override
  String get athletesEmpty => 'No athletes yet';

  @override
  String get athleteCompositeScore => 'Composite';

  @override
  String get athleteOverview => 'Overview';

  @override
  String athleteMemberNo(int number) {
    return 'Member #$number';
  }

  @override
  String athleteAge(int years) {
    return '$years yrs';
  }

  @override
  String athleteWeightFmt(String kg) {
    return '$kg kg';
  }

  @override
  String get beltWhite => 'White Belt';

  @override
  String get beltYellow => 'Yellow Belt';

  @override
  String get beltGreen => 'Green Belt';

  @override
  String get beltBlue => 'Blue Belt';

  @override
  String get beltRed => 'Red Belt';

  @override
  String get beltBlack => 'Black Belt';

  @override
  String get statusCompetitionTeam => 'Competition Team';

  @override
  String get statusReadyToGrade => 'Ready to Grade';

  @override
  String get statusWatch => 'Watch';

  @override
  String get statusRest => 'Rest';

  @override
  String get statusActive => 'Active';

  @override
  String get ageCubs => 'Cubs';

  @override
  String get ageKids => 'Kids';

  @override
  String get ageCadets => 'Cadets';

  @override
  String get ageJuniors => 'Juniors';

  @override
  String get ageSeniors => 'Seniors';

  @override
  String get ageMasters => 'Masters';

  @override
  String get navCoaches => 'Coaches';

  @override
  String get coachesTitle => 'Coaches';

  @override
  String get coachesSearch => 'Search coaches';

  @override
  String get coachesEmpty => 'No coaches yet';

  @override
  String get coachOverview => 'Competency';

  @override
  String get coachTabOverview => 'Overview';

  @override
  String get coachTabAthletes => 'Athletes';

  @override
  String get coachTabCertifications => 'Certifications';

  @override
  String get coachTabCompetitions => 'Competitions';

  @override
  String get coachCompEmpty => 'No competition results';

  @override
  String get coachNoAthletes => 'No assigned athletes';

  @override
  String coachDanRank(int dan) {
    return '$dan Dan';
  }

  @override
  String coachYearsExp(int years) {
    return '$years yrs exp';
  }

  @override
  String coachAthletesCount(int count) {
    return '$count athletes';
  }

  @override
  String get coachCertExpiry => 'Next cert expiry';

  @override
  String get coachNoCerts => 'No certifications on file';

  @override
  String get coachLevelAssistant => 'Assistant Coach';

  @override
  String get coachLevelJunior => 'Junior Coach';

  @override
  String get coachLevelSenior => 'Senior Coach';

  @override
  String get coachLevelHead => 'Head Coach';

  @override
  String get coachLevelNational => 'National Coach';

  @override
  String get coachLevelInternational => 'International Coach';

  @override
  String get coachEmpActive => 'Active';

  @override
  String get coachEmpLeave => 'On Leave';

  @override
  String get coachEmpTransferred => 'Transferred';

  @override
  String get coachEmpRetired => 'Retired';

  @override
  String get coachEmpSuspended => 'Suspended';

  @override
  String get competencyTechnical => 'Technical';

  @override
  String get competencySparring => 'Sparring';

  @override
  String get competencyPoomsae => 'Poomsae';

  @override
  String get competencyFitness => 'Fitness';

  @override
  String get navBranches => 'Branches';

  @override
  String get branchesTitle => 'Branches';

  @override
  String get branchesEmpty => 'No branches yet';

  @override
  String get branchMainBadge => 'Main branch';

  @override
  String branchAthletesCount(int count) {
    return '$count athletes';
  }

  @override
  String branchCoachesCount(int count) {
    return '$count coaches';
  }

  @override
  String get branchUtilisation => 'Utilisation';

  @override
  String get branchCapacity => 'Capacity';

  @override
  String get branchOperations => 'Operations';

  @override
  String get branchesKpiBranches => 'Branches';

  @override
  String get branchesKpiAthletes => 'Athletes';

  @override
  String get branchesKpiAvgScore => 'Avg score';

  @override
  String get metricRegistered => 'Registered';

  @override
  String get metricActive => 'Active';

  @override
  String get metricCompetitionTeam => 'Competition team';

  @override
  String get metricReadyToGrade => 'Ready to grade';

  @override
  String get metricAttendance => 'Avg attendance';

  @override
  String get metricSafeguarding => 'Safeguarding current';

  @override
  String get metricSessionsWeek => 'Sessions / week';

  @override
  String get metricCoaches => 'Coaches';

  @override
  String get branchStatusActive => 'Active';

  @override
  String get branchStatusMaintenance => 'Maintenance';

  @override
  String get branchStatusTournamentMode => 'Tournament mode';

  @override
  String get branchStatusClosed => 'Closed';

  @override
  String get navSchedule => 'Schedule';

  @override
  String get scheduleTitle => 'Schedule';

  @override
  String get scheduleEmpty => 'No classes this day';

  @override
  String get scheduleToday => 'Today';

  @override
  String get scheduleTomorrow => 'Tomorrow';

  @override
  String get disciplinePoomsae => 'Poomsae';

  @override
  String get disciplineKyorugi => 'Sparring';

  @override
  String get disciplineFundamentals => 'Fundamentals';

  @override
  String get disciplineCompetition => 'Competition';

  @override
  String get disciplineFitness => 'Fitness';

  @override
  String get attendanceTitle => 'Attendance';

  @override
  String get attendancePresent => 'Present';

  @override
  String get attendanceLate => 'Late';

  @override
  String get attendanceAbsent => 'Absent';

  @override
  String get attendanceExcused => 'Excused';

  @override
  String get attMarkAll => 'Mark all present';

  @override
  String get attSave => 'Save';

  @override
  String get attSaved => 'Attendance saved';

  @override
  String attPresentCount(int count) {
    return '$count present';
  }

  @override
  String attAbsentCount(int count) {
    return '$count absent';
  }

  @override
  String sessionRoster(int enrolled, int capacity) {
    return '$enrolled/$capacity';
  }

  @override
  String get navMore => 'More';

  @override
  String get moreTitle => 'More';

  @override
  String get moreSwitchRole => 'Switch role (demo)';

  @override
  String get navGrading => 'Grading';

  @override
  String get gradingTitle => 'Grading';

  @override
  String get gradingEmpty => 'No grading sessions';

  @override
  String get gradingStatusScheduled => 'Scheduled';

  @override
  String get gradingStatusInProgress => 'In progress';

  @override
  String get gradingStatusCompleted => 'Completed';

  @override
  String get gradingStatusCancelled => 'Cancelled';

  @override
  String gradingProgress(int scored, int total) {
    return '$scored/$total scored';
  }

  @override
  String gradingCandidates(int count) {
    return '$count candidates';
  }

  @override
  String get gradingEligible => 'Eligible';

  @override
  String get gradingNotEligible => 'Not eligible';

  @override
  String gradingMonthsAtRank(int months) {
    return '$months mo at rank';
  }

  @override
  String get gradingTargetBelt => 'Target';

  @override
  String get athleteTabOverview => 'Overview';

  @override
  String get athleteTabPerformance => 'Performance';

  @override
  String get perfPhysical => 'Physical';

  @override
  String get perfTechnical => 'Technical';

  @override
  String get perfWellness => 'Wellness';

  @override
  String get perfNoData => 'No data yet';

  @override
  String perfWellnessStreak(int days) {
    return '$days-day streak';
  }

  @override
  String perfLatest(String value) {
    return 'Latest $value';
  }

  @override
  String get athleteTabCompetitions => 'Competitions';

  @override
  String get athleteTabAttendance => 'Attendance';

  @override
  String get athleteTabMedical => 'Medical';

  @override
  String get athleteTabNotes => 'Notes';

  @override
  String get athleteTabMore => 'More';

  @override
  String get athleteTabDocuments => 'Documents';

  @override
  String get docsEmpty => 'No documents on file';

  @override
  String get docStatusValid => 'Valid';

  @override
  String get docStatusExpiring => 'Expiring';

  @override
  String get docStatusExpired => 'Expired';

  @override
  String get docStatusMissing => 'Missing';

  @override
  String get docStatusPending => 'Pending';

  @override
  String get docKindEmiratesID => 'Emirates ID';

  @override
  String get docKindPassport => 'Passport';

  @override
  String get docKindFederationLicence => 'Federation Licence';

  @override
  String get docKindWorldTaekwondoCard => 'WT Card';

  @override
  String get docKindMedicalClearance => 'Medical Clearance';

  @override
  String get docKindImageRightsConsent => 'Image Rights Consent';

  @override
  String get docKindTravelPermission => 'Travel Permission';

  @override
  String get docKindSchoolID => 'School ID';

  @override
  String get docKindOther => 'Other';

  @override
  String get moreBeltProgression => 'Belt progression';

  @override
  String get moreEmergencyContacts => 'Emergency contacts';

  @override
  String get moreGoals => 'Goals';

  @override
  String get moreNone => 'None recorded';

  @override
  String get goalActive => 'Active';

  @override
  String get goalCompleted => 'Completed';

  @override
  String get goalAbandoned => 'Abandoned';

  @override
  String get notesEmpty => 'No coach notes';

  @override
  String get notePinned => 'Pinned';

  @override
  String get noteCatTechnical => 'Technical';

  @override
  String get noteCatTactical => 'Tactical';

  @override
  String get noteCatBehavioural => 'Behavioural';

  @override
  String get noteCatMedical => 'Medical';

  @override
  String get noteCatMental => 'Mental';

  @override
  String get noteCatGeneral => 'General';

  @override
  String get medBloodType => 'Blood type';

  @override
  String get medHeight => 'Height';

  @override
  String get medFitToTrain => 'Cleared to train';

  @override
  String get medNotFit => 'Not cleared';

  @override
  String get medAllergies => 'Allergies';

  @override
  String get medConditions => 'Conditions';

  @override
  String get medMedications => 'Medications';

  @override
  String get medInjuries => 'Injury log';

  @override
  String get medWeightHistory => 'Weight history';

  @override
  String get medNone => 'None recorded';

  @override
  String get injuryMinor => 'Minor';

  @override
  String get injuryModerate => 'Moderate';

  @override
  String get injurySevere => 'Severe';

  @override
  String get attRateLabel => 'Attendance';

  @override
  String get attEmpty => 'No attendance records';

  @override
  String get compEmpty => 'No competitions yet';

  @override
  String get compEvents => 'Events';

  @override
  String get compMedals => 'Medals';

  @override
  String get navAnnouncements => 'Announcements';

  @override
  String get announcementsTitle => 'Announcements';

  @override
  String get announcementsEmpty => 'No announcements';

  @override
  String get annCatGeneral => 'General';

  @override
  String get annCatEvent => 'Event';

  @override
  String get annCatRegistration => 'Registration';

  @override
  String get annCatGrading => 'Grading';

  @override
  String get annCatTournament => 'Tournament';

  @override
  String get annCatPolicy => 'Policy';

  @override
  String get annCatRecognition => 'Recognition';

  @override
  String get annScheduled => 'Scheduled';

  @override
  String get navCertifications => 'Certifications';

  @override
  String get certificationsTitle => 'Certifications';

  @override
  String get certificationsEmpty => 'No certifications';

  @override
  String get certOk => 'Valid';

  @override
  String get certExpiring => 'Expiring';

  @override
  String get certExpired => 'Expired';

  @override
  String certExpiresInDays(int days) {
    return 'in ${days}d';
  }

  @override
  String certExpiredAgo(int days) {
    return '${days}d ago';
  }

  @override
  String get certKindFirstAid => 'First Aid';

  @override
  String get certKindSafeguarding => 'Safeguarding';

  @override
  String get certKindWtCoaching => 'WT Coaching';

  @override
  String get certKindDoping => 'Anti-Doping';

  @override
  String get certKindRefereeing => 'Refereeing';

  @override
  String get navAudit => 'Audit log';

  @override
  String get auditTitle => 'Audit log';

  @override
  String get auditEmpty => 'No activity';

  @override
  String get navTournaments => 'Tournaments';

  @override
  String get tournamentsTitle => 'Tournaments';

  @override
  String get tournamentsEmpty => 'No tournaments';

  @override
  String get tournUpcoming => 'Upcoming';

  @override
  String get tournPast => 'Past';

  @override
  String get tournOfficial => 'Official';

  @override
  String get tournRegistrations => 'Registrations';

  @override
  String get tournNoRegistrations => 'No registrations';

  @override
  String tournPosition(int pos) {
    return '#$pos';
  }

  @override
  String get eventLevelLocal => 'Local';

  @override
  String get eventLevelNational => 'National';

  @override
  String get eventLevelRegional => 'Regional';

  @override
  String get eventLevelInternational => 'International';

  @override
  String get regRegistered => 'Registered';

  @override
  String get regWeighedIn => 'Weighed in';

  @override
  String get regWithdrawn => 'Withdrawn';

  @override
  String get regDisqualified => 'Disqualified';

  @override
  String get medalGold => 'Gold';

  @override
  String get medalSilver => 'Silver';

  @override
  String get medalBronze => 'Bronze';

  @override
  String get weightCutTitle => 'Weight cut';

  @override
  String weightCutLine(String current, String target) {
    return '$current → $target kg';
  }

  @override
  String weightCutDelta(String delta) {
    return '$delta kg to go';
  }

  @override
  String get bracketTitle => 'Bracket';

  @override
  String get bracketView => 'View bracket';

  @override
  String get bracketEmpty => 'No bracket for this event';

  @override
  String get bracketFinal => 'Final';

  @override
  String get bracketSemifinal => 'Semifinal';

  @override
  String get bracketQuarterfinal => 'Quarterfinal';

  @override
  String bracketRoundFmt(int n) {
    return 'Round $n';
  }

  @override
  String get navDrillTimer => 'Drill Timer';

  @override
  String get drillTimerTitle => 'Drill Timer';

  @override
  String get presetTabata => 'Tabata';

  @override
  String get presetTabataDesc => '8 rounds · 20s work / 10s rest';

  @override
  String get presetRounds => 'Sparring Rounds';

  @override
  String get presetRoundsDesc => '3 rounds · 3min work / 1min rest';

  @override
  String get presetEmom => 'EMOM';

  @override
  String get presetEmomDesc => '10 rounds · every minute';

  @override
  String get timerStart => 'Start';

  @override
  String timerRoundFmt(int round, int total) {
    return 'Round $round/$total';
  }

  @override
  String timerDrillFmt(int n, int total) {
    return 'Drill $n/$total';
  }

  @override
  String get phasePrepare => 'Get ready';

  @override
  String get phaseWork => 'Work';

  @override
  String get phaseRest => 'Rest';

  @override
  String get phaseRoundBreak => 'Round break';

  @override
  String get phaseFinished => 'Done!';

  @override
  String get timerReset => 'Reset';

  @override
  String get navLiveMatch => 'Live Match';

  @override
  String get liveMatchTitle => 'Live Match';

  @override
  String get lmSetupTitle => 'New Match';

  @override
  String get lmOpponent => 'Opponent';

  @override
  String get lmOpponentHint => 'Opponent name';

  @override
  String get lmStart => 'Start match';

  @override
  String get lmBlue => 'Blue';

  @override
  String get lmRed => 'Red';

  @override
  String get lmUndo => 'Undo';

  @override
  String get lmEndRound => 'End round';

  @override
  String get lmNextRound => 'Next round';

  @override
  String get lmFinalize => 'Finalize';

  @override
  String lmRoundFmt(int round, int total) {
    return 'Round $round/$total';
  }

  @override
  String lmWinnerFmt(String name) {
    return '$name wins';
  }

  @override
  String get scoreHeadKick => 'Head';

  @override
  String get scoreBodyKick => 'Body';

  @override
  String get scoreTurnBodyKick => 'Turn body';

  @override
  String get scoreTurnHeadKick => 'Turn head';

  @override
  String get scorePunch => 'Punch';

  @override
  String get scorePenalty => 'Penalty';

  @override
  String get authWelcome => 'Welcome';

  @override
  String get authSubtitle => 'Sign in to your SHJSDSC account';

  @override
  String get authEmail => 'Email';

  @override
  String get authPassword => 'Password';

  @override
  String get authSignIn => 'Sign in';

  @override
  String get navSignOut => 'Sign out';

  @override
  String get authName => 'Full name';

  @override
  String get authCreateAccount => 'Create account';

  @override
  String get authSignUpTitle => 'Create your account';

  @override
  String get authSignUp => 'Sign up';

  @override
  String get authHaveAccount => 'Already have an account? Sign in';

  @override
  String get navDevelopment => 'Development';

  @override
  String get developmentTitle => 'Coaching Development';

  @override
  String get developmentEmpty => 'No assistant coaches yet';

  @override
  String get devReadiness => 'Readiness';

  @override
  String get devMentor => 'Mentor';

  @override
  String devSessions(int count) {
    return '$count sessions';
  }

  @override
  String get devLevelAthlete => 'Athlete';

  @override
  String get devLevelAssistantCoach => 'Assistant Coach';

  @override
  String get devLevelJuniorCoach => 'Junior Coach';

  @override
  String get devLevelCoach => 'Coach';

  @override
  String get devLevelHeadCoach => 'Head Coach';

  @override
  String get devLevelTechnicalDirector => 'Technical Director';

  @override
  String get navProfile => 'Profile';

  @override
  String get navChildren => 'My Athletes';

  @override
  String get childrenTitle => 'My Athletes';

  @override
  String get familyNoProfile => 'No athlete profile is linked to this account';

  @override
  String get familyNoChildren => 'No athletes linked to this account';
}
