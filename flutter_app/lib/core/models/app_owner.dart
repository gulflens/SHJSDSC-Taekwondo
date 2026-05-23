// Port of Core/Models/CoreEntities.swift — AppOwner enum (static constants).
// Pure Dart — no Flutter imports (logic-layer rule).

/// The permanent project owner.
///
/// One account is hard-wired into the app as the owner: it always holds the
/// developer role — and therefore full access to every surface — and no other
/// user can demote, rename, recreate, or otherwise modify it.
///
/// Mirrors Swift's `AppOwner` enum with static members.
class AppOwner {
  AppOwner._();

  /// Hard-coded owner email. Matched case-insensitively against User.email.
  /// Changing this constant is the *only* way to reassign ownership.
  static const String email = 'gulflens.studio@gmail.com';

  /// Whether [candidate] identifies the project-owner account.
  static bool matches(String? candidate) {
    if (candidate == null) return false;
    return candidate.toLowerCase() == email.toLowerCase();
  }
}
