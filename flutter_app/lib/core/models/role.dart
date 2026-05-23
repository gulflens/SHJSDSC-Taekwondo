// Port of `Role` from Core/Models/CoreEntities.swift, plus the role→experience
// grouping that lived in App/RoleRouter.swift. Keeping the routing logic on the
// model (rather than in the widget) matches the Swift app's "8 base
// experiences" design and keeps the router declarative.

enum RoleExperience {
  developer,
  admin,
  technicalDirector,
  branchManager,
  coach,
  analyst,
  athlete,
  parent,
}

enum Role {
  // System & technical
  developer,
  admin,
  itSupport,
  // Federation leadership
  technicalDirector,
  operationsManager,
  branchManager,
  // Coaching staff
  headCoach,
  coach,
  assistantCoach,
  sparringCoach,
  poomsaeCoach,
  conditioningCoach,
  demoTeamCoach,
  // Medical & athlete support
  teamPhysician,
  physiotherapist,
  sportsPsychologist,
  nutritionist,
  analyst,
  // Competition & officiating
  tournamentAdmin,
  competitionCoordinator,
  referee,
  scorekeeper,
  // Grading
  gradingExaminer,
  // Administration & operations
  registrar,
  frontDesk,
  finance,
  hrManager,
  // Members & external
  athlete,
  parent,
  alumni,
  federationViewer,
  sponsor;

  String get label => 'role.$name';

  static Role fromJson(String raw) =>
      Role.values.firstWhere((r) => r.name == raw, orElse: () => Role.athlete);

  /// The single base experience this role routes to — mirrors the switch in
  /// RoleRouter.swift exactly.
  RoleExperience get experience => switch (this) {
        Role.developer => RoleExperience.developer,
        Role.admin ||
        Role.itSupport ||
        Role.operationsManager ||
        Role.tournamentAdmin ||
        Role.competitionCoordinator ||
        Role.registrar ||
        Role.frontDesk ||
        Role.finance ||
        Role.hrManager =>
          RoleExperience.admin,
        Role.technicalDirector || Role.gradingExaminer => RoleExperience.technicalDirector,
        Role.branchManager => RoleExperience.branchManager,
        Role.coach ||
        Role.headCoach ||
        Role.assistantCoach ||
        Role.sparringCoach ||
        Role.poomsaeCoach ||
        Role.conditioningCoach ||
        Role.demoTeamCoach ||
        Role.teamPhysician ||
        Role.physiotherapist ||
        Role.sportsPsychologist ||
        Role.nutritionist ||
        Role.referee ||
        Role.scorekeeper =>
          RoleExperience.coach,
        Role.analyst => RoleExperience.analyst,
        Role.athlete ||
        Role.alumni ||
        Role.federationViewer ||
        Role.sponsor =>
          RoleExperience.athlete,
        Role.parent => RoleExperience.parent,
      };
}
