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
            // Demo repository always has a default current user, so we land
            // straight into the authenticated state. Supabase mode returns
            // nil here when there's no live session.
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
        } catch {
            print("AppSession.switchTo:", error)
        }
    }

    public func signOut() async {
        do {
            // Supabase impl will sign out via auth.signOut(); demo repo no-ops.
            if let signable = repository as? AuthenticatingRepository {
                try await signable.signOut()
            }
            currentUser = nil
            isAuthenticated = false
        } catch {
            print("AppSession.signOut:", error)
        }
    }

    public func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws {
        if let auth = repository as? AuthenticatingRepository {
            try await auth.signInWithApple(credential: credential)
            currentUser = try await repository.currentUser()
            isAuthenticated = currentUser != nil
            needsRoleClaim = !isAuthenticated
        } else {
            // Demo / no-Supabase fallback: synthesise a session using the
            // first available admin user so the flow keeps moving.
            try await signInDemoFallback()
        }
    }

    public func signInWithEmail(email: String, password: String) async throws {
        if let auth = repository as? AuthenticatingRepository {
            try await auth.signInWithEmail(email: email, password: password)
            currentUser = try await repository.currentUser()
            isAuthenticated = currentUser != nil
            needsRoleClaim = !isAuthenticated
        } else {
            try await signInDemoFallback()
        }
    }

    public func signInDemoFallback() async {
        // Used by the SignInView "Use demo session" button when Supabase
        // isn't reachable. Pulls the TD user out of available users.
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
        }
    }

    public func branch(id: EntityID) -> Branch? {
        branches.first { $0.id == id }
    }
}

/// Optional protocol implemented by the Supabase repository. The demo
/// repository doesn't conform — auth methods route through
/// `signInDemoFallback` instead.
public protocol AuthenticatingRepository: Sendable {
    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws
    func signInWithEmail(email: String, password: String) async throws
    func signOut() async throws
    func claimRole(fullName: String, fullNameAr: String, role: Role, branchID: EntityID?) async throws
}
