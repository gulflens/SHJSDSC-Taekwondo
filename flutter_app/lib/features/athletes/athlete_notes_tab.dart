import 'package:flutter/material.dart';

import '../../core/models/athlete.dart';
import '../../core/models/athlete_extras.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../common/coach_note_labels.dart';
import '../common/design_system.dart';

/// Port of `AthleteCoachNotesTab` (subset) — pinned-first feed of coach notes
/// read off the embedded `Athlete.coachNotes`.
class AthleteNotesTab extends StatelessWidget {
  final Athlete athlete;
  const AthleteNotesTab({super.key, required this.athlete});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    if (athlete.coachNotes.isEmpty) {
      return Center(child: Text(l.notesEmpty));
    }
    // Pinned first, then newest.
    final notes = [...athlete.coachNotes]..sort((a, b) {
        if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
        return b.date.compareTo(a.date);
      });
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: notes.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _NoteCard(note: notes[i]),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final CoachNote note;
  const _NoteCard({required this.note});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final scheme = Theme.of(context).colorScheme;
    final d = note.date;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusPill(
                  label: note.category.localized(l), color: scheme.primary),
              if (note.isPinned) ...[
                const SizedBox(width: 8),
                Icon(Icons.push_pin, size: 14, color: AppColors.behind),
              ],
              const Spacer(),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text('${d.day}/${d.month}',
                    style: TextStyle(color: scheme.outline, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(note.body, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 6),
          Text(note.authorName,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
