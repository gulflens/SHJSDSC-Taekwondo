// Port of Core/Models/RoleMetadata.swift.
// NOT Codable in Swift (except RoleGroup/AccessLevel which have rawValue but
// no Codable conformance listed) — ported as plain enums / extension methods.
// Pure Dart — no Flutter imports (logic-layer rule).

import 'entity_id.dart';
import 'role.dart';

/// Functional grouping of the role taxonomy — used by the Users console to
/// organise ~30 roles into scannable sections.
enum RoleGroup {
  system,
  leadership,
  coaching,
  support,
  competition,
  grading,
  administration,
  members;

  String get labelKey => 'roleGroup.$name';
}

/// Coarse data-access tier surfaced as a chip in the Users console. The real
/// enforcement is [PermissionMatrix] — this is a human-readable summary, not
/// a security boundary.
enum AccessLevel {
  full,
  branchLimited,
  readOnly,
  restricted;

  String get labelKey => 'accessLevel.$name';
}

/// How wide a role's data visibility reaches.
enum ScopeTier {
  federation, // every branch
  branch, // a single assigned branch
  own, // only the user's own / linked records
}

/// Concrete, resolved data-visibility scope for the signed-in user.
/// Mirrors Swift's `AccessScope` associated-value enum.
sealed class AccessScope {
  const AccessScope();

  /// Whether [branchId] is visible under this scope.
  bool includes(EntityID? branchId);
}

class AccessScopeAll extends AccessScope {
  const AccessScopeAll();

  @override
  bool includes(EntityID? branchId) => true;
}

class AccessScopeBranch extends AccessScope {
  final EntityID id;
  const AccessScopeBranch(this.id);

  @override
  bool includes(EntityID? branchId) => branchId == id;
}

class AccessScopeOwnRecordsOnly extends AccessScope {
  const AccessScopeOwnRecordsOnly();

  @override
  bool includes(EntityID? branchId) => false;
}

// Extension methods on Role — mirrors the Swift `extension Role` blocks in
// RoleMetadata.swift.

extension RoleMetadataExtension on Role {
  /// How far this role can see across the federation.
  ScopeTier get scopeTier {
    switch (this) {
      case Role.developer:
      case Role.admin:
      case Role.itSupport:
      case Role.technicalDirector:
      case Role.operationsManager:
      case Role.analyst:
      case Role.tournamentAdmin:
      case Role.competitionCoordinator:
      case Role.gradingExaminer:
      case Role.finance:
      case Role.hrManager:
      case Role.federationViewer:
        return ScopeTier.federation;

      case Role.branchManager:
      case Role.headCoach:
      case Role.coach:
      case Role.assistantCoach:
      case Role.sparringCoach:
      case Role.poomsaeCoach:
      case Role.conditioningCoach:
      case Role.demoTeamCoach:
      case Role.teamPhysician:
      case Role.physiotherapist:
      case Role.sportsPsychologist:
      case Role.nutritionist:
      case Role.referee:
      case Role.scorekeeper:
      case Role.registrar:
      case Role.frontDesk:
        return ScopeTier.branch;

      case Role.athlete:
      case Role.parent:
      case Role.alumni:
      case Role.sponsor:
        return ScopeTier.own;
    }
  }

  /// The taxonomy group this role belongs to.
  RoleGroup get group {
    switch (this) {
      case Role.developer:
      case Role.admin:
      case Role.itSupport:
        return RoleGroup.system;

      case Role.technicalDirector:
      case Role.operationsManager:
      case Role.branchManager:
        return RoleGroup.leadership;

      case Role.headCoach:
      case Role.coach:
      case Role.assistantCoach:
      case Role.sparringCoach:
      case Role.poomsaeCoach:
      case Role.conditioningCoach:
      case Role.demoTeamCoach:
        return RoleGroup.coaching;

      case Role.teamPhysician:
      case Role.physiotherapist:
      case Role.sportsPsychologist:
      case Role.nutritionist:
      case Role.analyst:
        return RoleGroup.support;

      case Role.tournamentAdmin:
      case Role.competitionCoordinator:
      case Role.referee:
      case Role.scorekeeper:
        return RoleGroup.competition;

      case Role.gradingExaminer:
        return RoleGroup.grading;

      case Role.registrar:
      case Role.frontDesk:
      case Role.finance:
      case Role.hrManager:
        return RoleGroup.administration;

      case Role.athlete:
      case Role.parent:
      case Role.alumni:
      case Role.federationViewer:
      case Role.sponsor:
        return RoleGroup.members;
    }
  }

  /// Coarse access tier for display.
  AccessLevel get accessLevel {
    switch (this) {
      case Role.developer:
      case Role.admin:
      case Role.technicalDirector:
      case Role.operationsManager:
        return AccessLevel.full;

      case Role.branchManager:
      case Role.headCoach:
      case Role.coach:
      case Role.assistantCoach:
      case Role.sparringCoach:
      case Role.poomsaeCoach:
      case Role.conditioningCoach:
      case Role.demoTeamCoach:
      case Role.teamPhysician:
      case Role.physiotherapist:
      case Role.sportsPsychologist:
      case Role.nutritionist:
      case Role.frontDesk:
      case Role.registrar:
        return AccessLevel.branchLimited;

      case Role.analyst:
      case Role.federationViewer:
      case Role.alumni:
      case Role.sponsor:
      case Role.athlete:
      case Role.parent:
        return AccessLevel.readOnly;

      case Role.itSupport:
      case Role.finance:
      case Role.hrManager:
      case Role.tournamentAdmin:
      case Role.competitionCoordinator:
      case Role.referee:
      case Role.scorekeeper:
      case Role.gradingExaminer:
        return AccessLevel.restricted;
    }
  }

  /// SF Symbol used to represent the role in lists, chips, and avatars.
  String get icon {
    switch (this) {
      case Role.developer:
        return 'hammer.fill';
      case Role.admin:
        return 'shield.lefthalf.filled';
      case Role.itSupport:
        return 'wrench.and.screwdriver.fill';
      case Role.technicalDirector:
        return 'checkmark.seal.fill';
      case Role.operationsManager:
        return 'gearshape.2.fill';
      case Role.branchManager:
        return 'building.2.fill';
      case Role.headCoach:
        return 'figure.taekwondo';
      case Role.coach:
        return 'figure.taekwondo';
      case Role.assistantCoach:
        return 'figure.taekwondo';
      case Role.sparringCoach:
        return 'figure.kickboxing';
      case Role.poomsaeCoach:
        return 'figure.martial.arts';
      case Role.conditioningCoach:
        return 'dumbbell.fill';
      case Role.demoTeamCoach:
        return 'sparkles';
      case Role.teamPhysician:
        return 'stethoscope';
      case Role.physiotherapist:
        return 'bandage.fill';
      case Role.sportsPsychologist:
        return 'brain.head.profile';
      case Role.nutritionist:
        return 'fork.knife';
      case Role.analyst:
        return 'chart.bar.xaxis';
      case Role.tournamentAdmin:
        return 'rosette';
      case Role.competitionCoordinator:
        return 'calendar.badge.clock';
      case Role.referee:
        return 'flag.checkered';
      case Role.scorekeeper:
        return 'number.square.fill';
      case Role.gradingExaminer:
        return 'medal.fill';
      case Role.registrar:
        return 'person.text.rectangle.fill';
      case Role.frontDesk:
        return 'bell.fill';
      case Role.finance:
        return 'creditcard.fill';
      case Role.hrManager:
        return 'person.2.badge.gearshape.fill';
      case Role.athlete:
        return 'figure.run';
      case Role.parent:
        return 'figure.2.and.child.holdinghands';
      case Role.alumni:
        return 'graduationcap.fill';
      case Role.federationViewer:
        return 'eye.fill';
      case Role.sponsor:
        return 'star.circle.fill';
    }
  }
}
