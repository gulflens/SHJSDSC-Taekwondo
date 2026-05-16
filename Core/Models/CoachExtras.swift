import Foundation

// Embedded enums + structs that hang off Coach for the federation-grade
// profile redesign (Stage 1.6). Mirrors the Athlete dossier pattern — no new
// Repository methods, keeps the Android port mechanical.

public enum CoachLevel: String, Codable, CaseIterable, Sendable, Hashable {
    case assistant, junior, senior, head, national, international

    public var labelKey: String { "coach.level.\(rawValue)" }
}

public enum CoachLicenseLevel: String, Codable, CaseIterable, Sendable, Hashable {
    case poom2, poom1, dan1, dan2, dan3, dan4, dan5plus

    public var labelKey: String { "coach.license.\(rawValue)" }
}

public enum CoachSpecialisation: String, Codable, CaseIterable, Sendable, Hashable {
    case kyorugi, poomsae, technical, fitness, sparring, multi

    public var labelKey: String { "coach.specialisation.\(rawValue)" }

    public var systemIcon: String {
        switch self {
        case .kyorugi: "figure.martial.arts"
        case .poomsae: "figure.mind.and.body"
        case .technical: "figure.taichi"
        case .fitness: "figure.run"
        case .sparring: "figure.boxing"
        case .multi: "circle.grid.3x3.fill"
        }
    }
}

public enum CoachEmploymentStatus: String, Codable, CaseIterable, Sendable, Hashable {
    case active, leave, transferred, retired, suspended

    public var labelKey: String { "coach.employment.\(rawValue)" }
}

public enum CoachProgramStatus: String, Codable, CaseIterable, Sendable, Hashable {
    case none, candidate, supportStaff, member, leadStaff

    public var labelKey: String { "coach.program.\(rawValue)" }
}

/// Cross-federation ranking snapshot for a coach. Nil fields render as "—".
public struct CoachRanking: Codable, Hashable, Sendable {
    /// Internal rank inside SSDC (across all coaches).
    public var club: Int?
    /// UAE Taekwondo Federation coach standing.
    public var uae: Int?
    /// World Taekwondo recognition tier label (e.g. "Class A", "Class B").
    /// String — WT publishes tiers, not numeric ranks.
    public var worldTier: String?
    public var asOf: Date

    public init(club: Int? = nil, uae: Int? = nil, worldTier: String? = nil, asOf: Date = Date()) {
        self.club = club
        self.uae = uae
        self.worldTier = worldTier
        self.asOf = asOf
    }
}
