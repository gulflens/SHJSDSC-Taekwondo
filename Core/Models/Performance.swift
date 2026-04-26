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

public enum ScoreAction: String, Codable, CaseIterable, Sendable, Hashable {
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

public struct Match: Codable, Identifiable, Hashable, Sendable {
    public let id: EntityID
    public var tournamentName: String
    public var date: Date
    public var ourAthleteID: EntityID
    public var weightClassKg: Double
    public var rounds: Int
    public var ourScore: Int
    public var opponentScore: Int
    public var won: Bool
    public var medal: MedalType
    public var events: [ScoreEvent]

    public init(
        id: EntityID = UUID(),
        tournamentName: String,
        date: Date,
        ourAthleteID: EntityID,
        weightClassKg: Double,
        rounds: Int = 3,
        ourScore: Int,
        opponentScore: Int,
        won: Bool,
        medal: MedalType,
        events: [ScoreEvent] = []
    ) {
        self.id = id
        self.tournamentName = tournamentName
        self.date = date
        self.ourAthleteID = ourAthleteID
        self.weightClassKg = weightClassKg
        self.rounds = rounds
        self.ourScore = ourScore
        self.opponentScore = opponentScore
        self.won = won
        self.medal = medal
        self.events = events
    }
}
