import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of L10n
/// returned by `L10n.of(context)`.
///
/// Applications need to include `L10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: L10n.localizationsDelegates,
///   supportedLocales: L10n.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the L10n.supportedLocales
/// property.
abstract class L10n {
  L10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static L10n of(BuildContext context) {
    return Localizations.of<L10n>(context, L10n)!;
  }

  static const LocalizationsDelegate<L10n> delegate = _L10nDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'SHJSDSC Taekwondo'**
  String get appTitle;

  /// No description provided for @navAthletes.
  ///
  /// In en, this message translates to:
  /// **'Athletes'**
  String get navAthletes;

  /// No description provided for @settingsRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get settingsRole;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get actionRetry;

  /// No description provided for @loadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load data'**
  String get loadFailed;

  /// No description provided for @athletesTitle.
  ///
  /// In en, this message translates to:
  /// **'Athletes'**
  String get athletesTitle;

  /// No description provided for @athletesSearch.
  ///
  /// In en, this message translates to:
  /// **'Search athletes'**
  String get athletesSearch;

  /// No description provided for @athletesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No athletes yet'**
  String get athletesEmpty;

  /// No description provided for @athleteCompositeScore.
  ///
  /// In en, this message translates to:
  /// **'Composite'**
  String get athleteCompositeScore;

  /// No description provided for @athleteOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get athleteOverview;

  /// No description provided for @athleteMemberNo.
  ///
  /// In en, this message translates to:
  /// **'Member #{number}'**
  String athleteMemberNo(int number);

  /// No description provided for @athleteAge.
  ///
  /// In en, this message translates to:
  /// **'{years} yrs'**
  String athleteAge(int years);

  /// No description provided for @athleteWeightFmt.
  ///
  /// In en, this message translates to:
  /// **'{kg} kg'**
  String athleteWeightFmt(String kg);

  /// No description provided for @beltWhite.
  ///
  /// In en, this message translates to:
  /// **'White Belt'**
  String get beltWhite;

  /// No description provided for @beltYellow.
  ///
  /// In en, this message translates to:
  /// **'Yellow Belt'**
  String get beltYellow;

  /// No description provided for @beltGreen.
  ///
  /// In en, this message translates to:
  /// **'Green Belt'**
  String get beltGreen;

  /// No description provided for @beltBlue.
  ///
  /// In en, this message translates to:
  /// **'Blue Belt'**
  String get beltBlue;

  /// No description provided for @beltRed.
  ///
  /// In en, this message translates to:
  /// **'Red Belt'**
  String get beltRed;

  /// No description provided for @beltBlack.
  ///
  /// In en, this message translates to:
  /// **'Black Belt'**
  String get beltBlack;

  /// No description provided for @statusCompetitionTeam.
  ///
  /// In en, this message translates to:
  /// **'Competition Team'**
  String get statusCompetitionTeam;

  /// No description provided for @statusReadyToGrade.
  ///
  /// In en, this message translates to:
  /// **'Ready to Grade'**
  String get statusReadyToGrade;

  /// No description provided for @statusWatch.
  ///
  /// In en, this message translates to:
  /// **'Watch'**
  String get statusWatch;

  /// No description provided for @statusRest.
  ///
  /// In en, this message translates to:
  /// **'Rest'**
  String get statusRest;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// No description provided for @ageCubs.
  ///
  /// In en, this message translates to:
  /// **'Cubs'**
  String get ageCubs;

  /// No description provided for @ageKids.
  ///
  /// In en, this message translates to:
  /// **'Kids'**
  String get ageKids;

  /// No description provided for @ageCadets.
  ///
  /// In en, this message translates to:
  /// **'Cadets'**
  String get ageCadets;

  /// No description provided for @ageJuniors.
  ///
  /// In en, this message translates to:
  /// **'Juniors'**
  String get ageJuniors;

  /// No description provided for @ageSeniors.
  ///
  /// In en, this message translates to:
  /// **'Seniors'**
  String get ageSeniors;

  /// No description provided for @ageMasters.
  ///
  /// In en, this message translates to:
  /// **'Masters'**
  String get ageMasters;

  /// No description provided for @navCoaches.
  ///
  /// In en, this message translates to:
  /// **'Coaches'**
  String get navCoaches;

  /// No description provided for @coachesTitle.
  ///
  /// In en, this message translates to:
  /// **'Coaches'**
  String get coachesTitle;

  /// No description provided for @coachesSearch.
  ///
  /// In en, this message translates to:
  /// **'Search coaches'**
  String get coachesSearch;

  /// No description provided for @coachesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No coaches yet'**
  String get coachesEmpty;

  /// No description provided for @coachOverview.
  ///
  /// In en, this message translates to:
  /// **'Competency'**
  String get coachOverview;

  /// No description provided for @coachTabOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get coachTabOverview;

  /// No description provided for @coachTabAthletes.
  ///
  /// In en, this message translates to:
  /// **'Athletes'**
  String get coachTabAthletes;

  /// No description provided for @coachTabCertifications.
  ///
  /// In en, this message translates to:
  /// **'Certifications'**
  String get coachTabCertifications;

  /// No description provided for @coachTabCompetitions.
  ///
  /// In en, this message translates to:
  /// **'Competitions'**
  String get coachTabCompetitions;

  /// No description provided for @coachCompEmpty.
  ///
  /// In en, this message translates to:
  /// **'No competition results'**
  String get coachCompEmpty;

  /// No description provided for @coachNoAthletes.
  ///
  /// In en, this message translates to:
  /// **'No assigned athletes'**
  String get coachNoAthletes;

  /// No description provided for @coachDanRank.
  ///
  /// In en, this message translates to:
  /// **'{dan} Dan'**
  String coachDanRank(int dan);

  /// No description provided for @coachYearsExp.
  ///
  /// In en, this message translates to:
  /// **'{years} yrs exp'**
  String coachYearsExp(int years);

  /// No description provided for @coachAthletesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} athletes'**
  String coachAthletesCount(int count);

  /// No description provided for @coachCertExpiry.
  ///
  /// In en, this message translates to:
  /// **'Next cert expiry'**
  String get coachCertExpiry;

  /// No description provided for @coachNoCerts.
  ///
  /// In en, this message translates to:
  /// **'No certifications on file'**
  String get coachNoCerts;

  /// No description provided for @coachLevelAssistant.
  ///
  /// In en, this message translates to:
  /// **'Assistant Coach'**
  String get coachLevelAssistant;

  /// No description provided for @coachLevelJunior.
  ///
  /// In en, this message translates to:
  /// **'Junior Coach'**
  String get coachLevelJunior;

  /// No description provided for @coachLevelSenior.
  ///
  /// In en, this message translates to:
  /// **'Senior Coach'**
  String get coachLevelSenior;

  /// No description provided for @coachLevelHead.
  ///
  /// In en, this message translates to:
  /// **'Head Coach'**
  String get coachLevelHead;

  /// No description provided for @coachLevelNational.
  ///
  /// In en, this message translates to:
  /// **'National Coach'**
  String get coachLevelNational;

  /// No description provided for @coachLevelInternational.
  ///
  /// In en, this message translates to:
  /// **'International Coach'**
  String get coachLevelInternational;

  /// No description provided for @coachEmpActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get coachEmpActive;

  /// No description provided for @coachEmpLeave.
  ///
  /// In en, this message translates to:
  /// **'On Leave'**
  String get coachEmpLeave;

  /// No description provided for @coachEmpTransferred.
  ///
  /// In en, this message translates to:
  /// **'Transferred'**
  String get coachEmpTransferred;

  /// No description provided for @coachEmpRetired.
  ///
  /// In en, this message translates to:
  /// **'Retired'**
  String get coachEmpRetired;

  /// No description provided for @coachEmpSuspended.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get coachEmpSuspended;

  /// No description provided for @competencyTechnical.
  ///
  /// In en, this message translates to:
  /// **'Technical'**
  String get competencyTechnical;

  /// No description provided for @competencySparring.
  ///
  /// In en, this message translates to:
  /// **'Sparring'**
  String get competencySparring;

  /// No description provided for @competencyPoomsae.
  ///
  /// In en, this message translates to:
  /// **'Poomsae'**
  String get competencyPoomsae;

  /// No description provided for @competencyFitness.
  ///
  /// In en, this message translates to:
  /// **'Fitness'**
  String get competencyFitness;

  /// No description provided for @navBranches.
  ///
  /// In en, this message translates to:
  /// **'Branches'**
  String get navBranches;

  /// No description provided for @branchesTitle.
  ///
  /// In en, this message translates to:
  /// **'Branches'**
  String get branchesTitle;

  /// No description provided for @branchesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No branches yet'**
  String get branchesEmpty;

  /// No description provided for @branchMainBadge.
  ///
  /// In en, this message translates to:
  /// **'Main branch'**
  String get branchMainBadge;

  /// No description provided for @branchAthletesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} athletes'**
  String branchAthletesCount(int count);

  /// No description provided for @branchCoachesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} coaches'**
  String branchCoachesCount(int count);

  /// No description provided for @branchUtilisation.
  ///
  /// In en, this message translates to:
  /// **'Utilisation'**
  String get branchUtilisation;

  /// No description provided for @branchCapacity.
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get branchCapacity;

  /// No description provided for @branchOperations.
  ///
  /// In en, this message translates to:
  /// **'Operations'**
  String get branchOperations;

  /// No description provided for @branchesKpiBranches.
  ///
  /// In en, this message translates to:
  /// **'Branches'**
  String get branchesKpiBranches;

  /// No description provided for @branchesKpiAthletes.
  ///
  /// In en, this message translates to:
  /// **'Athletes'**
  String get branchesKpiAthletes;

  /// No description provided for @branchesKpiAvgScore.
  ///
  /// In en, this message translates to:
  /// **'Avg score'**
  String get branchesKpiAvgScore;

  /// No description provided for @metricRegistered.
  ///
  /// In en, this message translates to:
  /// **'Registered'**
  String get metricRegistered;

  /// No description provided for @metricActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get metricActive;

  /// No description provided for @metricCompetitionTeam.
  ///
  /// In en, this message translates to:
  /// **'Competition team'**
  String get metricCompetitionTeam;

  /// No description provided for @metricReadyToGrade.
  ///
  /// In en, this message translates to:
  /// **'Ready to grade'**
  String get metricReadyToGrade;

  /// No description provided for @metricAttendance.
  ///
  /// In en, this message translates to:
  /// **'Avg attendance'**
  String get metricAttendance;

  /// No description provided for @metricSafeguarding.
  ///
  /// In en, this message translates to:
  /// **'Safeguarding current'**
  String get metricSafeguarding;

  /// No description provided for @metricSessionsWeek.
  ///
  /// In en, this message translates to:
  /// **'Sessions / week'**
  String get metricSessionsWeek;

  /// No description provided for @metricCoaches.
  ///
  /// In en, this message translates to:
  /// **'Coaches'**
  String get metricCoaches;

  /// No description provided for @branchStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get branchStatusActive;

  /// No description provided for @branchStatusMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get branchStatusMaintenance;

  /// No description provided for @branchStatusTournamentMode.
  ///
  /// In en, this message translates to:
  /// **'Tournament mode'**
  String get branchStatusTournamentMode;

  /// No description provided for @branchStatusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get branchStatusClosed;

  /// No description provided for @navSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get navSchedule;

  /// No description provided for @scheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get scheduleTitle;

  /// No description provided for @scheduleEmpty.
  ///
  /// In en, this message translates to:
  /// **'No classes this day'**
  String get scheduleEmpty;

  /// No description provided for @scheduleToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get scheduleToday;

  /// No description provided for @scheduleTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get scheduleTomorrow;

  /// No description provided for @disciplinePoomsae.
  ///
  /// In en, this message translates to:
  /// **'Poomsae'**
  String get disciplinePoomsae;

  /// No description provided for @disciplineKyorugi.
  ///
  /// In en, this message translates to:
  /// **'Sparring'**
  String get disciplineKyorugi;

  /// No description provided for @disciplineFundamentals.
  ///
  /// In en, this message translates to:
  /// **'Fundamentals'**
  String get disciplineFundamentals;

  /// No description provided for @disciplineCompetition.
  ///
  /// In en, this message translates to:
  /// **'Competition'**
  String get disciplineCompetition;

  /// No description provided for @disciplineFitness.
  ///
  /// In en, this message translates to:
  /// **'Fitness'**
  String get disciplineFitness;

  /// No description provided for @attendanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get attendanceTitle;

  /// No description provided for @attendancePresent.
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get attendancePresent;

  /// No description provided for @attendanceLate.
  ///
  /// In en, this message translates to:
  /// **'Late'**
  String get attendanceLate;

  /// No description provided for @attendanceAbsent.
  ///
  /// In en, this message translates to:
  /// **'Absent'**
  String get attendanceAbsent;

  /// No description provided for @attendanceExcused.
  ///
  /// In en, this message translates to:
  /// **'Excused'**
  String get attendanceExcused;

  /// No description provided for @attMarkAll.
  ///
  /// In en, this message translates to:
  /// **'Mark all present'**
  String get attMarkAll;

  /// No description provided for @attSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get attSave;

  /// No description provided for @attSaved.
  ///
  /// In en, this message translates to:
  /// **'Attendance saved'**
  String get attSaved;

  /// No description provided for @attPresentCount.
  ///
  /// In en, this message translates to:
  /// **'{count} present'**
  String attPresentCount(int count);

  /// No description provided for @attAbsentCount.
  ///
  /// In en, this message translates to:
  /// **'{count} absent'**
  String attAbsentCount(int count);

  /// No description provided for @sessionRoster.
  ///
  /// In en, this message translates to:
  /// **'{enrolled}/{capacity}'**
  String sessionRoster(int enrolled, int capacity);

  /// No description provided for @navMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get navMore;

  /// No description provided for @moreTitle.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get moreTitle;

  /// No description provided for @moreSwitchRole.
  ///
  /// In en, this message translates to:
  /// **'Switch role (demo)'**
  String get moreSwitchRole;

  /// No description provided for @navGrading.
  ///
  /// In en, this message translates to:
  /// **'Grading'**
  String get navGrading;

  /// No description provided for @gradingTitle.
  ///
  /// In en, this message translates to:
  /// **'Grading'**
  String get gradingTitle;

  /// No description provided for @gradingEmpty.
  ///
  /// In en, this message translates to:
  /// **'No grading sessions'**
  String get gradingEmpty;

  /// No description provided for @gradingStatusScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get gradingStatusScheduled;

  /// No description provided for @gradingStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get gradingStatusInProgress;

  /// No description provided for @gradingStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get gradingStatusCompleted;

  /// No description provided for @gradingStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get gradingStatusCancelled;

  /// No description provided for @gradingProgress.
  ///
  /// In en, this message translates to:
  /// **'{scored}/{total} scored'**
  String gradingProgress(int scored, int total);

  /// No description provided for @gradingCandidates.
  ///
  /// In en, this message translates to:
  /// **'{count} candidates'**
  String gradingCandidates(int count);

  /// No description provided for @gradingEligible.
  ///
  /// In en, this message translates to:
  /// **'Eligible'**
  String get gradingEligible;

  /// No description provided for @gradingNotEligible.
  ///
  /// In en, this message translates to:
  /// **'Not eligible'**
  String get gradingNotEligible;

  /// No description provided for @gradingMonthsAtRank.
  ///
  /// In en, this message translates to:
  /// **'{months} mo at rank'**
  String gradingMonthsAtRank(int months);

  /// No description provided for @gradingTargetBelt.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get gradingTargetBelt;

  /// No description provided for @athleteTabOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get athleteTabOverview;

  /// No description provided for @athleteTabPerformance.
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get athleteTabPerformance;

  /// No description provided for @perfPhysical.
  ///
  /// In en, this message translates to:
  /// **'Physical'**
  String get perfPhysical;

  /// No description provided for @perfTechnical.
  ///
  /// In en, this message translates to:
  /// **'Technical'**
  String get perfTechnical;

  /// No description provided for @perfWellness.
  ///
  /// In en, this message translates to:
  /// **'Wellness'**
  String get perfWellness;

  /// No description provided for @perfNoData.
  ///
  /// In en, this message translates to:
  /// **'No data yet'**
  String get perfNoData;

  /// No description provided for @perfWellnessStreak.
  ///
  /// In en, this message translates to:
  /// **'{days}-day streak'**
  String perfWellnessStreak(int days);

  /// No description provided for @perfLatest.
  ///
  /// In en, this message translates to:
  /// **'Latest {value}'**
  String perfLatest(String value);

  /// No description provided for @athleteTabCompetitions.
  ///
  /// In en, this message translates to:
  /// **'Competitions'**
  String get athleteTabCompetitions;

  /// No description provided for @athleteTabAttendance.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get athleteTabAttendance;

  /// No description provided for @athleteTabMedical.
  ///
  /// In en, this message translates to:
  /// **'Medical'**
  String get athleteTabMedical;

  /// No description provided for @athleteTabNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get athleteTabNotes;

  /// No description provided for @athleteTabMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get athleteTabMore;

  /// No description provided for @athleteTabDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get athleteTabDocuments;

  /// No description provided for @docsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No documents on file'**
  String get docsEmpty;

  /// No description provided for @docStatusValid.
  ///
  /// In en, this message translates to:
  /// **'Valid'**
  String get docStatusValid;

  /// No description provided for @docStatusExpiring.
  ///
  /// In en, this message translates to:
  /// **'Expiring'**
  String get docStatusExpiring;

  /// No description provided for @docStatusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get docStatusExpired;

  /// No description provided for @docStatusMissing.
  ///
  /// In en, this message translates to:
  /// **'Missing'**
  String get docStatusMissing;

  /// No description provided for @docStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get docStatusPending;

  /// No description provided for @docKindEmiratesID.
  ///
  /// In en, this message translates to:
  /// **'Emirates ID'**
  String get docKindEmiratesID;

  /// No description provided for @docKindPassport.
  ///
  /// In en, this message translates to:
  /// **'Passport'**
  String get docKindPassport;

  /// No description provided for @docKindFederationLicence.
  ///
  /// In en, this message translates to:
  /// **'Federation Licence'**
  String get docKindFederationLicence;

  /// No description provided for @docKindWorldTaekwondoCard.
  ///
  /// In en, this message translates to:
  /// **'WT Card'**
  String get docKindWorldTaekwondoCard;

  /// No description provided for @docKindMedicalClearance.
  ///
  /// In en, this message translates to:
  /// **'Medical Clearance'**
  String get docKindMedicalClearance;

  /// No description provided for @docKindImageRightsConsent.
  ///
  /// In en, this message translates to:
  /// **'Image Rights Consent'**
  String get docKindImageRightsConsent;

  /// No description provided for @docKindTravelPermission.
  ///
  /// In en, this message translates to:
  /// **'Travel Permission'**
  String get docKindTravelPermission;

  /// No description provided for @docKindSchoolID.
  ///
  /// In en, this message translates to:
  /// **'School ID'**
  String get docKindSchoolID;

  /// No description provided for @docKindOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get docKindOther;

  /// No description provided for @moreBeltProgression.
  ///
  /// In en, this message translates to:
  /// **'Belt progression'**
  String get moreBeltProgression;

  /// No description provided for @moreEmergencyContacts.
  ///
  /// In en, this message translates to:
  /// **'Emergency contacts'**
  String get moreEmergencyContacts;

  /// No description provided for @moreGoals.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get moreGoals;

  /// No description provided for @moreNone.
  ///
  /// In en, this message translates to:
  /// **'None recorded'**
  String get moreNone;

  /// No description provided for @goalActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get goalActive;

  /// No description provided for @goalCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get goalCompleted;

  /// No description provided for @goalAbandoned.
  ///
  /// In en, this message translates to:
  /// **'Abandoned'**
  String get goalAbandoned;

  /// No description provided for @notesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No coach notes'**
  String get notesEmpty;

  /// No description provided for @notePinned.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get notePinned;

  /// No description provided for @noteCatTechnical.
  ///
  /// In en, this message translates to:
  /// **'Technical'**
  String get noteCatTechnical;

  /// No description provided for @noteCatTactical.
  ///
  /// In en, this message translates to:
  /// **'Tactical'**
  String get noteCatTactical;

  /// No description provided for @noteCatBehavioural.
  ///
  /// In en, this message translates to:
  /// **'Behavioural'**
  String get noteCatBehavioural;

  /// No description provided for @noteCatMedical.
  ///
  /// In en, this message translates to:
  /// **'Medical'**
  String get noteCatMedical;

  /// No description provided for @noteCatMental.
  ///
  /// In en, this message translates to:
  /// **'Mental'**
  String get noteCatMental;

  /// No description provided for @noteCatGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get noteCatGeneral;

  /// No description provided for @medBloodType.
  ///
  /// In en, this message translates to:
  /// **'Blood type'**
  String get medBloodType;

  /// No description provided for @medHeight.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get medHeight;

  /// No description provided for @medFitToTrain.
  ///
  /// In en, this message translates to:
  /// **'Cleared to train'**
  String get medFitToTrain;

  /// No description provided for @medNotFit.
  ///
  /// In en, this message translates to:
  /// **'Not cleared'**
  String get medNotFit;

  /// No description provided for @medAllergies.
  ///
  /// In en, this message translates to:
  /// **'Allergies'**
  String get medAllergies;

  /// No description provided for @medConditions.
  ///
  /// In en, this message translates to:
  /// **'Conditions'**
  String get medConditions;

  /// No description provided for @medMedications.
  ///
  /// In en, this message translates to:
  /// **'Medications'**
  String get medMedications;

  /// No description provided for @medInjuries.
  ///
  /// In en, this message translates to:
  /// **'Injury log'**
  String get medInjuries;

  /// No description provided for @medWeightHistory.
  ///
  /// In en, this message translates to:
  /// **'Weight history'**
  String get medWeightHistory;

  /// No description provided for @medNone.
  ///
  /// In en, this message translates to:
  /// **'None recorded'**
  String get medNone;

  /// No description provided for @injuryMinor.
  ///
  /// In en, this message translates to:
  /// **'Minor'**
  String get injuryMinor;

  /// No description provided for @injuryModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get injuryModerate;

  /// No description provided for @injurySevere.
  ///
  /// In en, this message translates to:
  /// **'Severe'**
  String get injurySevere;

  /// No description provided for @attRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get attRateLabel;

  /// No description provided for @attEmpty.
  ///
  /// In en, this message translates to:
  /// **'No attendance records'**
  String get attEmpty;

  /// No description provided for @compEmpty.
  ///
  /// In en, this message translates to:
  /// **'No competitions yet'**
  String get compEmpty;

  /// No description provided for @compEvents.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get compEvents;

  /// No description provided for @compMedals.
  ///
  /// In en, this message translates to:
  /// **'Medals'**
  String get compMedals;

  /// No description provided for @navAnnouncements.
  ///
  /// In en, this message translates to:
  /// **'Announcements'**
  String get navAnnouncements;

  /// No description provided for @announcementsTitle.
  ///
  /// In en, this message translates to:
  /// **'Announcements'**
  String get announcementsTitle;

  /// No description provided for @announcementsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No announcements'**
  String get announcementsEmpty;

  /// No description provided for @annCatGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get annCatGeneral;

  /// No description provided for @annCatEvent.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get annCatEvent;

  /// No description provided for @annCatRegistration.
  ///
  /// In en, this message translates to:
  /// **'Registration'**
  String get annCatRegistration;

  /// No description provided for @annCatGrading.
  ///
  /// In en, this message translates to:
  /// **'Grading'**
  String get annCatGrading;

  /// No description provided for @annCatTournament.
  ///
  /// In en, this message translates to:
  /// **'Tournament'**
  String get annCatTournament;

  /// No description provided for @annCatPolicy.
  ///
  /// In en, this message translates to:
  /// **'Policy'**
  String get annCatPolicy;

  /// No description provided for @annCatRecognition.
  ///
  /// In en, this message translates to:
  /// **'Recognition'**
  String get annCatRecognition;

  /// No description provided for @annScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get annScheduled;

  /// No description provided for @navCertifications.
  ///
  /// In en, this message translates to:
  /// **'Certifications'**
  String get navCertifications;

  /// No description provided for @certificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Certifications'**
  String get certificationsTitle;

  /// No description provided for @certificationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No certifications'**
  String get certificationsEmpty;

  /// No description provided for @certOk.
  ///
  /// In en, this message translates to:
  /// **'Valid'**
  String get certOk;

  /// No description provided for @certExpiring.
  ///
  /// In en, this message translates to:
  /// **'Expiring'**
  String get certExpiring;

  /// No description provided for @certExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get certExpired;

  /// No description provided for @certExpiresInDays.
  ///
  /// In en, this message translates to:
  /// **'in {days}d'**
  String certExpiresInDays(int days);

  /// No description provided for @certExpiredAgo.
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String certExpiredAgo(int days);

  /// No description provided for @certKindFirstAid.
  ///
  /// In en, this message translates to:
  /// **'First Aid'**
  String get certKindFirstAid;

  /// No description provided for @certKindSafeguarding.
  ///
  /// In en, this message translates to:
  /// **'Safeguarding'**
  String get certKindSafeguarding;

  /// No description provided for @certKindWtCoaching.
  ///
  /// In en, this message translates to:
  /// **'WT Coaching'**
  String get certKindWtCoaching;

  /// No description provided for @certKindDoping.
  ///
  /// In en, this message translates to:
  /// **'Anti-Doping'**
  String get certKindDoping;

  /// No description provided for @certKindRefereeing.
  ///
  /// In en, this message translates to:
  /// **'Refereeing'**
  String get certKindRefereeing;

  /// No description provided for @navAudit.
  ///
  /// In en, this message translates to:
  /// **'Audit log'**
  String get navAudit;

  /// No description provided for @auditTitle.
  ///
  /// In en, this message translates to:
  /// **'Audit log'**
  String get auditTitle;

  /// No description provided for @auditEmpty.
  ///
  /// In en, this message translates to:
  /// **'No activity'**
  String get auditEmpty;

  /// No description provided for @navTournaments.
  ///
  /// In en, this message translates to:
  /// **'Tournaments'**
  String get navTournaments;

  /// No description provided for @tournamentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Tournaments'**
  String get tournamentsTitle;

  /// No description provided for @tournamentsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No tournaments'**
  String get tournamentsEmpty;

  /// No description provided for @tournUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get tournUpcoming;

  /// No description provided for @tournPast.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get tournPast;

  /// No description provided for @tournOfficial.
  ///
  /// In en, this message translates to:
  /// **'Official'**
  String get tournOfficial;

  /// No description provided for @tournRegistrations.
  ///
  /// In en, this message translates to:
  /// **'Registrations'**
  String get tournRegistrations;

  /// No description provided for @tournNoRegistrations.
  ///
  /// In en, this message translates to:
  /// **'No registrations'**
  String get tournNoRegistrations;

  /// No description provided for @tournPosition.
  ///
  /// In en, this message translates to:
  /// **'#{pos}'**
  String tournPosition(int pos);

  /// No description provided for @eventLevelLocal.
  ///
  /// In en, this message translates to:
  /// **'Local'**
  String get eventLevelLocal;

  /// No description provided for @eventLevelNational.
  ///
  /// In en, this message translates to:
  /// **'National'**
  String get eventLevelNational;

  /// No description provided for @eventLevelRegional.
  ///
  /// In en, this message translates to:
  /// **'Regional'**
  String get eventLevelRegional;

  /// No description provided for @eventLevelInternational.
  ///
  /// In en, this message translates to:
  /// **'International'**
  String get eventLevelInternational;

  /// No description provided for @regRegistered.
  ///
  /// In en, this message translates to:
  /// **'Registered'**
  String get regRegistered;

  /// No description provided for @regWeighedIn.
  ///
  /// In en, this message translates to:
  /// **'Weighed in'**
  String get regWeighedIn;

  /// No description provided for @regWithdrawn.
  ///
  /// In en, this message translates to:
  /// **'Withdrawn'**
  String get regWithdrawn;

  /// No description provided for @regDisqualified.
  ///
  /// In en, this message translates to:
  /// **'Disqualified'**
  String get regDisqualified;

  /// No description provided for @medalGold.
  ///
  /// In en, this message translates to:
  /// **'Gold'**
  String get medalGold;

  /// No description provided for @medalSilver.
  ///
  /// In en, this message translates to:
  /// **'Silver'**
  String get medalSilver;

  /// No description provided for @medalBronze.
  ///
  /// In en, this message translates to:
  /// **'Bronze'**
  String get medalBronze;

  /// No description provided for @weightCutTitle.
  ///
  /// In en, this message translates to:
  /// **'Weight cut'**
  String get weightCutTitle;

  /// No description provided for @weightCutLine.
  ///
  /// In en, this message translates to:
  /// **'{current} → {target} kg'**
  String weightCutLine(String current, String target);

  /// No description provided for @weightCutDelta.
  ///
  /// In en, this message translates to:
  /// **'{delta} kg to go'**
  String weightCutDelta(String delta);

  /// No description provided for @bracketTitle.
  ///
  /// In en, this message translates to:
  /// **'Bracket'**
  String get bracketTitle;

  /// No description provided for @bracketView.
  ///
  /// In en, this message translates to:
  /// **'View bracket'**
  String get bracketView;

  /// No description provided for @bracketEmpty.
  ///
  /// In en, this message translates to:
  /// **'No bracket for this event'**
  String get bracketEmpty;

  /// No description provided for @bracketFinal.
  ///
  /// In en, this message translates to:
  /// **'Final'**
  String get bracketFinal;

  /// No description provided for @bracketSemifinal.
  ///
  /// In en, this message translates to:
  /// **'Semifinal'**
  String get bracketSemifinal;

  /// No description provided for @bracketQuarterfinal.
  ///
  /// In en, this message translates to:
  /// **'Quarterfinal'**
  String get bracketQuarterfinal;

  /// No description provided for @bracketRoundFmt.
  ///
  /// In en, this message translates to:
  /// **'Round {n}'**
  String bracketRoundFmt(int n);

  /// No description provided for @navDrillTimer.
  ///
  /// In en, this message translates to:
  /// **'Drill Timer'**
  String get navDrillTimer;

  /// No description provided for @drillTimerTitle.
  ///
  /// In en, this message translates to:
  /// **'Drill Timer'**
  String get drillTimerTitle;

  /// No description provided for @presetTabata.
  ///
  /// In en, this message translates to:
  /// **'Tabata'**
  String get presetTabata;

  /// No description provided for @presetTabataDesc.
  ///
  /// In en, this message translates to:
  /// **'8 rounds · 20s work / 10s rest'**
  String get presetTabataDesc;

  /// No description provided for @presetRounds.
  ///
  /// In en, this message translates to:
  /// **'Sparring Rounds'**
  String get presetRounds;

  /// No description provided for @presetRoundsDesc.
  ///
  /// In en, this message translates to:
  /// **'3 rounds · 3min work / 1min rest'**
  String get presetRoundsDesc;

  /// No description provided for @presetEmom.
  ///
  /// In en, this message translates to:
  /// **'EMOM'**
  String get presetEmom;

  /// No description provided for @presetEmomDesc.
  ///
  /// In en, this message translates to:
  /// **'10 rounds · every minute'**
  String get presetEmomDesc;

  /// No description provided for @timerStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get timerStart;

  /// No description provided for @timerRoundFmt.
  ///
  /// In en, this message translates to:
  /// **'Round {round}/{total}'**
  String timerRoundFmt(int round, int total);

  /// No description provided for @timerDrillFmt.
  ///
  /// In en, this message translates to:
  /// **'Drill {n}/{total}'**
  String timerDrillFmt(int n, int total);

  /// No description provided for @phasePrepare.
  ///
  /// In en, this message translates to:
  /// **'Get ready'**
  String get phasePrepare;

  /// No description provided for @phaseWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get phaseWork;

  /// No description provided for @phaseRest.
  ///
  /// In en, this message translates to:
  /// **'Rest'**
  String get phaseRest;

  /// No description provided for @phaseRoundBreak.
  ///
  /// In en, this message translates to:
  /// **'Round break'**
  String get phaseRoundBreak;

  /// No description provided for @phaseFinished.
  ///
  /// In en, this message translates to:
  /// **'Done!'**
  String get phaseFinished;

  /// No description provided for @timerReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get timerReset;

  /// No description provided for @navLiveMatch.
  ///
  /// In en, this message translates to:
  /// **'Live Match'**
  String get navLiveMatch;

  /// No description provided for @liveMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'Live Match'**
  String get liveMatchTitle;

  /// No description provided for @lmSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'New Match'**
  String get lmSetupTitle;

  /// No description provided for @lmOpponent.
  ///
  /// In en, this message translates to:
  /// **'Opponent'**
  String get lmOpponent;

  /// No description provided for @lmOpponentHint.
  ///
  /// In en, this message translates to:
  /// **'Opponent name'**
  String get lmOpponentHint;

  /// No description provided for @lmStart.
  ///
  /// In en, this message translates to:
  /// **'Start match'**
  String get lmStart;

  /// No description provided for @lmBlue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get lmBlue;

  /// No description provided for @lmRed.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get lmRed;

  /// No description provided for @lmUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get lmUndo;

  /// No description provided for @lmEndRound.
  ///
  /// In en, this message translates to:
  /// **'End round'**
  String get lmEndRound;

  /// No description provided for @lmNextRound.
  ///
  /// In en, this message translates to:
  /// **'Next round'**
  String get lmNextRound;

  /// No description provided for @lmFinalize.
  ///
  /// In en, this message translates to:
  /// **'Finalize'**
  String get lmFinalize;

  /// No description provided for @lmRoundFmt.
  ///
  /// In en, this message translates to:
  /// **'Round {round}/{total}'**
  String lmRoundFmt(int round, int total);

  /// No description provided for @lmWinnerFmt.
  ///
  /// In en, this message translates to:
  /// **'{name} wins'**
  String lmWinnerFmt(String name);

  /// No description provided for @scoreHeadKick.
  ///
  /// In en, this message translates to:
  /// **'Head'**
  String get scoreHeadKick;

  /// No description provided for @scoreBodyKick.
  ///
  /// In en, this message translates to:
  /// **'Body'**
  String get scoreBodyKick;

  /// No description provided for @scoreTurnBodyKick.
  ///
  /// In en, this message translates to:
  /// **'Turn body'**
  String get scoreTurnBodyKick;

  /// No description provided for @scoreTurnHeadKick.
  ///
  /// In en, this message translates to:
  /// **'Turn head'**
  String get scoreTurnHeadKick;

  /// No description provided for @scorePunch.
  ///
  /// In en, this message translates to:
  /// **'Punch'**
  String get scorePunch;

  /// No description provided for @scorePenalty.
  ///
  /// In en, this message translates to:
  /// **'Penalty'**
  String get scorePenalty;

  /// No description provided for @authWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get authWelcome;

  /// No description provided for @authSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your SHJSDSC account'**
  String get authSubtitle;

  /// No description provided for @authEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmail;

  /// No description provided for @authPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPassword;

  /// No description provided for @authSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignIn;

  /// No description provided for @navSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get navSignOut;

  /// No description provided for @authName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get authName;

  /// No description provided for @authCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authCreateAccount;

  /// No description provided for @authSignUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get authSignUpTitle;

  /// No description provided for @authSignUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get authSignUp;

  /// No description provided for @authHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get authHaveAccount;

  /// No description provided for @navDevelopment.
  ///
  /// In en, this message translates to:
  /// **'Development'**
  String get navDevelopment;

  /// No description provided for @developmentTitle.
  ///
  /// In en, this message translates to:
  /// **'Coaching Development'**
  String get developmentTitle;

  /// No description provided for @developmentEmpty.
  ///
  /// In en, this message translates to:
  /// **'No assistant coaches yet'**
  String get developmentEmpty;

  /// No description provided for @devReadiness.
  ///
  /// In en, this message translates to:
  /// **'Readiness'**
  String get devReadiness;

  /// No description provided for @devMentor.
  ///
  /// In en, this message translates to:
  /// **'Mentor'**
  String get devMentor;

  /// No description provided for @devSessions.
  ///
  /// In en, this message translates to:
  /// **'{count} sessions'**
  String devSessions(int count);

  /// No description provided for @devLevelAthlete.
  ///
  /// In en, this message translates to:
  /// **'Athlete'**
  String get devLevelAthlete;

  /// No description provided for @devLevelAssistantCoach.
  ///
  /// In en, this message translates to:
  /// **'Assistant Coach'**
  String get devLevelAssistantCoach;

  /// No description provided for @devLevelJuniorCoach.
  ///
  /// In en, this message translates to:
  /// **'Junior Coach'**
  String get devLevelJuniorCoach;

  /// No description provided for @devLevelCoach.
  ///
  /// In en, this message translates to:
  /// **'Coach'**
  String get devLevelCoach;

  /// No description provided for @devLevelHeadCoach.
  ///
  /// In en, this message translates to:
  /// **'Head Coach'**
  String get devLevelHeadCoach;

  /// No description provided for @devLevelTechnicalDirector.
  ///
  /// In en, this message translates to:
  /// **'Technical Director'**
  String get devLevelTechnicalDirector;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @navChildren.
  ///
  /// In en, this message translates to:
  /// **'My Athletes'**
  String get navChildren;

  /// No description provided for @childrenTitle.
  ///
  /// In en, this message translates to:
  /// **'My Athletes'**
  String get childrenTitle;

  /// No description provided for @familyNoProfile.
  ///
  /// In en, this message translates to:
  /// **'No athlete profile is linked to this account'**
  String get familyNoProfile;

  /// No description provided for @familyNoChildren.
  ///
  /// In en, this message translates to:
  /// **'No athletes linked to this account'**
  String get familyNoChildren;
}

class _L10nDelegate extends LocalizationsDelegate<L10n> {
  const _L10nDelegate();

  @override
  Future<L10n> load(Locale locale) {
    return SynchronousFuture<L10n>(lookupL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_L10nDelegate old) => false;
}

L10n lookupL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return L10nAr();
    case 'en':
      return L10nEn();
  }

  throw FlutterError(
    'L10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
