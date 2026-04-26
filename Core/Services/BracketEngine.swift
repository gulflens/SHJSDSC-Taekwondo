import Foundation

public enum BracketEngine {

    /// Generate single-elimination bracket matches from a seeded list of athlete IDs.
    /// Pads to the next power of 2 with byes; bye opponents auto-advance.
    public static func generateSingleElimination(bracketID: EntityID, seeds: [EntityID]) -> [BracketMatch] {
        guard !seeds.isEmpty else { return [] }
        let n = nextPowerOfTwo(seeds.count)
        var padded: [EntityID?] = seeds.map { Optional($0) }
        while padded.count < n { padded.append(nil) }

        let positions = bracketPositions(size: n)
        var matches: [BracketMatch] = []
        var roundParticipants: [EntityID?] = positions.map { padded[$0] }
        var round = 1

        while roundParticipants.count > 1 {
            var nextRound: [EntityID?] = []
            for pair in 0..<(roundParticipants.count / 2) {
                let a = roundParticipants[pair * 2]
                let b = roundParticipants[pair * 2 + 1]
                let winner: EntityID? = (a != nil && b == nil) ? a : (a == nil && b != nil ? b : nil)
                matches.append(BracketMatch(
                    bracketID: bracketID,
                    round: round,
                    position: pair,
                    athleteAID: a,
                    athleteBID: b,
                    winnerID: winner,
                    matchID: nil
                ))
                nextRound.append(winner)
            }
            roundParticipants = nextRound
            round += 1
        }
        return matches
    }

    /// Apply a fight result to the bracket, propagating the winner to the next round.
    public static func recordResult(
        in matches: [BracketMatch],
        bracketID: EntityID,
        round: Int,
        position: Int,
        winnerID: EntityID,
        matchID: EntityID?
    ) -> [BracketMatch] {
        var out = matches
        guard let idx = out.firstIndex(where: { $0.bracketID == bracketID && $0.round == round && $0.position == position }) else {
            return out
        }
        out[idx].winnerID = winnerID
        out[idx].matchID = matchID
        // Propagate to next round
        let nextRound = round + 1
        let nextPosition = position / 2
        if let nextIdx = out.firstIndex(where: { $0.bracketID == bracketID && $0.round == nextRound && $0.position == nextPosition }) {
            if position.isMultiple(of: 2) {
                out[nextIdx].athleteAID = winnerID
            } else {
                out[nextIdx].athleteBID = winnerID
            }
        }
        return out
    }

    public static func nextPowerOfTwo(_ n: Int) -> Int {
        guard n > 1 else { return 1 }
        var v = 1
        while v < n { v <<= 1 }
        return v
    }

    /// Standard tournament-bracket position ordering. For size n=4 returns [0,3,1,2];
    /// for n=8 returns [0,7,3,4,1,6,2,5]. Top seed always lands in position 0; #2 always
    /// in the opposite half so they only meet in the final.
    public static func bracketPositions(size: Int) -> [Int] {
        if size == 1 { return [0] }
        let half = bracketPositions(size: size / 2)
        var result: [Int] = []
        for p in half {
            result.append(p)
            result.append(size - 1 - p)
        }
        return result
    }
}
