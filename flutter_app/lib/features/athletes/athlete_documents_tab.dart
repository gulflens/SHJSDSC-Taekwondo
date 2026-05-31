import 'package:flutter/material.dart';

import '../../core/models/athlete.dart';
import '../../core/models/athlete_extras.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../common/design_system.dart';
import '../common/document_labels.dart';

/// Port of `AthleteDocumentsTab` (subset) — identity / medical / federation
/// documents with a derived expiry status (valid / expiring / expired), read
/// off the embedded `Athlete.documents`.
class AthleteDocumentsTab extends StatelessWidget {
  final Athlete athlete;
  const AthleteDocumentsTab({super.key, required this.athlete});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    if (athlete.documents.isEmpty) {
      return Center(child: Text(l.docsEmpty));
    }
    // Worst status first (expired → expiring → valid → …).
    final docs = [...athlete.documents]
      ..sort((a, b) =>
          _rank(b.derivedStatus()).compareTo(_rank(a.derivedStatus())));
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: docs.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) => _DocRow(doc: docs[i]),
    );
  }

  int _rank(AthleteDocumentStatus s) => switch (s) {
        AthleteDocumentStatus.expired => 4,
        AthleteDocumentStatus.missing => 3,
        AthleteDocumentStatus.expiringSoon => 2,
        AthleteDocumentStatus.pending => 1,
        AthleteDocumentStatus.valid => 0,
      };
}

class _DocRow extends StatelessWidget {
  final AthleteDocument doc;
  const _DocRow({required this.doc});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final status = doc.derivedStatus();
    final color = _statusColor(status, context);
    final exp = doc.expiresAt;
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
                Text(doc.kind.localized(l),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                if (exp != null)
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      '${exp.day}/${exp.month}/${exp.year}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
          ),
          StatusPill(label: status.localized(l), color: color),
        ],
      ),
    );
  }

  Color _statusColor(AthleteDocumentStatus s, BuildContext context) =>
      switch (s) {
        AthleteDocumentStatus.valid => AppColors.good,
        AthleteDocumentStatus.expiringSoon => AppColors.behind,
        AthleteDocumentStatus.expired => AppColors.critical,
        AthleteDocumentStatus.missing => AppColors.critical,
        AthleteDocumentStatus.pending => Theme.of(context).colorScheme.outline,
      };
}
