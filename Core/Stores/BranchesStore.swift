import Foundation
import Observation

public struct BranchSummary: Identifiable, Sendable, Hashable {
    public let id: EntityID
    public let branch: Branch
    public let composite: Double
    public let grade: LetterGrade
    public let athleteCount: Int
    public let utilisation: Double

    public init(id: EntityID, branch: Branch, composite: Double, grade: LetterGrade, athleteCount: Int, utilisation: Double) {
        self.id = id
        self.branch = branch
        self.composite = composite
        self.grade = grade
        self.athleteCount = athleteCount
        self.utilisation = utilisation
    }
}

@Observable @MainActor
public final class BranchesStore {
    public private(set) var summaries: [BranchSummary] = []
    public private(set) var isLoading = false

    private let repository: any Repository

    public init(repository: any Repository) {
        self.repository = repository
    }

    public func loadAll() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let branches = try await repository.branches()
            var out: [BranchSummary] = []
            for b in branches {
                let athletes = try await repository.athletes(branchID: b.id)
                let scores = try await repository.scores(branchID: b.id)
                let comp = ScoreEngine.branchComposite(scores)
                let utilisation = b.capacity > 0 ? Double(athletes.count) / Double(b.capacity) : 0
                out.append(BranchSummary(
                    id: b.id,
                    branch: b,
                    composite: comp,
                    grade: LetterGrade.from(score: comp),
                    athleteCount: athletes.count,
                    utilisation: min(1.0, utilisation)
                ))
            }
            self.summaries = out
        } catch {
            print("BranchesStore.loadAll:", error)
        }
    }
}
