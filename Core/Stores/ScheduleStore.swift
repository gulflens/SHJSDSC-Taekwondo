import Foundation
import Observation

@Observable @MainActor
public final class ScheduleStore {
    public private(set) var sessionsToday: [ClassSession] = []
    public private(set) var coachLookup: [EntityID: Coach] = [:]
    public private(set) var branchLookup: [EntityID: Branch] = [:]
    public private(set) var isLoading = false

    private let repository: any Repository

    public init(repository: any Repository) {
        self.repository = repository
    }

    public func loadCoachDay(coachID: EntityID, day: Date = Date()) async {
        isLoading = true
        defer { isLoading = false }
        do {
            sessionsToday = try await repository.sessions(coachID: coachID, on: day)
            await loadLookups()
        } catch {
            print("ScheduleStore.loadCoachDay:", error)
        }
    }

    public func loadBranchDay(branchID: EntityID, day: Date = Date()) async {
        isLoading = true
        defer { isLoading = false }
        do {
            sessionsToday = try await repository.sessions(branchID: branchID, on: day)
            await loadLookups()
        } catch {
            print("ScheduleStore.loadBranchDay:", error)
        }
    }

    private func loadLookups() async {
        do {
            let cs = try await repository.coaches()
            coachLookup = Dictionary(uniqueKeysWithValues: cs.map { ($0.id, $0) })
            let bs = try await repository.branches()
            branchLookup = Dictionary(uniqueKeysWithValues: bs.map { ($0.id, $0) })
        } catch {
            print("ScheduleStore.loadLookups:", error)
        }
    }
}
