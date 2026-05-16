import Foundation

public enum TechniqueCategory: String, Codable, CaseIterable, Sendable, Hashable {
    case basicKicks
    case spinningJumpingKicks
    case handTechniques
    case footwork
    case defensive

    public var labelKey: String { "technique_category.\(rawValue)" }

    public var systemIcon: String {
        switch self {
        case .basicKicks: "figure.kickboxing"
        case .spinningJumpingKicks: "arrow.triangle.2.circlepath"
        case .handTechniques: "hand.raised.fill"
        case .footwork: "shoe.fill"
        case .defensive: "shield.fill"
        }
    }
}

public enum TechniqueKind: String, Codable, CaseIterable, Sendable, Hashable {
    // Basic kicks (9)
    case frontKick                  // ap-chagi
    case roundhouseBack             // dollyo-chagi (back leg)
    case roundhouseFront            // dollyo-chagi (front leg)
    case sideKick                   // yop-chagi
    case backKick                   // dwit-chagi
    case axeKick                    // naeryeo-chagi
    case hookKick                   // huryeo-chagi
    case pushKick                   // mireo-chagi
    case crescentKick

    // Spinning / jumping kicks (8)
    case spinningHookKick
    case spinningBackKick
    case tornadoKick                // 360 roundhouse
    case jumpingBackKick
    case jumpingRoundhouse
    case scissorKick                // gawi-chagi
    case twimyoDollyo               // jump roundhouse (different mechanic vs jumping roundhouse)
    case kick540                    // 540 kick (advanced)

    // Hand techniques (4)
    case jabPunch
    case crossPunch
    case backFistStrike
    case knifeHandStrike

    // Footwork (6)
    case switchStep
    case slideStep
    case pushStep
    case cutStep
    case pivot
    case skipStep

    // Defensive (6)
    case blockHigh
    case blockMiddle
    case blockLow
    case parry
    case evasionLeanBack
    case clinchAndBreak

    public var labelKey: String { "technique.\(rawValue)" }

    public var category: TechniqueCategory {
        switch self {
        case .frontKick, .roundhouseBack, .roundhouseFront, .sideKick, .backKick,
             .axeKick, .hookKick, .pushKick, .crescentKick:
            .basicKicks
        case .spinningHookKick, .spinningBackKick, .tornadoKick, .jumpingBackKick,
             .jumpingRoundhouse, .scissorKick, .twimyoDollyo, .kick540:
            .spinningJumpingKicks
        case .jabPunch, .crossPunch, .backFistStrike, .knifeHandStrike:
            .handTechniques
        case .switchStep, .slideStep, .pushStep, .cutStep, .pivot, .skipStep:
            .footwork
        case .blockHigh, .blockMiddle, .blockLow, .parry, .evasionLeanBack, .clinchAndBreak:
            .defensive
        }
    }
}

public struct TechnicalSkill: Codable, Identifiable, Hashable, Sendable {
    public let id: EntityID
    public var athleteID: EntityID
    public var recordedAt: Date
    public var recordedByCoachID: EntityID
    public var kind: TechniqueKind
    /// 1...10 — how cleanly the technique is executed in isolation.
    public var formScore: Int
    /// 1...10 — how effectively the technique is used in sparring/scenarios.
    public var applicationScore: Int
    public var videoURL: String?
    public var notes: String?

    public init(
        id: EntityID = UUID(),
        athleteID: EntityID,
        recordedAt: Date,
        recordedByCoachID: EntityID,
        kind: TechniqueKind,
        formScore: Int,
        applicationScore: Int,
        videoURL: String? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.athleteID = athleteID
        self.recordedAt = recordedAt
        self.recordedByCoachID = recordedByCoachID
        self.kind = kind
        self.formScore = max(1, min(10, formScore))
        self.applicationScore = max(1, min(10, applicationScore))
        self.videoURL = videoURL
        self.notes = notes
    }

    /// Mean of form + application, 1...10.
    public var averageScore: Double {
        Double(formScore + applicationScore) / 2.0
    }
}

public extension Array where Element == TechnicalSkill {
    /// Latest skill capture per kind. Drives the dashboard "current scores".
    func latestPerKind() -> [TechnicalSkill] {
        var seen: [TechniqueKind: TechnicalSkill] = [:]
        for s in self.sorted(by: { $0.recordedAt > $1.recordedAt }) {
            if seen[s.kind] == nil { seen[s.kind] = s }
        }
        return Array(seen.values)
    }

    /// Average of (form+app)/2 across the latest capture of each assessed kind.
    /// Returns 0 when no skills have been captured.
    var latestAverageScore: Double {
        let latest = latestPerKind()
        guard !latest.isEmpty else { return 0 }
        let sum = latest.map(\.averageScore).reduce(0, +)
        return sum / Double(latest.count)
    }
}
