import Foundation

/// Functional grouping of the role taxonomy — used by the Users console to
/// organise ~30 roles into scannable sections.
public enum RoleGroup: String, CaseIterable, Sendable, Hashable {
    case system
    case leadership
    case coaching
    case support
    case competition
    case grading
    case administration
    case members

    public var labelKey: String { "roleGroup.\(rawValue)" }
}

/// Coarse data-access tier surfaced as a chip in the Users console. The real
/// enforcement is `PermissionMatrix` (and, later, branch scope) — this is a
/// human-readable summary, not a security boundary.
public enum AccessLevel: String, CaseIterable, Sendable, Hashable {
    case full
    case branchLimited
    case readOnly
    case restricted

    public var labelKey: String { "accessLevel.\(rawValue)" }
}

/// How wide a role's data visibility reaches. Resolved into a concrete
/// `AccessScope` (with a branch id) by `AppSession.accessScope`.
public enum ScopeTier: String, Sendable, Hashable {
    case federation   // every branch
    case branch       // a single assigned branch
    case own          // only the user's own / linked records
}

/// Concrete, resolved data-visibility scope for the signed-in user.
public enum AccessScope: Sendable, Hashable {
    case all
    case branch(EntityID)
    case ownRecordsOnly

    /// Whether `branchID` is visible under this scope.
    public func includes(branchID: EntityID?) -> Bool {
        switch self {
        case .all: return true
        case .branch(let id): return branchID == id
        case .ownRecordsOnly: return false
        }
    }
}

public extension Role {
    /// How far this role can see across the federation.
    var scopeTier: ScopeTier {
        switch self {
        case .developer, .admin, .itSupport, .technicalDirector, .operationsManager,
             .analyst, .tournamentAdmin, .competitionCoordinator, .gradingExaminer,
             .finance, .hrManager, .federationViewer:
            .federation
        case .branchManager, .headCoach, .coach, .assistantCoach, .sparringCoach,
             .poomsaeCoach, .conditioningCoach, .demoTeamCoach, .teamPhysician,
             .physiotherapist, .sportsPsychologist, .nutritionist, .referee,
             .scorekeeper, .registrar, .frontDesk:
            .branch
        case .athlete, .parent, .alumni, .sponsor:
            .own
        }
    }
}

public extension Role {
    /// The taxonomy group this role belongs to.
    var group: RoleGroup {
        switch self {
        case .developer, .admin, .itSupport:
            .system
        case .technicalDirector, .operationsManager, .branchManager:
            .leadership
        case .headCoach, .coach, .assistantCoach, .sparringCoach,
             .poomsaeCoach, .conditioningCoach, .demoTeamCoach:
            .coaching
        case .teamPhysician, .physiotherapist, .sportsPsychologist,
             .nutritionist, .analyst:
            .support
        case .tournamentAdmin, .competitionCoordinator, .referee, .scorekeeper:
            .competition
        case .gradingExaminer:
            .grading
        case .registrar, .frontDesk, .finance, .hrManager:
            .administration
        case .athlete, .parent, .alumni, .federationViewer, .sponsor:
            .members
        }
    }

    /// Coarse access tier for display.
    var accessLevel: AccessLevel {
        switch self {
        case .developer, .admin, .technicalDirector, .operationsManager:
            .full
        case .branchManager, .headCoach, .coach, .assistantCoach, .sparringCoach,
             .poomsaeCoach, .conditioningCoach, .demoTeamCoach, .teamPhysician,
             .physiotherapist, .sportsPsychologist, .nutritionist, .frontDesk, .registrar:
            .branchLimited
        case .analyst, .federationViewer, .alumni, .sponsor, .athlete, .parent:
            .readOnly
        case .itSupport, .finance, .hrManager, .tournamentAdmin,
             .competitionCoordinator, .referee, .scorekeeper, .gradingExaminer:
            .restricted
        }
    }

    /// SF Symbol used to represent the role in lists, chips, and avatars.
    var icon: String {
        switch self {
        case .developer:             "hammer.fill"
        case .admin:                 "shield.lefthalf.filled"
        case .itSupport:             "wrench.and.screwdriver.fill"
        case .technicalDirector:     "checkmark.seal.fill"
        case .operationsManager:     "gearshape.2.fill"
        case .branchManager:         "building.2.fill"
        case .headCoach:             "figure.taekwondo"
        case .coach:                 "figure.taekwondo"
        case .assistantCoach:        "figure.taekwondo"
        case .sparringCoach:         "figure.kickboxing"
        case .poomsaeCoach:          "figure.martial.arts"
        case .conditioningCoach:     "dumbbell.fill"
        case .demoTeamCoach:         "sparkles"
        case .teamPhysician:         "stethoscope"
        case .physiotherapist:       "bandage.fill"
        case .sportsPsychologist:    "brain.head.profile"
        case .nutritionist:          "fork.knife"
        case .analyst:               "chart.bar.xaxis"
        case .tournamentAdmin:       "rosette"
        case .competitionCoordinator: "calendar.badge.clock"
        case .referee:               "flag.checkered"
        case .scorekeeper:           "number.square.fill"
        case .gradingExaminer:       "medal.fill"
        case .registrar:             "person.text.rectangle.fill"
        case .frontDesk:             "bell.fill"
        case .finance:               "creditcard.fill"
        case .hrManager:             "person.2.badge.gearshape.fill"
        case .athlete:               "figure.run"
        case .parent:                "figure.2.and.child.holdinghands"
        case .alumni:                "graduationcap.fill"
        case .federationViewer:      "eye.fill"
        case .sponsor:               "star.circle.fill"
        }
    }
}
