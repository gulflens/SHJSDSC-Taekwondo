import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/locator.dart';
import '../../core/blocs/audit_cubit.dart';
import '../../l10n/app_localizations.dart';
import '../common/design_system.dart';

/// Port of `AuditLogView` (subset) — an activity timeline via the ported
/// [AuditCubit]. Actor names resolve from the cubit's user lookup.
class AuditScreen extends StatelessWidget {
  const AuditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuditCubit(getIt())..load(),
      child: const _AuditBody(),
    );
  }
}

class _AuditBody extends StatelessWidget {
  const _AuditBody();

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.auditTitle)),
      body: BlocBuilder<AuditCubit, AuditState>(
        builder: (context, state) {
          if (state.status == AuditStatus.failed) {
            return Center(child: Text(l.loadFailed));
          }
          if (state.status != AuditStatus.ready) {
            return const Center(child: CircularProgressIndicator());
          }
          final entries = [...state.entries]
            ..sort((a, b) => b.at.compareTo(a.at));
          if (entries.isEmpty) {
            return Center(child: Text(l.auditEmpty));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final e = entries[i];
              final actor = state.userLookup[e.actorUserId]?.fullName ?? '—';
              final d = e.at;
              return SectionCard(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      child: Text(_initials(actor)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text.rich(TextSpan(children: [
                            TextSpan(
                                text: actor,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            TextSpan(text: '  ${e.action}'),
                          ])),
                          const SizedBox(height: 2),
                          Text('${e.targetEntity} · ${e.targetId}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text('${d.day}/${d.month}',
                          style: Theme.of(context).textTheme.bodySmall),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _initials(String name) {
    final parts = name.split(' ').where((p) => p.isNotEmpty).take(2);
    return parts.map((p) => p.substring(0, 1)).join().toUpperCase();
  }
}
