import Foundation

// MARK: - Drill Timer model
//
// Stage 1.8 — the from-scratch operational timer for the Drills hub. A
// `DrillTimerSession` is a flat, ordered list of work/rest intervals plus a
// round multiplier, an optional lead-in, a between-rounds break, and optional
// athlete groups for station rotation. Pure data — Android-portable.

/// Phase the running timer is in. Drives colour, label, and audio.
public enum DrillTimerPhase: String, Codable, Sendable, Hashable, CaseIterable {
    case prepare      // lead-in countdown before the first interval
    case work
    case rest
    case roundBreak   // longer rest inserted between rounds
    case finished

    public var labelKey: String { "timer.phase.\(rawValue)" }

    /// Work-like phases drive the "active" visual treatment.
    public var isEffort: Bool { self == .work }
}

/// One interval in a session — a fixed span of work or rest. A work interval
/// may carry a free-text label and/or a `drillID` so a session can be a
/// sequenced run through real library drills.
public struct DrillTimerInterval: Codable, Identifiable, Hashable, Sendable {
    public let id: EntityID
    public var isWork: Bool
    public var seconds: Int
    public var label: String?
    public var drillID: EntityID?

    public init(
        id: EntityID = UUID(),
        isWork: Bool,
        seconds: Int,
        label: String? = nil,
        drillID: EntityID? = nil
    ) {
        self.id = id
        self.isWork = isWork
        self.seconds = max(1, seconds)
        self.label = label
        self.drillID = drillID
    }
}

/// A complete timer configuration. Not persisted in Stage 1.8 — built fresh
/// from a preset or the in-app builder each session.
public struct DrillTimerSession: Codable, Identifiable, Hashable, Sendable {
    public let id: EntityID
    public var name: String
    public var nameAr: String
    public var prepareSeconds: Int
    public var intervals: [DrillTimerInterval]
    public var rounds: Int
    public var roundBreakSeconds: Int
    /// Athlete groups for station rotation. Empty → grouping off. When set,
    /// round *r* is owned by `athleteGroups[(r-1) % count]`.
    public var athleteGroups: [String]
    public var createdAt: Date

    public init(
        id: EntityID = UUID(),
        name: String,
        nameAr: String = "",
        prepareSeconds: Int = 10,
        intervals: [DrillTimerInterval] = [],
        rounds: Int = 1,
        roundBreakSeconds: Int = 0,
        athleteGroups: [String] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.nameAr = nameAr
        self.prepareSeconds = max(0, prepareSeconds)
        self.intervals = intervals
        self.rounds = max(1, rounds)
        self.roundBreakSeconds = max(0, roundBreakSeconds)
        self.athleteGroups = athleteGroups
        self.createdAt = createdAt
    }

    /// Number of work intervals in a single round.
    public var workPerRound: Int { intervals.filter(\.isWork).count }

    /// Total work intervals across every round.
    public var totalWorkIntervals: Int { workPerRound * rounds }

    public var secondsPerRound: Int { intervals.reduce(0) { $0 + $1.seconds } }

    /// Full wall-clock length including lead-in and round breaks.
    public var totalSeconds: Int {
        prepareSeconds
            + secondsPerRound * rounds
            + roundBreakSeconds * max(0, rounds - 1)
    }

    public var usesGroups: Bool { !athleteGroups.isEmpty }
}

// MARK: - Presets

public extension DrillTimerSession {
    /// Classic Tabata — 8 × (20s work / 10s rest).
    static func tabata() -> DrillTimerSession {
        DrillTimerSession(
            name: "Tabata",
            nameAr: "تاباتا",
            prepareSeconds: 10,
            intervals: [
                DrillTimerInterval(isWork: true, seconds: 20),
                DrillTimerInterval(isWork: false, seconds: 10),
            ],
            rounds: 8
        )
    }

    /// Sparring rounds — 3 × (3 min work / 1 min rest).
    static func rounds() -> DrillTimerSession {
        DrillTimerSession(
            name: "Sparring Rounds",
            nameAr: "جولات القتال",
            prepareSeconds: 15,
            intervals: [
                DrillTimerInterval(isWork: true, seconds: 180),
                DrillTimerInterval(isWork: false, seconds: 60),
            ],
            rounds: 3
        )
    }

    /// EMOM — 10 × 60s work, no rest.
    static func emom() -> DrillTimerSession {
        DrillTimerSession(
            name: "EMOM",
            nameAr: "كل دقيقة",
            prepareSeconds: 10,
            intervals: [DrillTimerInterval(isWork: true, seconds: 60)],
            rounds: 10
        )
    }

    /// Builds a simple work/rest interval session from raw numbers.
    static func interval(
        name: String,
        work: Int,
        rest: Int,
        rounds: Int,
        prepare: Int = 10,
        groups: [String] = []
    ) -> DrillTimerSession {
        var intervals = [DrillTimerInterval(isWork: true, seconds: work)]
        if rest > 0 { intervals.append(DrillTimerInterval(isWork: false, seconds: rest)) }
        return DrillTimerSession(
            name: name,
            prepareSeconds: prepare,
            intervals: intervals,
            rounds: rounds,
            athleteGroups: groups
        )
    }
}
