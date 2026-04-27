import Foundation
import Observation

@Observable @MainActor
public final class AthletesStore {
    public private(set) var athletes: [Athlete] = []
    public private(set) var scoreByAthlete: [EntityID: PerformanceScore] = [:]
    public private(set) var isLoading = false

    private let repository: any Repository

    public init(repository: any Repository) {
        self.repository = repository
    }

    public func load(branchID: EntityID) async {
        isLoading = true
        defer { isLoading = false }
        do {
            athletes = try await repository.athletes(branchID: branchID)
            let s = try await repository.scores(branchID: branchID)
            scoreByAthlete = Dictionary(uniqueKeysWithValues: s.map { ($0.athleteID, $0) })
        } catch {
            print("AthletesStore.load:", error)
        }
    }

    public func loadForCoach(_ coachID: EntityID) async {
        isLoading = true
        defer { isLoading = false }
        do {
            athletes = try await repository.athletes(coachID: coachID)
            let allScores = try await repository.allScores()
            let mine = Set(athletes.map { $0.id })
            scoreByAthlete = Dictionary(uniqueKeysWithValues: allScores
                .filter { mine.contains($0.athleteID) }
                .map { ($0.athleteID, $0) })
        } catch {
            print("AthletesStore.loadForCoach:", error)
        }
    }

    public func loadAll() async {
        isLoading = true
        defer { isLoading = false }
        do {
            athletes = try await repository.athletes()
            let s = try await repository.allScores()
            scoreByAthlete = Dictionary(uniqueKeysWithValues: s.map { ($0.athleteID, $0) })
        } catch {
            print("AthletesStore.loadAll:", error)
        }
    }

    public func composite(_ athlete: Athlete) -> Double {
        guard let s = scoreByAthlete[athlete.id] else { return 0 }
        let weights: ScoreWeights = athlete.status == .competitionTeam
            ? .competitionTeam
            : (athlete.ageGroup == .cubs ? .cubs : .standard)
        return ScoreEngine.composite(s, weights: weights)
    }

    public func grade(_ athlete: Athlete) -> LetterGrade {
        LetterGrade.from(score: composite(athlete))
    }

    public func insertOrUpdate(_ athlete: Athlete) {
        if let i = athletes.firstIndex(where: { $0.id == athlete.id }) {
            athletes[i] = athlete
        } else {
            athletes.append(athlete)
        }
    }
}
