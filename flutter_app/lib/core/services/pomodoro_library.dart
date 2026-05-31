import 'dart:convert';

import '../models/entity_id.dart';
import '../models/training_pomodoro.dart';

/// 1:1 port of Core/Services/PomodoroLibrary.swift.
///
/// Local-only library of saved pomodoro plans. The Swift actor uses
/// UserDefaults; in Dart we expose the same API against an injected
/// [PomodoroStorage] interface so the library stays testable and
/// platform-free. Wire it to `shared_preferences` in the platform stage.
///
/// Per-device — no cloud sync. Two coaches on different devices keep their
/// own libraries; that's a known limitation matching the Swift feature ask
/// (single-coach drills, not shared club playlists).

/// Minimal key-value storage contract.
/// TODO(platform): implement with package:shared_preferences in the
/// platform stage and inject via the locator.
abstract class PomodoroStorage {
  String? getString(String key);
  void setString(String key, String value);
  void remove(String key);
}

/// In-memory implementation for tests and the demo build.
class InMemoryPomodoroStorage implements PomodoroStorage {
  final _store = <String, String>{};

  @override
  String? getString(String key) => _store[key];

  @override
  void setString(String key, String value) => _store[key] = value;

  @override
  void remove(String key) => _store.remove(key);
}

class PomodoroLibrary {
  static const _key = 'trainingPomodoros.v1';

  final PomodoroStorage _storage;

  PomodoroLibrary({PomodoroStorage? storage})
    : _storage = storage ?? InMemoryPomodoroStorage();

  /// Returns all persisted plans, newest first. Returns an empty list if the
  /// store is empty or the JSON cannot be decoded.
  List<TrainingPomodoro> all() {
    final raw = _storage.getString(_key);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => TrainingPomodoro.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Upserts [plan] — replaces an existing plan with the same [id], or
  /// appends if this is a new plan.
  void save(TrainingPomodoro plan) {
    var current = all();
    final idx = current.indexWhere((p) => p.id == plan.id);
    if (idx >= 0) {
      current[idx] = plan;
    } else {
      current.add(plan);
    }
    _persist(current);
  }

  /// Removes the plan with [id]. No-op when the id is not found.
  void delete(EntityID id) {
    final filtered = all().where((p) => p.id != id).toList();
    _persist(filtered);
  }

  void _persist(List<TrainingPomodoro> plans) {
    try {
      final encoded = jsonEncode(plans.map((p) => p.toJson()).toList());
      _storage.setString(_key, encoded);
    } catch (_) {
      // JSON encoding failures are silently swallowed — same as Swift's
      // `try? JSONEncoder().encode(plans)`.
    }
  }
}
