import Foundation

/// The permanent project owner.
///
/// One account is hard-wired into the app as the owner: it always holds the
/// `.developer` role — and therefore full access to every surface — and no
/// other user can demote, rename, recreate, or otherwise modify it.
///
/// Identity is anchored to a fixed email constant. Enforcement lives in the
/// data layer (`DemoStore.upsertUser`, `SupabaseRepository.updateUser` /
/// `createAccount`) so the guarantee holds no matter which UI surface — now
/// or in future — attempts a change. `AppSession.canModify(_:)` is the
/// matching gate for UI-level edit affordances.
public enum AppOwner {
    /// Hard-coded owner email. Matched case-insensitively against `User.email`.
    /// Changing this constant is the *only* way to reassign ownership.
    public static let email = "gulflens.studio@gmail.com"

    /// Whether `candidate` identifies the project-owner account.
    public static func matches(_ candidate: String?) -> Bool {
        guard let candidate else { return false }
        return candidate.caseInsensitiveCompare(email) == .orderedSame
    }
}

public extension User {
    /// True for the permanent project-owner account — the developer who
    /// remains part of the project and whose access cannot be altered by
    /// anyone else. Owner-protection guards across the app key off this.
    var isAppOwner: Bool { AppOwner.matches(email) }
}
