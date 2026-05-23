import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/locator.dart';
import '../../core/blocs/operations_cubit.dart';
import '../../core/models/operations.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../common/design_system.dart';
import '../common/operations_localized_labels.dart';

/// Port of `AnnouncementsView` (subset) — feed of announcement cards via the
/// ported [OperationsCubit]. The compose/edit + RSVP detail land in a later
/// stage.
class AnnouncementsScreen extends StatelessWidget {
  const AnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OperationsCubit(getIt())..load(),
      child: const _AnnouncementsBody(),
    );
  }
}

class _AnnouncementsBody extends StatelessWidget {
  const _AnnouncementsBody();

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.announcementsTitle)),
      body: BlocBuilder<OperationsCubit, OperationsState>(
        builder: (context, state) {
          if (state.status == OperationsStatus.failed) {
            return Center(child: Text(l.loadFailed));
          }
          if (state.status != OperationsStatus.ready) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.announcements.isEmpty) {
            return Center(child: Text(l.announcementsEmpty));
          }
          final items = [...state.announcements]
            ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _AnnouncementCard(item: items[i]),
          );
        },
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final Announcement item;
  const _AnnouncementCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final scheme = Theme.of(context).colorScheme;
    final d = item.publishedAt;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusPill(
                label: item.category.localized(l),
                color: _categoryColor(item.category, context),
              ),
              if (item.status == AnnouncementStatus.scheduled) ...[
                const SizedBox(width: 8),
                StatusPill(label: l.annScheduled, color: AppColors.behind),
              ],
              const Spacer(),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text('${d.day}/${d.month}',
                    style: TextStyle(color: scheme.outline, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(item.title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          if (item.body.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(item.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium),
          ],
          if ((item.authorName ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(item.authorName!,
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

Color _categoryColor(AnnouncementCategory c, BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  return switch (c) {
    AnnouncementCategory.grading => AppColors.good,
    AnnouncementCategory.tournament => scheme.primary,
    AnnouncementCategory.registration => scheme.secondary,
    AnnouncementCategory.policy => AppColors.behind,
    AnnouncementCategory.event => scheme.primary,
    AnnouncementCategory.recognition => AppColors.good,
    AnnouncementCategory.general => scheme.outline,
  };
}
