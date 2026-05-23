import 'entity_id.dart';

// Port of Core/Models/Goal.swift.

enum GoalStatus {
  active,
  completed,
  abandoned;

  String get labelKey => 'goal.status.$name';

  static GoalStatus fromJson(String raw) => GoalStatus.values.firstWhere(
    (s) => s.name == raw,
    orElse: () => GoalStatus.active,
  );
}

class Goal {
  final EntityID id;
  final EntityID athleteId;
  final String title;
  final DateTime? targetDate;
  final GoalStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? notes;

  const Goal({
    required this.id,
    required this.athleteId,
    required this.title,
    this.targetDate,
    this.status = GoalStatus.active,
    required this.createdAt,
    this.completedAt,
    this.notes,
  });

  factory Goal.create({
    EntityID? id,
    required EntityID athleteId,
    required String title,
    DateTime? targetDate,
    GoalStatus status = GoalStatus.active,
    DateTime? createdAt,
    DateTime? completedAt,
    String? notes,
  }) => Goal(
    id: id ?? newEntityId(),
    athleteId: athleteId,
    title: title,
    targetDate: targetDate,
    status: status,
    createdAt: createdAt ?? DateTime.now(),
    completedAt: completedAt,
    notes: notes,
  );

  /// True when the goal is still active and its [targetDate] is in the past.
  bool get isOverdue {
    if (status != GoalStatus.active || targetDate == null) return false;
    return targetDate!.isBefore(DateTime.now());
  }

  factory Goal.fromJson(Map<String, dynamic> json) => Goal(
    id: json['id'] as String,
    athleteId: json['athleteID'] as String,
    title: json['title'] as String,
    targetDate: json['targetDate'] != null
        ? DateTime.parse(json['targetDate'] as String)
        : null,
    status: GoalStatus.fromJson(json['status'] as String? ?? 'active'),
    createdAt: DateTime.parse(json['createdAt'] as String),
    completedAt: json['completedAt'] != null
        ? DateTime.parse(json['completedAt'] as String)
        : null,
    notes: json['notes'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'athleteID': athleteId,
    'title': title,
    'targetDate': targetDate?.toIso8601String(),
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'notes': notes,
  };
}

/// Goal completion rate over goals that have reached a terminal state.
/// Active goals don't count for or against.
/// Returns null when there are no completed-or-abandoned entries.
///
/// Port of the Swift [Array where Element == Goal].completionRate extension.
double? goalCompletionRate(List<Goal> goals) {
  final terminal = goals.where((g) => g.status != GoalStatus.active).toList();
  if (terminal.isEmpty) return null;
  final completed = terminal
      .where((g) => g.status == GoalStatus.completed)
      .length;
  return completed / terminal.length;
}
