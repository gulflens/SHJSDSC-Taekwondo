import Foundation

/// Live-match scoring engine — distinct from `ScoreEngine` which deals with composite
/// performance scores. Handles WT-style point accrual, including the "penalty awards
/// the *opposite* side a point" rule.
public enum ScoringEngine {

    public static func applyEvent(to match: Match, event: ScoreEvent) -> Match {
        var m = match
        m.events.append(event)
        let pts = event.action.points
        if event.action == .penalty {
            switch event.side {
            case .chung: m.opponentScore += pts
            case .hong: m.ourScore += pts
            }
        } else {
            switch event.side {
            case .chung: m.ourScore += pts
            case .hong: m.opponentScore += pts
            }
        }
        return m
    }

    /// Match is over when all rounds have been completed or the PSS gap reaches 12.
    public static func isMatchOver(_ match: Match, currentRound: Int) -> Bool {
        if currentRound > match.rounds { return true }
        if abs(match.ourScore - match.opponentScore) >= 12 { return true }
        return false
    }

    public static func declareWinner(_ match: Match) -> MatchSide? {
        if match.ourScore > match.opponentScore { return .chung }
        if match.opponentScore > match.ourScore { return .hong }
        return nil
    }
}
