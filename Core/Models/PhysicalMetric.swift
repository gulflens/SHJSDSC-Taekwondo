import Foundation

public enum BodySide: String, Codable, CaseIterable, Sendable, Hashable {
    case left, right
    public var labelKey: String { "body_side.\(rawValue)" }
}

public enum PhysicalCategory: String, Codable, CaseIterable, Sendable, Hashable {
    case flexibility, power, speed, endurance, strength, bodyComposition

    public var labelKey: String { "physical_category.\(rawValue)" }

    public var systemIcon: String {
        switch self {
        case .flexibility: "figure.flexibility"
        case .power: "bolt.fill"
        case .speed: "hare.fill"
        case .endurance: "lungs.fill"
        case .strength: "dumbbell.fill"
        case .bodyComposition: "scalemass.fill"
        }
    }
}

public enum TestFrequency: String, Codable, CaseIterable, Sendable, Hashable {
    case weekly, monthly, quarterly

    public var labelKey: String { "test_frequency.\(rawValue)" }

    /// Days between recommended captures.
    public var dayInterval: Int {
        switch self {
        case .weekly: 7
        case .monthly: 30
        case .quarterly: 90
        }
    }

    /// Past this many days beyond `dayInterval`, the test is considered overdue
    /// (red rather than amber).
    public var graceDays: Int {
        switch self {
        case .weekly: 3
        case .monthly: 7
        case .quarterly: 14
        }
    }
}

public enum PhysicalMetricKind: String, Codable, CaseIterable, Sendable, Hashable {
    // Flexibility
    case frontSplitCm
    case sideSplitCm
    case kickHeightHead
    case kickHeightChest
    case legRaiseAngle

    // Power
    case roundhouseForceBack
    case roundhouseForceFront
    case sideKickForce
    case verticalJumpCm
    case broadJumpCm

    // Speed
    case roundhouseKicks10s
    case backKicks10s
    case sprint20mSec
    case reactionMs

    // Endurance
    case yoyoLevel
    case twoMinKickTotal
    case plankSec

    // Strength
    case singleLegSquatReps
    case hollowBodyHoldSec
    case pushUps60s

    // Body composition
    case bodyWeightKg
    case bodyFatPct
    case restingHr

    public var labelKey: String { "metric.\(rawValue)" }

    public var category: PhysicalCategory {
        switch self {
        case .frontSplitCm, .sideSplitCm, .kickHeightHead, .kickHeightChest, .legRaiseAngle:
            .flexibility
        case .roundhouseForceBack, .roundhouseForceFront, .sideKickForce, .verticalJumpCm, .broadJumpCm:
            .power
        case .roundhouseKicks10s, .backKicks10s, .sprint20mSec, .reactionMs:
            .speed
        case .yoyoLevel, .twoMinKickTotal, .plankSec:
            .endurance
        case .singleLegSquatReps, .hollowBodyHoldSec, .pushUps60s:
            .strength
        case .bodyWeightKg, .bodyFatPct, .restingHr:
            .bodyComposition
        }
    }

    public var frequency: TestFrequency {
        switch self {
        case .frontSplitCm, .sideSplitCm, .kickHeightHead, .kickHeightChest: .monthly
        case .legRaiseAngle: .quarterly
        case .roundhouseForceBack, .roundhouseForceFront, .sideKickForce: .quarterly
        case .verticalJumpCm, .broadJumpCm: .quarterly
        case .roundhouseKicks10s, .backKicks10s: .monthly
        case .sprint20mSec, .reactionMs: .quarterly
        case .yoyoLevel: .quarterly
        case .twoMinKickTotal, .plankSec: .monthly
        case .singleLegSquatReps, .hollowBodyHoldSec, .pushUps60s: .quarterly
        case .bodyWeightKg, .restingHr: .weekly
        case .bodyFatPct: .monthly
        }
    }

    /// Display unit; empty string for pass/fail.
    public var unit: String {
        switch self {
        case .frontSplitCm, .sideSplitCm, .verticalJumpCm, .broadJumpCm: "cm"
        case .kickHeightHead, .kickHeightChest: ""
        case .legRaiseAngle: "°"
        case .roundhouseForceBack, .roundhouseForceFront, .sideKickForce: "kg"
        case .roundhouseKicks10s, .backKicks10s, .twoMinKickTotal: "kicks"
        case .sprint20mSec, .plankSec, .hollowBodyHoldSec: "s"
        case .reactionMs: "ms"
        case .yoyoLevel: "lvl"
        case .singleLegSquatReps, .pushUps60s: "reps"
        case .bodyWeightKg: "kg"
        case .bodyFatPct: "%"
        case .restingHr: "bpm"
        }
    }

    public var isPassFail: Bool {
        switch self {
        case .kickHeightHead, .kickHeightChest: true
        default: false
        }
    }

    /// Recorded once per leg (left + right are separate rows).
    public var isUnilateral: Bool {
        switch self {
        case .singleLegSquatReps: true
        default: false
        }
    }

    /// Stepper / slider hints (lower, upper, step).
    public var inputRange: (lower: Double, upper: Double, step: Double) {
        switch self {
        case .frontSplitCm, .sideSplitCm: (0, 60, 0.5)
        case .kickHeightHead, .kickHeightChest: (0, 1, 1)
        case .legRaiseAngle: (0, 180, 1)
        case .roundhouseForceBack, .roundhouseForceFront, .sideKickForce: (0, 600, 1)
        case .verticalJumpCm: (0, 80, 1)
        case .broadJumpCm: (0, 350, 1)
        case .roundhouseKicks10s, .backKicks10s: (0, 60, 1)
        case .sprint20mSec: (2.0, 6.0, 0.01)
        case .reactionMs: (100, 500, 1)
        case .yoyoLevel: (1, 21, 1)
        case .twoMinKickTotal: (0, 300, 1)
        case .plankSec, .hollowBodyHoldSec: (0, 300, 1)
        case .singleLegSquatReps, .pushUps60s: (0, 100, 1)
        case .bodyWeightKg: (15, 140, 0.1)
        case .bodyFatPct: (3, 50, 0.1)
        case .restingHr: (30, 120, 1)
        }
    }

    /// True if a higher raw number means a better result. Used for normalising
    /// the composite score and for trend-direction icons.
    public var higherIsBetter: Bool {
        switch self {
        case .sprint20mSec, .reactionMs,
             .frontSplitCm, .sideSplitCm,
             .bodyFatPct, .restingHr: false
        default: true
        }
    }

    /// 0...1 normalisation against the input range. Used by the composite.
    public func normalized(_ value: Double) -> Double {
        let r = inputRange
        guard r.upper > r.lower else { return 0 }
        let raw = (value - r.lower) / (r.upper - r.lower)
        let clamped = max(0, min(1, raw))
        return higherIsBetter ? clamped : 1 - clamped
    }
}

public struct PhysicalMetric: Codable, Identifiable, Hashable, Sendable {
    public let id: EntityID
    public var athleteID: EntityID
    public var recordedAt: Date
    public var recordedByCoachID: EntityID
    public var kind: PhysicalMetricKind
    /// Raw measurement in the kind's unit. For pass/fail kinds: 0 = fail, 1 = pass.
    public var value: Double
    /// Set only for unilateral kinds (e.g. single-leg squat). nil otherwise.
    public var leg: BodySide?
    public var notes: String?

    public init(
        id: EntityID = UUID(),
        athleteID: EntityID,
        recordedAt: Date,
        recordedByCoachID: EntityID,
        kind: PhysicalMetricKind,
        value: Double,
        leg: BodySide? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.athleteID = athleteID
        self.recordedAt = recordedAt
        self.recordedByCoachID = recordedByCoachID
        self.kind = kind
        self.value = value
        self.leg = leg
        self.notes = notes
    }
}

public extension Array where Element == PhysicalMetric {
    /// Latest entry per (kind, leg) tuple. Drives the dashboard "current values".
    func latestPerKind() -> [PhysicalMetric] {
        var seen: [String: PhysicalMetric] = [:]
        for m in self.sorted(by: { $0.recordedAt > $1.recordedAt }) {
            let key = "\(m.kind.rawValue)|\(m.leg?.rawValue ?? "-")"
            if seen[key] == nil { seen[key] = m }
        }
        return Array(seen.values)
    }
}
