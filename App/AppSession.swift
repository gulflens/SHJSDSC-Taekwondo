import Foundation
import Observation

@Observable @MainActor
public final class AppSession {
    public let repository: any Repository
    public private(set) var currentUser: User?
    public private(set) var availableUsers: [User] = []
    public private(set) var branches: [Branch] = []
    public private(set) var isLoading = false

    public init(repository: any Repository) {
        self.repository = repository
    }

    public func bootstrap() async {
        isLoading = true
        defer { isLoading = false }
        do {
            currentUser = try await repository.currentUser()
            availableUsers = try await repository.availableUsers()
            branches = try await repository.branches()
        } catch {
            print("AppSession.bootstrap:", error)
        }
    }

    public func switchTo(_ user: User) async {
        do {
            try await repository.setCurrentUser(id: user.id)
            currentUser = user
        } catch {
            print("AppSession.switchTo:", error)
        }
    }

    public func branch(id: EntityID) -> Branch? {
        branches.first { $0.id == id }
    }
}
