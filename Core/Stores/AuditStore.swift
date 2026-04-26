import Foundation
import Observation

@Observable @MainActor
public final class AuditStore {
    public private(set) var entries: [AuditEntry] = []
    public private(set) var userLookup: [EntityID: User] = [:]
    public private(set) var isLoading = false

    public var actorFilter: EntityID?
    public var sinceFilter: Date?

    private let repository: any Repository

    public init(repository: any Repository) {
        self.repository = repository
    }

    public func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            entries = try await repository.entries(actor: actorFilter, since: sinceFilter)
            let actorIDs = Set(entries.map { $0.actorUserID })
            var lookup: [EntityID: User] = [:]
            for id in actorIDs {
                if let u = try await repository.user(id: id) { lookup[id] = u }
            }
            userLookup = lookup
        } catch {
            print("AuditStore.load:", error)
        }
    }
}
