/// Key-case bridge between the Dart models' camelCase JSON (which mirrors the
/// Swift Codable property names) and the snake_case Postgres columns / jsonb
/// keys used by the Supabase schema.
///
/// This is a 1:1 port of the `camelToSnake` / `snakeToCamel` strategy in
/// Core/Repository/SupabaseRepository.swift, including the uppercase-acronym
/// suffix handling — Foundation's generic snake_case strategy would mangle
/// `avatarURL` → `avatar_u_r_l`, so the Swift app special-cases a fixed list
/// of acronym suffixes. We must match that list exactly or column names won't
/// line up (PGRST204).
///
/// Conversion is applied recursively to nested maps and lists, because the
/// Swift `JSONEncoder.keyEncodingStrategy` rewrites keys at every depth — so
/// jsonb blobs (e.g. `current_belt { awarded_at }`) are snake_case too. Only
/// KEYS are converted; string VALUES (enum raw values like `competitionTeam`)
/// pass through untouched.
library;

/// Every acronym suffix that appears on a `Core/` Codable property. Order
/// matters — longer variants first (`IDs` before `ID`) — and the first match
/// wins, mirroring the Swift `break`.
const _suffixAcronyms = ['IDs', 'ID', 'URLs', 'URL', 'AED', 'RSVP', 'PSS', 'AC'];

String camelToSnakeKey(String key) {
  // Normalise a trailing acronym to TitleCase so the generic splitter treats
  // it as one word: avatarURL → avatarUrl, parentUserIDs → parentUserIds.
  var k = key;
  for (final acronym in _suffixAcronyms) {
    if (k.endsWith(acronym)) {
      final head = k.substring(0, k.length - acronym.length);
      final firstUpper = acronym.substring(0, 1);
      final restLower = acronym.substring(1).toLowerCase();
      k = head + firstUpper + restLower;
      break;
    }
  }
  final out = StringBuffer();
  for (var i = 0; i < k.length; i++) {
    final c = k[i];
    final isUpper = c.toUpperCase() == c && c.toLowerCase() != c;
    if (isUpper && i > 0) out.write('_');
    out.write(c.toLowerCase());
  }
  return out.toString();
}

String snakeToCamelKey(String key) {
  // Restore an acronym suffix by matching its snake form (`_url`, `_rsvp`) so
  // unrelated tail tokens aren't upcased.
  for (final acronym in _suffixAcronyms) {
    final snakeSuffix = '_${acronym.toLowerCase()}';
    if (key.endsWith(snakeSuffix)) {
      final head = key.substring(0, key.length - snakeSuffix.length);
      return _baseSnakeToCamel(head) + acronym;
    }
  }
  return _baseSnakeToCamel(key);
}

String _baseSnakeToCamel(String key) {
  final parts = key.split('_');
  if (parts.isEmpty) return key;
  final buffer = StringBuffer(parts.first);
  for (var i = 1; i < parts.length; i++) {
    final p = parts[i];
    if (p.isEmpty) continue;
    buffer.write(p[0].toUpperCase());
    buffer.write(p.substring(1));
  }
  return buffer.toString();
}

/// Recursively convert a model `toJson()` map (camelCase keys) into the
/// snake_case shape Supabase expects.
Object? encodeKeys(Object? value) {
  if (value is Map<String, dynamic>) {
    return {
      for (final entry in value.entries)
        camelToSnakeKey(entry.key): encodeKeys(entry.value),
    };
  }
  if (value is List) {
    return value.map(encodeKeys).toList();
  }
  return value;
}

/// Recursively convert a Supabase row (snake_case keys) into the camelCase
/// shape the model `fromJson()` expects.
Map<String, dynamic> decodeRow(Map<String, dynamic> row) =>
    _decode(row) as Map<String, dynamic>;

Object? _decode(Object? value) {
  if (value is Map<String, dynamic>) {
    return {
      for (final entry in value.entries)
        snakeToCamelKey(entry.key): _decode(entry.value),
    };
  }
  if (value is List) {
    return value.map(_decode).toList();
  }
  return value;
}
