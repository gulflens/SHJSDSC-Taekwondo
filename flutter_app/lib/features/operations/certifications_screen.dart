import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/locator.dart';
import '../../core/blocs/certifications_cubit.dart';
import '../../core/models/entity_id.dart';
import '../../core/models/operations.dart';
import '../../core/repository/repository.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../common/design_system.dart';
import '../common/operations_localized_labels.dart';

/// Port of `CertificationsListView` (subset) — federation compliance dashboard:
/// valid / expiring / expired summary + a severity-sorted certification list,
/// via the ported [CertificationsCubit]. Coach names are resolved alongside.
class CertificationsScreen extends StatelessWidget {
  const CertificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CertificationsCubit(getIt())..loadAll(),
      child: const _CertificationsBody(),
    );
  }
}

class _CertificationsBody extends StatefulWidget {
  const _CertificationsBody();

  @override
  State<_CertificationsBody> createState() => _CertificationsBodyState();
}

class _CertificationsBodyState extends State<_CertificationsBody> {
  late final Future<Map<EntityID, String>> _coachNames = _loadNames();

  Future<Map<EntityID, String>> _loadNames() async {
    final coaches = await getIt<Repository>().coaches();
    return {for (final c in coaches) c.id: c.fullName};
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.certificationsTitle)),
      body: FutureBuilder<Map<EntityID, String>>(
        future: _coachNames,
        builder: (context, namesSnap) {
          return BlocBuilder<CertificationsCubit, CertificationsState>(
            builder: (context, state) {
              if (state.status == CertificationsStatus.failed) {
                return Center(child: Text(l.loadFailed));
              }
              if (state.status != CertificationsStatus.ready ||
                  !namesSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final names = namesSnap.data!;
              final certs = [...state.certifications]..sort((a, b) =>
                  _rank(b.severity).compareTo(_rank(a.severity)));
              if (certs.isEmpty) {
                return Center(child: Text(l.certificationsEmpty));
              }
              final expired = certs
                  .where((c) => c.severity == CertificationSeverity.expired)
                  .length;
              final expiring = certs
                  .where((c) => c.severity == CertificationSeverity.expiring)
                  .length;
              final ok = certs.length - expired - expiring;
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _ComplianceSummary(ok: ok, expiring: expiring, expired: expired),
                  const SizedBox(height: 16),
                  for (final c in certs) ...[
                    _CertRow(cert: c, coachName: names[c.coachId] ?? '—'),
                    const SizedBox(height: 8),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }

  int _rank(CertificationSeverity s) => switch (s) {
        CertificationSeverity.expired => 2,
        CertificationSeverity.expiring => 1,
        CertificationSeverity.ok => 0,
      };
}

class _ComplianceSummary extends StatelessWidget {
  final int ok;
  final int expiring;
  final int expired;
  const _ComplianceSummary(
      {required this.ok, required this.expiring, required this.expired});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    return SectionCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Stat(value: ok, label: l.certOk, color: AppColors.good),
          _Stat(value: expiring, label: l.certExpiring, color: AppColors.behind),
          _Stat(value: expired, label: l.certExpired, color: AppColors.critical),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final int value;
  final String label;
  final Color color;
  const _Stat({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Directionality(
          textDirection: TextDirection.ltr,
          child: Text('$value',
              style: TextStyle(
                  color: color,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()])),
        ),
        const SizedBox(height: 2),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _CertRow extends StatelessWidget {
  final Certification cert;
  final String coachName;
  const _CertRow({required this.cert, required this.coachName});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final sev = cert.severity;
    final color = _sevColor(sev);
    final days = cert.daysUntilExpiry;
    return SectionCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(width: 4, height: 38, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cert.kind.localized(l),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('$coachName · ${cert.issuer}',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          StatusPill(
            label: days < 0
                ? l.certExpiredAgo(-days)
                : l.certExpiresInDays(days),
            color: color,
          ),
        ],
      ),
    );
  }

  Color _sevColor(CertificationSeverity s) => switch (s) {
        CertificationSeverity.ok => AppColors.good,
        CertificationSeverity.expiring => AppColors.behind,
        CertificationSeverity.expired => AppColors.critical,
      };
}
