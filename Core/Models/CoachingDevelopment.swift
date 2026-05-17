import Foundation

// Coaching-development model layer (Stage 1.15).
//
// SSDC's coaching structure is a *sports development pathway*, not a corporate
// hierarchy. An Assistant Coach is NOT a standalone staff entity — it is an
// active `Athlete` who additionally carries a coaching dossier. The duality is
// expressed entirely on `Athlete`:
//
//     athlete.programRoles.contains(.assistantCoach)   // wears the coaching hat
//     athlete.assistantCoach                           // the coaching dossier
//
// This keeps the Repository surface stable (embedded-dossier pattern) and the
// athlete keeps every athlete capability — belt, attendance, competitions.
//
// Pure data only — no SwiftUI/UIKit imports. Colour tints live in the UX layer
// (`Features/Coaching/CoachingKit.swift`), mirroring `DrillCategory.tint`.

// MARK: - Program roles

/// A program membership an athlete holds *in addition* to being an athlete.
/// Rendered as pastel chips in the athlete profile's Roles section. One user
/// can hold several at once — this is the multi-role pathway.
public enum ProgramRole: String, Codable, CaseIterable, Sendable, Hashable, Identifiable {
    case athlete
    case assistantCoach
    case competitionTeam
    case eliteSquad
    case demoTeam

    public var id: String { rawValue }
    public var labelKey: String { "programRole.\(rawValue)" }

    public var systemIcon: String {
        switch self {
        case .athlete:         "figure.run"
        case .assistantCoach:  "figure.taekwondo"
        case .competitionTeam: "flame.fill"
        case .eliteSquad:      "star.circle.fill"
        case .demoTeam:        "sparkles"
        }
    }

    /// Stable display order for chip rows — independent of `Set` iteration.
    public static func ordered(_ roles: Set<ProgramRole>) -> [ProgramRole] {
        allCases.filter { roles.contains($0) }
    }
}

// MARK: - Coaching permissions

/// A discrete action in the coaching workflow. Assistant coaches hold a
/// *subset* — the senior-coach actions in `restricted` are never granted at
/// this development tier. This is supervision-by-design, not flat permissions.
public enum CoachingPermission: String, Codable, CaseIterable, Sendable, Hashable, Identifiable {
    // Allowed at the assistant-coach tier.
    case takeAttendance
    case assistWarmUp
    case assistDrills
    case supportCompetitions
    case monitorKidsGroups
    case uploadSessionNotes
    case assistDuringClasses
    // Restricted — senior-coach / management only.
    case approveGrading
    case suspendAthlete
    case manageBranch
    case evaluateCoaches
    case systemAdministration

    public var id: String { rawValue }
    public var labelKey: String { "coachingPermission.\(rawValue)" }

    /// Actions an assistant coach is allowed to be granted.
    public static let assistantCoachGrantable: [CoachingPermission] = [
        .takeAttendance, .assistWarmUp, .assistDrills, .supportCompetitions,
        .monitorKidsGroups, .uploadSessionNotes, .assistDuringClasses
    ]

    /// Senior-coach / management actions an assistant coach can never hold.
    public static let restricted: [CoachingPermission] = [
        .approveGrading, .suspendAthlete, .manageBranch,
        .evaluateCoaches, .systemAdministration
    ]

    public var isRestricted: Bool { Self.restricted.contains(self) }

    public var systemIcon: String {
        switch self {
        case .takeAttendance:      "checklist"
        case .assistWarmUp:        "figure.cooldown"
        case .assistDrills:        "list.bullet.clipboard"
        case .supportCompetitions: "trophy.fill"
        case .monitorKidsGroups:   "figure.2.and.child.holdinghands"
        case .uploadSessionNotes:  "square.and.pencil"
        case .assistDuringClasses: "person.2.fill"
        case .approveGrading:      "medal.fill"
        case .suspendAthlete:      "nosign"
        case .manageBranch:        "building.2.fill"
        case .evaluateCoaches:     "person.crop.circle.badge.checkmark"
        case .systemAdministration: "gearshape.fill"
        }
    }
}

// MARK: - Development pipeline

/// A stage in the coaching-development pipeline. The pathway runs
/// athlete → assistantCoach → juniorCoach → coach → headCoach → technicalDirector.
/// An athlete on the coaching pathway sits at `.assistantCoach` or `.juniorCoach`.
public enum DevelopmentLevel: String, Codable, CaseIterable, Sendable, Hashable, Identifiable {
    case athlete
    case assistantCoach
    case juniorCoach
    case coach
    case headCoach
    case technicalDirector

    public var id: String { rawValue }
    public var labelKey: String { "developmentLevel.\(rawValue)" }

    /// 0-based position along the pipeline.
    public var stageIndex: Int { Self.allCases.firstIndex(of: self) ?? 0 }

    /// The next rung up the pathway, or nil at the top.
    public var next: DevelopmentLevel? {
        let all = Self.allCases
        guard let i = all.firstIndex(of: self), i + 1 < all.count else { return nil }
        return all[i + 1]
    }

    public var systemIcon: String {
        switch self {
        case .athlete:           "figure.run"
        case .assistantCoach:    "hand.raised.fill"
        case .juniorCoach:       "figure.taekwondo"
        case .coach:             "figure.martial.arts"
        case .headCoach:         "star.fill"
        case .technicalDirector: "checkmark.seal.fill"
        }
    }
}

// MARK: - Coaching evaluation

/// A coaching evaluation recorded by a supervising coach for an assistant
/// coach. This is mentorship feedback — leadership growth, reliability — not
/// an HR performance review. Scores are 1...5.
public struct CoachingEvaluation: Codable, Identifiable, Hashable, Sendable {
    public let id: EntityID
    public var date: Date
    public var evaluatorCoachID: EntityID?
    public var evaluatorName: String
    /// 1...5 — overall coaching performance.
    public var overallScore: Int
    /// 1...5 — reliability and dependability running sessions.
    public var reliability: Int
    /// 1...5 — leadership, communication, and rapport with athletes.
    public var leadership: Int
    public var notes: String

    public init(
        id: EntityID = UUID(),
        date: Date,
        evaluatorCoachID: EntityID? = nil,
        evaluatorName: String,
        overallScore: Int,
        reliability: Int,
        leadership: Int,
        notes: String = ""
    ) {
        self.id = id
        self.date = date
        self.evaluatorCoachID = evaluatorCoachID
        self.evaluatorName = evaluatorName
        self.overallScore = max(1, min(5, overallScore))
        self.reliability = max(1, min(5, reliability))
        self.leadership = max(1, min(5, leadership))
        self.notes = notes
    }
}

// MARK: - Assistant-coach dossier

/// Coaching dossier embedded on an `Athlete` who also serves as an assistant
/// coach. Its presence — together with `.assistantCoach` in `programRoles` —
/// is what makes the athlete an assistant coach. There is deliberately no
/// standalone `AssistantCoach` entity: the athlete keeps every athlete
/// capability and gains a coaching layer on top.
public struct AssistantCoachProfile: Codable, Hashable, Sendable {
    /// The senior coach mentoring this assistant coach. May differ from the
    /// athlete's `primaryCoachID` — mentorship is its own relationship.
    public var supervisingCoachID: EntityID?
    /// Branch where the assistant coach principally helps.
    public var primaryBranchID: EntityID
    /// Branches the assistant coach additionally supports.
    public var supportBranchIDs: [EntityID]
    /// The coaching actions this assistant coach is cleared to perform.
    public var permissions: Set<CoachingPermission>
    /// Current rung on the coaching-development pipeline.
    public var developmentLevel: DevelopmentLevel
    /// Date the athlete began their coaching pathway.
    public var startedCoachingAt: Date
    /// Sessions the assistant coach has helped run.
    public var assistedSessionCount: Int
    /// Coaching evaluations from supervising coaches — newest first by
    /// convention; views sort defensively anyway.
    public var evaluations: [CoachingEvaluation]

    public init(
        supervisingCoachID: EntityID? = nil,
        primaryBranchID: EntityID,
        supportBranchIDs: [EntityID] = [],
        permissions: Set<CoachingPermission> = Set(CoachingPermission.assistantCoachGrantable),
        developmentLevel: DevelopmentLevel = .assistantCoach,
        startedCoachingAt: Date,
        assistedSessionCount: Int = 0,
        evaluations: [CoachingEvaluation] = []
    ) {
        self.supervisingCoachID = supervisingCoachID
        self.primaryBranchID = primaryBranchID
        self.supportBranchIDs = supportBranchIDs
        // Restricted actions can never be held at the assistant-coach tier.
        self.permissions = permissions.filter { !$0.isRestricted }
        self.developmentLevel = developmentLevel
        self.startedCoachingAt = startedCoachingAt
        self.assistedSessionCount = max(0, assistedSessionCount)
        self.evaluations = evaluations
    }

    /// Mean overall evaluation score, 0...5. Nil when never evaluated.
    public var coachEvaluationScore: Double? {
        guard !evaluations.isEmpty else { return nil }
        let total = evaluations.reduce(0) { $0 + $1.overallScore }
        return Double(total) / Double(evaluations.count)
    }

    /// Mean reliability score, 0...5. Nil when never evaluated.
    public var reliabilityScore: Double? {
        guard !evaluations.isEmpty else { return nil }
        let total = evaluations.reduce(0) { $0 + $1.reliability }
        return Double(total) / Double(evaluations.count)
    }

    /// Mean leadership score, 0...5. Nil when never evaluated.
    public var leadershipScore: Double? {
        guard !evaluations.isEmpty else { return nil }
        let total = evaluations.reduce(0) { $0 + $1.leadership }
        return Double(total) / Double(evaluations.count)
    }

    /// Whole months the athlete has been on the coaching pathway.
    public var monthsCoaching: Int {
        Calendar.current.dateComponents([.month], from: startedCoachingAt, to: Date()).month ?? 0
    }

    /// 0...1 readiness for promotion to the next development level. Blends the
    /// evaluation score (50%), assisted-session volume (30%), and how broad
    /// the granted permission set is (20%). Deterministic — no analytics table.
    public var promotionReadiness: Double {
        let evalComponent = ((coachEvaluationScore ?? 0) / 5.0) * 0.5
        let sessionComponent = min(Double(assistedSessionCount) / 120.0, 1.0) * 0.3
        let grantable = Double(CoachingPermission.assistantCoachGrantable.count)
        let permissionComponent = (grantable > 0
            ? Double(permissions.count) / grantable
            : 0) * 0.2
        return max(0, min(1, evalComponent + sessionComponent + permissionComponent))
    }
}
