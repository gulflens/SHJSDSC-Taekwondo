import Foundation
import Observation

@Observable @MainActor
public final class TournamentsStore {
    public private(set) var tournaments: [Tournament] = []
    public private(set) var isLoading = false

    private let repository: any Repository

    public init(repository: any Repository) {
        self.repository = repository
    }

    public func loadTournaments() async {
        isLoading = true
        defer { isLoading = false }
        do {
            tournaments = try await repository.tournaments()
        } catch {
            print("TournamentsStore.loadTournaments:", error)
        }
    }

    public var upcoming: [Tournament] {
        let now = Date()
        return tournaments.filter { $0.startsAt >= now }.sorted { $0.startsAt < $1.startsAt }
    }

    public var past: [Tournament] {
        let now = Date()
        return tournaments.filter { $0.endsAt < now }.sorted { $0.startsAt > $1.startsAt }
    }

    public func byID(_ id: EntityID) -> Tournament? {
        tournaments.first { $0.id == id }
    }
}
