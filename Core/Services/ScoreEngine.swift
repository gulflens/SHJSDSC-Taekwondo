import Foundation

public struct ScoreWeights: Sendable {
    public let competition: Double
    public let technical: Double
    public let physical: Double
    public let adherence: Double
    public let beltProgression: Double
    public let wellness: Double
    public let character: Double

    public init(competition: Double, technical: Double, physical: Double, adherence: Double, beltProgression: Double, wellness: Double, character: Double) {
        self.competition = competition
        self.technical = technical
        self.physical = physical
        self.adherence = adherence
        self.beltProgression = beltProgression
        self.wellness = wellness
        self.character = character
    }

    public static let standard = ScoreWeights(
        competition: 25, technical: 20, physical: 15,
        adherence: 15, beltProgression: 10, wellness: 10, character: 5
    )
    public static let competitionTeam = ScoreWeights(
        competition: 35, technical: 20, physical: 15,
        adherence: 10, beltProgression: 5, wellness: 10, character: 5
    )
    public static let cubs = ScoreWeights(
        competition: 5, technical: 35, physical: 20,
        adherence: 15, beltProgression: 10, wellness: 10, character: 5
    )
}

public enum LetterGrade: Sendable, CaseIterable, Hashable {
    case aPlus, a, aMinus
    case bPlus, b, bMinus
    case cPlus, c, cMinus
    case dPlus, d, f

    public var label: String {
        switch self {
        case .aPlus: "A+"
        case .a: "A"
        case .aMinus: "A-"
        case .bPlus: "B+"
        case .b: "B"
        case .bMinus: "B-"
        case .cPlus: "C+"
        case .c: "C"
        case .cMinus: "C-"
        case .dPlus: "D+"
        case .d: "D"
        case .f: "F"
        }
    }

    public static func from(score: Double) -> LetterGrade {
        switch score {
        case 95...: .aPlus
        case 90..<95: .a
        case 85..<90: .aMinus
        case 80..<85: .bPlus
        case 75..<80: .b
        case 70..<75: .bMinus
        case 65..<70: .cPlus
        case 60..<65: .c
        case 55..<60: .cMinus
        case 50..<55: .dPlus
        case 40..<50: .d
        default: .f
        }
    }
}

public enum ScoreEngine {
    public static func composite(_ s: PerformanceScore, weights: ScoreWeights = .standard) -> Double {
        let total = weights.competition + weights.technical + weights.physical
            + weights.adherence + weights.beltProgression + weights.wellness + weights.character
        guard total > 0 else { return 0 }
        var weighted: Double = 0
        weighted += s.competition * weights.competition
        weighted += s.technical * weights.technical
        weighted += s.physical * weights.physical
        weighted += s.adherence * weights.adherence
        weighted += s.beltProgression * weights.beltProgression
        weighted += s.wellness * weights.wellness
        weighted += s.character * weights.character
        return weighted / total
    }

    public static func grade(_ s: PerformanceScore, weights: ScoreWeights = .standard) -> LetterGrade {
        LetterGrade.from(score: composite(s, weights: weights))
    }

    public static func branchComposite(_ scores: [PerformanceScore], weights: ScoreWeights = .standard) -> Double {
        guard !scores.isEmpty else { return 0 }
        let sum = scores.reduce(0.0) { $0 + composite($1, weights: weights) }
        return sum / Double(scores.count)
    }
}
