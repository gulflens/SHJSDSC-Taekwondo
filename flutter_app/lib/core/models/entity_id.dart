import 'dart:math';

/// Mirrors Swift's `EntityID = UUID`. We keep IDs as opaque strings in Dart so
/// they round-trip through JSON / Supabase unchanged. Generate new ones with
/// [newEntityId].
typedef EntityID = String;

final _rng = Random.secure();

/// RFC-4122 v4 UUID string. Used wherever Swift wrote `UUID()`.
EntityID newEntityId() {
  final bytes = List<int>.generate(16, (_) => _rng.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant 1
  String hex(int start, int end) => bytes
      .sublist(start, end)
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
}
