// Port of Core/Models/AuditLog.swift.
// Pure data — no Flutter imports (logic-layer rule).

import 'entity_id.dart';

class AuditEntry {
  final EntityID id;
  final DateTime at;
  final EntityID actorUserId;
  final String action;
  final String targetEntity;
  final EntityID targetId;
  final Map<String, String> changes;

  const AuditEntry({
    required this.id,
    required this.at,
    required this.actorUserId,
    required this.action,
    required this.targetEntity,
    required this.targetId,
    this.changes = const {},
  });

  factory AuditEntry.fromJson(Map<String, dynamic> json) => AuditEntry(
    id: json['id'] as String,
    at: DateTime.parse(json['at'] as String),
    actorUserId: json['actorUserID'] as String,
    action: json['action'] as String,
    targetEntity: json['targetEntity'] as String,
    targetId: json['targetID'] as String,
    changes:
        (json['changes'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(k, v as String),
        ) ??
        {},
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'at': at.toIso8601String(),
    'actorUserID': actorUserId,
    'action': action,
    'targetEntity': targetEntity,
    'targetID': targetId,
    'changes': changes,
  };
}
