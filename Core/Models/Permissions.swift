import Foundation

public enum Permission: String, CaseIterable, Sendable, Hashable {
    case viewAllAthletes
    case editAthlete
    case editCoach
    case recordAttendance
    case scoreGrading
    case scheduleSession
    case createTournament
    case scoreLiveMatch
    case publishAnnouncement
    case exportReports
    case viewBilling
    case manageStaff
    case viewAuditLog
    // Stage 1.5: branch profile editing. Stage 4 will tighten the matrix.
    case editBranchProfile
    case editBranchFinancials
    case editBranchInventory
    case editBranchPrograms
    case viewBranchFinancials
}

public enum PermissionMatrix {

    public static func allowed(role: Role, permission: Permission) -> Bool {
        switch role {
        case .developer:
            return true

        case .admin, .operationsManager:
            // Audit log is Developer-only — even full admins are excluded.
            return permission != .viewAuditLog

        case .technicalDirector:
            switch permission {
            case .viewBilling, .manageStaff, .viewAuditLog: return false
            default: return true
            }

        case .branchManager:
            switch permission {
            case .viewAllAthletes,
                 .editAthlete,
                 .editCoach,
                 .recordAttendance,
                 .scoreGrading,
                 .scheduleSession,
                 .publishAnnouncement,
                 .exportReports,
                 .createTournament,
                 .editBranchProfile,
                 .editBranchInventory,
                 .editBranchPrograms,
                 .viewBranchFinancials:
                return true
            default: return false
            }

        case .coach, .headCoach, .assistantCoach, .sparringCoach,
             .poomsaeCoach, .conditioningCoach, .demoTeamCoach:
            switch permission {
            case .editAthlete,
                 .recordAttendance,
                 .scoreLiveMatch,
                 .scoreGrading,
                 .scheduleSession:
                return true
            default: return false
            }

        // Medical & athlete-support staff — read athletes and edit their
        // records, but no coaching/scoring authority.
        case .teamPhysician, .physiotherapist, .sportsPsychologist, .nutritionist:
            switch permission {
            case .viewAllAthletes, .editAthlete: return true
            default: return false
            }

        case .analyst, .federationViewer:
            switch permission {
            case .viewAllAthletes, .exportReports: return true
            default: return false
            }

        case .gradingExaminer:
            switch permission {
            case .viewAllAthletes, .scoreGrading: return true
            default: return false
            }

        case .tournamentAdmin, .competitionCoordinator:
            switch permission {
            case .createTournament, .scoreLiveMatch, .exportReports: return true
            default: return false
            }

        case .referee, .scorekeeper:
            switch permission {
            case .scoreLiveMatch: return true
            default: return false
            }

        case .registrar, .frontDesk:
            switch permission {
            case .viewAllAthletes: return true
            default: return false
            }

        case .finance:
            switch permission {
            case .viewBilling, .viewBranchFinancials, .editBranchFinancials, .exportReports:
                return true
            default: return false
            }

        case .hrManager:
            switch permission {
            case .manageStaff, .editCoach: return true
            default: return false
            }

        case .itSupport:
            switch permission {
            case .manageStaff: return true
            default: return false
            }

        case .athlete, .parent, .alumni, .sponsor:
            return false
        }
    }
}
