import 'package:flutter_test/flutter_test.dart';
import 'package:shjsdsc/core/models/athlete_extras.dart';
import 'package:shjsdsc/core/repository/demo_repository.dart';

void main() {
  test('showcase athletes carry seeded coach notes (incl. a pinned one)', () async {
    final repo = DemoRepository();
    final rashid = (await repo.athlete('ath-1'))!;
    expect(rashid.coachNotes.length, 3);
    expect(rashid.coachNotes.where((n) => n.isPinned), hasLength(1));

    final hamad = (await repo.athlete('ath-3'))!;
    expect(hamad.coachNotes, isNotEmpty);
    final pinned = hamad.coachNotes.firstWhere((n) => n.isPinned);
    expect(pinned.category, CoachNoteCategory.medical);
  });

  test('an athlete with no notes has an empty list', () async {
    final repo = DemoRepository();
    expect((await repo.athlete('ath-7'))!.coachNotes, isEmpty);
  });
}
