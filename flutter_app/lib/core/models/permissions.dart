// Port of Core/Models/Permissions.swift.
// NOT Codable in Swift — plain enum + static class. No fromJson/toJson.
// Pure Dart — no Flutter imports (logic-layer rule).

import 'role.dart';

enum Permission {
  viewAllAthletes,
  editAthlete,
  editCoach,
  recordAttendance,
  scoreGrading,
  scheduleSession,
  createTournament,
  scoreLiveMatch,
  publishAnnouncement,
  exportReports,
  viewBilling,
  manageStaff,
  viewAuditLog,
  // Stage 1.5: branch profile editing.
  editBranchProfile,
  editBranchFinancials,
  editBranchInventory,
  editBranchPrograms,
  viewBranchFinancials,
}

/// Swift `PermissionMatrix` was an enum namespace of static funcs.
/// Ported as a Dart class with a private constructor and a single static
/// method mirroring `PermissionMatrix.allowed(role:permission:)`.
class PermissionMatrix {
  PermissionMatrix._();

  static bool allowed(Role role, Permission permission) {
    switch (role) {
      case Role.developer:
        return true;

      case Role.admin:
      case Role.operationsManager:
        // Audit log is Developer-only — even full admins are excluded.
        return permission != Permission.viewAuditLog;

      case Role.technicalDirector:
        switch (permission) {
          case Permission.viewBilling:
          case Permission.manageStaff:
          case Permission.viewAuditLog:
            return false;
          default:
            return true;
        }

      case Role.branchManager:
        switch (permission) {
          case Permission.viewAllAthletes:
          case Permission.editAthlete:
          case Permission.editCoach:
          case Permission.recordAttendance:
          case Permission.scoreGrading:
          case Permission.scheduleSession:
          case Permission.publishAnnouncement:
          case Permission.exportReports:
          case Permission.createTournament:
          case Permission.editBranchProfile:
          case Permission.editBranchInventory:
          case Permission.editBranchPrograms:
          case Permission.viewBranchFinancials:
            return true;
          default:
            return false;
        }

      case Role.coach:
      case Role.headCoach:
      case Role.assistantCoach:
      case Role.sparringCoach:
      case Role.poomsaeCoach:
      case Role.conditioningCoach:
      case Role.demoTeamCoach:
        switch (permission) {
          case Permission.editAthlete:
          case Permission.recordAttendance:
          case Permission.scoreLiveMatch:
          case Permission.scoreGrading:
          case Permission.scheduleSession:
            return true;
          default:
            return false;
        }

      // Medical & athlete-support staff.
      case Role.teamPhysician:
      case Role.physiotherapist:
      case Role.sportsPsychologist:
      case Role.nutritionist:
        switch (permission) {
          case Permission.viewAllAthletes:
          case Permission.editAthlete:
            return true;
          default:
            return false;
        }

      case Role.analyst:
      case Role.federationViewer:
        switch (permission) {
          case Permission.viewAllAthletes:
          case Permission.exportReports:
            return true;
          default:
            return false;
        }

      case Role.gradingExaminer:
        switch (permission) {
          case Permission.viewAllAthletes:
          case Permission.scoreGrading:
            return true;
          default:
            return false;
        }

      case Role.tournamentAdmin:
      case Role.competitionCoordinator:
        switch (permission) {
          case Permission.createTournament:
          case Permission.scoreLiveMatch:
          case Permission.exportReports:
            return true;
          default:
            return false;
        }

      case Role.referee:
      case Role.scorekeeper:
        switch (permission) {
          case Permission.scoreLiveMatch:
            return true;
          default:
            return false;
        }

      case Role.registrar:
      case Role.frontDesk:
        switch (permission) {
          case Permission.viewAllAthletes:
            return true;
          default:
            return false;
        }

      case Role.finance:
        switch (permission) {
          case Permission.viewBilling:
          case Permission.viewBranchFinancials:
          case Permission.editBranchFinancials:
          case Permission.exportReports:
            return true;
          default:
            return false;
        }

      case Role.hrManager:
        switch (permission) {
          case Permission.manageStaff:
          case Permission.editCoach:
            return true;
          default:
            return false;
        }

      case Role.itSupport:
        switch (permission) {
          case Permission.manageStaff:
            return true;
          default:
            return false;
        }

      case Role.athlete:
      case Role.parent:
      case Role.alumni:
      case Role.sponsor:
        return false;
    }
  }
}
