import Foundation
import Observation

public struct PromotionReadinessEntry: Identifiable, Hashable, Sendable {
    public let athlete: Athlete
    public let eligibility: GradingEligibility

    public var id: EntityID { athlete.id }

    public init(athlete: Athlete, eligibility: GradingEligibility) {
        self.athlete = athlete
        self.eligibility = eligibility
    }
}

/// Surfaces athletes assigned to a coach whose attendance / technical /
/// physical / time-at-rank thresholds have all been met. Drives the
/// "promotion readiness" card on the coach home dashboard.
@Observable @MainActor
public final class PromotionReadinessStore {
    public private(set) var entries: [PromotionReadinessEntry] = []
    public private(set) var isLoading = false

    private let repository: any Repository

    public init(repository: any Repository) {
        self.repository = repository
    }

    public func load(coachID: EntityID) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let athletes = try await repository.athletes(coachID: coachID)
            var found: [PromotionReadinessEntry] = []
            for athlete in athletes {
                let target = GradingEngine.nextBelt(after: athlete.currentBelt)
                guard target != athlete.currentBelt else { continue }
                let eligibility = try await repository.eligibility(
                    athleteID: athlete.id,
                    targetBelt: target
                )
                guard eligibility.isEligible else { continue }
                found.append(PromotionReadinessEntry(athlete: athlete, eligibility: eligibility))
            }
            entries = found.sorted { lhs, rhs in
                if lhs.eligibility.attendancePct != rhs.eligibility.attendancePct {
                    return lhs.eligibility.attendancePct > rhs.eligibility.attendancePct
                }
                return lhs.athlete.fullName < rhs.athlete.fullName
            }
        } catch {
            print("PromotionReadinessStore.load:", error)
            entries = []
        }
    }
}
