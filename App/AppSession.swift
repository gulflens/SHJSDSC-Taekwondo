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
    private static let rememberedRoleKey = "rememberedUserRole"
    /// Sticky "the user pressed Sign Out themselves" flag. The sign-in
    /// screen is only shown when this is true (or on the very first launch
    /// before any sign-in has happened) — every other restart, including
    /// hitting Run in Xcode, restores the previous identity automatically.
    private static let manuallySignedOutKey = "auth.manuallySignedOut"
    /// JSON snapshot of the last-known signed-in `User`. Used as a final
    /// identity fallback in `bootstrap` so a cold-start hiccup (Supabase RLS
    /// blocking unauthenticated reads, no network, refresh-token expired)
    /// doesn't bounce the user back to the sign-in screen. They stay signed
    /// in visually; reads/writes that need a live session may fail until
    /// connectivity returns, but the app remembers who they are.
    private static let cachedUserKey = "auth.cachedUser"

    public init(repository: any Repository) {
        self.repository = repository
    }

    public func bootstrap() async {
        isLoading = true
        defer { isLoading = false }

        // Reference data is non-fatal: with Supabase RLS, `availableUsers()`
        // commonly fails for unauthenticated callers, but that must NOT cost
        // the user their session. Each fetch is best-effort.
        availableUsers = (try? await repository.availableUsers()) ?? []
        branches = (try? await repository.branches()) ?? []

        // 1) Try the live session first — Supabase keychain restore, or the
        //    demo repo's in-memory currentUserID.
        if let saved = Self.rememberedUserID {
            try? await repository.setCurrentUser(id: saved)
        }
        currentUser = try? await repository.currentUser()

        // 2) Demo-mode role fallback: IDs regenerate per launch, so match
        //    by remembered role from the seed list.
        if currentUser == nil, let roleName = Self.rememberedRole,
           let match = availableUsers.first(where: { $0.role.rawValue == roleName }) {
            try? await repository.setCurrentUser(id: match.id)
            currentUser = match
            Self.rememberUser(match.id, role: match.role.rawValue)
        }

        // 3) Stickier demo fallback: any first user, unless they manually
        //    signed out. Keeps demo sessions alive across Xcode Run cycles.
        if currentUser == nil,
           !Self.hasManuallySignedOut,
           !availableUsers.isEmpty {
            let candidate = Self.rememberedRole.flatMap { roleName in
                availableUsers.first(where: { $0.role.rawValue == roleName })
            } ?? availableUsers.first
            if let candidate {
                try? await repository.setCurrentUser(id: candidate.id)
                currentUser = candidate
                Self.rememberUser(candidate.id, role: candidate.role.rawValue)
            }
        }

        // 4) Last-resort identity restore from local cache. Unless they hit
        //    Sign Out, an installed app should never dump the user back to
        //    SignInView just because the network/Supabase couldn't answer.
        if currentUser == nil, !Self.hasManuallySignedOut, let cached = Self.cachedUser {
            currentUser = cached
        }

        if let user = currentUser {
            Self.cacheUser(user)
        }
        isAuthenticated = currentUser != nil
    }

    public func switchTo(_ user: User) async {
        do {
            try await repository.setCurrentUser(id: user.id)
            currentUser = user
            isAuthenticated = true
            Self.rememberUser(user.id, role: user.role.rawValue)
            Self.cacheUser(user)
            Self.setManuallySignedOut(false)
            logSignIn(user)
        } catch {
            print("AppSession.switchTo:", error)
        }
    }

    /// Records a sign-in event in the audit log so the Login Activity screen
    /// has real data to show. Best-effort and fire-and-forget — a failed log
    /// write must never block sign-in.
    private func logSignIn(_ user: User) {
        let platform: String
        #if os(macOS)
        platform = "macOS"
        #else
        platform = "iOS"
        #endif
        let entry = AuditEntry(
            actorUserID: user.id,
            action: "auth.signin",
            targetEntity: "session",
            targetID: user.id,
            changes: ["platform": platform]
        )
        Task { [repository] in
            try? await repository.log(entry)
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
            Self.clearCachedUser()
            Self.setManuallySignedOut(true)
        } catch {
            print("AppSession.signOut:", error)
        }
    }

    private static var rememberedUserID: EntityID? {
        guard let str = UserDefaults.standard.string(forKey: rememberedUserKey) else { return nil }
        return UUID(uuidString: str)
    }

    private static var rememberedRole: String? {
        UserDefaults.standard.string(forKey: rememberedRoleKey)
    }

    private static func rememberUser(_ id: EntityID, role: String) {
        UserDefaults.standard.set(id.uuidString, forKey: rememberedUserKey)
        UserDefaults.standard.set(role, forKey: rememberedRoleKey)
    }

    private static func forgetUser() {
        UserDefaults.standard.removeObject(forKey: rememberedUserKey)
        UserDefaults.standard.removeObject(forKey: rememberedRoleKey)
    }

    private static var hasManuallySignedOut: Bool {
        UserDefaults.standard.bool(forKey: manuallySignedOutKey)
    }

    private static func setManuallySignedOut(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: manuallySignedOutKey)
    }

    private static var cachedUser: User? {
        guard let data = UserDefaults.standard.data(forKey: cachedUserKey) else { return nil }
        return try? JSONDecoder().decode(User.self, from: data)
    }

    private static func cacheUser(_ user: User) {
        if let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: cachedUserKey)
        }
    }

    private static func clearCachedUser() {
        UserDefaults.standard.removeObject(forKey: cachedUserKey)
    }

    public func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws {
        if let auth = repository as? AuthenticatingRepository {
            try await auth.signInWithApple(credential: credential)
            currentUser = try await repository.currentUser()
            isAuthenticated = currentUser != nil
            needsRoleClaim = !isAuthenticated
            if let u = currentUser {
                Self.rememberUser(u.id, role: u.role.rawValue)
                Self.cacheUser(u)
                Self.setManuallySignedOut(false)
                logSignIn(u)
            }
        } else {
            await signInDemoFallback()
        }
    }

    public func signInWithEmail(email: String, password: String, rememberMe: Bool = true) async throws {
        if let auth = repository as? AuthenticatingRepository {
            try await auth.signInWithEmail(email: email, password: password)
            currentUser = try await repository.currentUser()
            isAuthenticated = currentUser != nil
            needsRoleClaim = !isAuthenticated
            applyRememberMe(rememberMe)
            if let u = currentUser { logSignIn(u) }
        } else if let demo = repository as? DemoRepository {
            try await demo.signIn(email: email, password: password)
            currentUser = try await repository.currentUser()
            isAuthenticated = currentUser != nil
            applyRememberMe(rememberMe)
            if let u = currentUser { logSignIn(u) }
        } else {
            await signInDemoFallback()
        }
    }

    private func applyRememberMe(_ remember: Bool) {
        if remember, let u = currentUser {
            Self.rememberUser(u.id, role: u.role.rawValue)
            Self.cacheUser(u)
        } else {
            Self.forgetUser()
            Self.clearCachedUser()
        }
        // A successful sign-in (regardless of "remember me") clears the
        // sticky manual-signout flag, so the user is no longer routed to
        // the sign-in screen on subsequent launches.
        if currentUser != nil {
            Self.setManuallySignedOut(false)
        }
    }

    public func signInDemoFallback() async {
        let users = (try? await repository.availableUsers()) ?? []
        if let td = users.first(where: { $0.role == .technicalDirector }) ?? users.first {
            await switchTo(td)
        }
    }

    /// One-tap sign-in straight into the seeded developer account
    /// (Ayman Maklad, `.developer`). Wired to the "Sign in as Developer"
    /// shortcut on the sign-in screen so the developer account is always
    /// reachable without typing credentials — useful while the build still
    /// runs on demo data. Falls back to the demo session if no developer
    /// user exists in the active repository.
    public func signInAsDeveloper() async {
        let users = (try? await repository.availableUsers()) ?? []
        if let dev = users.first(where: { $0.role == .developer }) {
            await switchTo(dev)
        } else {
            await signInDemoFallback()
        }
    }

    public func claimRole(fullName: String, fullNameAr: String, role: Role, branchID: EntityID?) async throws {
        if let auth = repository as? AuthenticatingRepository {
            try await auth.claimRole(fullName: fullName, fullNameAr: fullNameAr, role: role, branchID: branchID)
            currentUser = try await repository.currentUser()
            isAuthenticated = currentUser != nil
            needsRoleClaim = false
            if let u = currentUser {
                Self.rememberUser(u.id, role: u.role.rawValue)
                Self.cacheUser(u)
                Self.setManuallySignedOut(false)
            }
        }
    }

    public func branch(id: EntityID) -> Branch? {
        branches.first { $0.id == id }
    }

    /// Single entry point for permission checks — resolves the current
    /// user's role against `PermissionMatrix`. Prefer this over ad-hoc
    /// `role == …` comparisons so access rules stay in one place.
    public func can(_ permission: Permission) -> Bool {
        guard let role = currentUser?.role else { return false }
        return PermissionMatrix.allowed(role: role, permission: permission)
    }

    /// Resolved data-visibility scope for the signed-in user. Branch-tier
    /// roles without an assigned branch fall back to own-records-only.
    /// Client-side scoping is a UX layer; server RLS is the real boundary.
    public var accessScope: AccessScope {
        guard let user = currentUser else { return .ownRecordsOnly }
        switch user.role.scopeTier {
        case .federation:
            return .all
        case .branch:
            if let branchID = user.primaryBranchID { return .branch(branchID) }
            return .ownRecordsOnly
        case .own:
            return .ownRecordsOnly
        }
    }

    /// Persists profile edits made from the "Edit My Account" sheet and
    /// refreshes the in-memory `currentUser` so every observing view sees
    /// the new name / avatar / preferences immediately.
    public func updateProfile(_ user: User) async {
        do {
            try await repository.updateUser(user)
            currentUser = user
            Self.cacheUser(user)
            if let idx = availableUsers.firstIndex(where: { $0.id == user.id }) {
                availableUsers[idx] = user
            }
        } catch {
            print("AppSession.updateProfile:", error)
        }
    }
}

public protocol AuthenticatingRepository: Sendable {
    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws
    func signInWithEmail(email: String, password: String) async throws
    func signOut() async throws
    func claimRole(fullName: String, fullNameAr: String, role: Role, branchID: EntityID?) async throws
    /// Updates the password of the currently signed-in account. The live
    /// session already authenticates the caller, so no current password is
    /// required at the protocol level.
    func changePassword(newPassword: String) async throws
}
