import 'package:flutter/material.dart';

import '../../app/locator.dart';
import '../../core/models/entity_id.dart';
import '../../core/models/operations.dart';
import '../../core/repository/repository.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../common/design_system.dart';
import '../common/operations_localized_labels.dart';

/// Port of `CoachCertificationsTab` (subset) — the coach's certifications from
/// `certificationsForCoach(coach.id)`, sorted worst-severity-first, with the
/// model-derived valid/expiring/expired status.
class CoachCertificationsTab extends StatelessWidget {
  final EntityID coachId;
  const CoachCertificationsTab({super.key, required this.coachId});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    return FutureBuilder<List<Certification>>(
      future: getIt<Repository>().certificationsForCoach(coachId),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final certs = [...snap.data!]
          ..sort((a, b) => _rank(b.severity).compareTo(_rank(a.severity)));
        if (certs.isEmpty) {
          return Center(child: Text(l.certificationsEmpty));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: certs.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, i) => _CertRow(cert: certs[i]),
        );
      },
    );
  }

  int _rank(CertificationSeverity s) => switch (s) {
        CertificationSeverity.expired => 2,
        CertificationSeverity.expiring => 1,
        CertificationSeverity.ok => 0,
      };
}

class _CertRow extends StatelessWidget {
  final Certification cert;
  const _CertRow({required this.cert});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final color = switch (cert.severity) {
      CertificationSeverity.ok => AppColors.good,
      CertificationSeverity.expiring => AppColors.behind,
      CertificationSeverity.expired => AppColors.critical,
    };
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
                Text(cert.issuer,
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
}
