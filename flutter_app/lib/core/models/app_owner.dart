// Port of Core/Models/CoreEntities.swift — AppOwner enum (static constants).
// Pure Dart — no Flutter imports (logic-layer rule).

import 'role.dart';
import 'user.dart';

/// The permanent project owner.
///
/// One account is hard-wired into the app as the owner: it always holds the
/// developer role — and therefore full access to every surface — and no other
/// user can demote, rename, recreate, or otherwise modify it.
///
/// Mirrors Swift's `AppOwner` enum. Enforcement lives in the data layer
/// (DemoRepository / SupabaseRepository `createAccount` + `updateUser`) so the
/// guarantee holds regardless of which UI surface attempts a change.
class AppOwner {
  AppOwner._();

  /// Hard-coded owner email. Matched case-insensitively against `User.email`.
  /// Changing this constant is the *only* way to reassign ownership.
  static const String email = 'gulflens.studio@gmail.com';

  /// Whether [candidate] identifies the project-owner account. Trims and
  /// lower-cases so a padded/pasted address (" gulflens.studio@gmail.com ")
  /// can't slip past the reservation guard while still resolving to the owner.
  static bool matches(String? candidate) {
    if (candidate == null) return false;
    return candidate.trim().toLowerCase() == email.toLowerCase();
  }
}

extension AppOwnerUser on User {
  /// True when this record is the project-owner account (by email).
  bool get isAppOwner => AppOwner.matches(email);

  /// A copy re-pinned to the owner invariant: `developer` role + the canonical
  /// owner email. Used by `updateUser` so the owner can't be demoted/renamed.
  User pinnedAsOwner() => User(
        id: id,
        fullName: fullName,
        fullNameAr: fullNameAr,
        role: Role.developer,
        primaryBranchId: primaryBranchId,
        avatarSeed: avatarSeed,
        linkedAthleteIds: linkedAthleteIds,
        avatarUrl: avatarUrl,
        email: AppOwner.email,
      );
}
