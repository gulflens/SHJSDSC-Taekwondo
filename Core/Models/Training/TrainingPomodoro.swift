import Foundation

public enum WorkRest: String, Codable, Sendable, Hashable, CaseIterable {
    case work, rest

    public var labelKey: String { "pomodoro.\(rawValue)" }
}

public struct PomodoroInterval: Codable, Identifiable, Hashable, Sendable {
    public let id: EntityID
    public var kind: WorkRest
    public var durationSeconds: Int

    public init(id: EntityID = UUID(), kind: WorkRest, durationSeconds: Int) {
        self.id = id
        self.kind = kind
        self.durationSeconds = durationSeconds
    }

    /// Snaps a candidate value to the nearest valid step for the given phase.
    /// Work intervals are 30s+ in 10s increments, rest intervals are 5s+ in
    /// 5s increments.
    public static func snap(_ raw: Int, kind: WorkRest) -> Int {
        switch kind {
        case .work:
            let clamped = max(30, raw)
            let stepped = ((clamped - 30) / 10) * 10 + 30
            return stepped
        case .rest:
            let clamped = max(5, raw)
            let stepped = ((clamped - 5) / 5) * 5 + 5
            return stepped
        }
    }
}

public struct PomodoroGroup: Codable, Identifiable, Hashable, Sendable {
    public let id: EntityID
    public var name: String?
    public var nameAr: String?
    public var repetitions: Int
    public var intervals: [PomodoroInterval]

    public init(
        id: EntityID = UUID(),
        name: String? = nil,
        nameAr: String? = nil,
        repetitions: Int = 1,
        intervals: [PomodoroInterval] = []
    ) {
        self.id = id
        self.name = name
        self.nameAr = nameAr
        self.repetitions = max(1, repetitions)
        self.intervals = intervals
    }

    public var totalSecondsPerRound: Int {
        intervals.reduce(0) { $0 + $1.durationSeconds }
    }

    public var totalSeconds: Int { totalSecondsPerRound * repetitions }
}

public struct TrainingPomodoro: Codable, Identifiable, Hashable, Sendable {
    public let id: EntityID
    public var name: String
    public var nameAr: String
    public var groups: [PomodoroGroup]
    /// Length in seconds of the transition whistle. Validated 1...5.
    public var whistleSeconds: Double
    public var createdByCoachID: EntityID?
    public var createdAt: Date

    public init(
        id: EntityID = UUID(),
        name: String,
        nameAr: String = "",
        groups: [PomodoroGroup] = [],
        whistleSeconds: Double = 2,
        createdByCoachID: EntityID? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.nameAr = nameAr
        self.groups = groups
        self.whistleSeconds = min(5, max(1, whistleSeconds))
        self.createdByCoachID = createdByCoachID
        self.createdAt = createdAt
    }

    public var totalSeconds: Int {
        groups.reduce(0) { $0 + $1.totalSeconds }
    }
}
