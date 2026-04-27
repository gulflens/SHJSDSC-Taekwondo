import Foundation

public enum Permission: String, CaseIterable, Sendable, Hashable {
    case viewAllAthletes
    case editAthlete
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
}

public enum PermissionMatrix {

    public static func allowed(role: Role, permission: Permission) -> Bool {
        switch role {
        case .developer:
            return true

        case .admin:
            return true

        case .technicalDirector:
            switch permission {
            case .viewBilling, .manageStaff: return false
            default: return true
            }

        case .branchManager:
            switch permission {
            case .viewAllAthletes,
                 .editAthlete,
                 .recordAttendance,
                 .scoreGrading,
                 .scheduleSession,
                 .publishAnnouncement,
                 .exportReports,
                 .viewAuditLog,
                 .createTournament:
                return true
            default: return false
            }

        case .coach:
            switch permission {
            case .editAthlete,
                 .recordAttendance,
                 .scoreLiveMatch,
                 .scoreGrading,
                 .scheduleSession:
                return true
            default: return false
            }

        case .analyst:
            switch permission {
            case .viewAllAthletes, .exportReports: return true
            default: return false
            }

        case .athlete, .parent:
            return false
        }
    }
}
