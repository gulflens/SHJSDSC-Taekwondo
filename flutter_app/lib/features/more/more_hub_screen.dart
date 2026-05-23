import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/role_router.dart' show DemoRolePicker;
import '../../core/blocs/session_cubit.dart';
import '../../l10n/app_localizations.dart';
import '../coaching/coaching_development_screen.dart';
import '../drills/drill_timer_screen.dart';
import '../grading/grading_screen.dart';
import '../livematch/live_match_screen.dart';
import '../operations/announcements_screen.dart';
import '../operations/audit_screen.dart';
import '../operations/certifications_screen.dart';
import '../tournaments/tournaments_screen.dart';

/// The "More" overflow hub — mirrors the Swift `AdaptiveNavigationShell` "More"
/// tab. Houses modules beyond the primary tabs; each new feature stage adds a
/// tile here until the per-role tab sets land. Also hosts the demo role
/// switcher.
class MoreHubScreen extends StatelessWidget {
  const MoreHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.moreTitle)),
      body: ListView(
        children: [
          _MoreTile(
            icon: Icons.school_outlined,
            label: l.navDevelopment,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const CoachingDevelopmentScreen()),
            ),
          ),
          const Divider(height: 1),
          _MoreTile(
            icon: Icons.workspace_premium_outlined,
            label: l.navGrading,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const GradingScreen()),
            ),
          ),
          const Divider(height: 1),
          _MoreTile(
            icon: Icons.sports_kabaddi_outlined,
            label: l.navLiveMatch,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LiveMatchSetupScreen()),
            ),
          ),
          const Divider(height: 1),
          _MoreTile(
            icon: Icons.timer_outlined,
            label: l.navDrillTimer,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DrillTimerSetupScreen()),
            ),
          ),
          const Divider(height: 1),
          _MoreTile(
            icon: Icons.emoji_events_outlined,
            label: l.navTournaments,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TournamentsScreen()),
            ),
          ),
          const Divider(height: 1),
          _MoreTile(
            icon: Icons.campaign_outlined,
            label: l.navAnnouncements,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AnnouncementsScreen()),
            ),
          ),
          const Divider(height: 1),
          _MoreTile(
            icon: Icons.verified_user_outlined,
            label: l.navCertifications,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CertificationsScreen()),
            ),
          ),
          const Divider(height: 1),
          _MoreTile(
            icon: Icons.history,
            label: l.navAudit,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AuditScreen()),
            ),
          ),
          const Divider(height: 1),
          _MoreTile(
            icon: Icons.people_alt_outlined,
            label: l.moreSwitchRole,
            onTap: () => DemoRolePicker.show(context),
          ),
          const Divider(height: 1),
          _MoreTile(
            icon: Icons.logout,
            label: l.navSignOut,
            onTap: () => context.read<SessionCubit>().signOut(),
          ),
        ],
      ),
    );
  }
}

class _MoreTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MoreTile(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
