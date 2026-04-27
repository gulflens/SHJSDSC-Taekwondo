import Foundation
import Observation

@Observable @MainActor
public final class BranchProfileStore {
    public private(set) var branch: Branch?
    public private(set) var facility: BranchFacility?
    public private(set) var hours: BranchHours?
    public private(set) var programs: [BranchProgram] = []
    public private(set) var inventory: BranchInventory?
    public private(set) var compliance: BranchCompliance?
    public private(set) var pricing: BranchPricing?
    public private(set) var financials: [BranchFinancials] = []
    public private(set) var media: BranchMedia?
    public private(set) var socialLinks: BranchSocialLinks?
    public private(set) var safeguarding: BranchSafeguarding?
    public private(set) var milestones: [BranchMilestone] = []
    public private(set) var coaches: [Coach] = []
    public private(set) var metrics: BranchOperationalMetrics = .empty
    public private(set) var isLoading = false

    private let repository: any Repository

    public init(repository: any Repository) {
        self.repository = repository
    }

    public func load(branchID: EntityID, monthsBack: Int = 12) async {
        isLoading = true
        defer { isLoading = false }
        do {
            // Fan out the per-section reads concurrently — each independent
            // call hits the repository on its own task and we await them all
            // together. With Demo this is "free"; with Supabase this matters.
            async let branchTask = repository.branch(id: branchID)
            async let facilityTask = repository.facility(branchID: branchID)
            async let hoursTask = repository.hours(branchID: branchID)
            async let programsTask = repository.programs(branchID: branchID)
            async let inventoryTask = repository.inventory(branchID: branchID)
            async let complianceTask = repository.compliance(branchID: branchID)
            async let pricingTask = repository.pricing(branchID: branchID)
            async let financialsTask = repository.financials(branchID: branchID, monthsBack: monthsBack)
            async let mediaTask = repository.media(branchID: branchID)
            async let socialTask = repository.socialLinks(branchID: branchID)
            async let safeTask = repository.safeguarding(branchID: branchID)
            async let milestonesTask = repository.milestones(branchID: branchID)
            async let coachesTask = repository.coaches(branchID: branchID)
            async let athletesTask = repository.athletes(branchID: branchID)
            async let sessionsTask = sessionsThisWeek(branchID: branchID)

            self.branch = try await branchTask
            self.facility = try await facilityTask
            self.hours = try await hoursTask
            self.programs = try await programsTask
            self.inventory = try await inventoryTask
            self.compliance = try await complianceTask
            self.pricing = try await pricingTask
            self.financials = try await financialsTask
            self.media = try await mediaTask
            self.socialLinks = try await socialTask
            self.safeguarding = try await safeTask
            self.milestones = try await milestonesTask
            self.coaches = try await coachesTask

            let athletes = try await athletesTask
            let sessions = await sessionsTask

            // Pull a 30-day attendance window for the metrics compute. We
            // don't have a branch-scoped attendance API, so we union per
            // athlete — fine for demo size; Stage 5 will expose a direct
            // by-branch query when this becomes hot.
            let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            var attendance: [AttendanceRecord] = []
            for a in athletes {
                if let recs = try? await repository.attendance(athleteID: a.id, since: cutoff) {
                    attendance.append(contentsOf: recs)
                }
            }

            if let branch {
                self.metrics = BranchMetrics.compute(
                    branch: branch,
                    athletes: athletes,
                    attendance: attendance,
                    sessions: sessions,
                    coaches: coaches
                )
            }
        } catch {
            print("BranchProfileStore.load:", error)
        }
    }

    private func sessionsThisWeek(branchID: EntityID) async -> [ClassSession] {
        let cal = Calendar(identifier: .gregorian)
        let today = Date()
        let weekStart = cal.date(byAdding: .day, value: -((cal.component(.weekday, from: today)) - 1), to: today) ?? today
        var out: [ClassSession] = []
        for offset in 0..<7 {
            guard let day = cal.date(byAdding: .day, value: offset, to: weekStart) else { continue }
            if let s = try? await repository.sessions(branchID: branchID, on: day) {
                out.append(contentsOf: s)
            }
        }
        return out
    }
}
