import Foundation
import Observation

@Observable @MainActor
public final class AthleteGroupStore {
    public private(set) var groups: [AthleteGroup] = []
    public private(set) var isLoading = false

    private let repository: any Repository

    public init(repository: any Repository) {
        self.repository = repository
    }

    public func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            groups = try await repository.athleteGroups()
        } catch {
            print("AthleteGroupStore.load:", error)
        }
    }

    public var activeGroups: [AthleteGroup] {
        groups.filter { !$0.isArchived && !$0.isExpired }
    }

    public var archivedGroups: [AthleteGroup] {
        groups.filter { $0.isArchived || $0.isExpired }
    }

    public func save(_ group: AthleteGroup) async {
        do {
            try await repository.upsert(group)
            await load()
        } catch {
            print("AthleteGroupStore.save:", error)
        }
    }

    public func archive(_ group: AthleteGroup) async {
        var updated = group
        updated.isArchived = true
        await save(updated)
    }

    public func delete(id: EntityID) async {
        do {
            try await repository.deleteAthleteGroup(id: id)
            await load()
        } catch {
            print("AthleteGroupStore.delete:", error)
        }
    }
}
