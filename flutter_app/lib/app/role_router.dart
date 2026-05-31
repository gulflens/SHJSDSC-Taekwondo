import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/blocs/session_cubit.dart';
import '../core/models/entity_id.dart';
import '../core/models/role.dart';
import '../core/models/user.dart';
import '../features/athletes/athlete_detail_screen.dart';
import '../features/athletes/athlete_list_screen.dart';
import '../features/auth/sign_in_screen.dart';
import '../features/branches/branches_overview_screen.dart';
import '../features/coaches/coach_list_screen.dart';
import '../features/family/my_children_screen.dart';
import '../features/more/more_hub_screen.dart';
import '../features/schedule/schedule_screen.dart';
import '../l10n/app_localizations.dart';

/// Port of App/RoleRouter.swift. Watches the session and routes to one of the
/// base experiences by `role.experience`. Each experience gets its own primary
/// tab set (see [_tabsFor]) — federation roles see the full console, a coach
/// sees roster + schedule, athletes/parents see their schedule.
class RoleRouter extends StatelessWidget {
  const RoleRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SessionCubit, SessionState>(
      builder: (context, state) {
        if (state.loading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (!state.isAuthenticated) {
          // Unauthenticated (Supabase backend with no session, or after sign
          // out). The offline DemoRepository auto-resolves a user, so this
          // only appears on the backend path.
          return const SignInScreen();
        }
        final user = state.currentUser!;
        // Key by user so switching account/role rebuilds the shell fresh
        // (selected tab resets, tab set + per-user scoping re-derive).
        return _ExperienceShell(key: ValueKey(user.id), user: user);
      },
    );
  }
}

/// One primary tab: nav icons + label + the screen it shows.
class _TabSpec {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final Widget screen;
  const _TabSpec(this.icon, this.selectedIcon, this.label, this.screen);
}

/// Per-experience primary tab shell — the Flutter equivalent of the Swift
/// per-role `TabView`s (AthleteTabView, CoachTabView, …).
class _ExperienceShell extends StatefulWidget {
  final User user;
  const _ExperienceShell({super.key, required this.user});

  @override
  State<_ExperienceShell> createState() => _ExperienceShellState();
}

class _ExperienceShellState extends State<_ExperienceShell> {
  int _index = 0;

  /// The tab set for the signed-in user's experience. Athlete/parent tabs are
  /// scoped to `linkedAthleteIds` (own profile / children); the branch-manager
  /// roster + schedule are scoped to the user's branch; everyone else's
  /// schedule defaults to their branch (or the main branch for federation).
  /// `More` (with the role switcher) is always present.
  List<_TabSpec> _tabsFor(User user, L10n l) {
    final branch = user.primaryBranchId;

    _TabSpec athletes(EntityID? scope) => _TabSpec(Icons.people_outline,
        Icons.people, l.navAthletes, AthleteListScreen(branchId: scope));
    _TabSpec coaches(EntityID? scope) => _TabSpec(
        Icons.sports_martial_arts_outlined,
        Icons.sports_martial_arts,
        l.navCoaches,
        CoachListScreen(branchId: scope));
    _TabSpec schedule(EntityID? scope) => _TabSpec(Icons.calendar_month_outlined,
        Icons.calendar_month, l.navSchedule, ScheduleScreen(branchId: scope));
    final branchesTab = _TabSpec(Icons.business_outlined, Icons.business,
        l.navBranches, const BranchesOverviewScreen());
    final moreTab = _TabSpec(
        Icons.more_horiz, Icons.more_horiz, l.navMore, const MoreHubScreen());

    switch (user.role.experience) {
      case RoleExperience.coach:
        return [athletes(null), schedule(branch), moreTab];
      case RoleExperience.athlete:
        final linked = user.linkedAthleteIds;
        final profile = _TabSpec(
          Icons.person_outline,
          Icons.person,
          l.navProfile,
          linked.isEmpty
              ? const _NoProfilePlaceholder()
              : AthleteDetailScreen(athleteId: linked.first),
        );
        return [profile, schedule(branch), moreTab];
      case RoleExperience.parent:
        final children = _TabSpec(
          Icons.family_restroom_outlined,
          Icons.family_restroom,
          l.navChildren,
          MyChildrenScreen(athleteIds: user.linkedAthleteIds),
        );
        return [children, schedule(branch), moreTab];
      case RoleExperience.branchManager:
        // Scoped to the manager's own branch.
        return [
          athletes(branch),
          coaches(branch),
          branchesTab,
          schedule(branch),
          moreTab,
        ];
      case RoleExperience.developer:
      case RoleExperience.admin:
      case RoleExperience.technicalDirector:
      case RoleExperience.analyst:
        return [
          athletes(null),
          coaches(null),
          branchesTab,
          schedule(null),
          moreTab,
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final tabs = _tabsFor(widget.user, l);
    final idx = _index.clamp(0, tabs.length - 1);
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          for (final t in tabs)
            NavigationDestination(
              icon: Icon(t.icon),
              selectedIcon: Icon(t.selectedIcon),
              label: t.label,
            ),
        ],
      ),
      body: IndexedStack(
        index: idx,
        children: [for (final t in tabs) t.screen],
      ),
    );
  }
}

/// Shown on the athlete experience when the account has no linked athlete.
class _NoProfilePlaceholder extends StatelessWidget {
  const _NoProfilePlaceholder();

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.navProfile)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(l.familyNoProfile, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}

/// Port of `DemoRolePickerView` — the demo role switcher (no auth in demo).
class DemoRolePicker extends StatelessWidget {
  const DemoRolePicker({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet(
        context: context,
        showDragHandle: true,
        builder: (_) => BlocProvider.value(
          value: context.read<SessionCubit>(),
          child: const DemoRolePicker(),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    return BlocBuilder<SessionCubit, SessionState>(
      builder: (context, state) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(l.settingsRole,
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final u in state.availableUsers)
                      ListTile(
                        leading: CircleAvatar(child: Text(u.initials)),
                        title: Text(u.fullName),
                        subtitle: Text(u.role.name),
                        trailing: state.currentUser?.id == u.id
                            ? Icon(Icons.check_circle,
                                color: Theme.of(context).colorScheme.primary)
                            : null,
                        onTap: () async {
                          await context.read<SessionCubit>().switchTo(u);
                          if (context.mounted) Navigator.pop(context);
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
