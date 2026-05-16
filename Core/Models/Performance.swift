import Foundation

public struct PerformanceScore: Codable, Identifiable, Hashable, Sendable {
    public let id: EntityID
    public var athleteID: EntityID
    public var competition: Double
    public var technical: Double
    public var physical: Double
    public var adherence: Double
    public var beltProgression: Double
    public var wellness: Double
    public var character: Double
    public var calculatedAt: Date

    public init(
        id: EntityID = UUID(),
        athleteID: EntityID,
        competition: Double,
        technical: Double,
        physical: Double,
        adherence: Double,
        beltProgression: Double,
        wellness: Double,
        character: Double,
        calculatedAt: Date = Date()
    ) {
        self.id = id
        self.athleteID = athleteID
        self.competition = competition
        self.technical = technical
        self.physical = physical
        self.adherence = adherence
        self.beltProgression = beltProgression
        self.wellness = wellness
        self.character = character
        self.calculatedAt = calculatedAt
    }
}

public enum MatchSide: String, Codable, CaseIterable, Sendable, Hashable {
    case chung, hong
}

public nonisolated enum ScoreAction: String, Codable, CaseIterable, Sendable, Hashable {
    case headKick
    case bodyKick
    case turnBodyKick
    case turnHeadKick
    case punch
    case penalty

    public var points: Int {
        switch self {
        case .headKick: 3
        case .bodyKick: 2
        case .turnBodyKick: 4
        case .turnHeadKick: 5
        case .punch: 1
        case .penalty: 1
        }
    }

    public var labelKey: String { "score.\(rawValue)" }
}

public struct ScoreEvent: Codable, Identifiable, Hashable, Sendable {
    public let id: EntityID
    public var matchID: EntityID
    public var round: Int
    public var atSecond: Int
    public var side: MatchSide
    public var action: ScoreAction

    public init(
        id: EntityID = UUID(),
        matchID: EntityID,
        round: Int,
        atSecond: Int,
        side: MatchSide,
        action: ScoreAction
    ) {
        self.id = id
        self.matchID = matchID
        self.round = round
        self.atSecond = atSecond
        self.side = side
        self.action = action
    }
}

public enum MedalType: String, Codable, CaseIterable, Sendable, Hashable {
    case gold, silver, bronze, none

    public var labelKey: String { "medal.\(rawValue)" }
}

// MARK: - Sparring (Pillar 3) enums

public enum SparringContext: String, Codable, CaseIterable, Sendable, Hashable {
    case training, friendly, competition

    public var labelKey: String { "sparring.context.\(rawValue)" }
}

public enum MatchType: String, Codable, CaseIterable, Sendable, Hashable {
    case bestOf3, bestOf5, goldenPoint, single

    public var labelKey: String { "match_type.\(rawValue)" }
}

public enum WinMethod: String, Codable, CaseIterable, Sendable, Hashable {
    case points, knockout, refereeStop, disqualification, withdrawal

    public var labelKey: String { "win_method.\(rawValue)" }
}

public enum MatchOutcome: String, Codable, CaseIterable, Sendable, Hashable {
    case win, loss, draw

    public var labelKey: String { "match_outcome.\(rawValue)" }
}

public struct Match: Codable, Identifiable, Hashable, Sendable {
    // === Identity ===
    public let id: EntityID
    public var tournamentName: String
    public var tournamentID: EntityID?
    public var date: Date
    public var ourAthleteID: EntityID
    public var opponentAthleteID: EntityID?
    public var opponentName: String?
    public var weightClassKg: Double
    public var rounds: Int
    public var ourScore: Int
    public var opponentScore: Int
    public var won: Bool
    public var medal: MedalType
    public var events: [ScoreEvent]

    // === Sparring metadata (Pillar 3) ===
    public var context: SparringContext
    public var matchType: MatchType?
    public var winMethod: WinMethod?
    /// Explicit outcome — distinguishes draw from loss (`won` only encodes win/not-win).
    /// Falls back to win/loss derived from `won` when nil.
    public var outcome: MatchOutcome?
    public var roundsWon: Int?
    public var roundsLost: Int?

    // === Aggregate counts ===
    public var kicksAttempted: Int?
    public var kicksLanded: Int?
    public var punchesAttempted: Int?
    public var punchesLanded: Int?

    // === Points scored, by technique value (1pt punches → 5pt spinning head kicks) ===
    public var ourPunchPoints: Int?
    public var ourBodyKickPoints: Int?
    public var ourHeadKickPoints: Int?
    public var ourSpinningBodyPoints: Int?
    public var ourSpinningHeadPoints: Int?

    // === Points conceded, same breakdown ===
    public var oppPunchPoints: Int?
    public var oppBodyKickPoints: Int?
    public var oppHeadKickPoints: Int?
    public var oppSpinningBodyPoints: Int?
    public var oppSpinningHeadPoints: Int?

    // === Discipline ===
    public var penaltiesGiven: Int?       // gam-jeoms against opponent (points to us)
    public var penaltiesReceived: Int?    // gam-jeoms against us (points to opponent)
    public var knockdownsScored: Int?
    public var knockdownsReceived: Int?

    // === Tactical ===
    public var leadLegKicks: Int?
    public var backLegKicks: Int?
    public var openingAttacks: Int?
    public var counterAttacks: Int?
    /// Free-form labels of the top three techniques used, ranked by frequency.
    public var topTechniques: [String]?
    public var combinations: String?
    public var offenceSeconds: Int?
    public var defenceSeconds: Int?
    public var ringControlRating: Int?       // 1...5
    public var composureRating: Int?         // 1...5 — overall composure (Pillar 5 reuses this)
    public var scoreManagementRating: Int?   // 1...5
    public var coachNotes: String?

    // === Pillar 5: post-competition mental review (each 1...5, optional) ===
    public var preMatchNerves: Int?
    public var interRoundRecovery: Int?
    public var responseToLosingPoint: Int?
    public var responseToWinningPoint: Int?

    public init(
        id: EntityID = UUID(),
        tournamentName: String,
        tournamentID: EntityID? = nil,
        date: Date,
        ourAthleteID: EntityID,
        opponentAthleteID: EntityID? = nil,
        opponentName: String? = nil,
        weightClassKg: Double,
        rounds: Int = 3,
        ourScore: Int,
        opponentScore: Int,
        won: Bool,
        medal: MedalType,
        events: [ScoreEvent] = [],
        context: SparringContext = .competition,
        matchType: MatchType? = nil,
        winMethod: WinMethod? = nil,
        outcome: MatchOutcome? = nil,
        roundsWon: Int? = nil,
        roundsLost: Int? = nil,
        kicksAttempted: Int? = nil,
        kicksLanded: Int? = nil,
        punchesAttempted: Int? = nil,
        punchesLanded: Int? = nil,
        ourPunchPoints: Int? = nil,
        ourBodyKickPoints: Int? = nil,
        ourHeadKickPoints: Int? = nil,
        ourSpinningBodyPoints: Int? = nil,
        ourSpinningHeadPoints: Int? = nil,
        oppPunchPoints: Int? = nil,
        oppBodyKickPoints: Int? = nil,
        oppHeadKickPoints: Int? = nil,
        oppSpinningBodyPoints: Int? = nil,
        oppSpinningHeadPoints: Int? = nil,
        penaltiesGiven: Int? = nil,
        penaltiesReceived: Int? = nil,
        knockdownsScored: Int? = nil,
        knockdownsReceived: Int? = nil,
        leadLegKicks: Int? = nil,
        backLegKicks: Int? = nil,
        openingAttacks: Int? = nil,
        counterAttacks: Int? = nil,
        topTechniques: [String]? = nil,
        combinations: String? = nil,
        offenceSeconds: Int? = nil,
        defenceSeconds: Int? = nil,
        ringControlRating: Int? = nil,
        composureRating: Int? = nil,
        scoreManagementRating: Int? = nil,
        coachNotes: String? = nil,
        preMatchNerves: Int? = nil,
        interRoundRecovery: Int? = nil,
        responseToLosingPoint: Int? = nil,
        responseToWinningPoint: Int? = nil
    ) {
        self.id = id
        self.tournamentName = tournamentName
        self.tournamentID = tournamentID
        self.date = date
        self.ourAthleteID = ourAthleteID
        self.opponentAthleteID = opponentAthleteID
        self.opponentName = opponentName
        self.weightClassKg = weightClassKg
        self.rounds = rounds
        self.ourScore = ourScore
        self.opponentScore = opponentScore
        self.won = won
        self.medal = medal
        self.events = events
        self.context = context
        self.matchType = matchType
        self.winMethod = winMethod
        self.outcome = outcome
        self.roundsWon = roundsWon
        self.roundsLost = roundsLost
        self.kicksAttempted = kicksAttempted
        self.kicksLanded = kicksLanded
        self.punchesAttempted = punchesAttempted
        self.punchesLanded = punchesLanded
        self.ourPunchPoints = ourPunchPoints
        self.ourBodyKickPoints = ourBodyKickPoints
        self.ourHeadKickPoints = ourHeadKickPoints
        self.ourSpinningBodyPoints = ourSpinningBodyPoints
        self.ourSpinningHeadPoints = ourSpinningHeadPoints
        self.oppPunchPoints = oppPunchPoints
        self.oppBodyKickPoints = oppBodyKickPoints
        self.oppHeadKickPoints = oppHeadKickPoints
        self.oppSpinningBodyPoints = oppSpinningBodyPoints
        self.oppSpinningHeadPoints = oppSpinningHeadPoints
        self.penaltiesGiven = penaltiesGiven
        self.penaltiesReceived = penaltiesReceived
        self.knockdownsScored = knockdownsScored
        self.knockdownsReceived = knockdownsReceived
        self.leadLegKicks = leadLegKicks
        self.backLegKicks = backLegKicks
        self.openingAttacks = openingAttacks
        self.counterAttacks = counterAttacks
        self.topTechniques = topTechniques
        self.combinations = combinations
        self.offenceSeconds = offenceSeconds
        self.defenceSeconds = defenceSeconds
        self.ringControlRating = ringControlRating
        self.composureRating = composureRating
        self.scoreManagementRating = scoreManagementRating
        self.coachNotes = coachNotes
        self.preMatchNerves = preMatchNerves
        self.interRoundRecovery = interRoundRecovery
        self.responseToLosingPoint = responseToLosingPoint
        self.responseToWinningPoint = responseToWinningPoint
    }

    // MARK: - Derived helpers

    public var effectiveOutcome: MatchOutcome {
        outcome ?? (won ? .win : .loss)
    }

    /// 0...100, nil if attempted is missing or zero.
    public var kickAccuracy: Double? {
        guard let attempted = kicksAttempted, attempted > 0,
              let landed = kicksLanded else { return nil }
        return Double(landed) / Double(attempted) * 100
    }

    public var punchAccuracy: Double? {
        guard let attempted = punchesAttempted, attempted > 0,
              let landed = punchesLanded else { return nil }
        return Double(landed) / Double(attempted) * 100
    }

    /// True when any sparring metric beyond the basic scoreboard has been logged.
    public var hasDetailedSparringData: Bool {
        kicksAttempted != nil || punchesAttempted != nil
            || ourPunchPoints != nil || ourBodyKickPoints != nil || ourHeadKickPoints != nil
            || ourSpinningBodyPoints != nil || ourSpinningHeadPoints != nil
            || ringControlRating != nil || composureRating != nil || scoreManagementRating != nil
            || (topTechniques?.isEmpty == false)
    }
}
