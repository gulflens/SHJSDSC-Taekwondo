import Foundation
import Observation
import AuthenticationServices

@Observable @MainActor
public final class AppSession {
    public let repository: any Repository
    public private(set) var currentUser: User?
    public private(set) var availableUsers: [User] = []
    public private(set) var branches: [Branch] = []
    public private(set) var isLoading = false
    public private(set) var isAuthenticated = false
    public private(set) var needsRoleClaim = false

    private static let rememberedUserKey = "rememberedUserID"

    public init(repository: any Repository) {
        self.repository = repository
    }

    public func bootstrap() async {
        isLoading = true
        defer { isLoading = false }
        do {
            availableUsers = try await repository.availableUsers()
            branches = try await repository.branches()

            if let saved = Self.rememberedUserID {
                try await repository.setCurrentUser(id: saved)
                currentUser = try await repository.currentUser()
            } else {
                currentUser = try await repository.currentUser()
            }
            isAuthenticated = currentUser != nil
        } catch {
            print("AppSession.bootstrap:", error)
            isAuthenticated = false
        }
    }

    public func switchTo(_ user: User) async {
        do {
            try await repository.setCurrentUser(id: user.id)
            currentUser = user
            isAuthenticated = true
            Self.rememberUser(user.id)
        } catch {
            print("AppSession.switchTo:", error)
        }
    }

    public func signOut() async {
        do {
            if let signable = repository as? AuthenticatingRepository {
                try await signable.signOut()
            }
            currentUser = nil
            isAuthenticated = false
            Self.forgetUser()
        } catch {
            print("AppSession.signOut:", error)
        }
    }

    private static var rememberedUserID: EntityID? {
        guard let str = UserDefaults.standard.string(forKey: rememberedUserKey) else { return nil }
        return UUID(uuidString: str)
    }

    private static func rememberUser(_ id: EntityID) {
        UserDefaults.standard.set(id.uuidString, forKey: rememberedUserKey)
    }

    private static func forgetUser() {
        UserDefaults.standard.removeObject(forKey: rememberedUserKey)
    }

    public func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws {
        if let auth = repository as? AuthenticatingRepository {
            try await auth.signInWithApple(credential: credential)
            currentUser = try await repository.currentUser()
            isAuthenticated = currentUser != nil
            needsRoleClaim = !isAuthenticated
            if let id = currentUser?.id { Self.rememberUser(id) }
        } else {
            await signInDemoFallback()
        }
    }

    public func signInWithEmail(email: String, password: String) async throws {
        if let auth = repository as? AuthenticatingRepository {
            try await auth.signInWithEmail(email: email, password: password)
            currentUser = try await repository.currentUser()
            isAuthenticated = currentUser != nil
            needsRoleClaim = !isAuthenticated
            if let id = currentUser?.id { Self.rememberUser(id) }
        } else if let demo = repository as? DemoRepository {
            try await demo.signIn(email: email, password: password)
            currentUser = try await repository.currentUser()
            isAuthenticated = currentUser != nil
            if let id = currentUser?.id { Self.rememberUser(id) }
        } else {
            await signInDemoFallback()
        }
    }

    public func signInDemoFallback() async {
        let users = (try? await repository.availableUsers()) ?? []
        if let td = users.first(where: { $0.role == .technicalDirector }) ?? users.first {
            await switchTo(td)
        }
    }

    public func claimRole(fullName: String, fullNameAr: String, role: Role, branchID: EntityID?) async throws {
        if let auth = repository as? AuthenticatingRepository {
            try await auth.claimRole(fullName: fullName, fullNameAr: fullNameAr, role: role, branchID: branchID)
            currentUser = try await repository.currentUser()
            isAuthenticated = currentUser != nil
            needsRoleClaim = false
            if let id = currentUser?.id { Self.rememberUser(id) }
        }
    }

    public func branch(id: EntityID) -> Branch? {
        branches.first { $0.id == id }
    }
}

public protocol AuthenticatingRepository: Sendable {
    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws
    func signInWithEmail(email: String, password: String) async throws
    func signOut() async throws
    func claimRole(fullName: String, fullNameAr: String, role: Role, branchID: EntityID?) async throws
}
