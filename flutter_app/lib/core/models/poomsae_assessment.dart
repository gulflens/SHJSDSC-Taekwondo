import 'belt.dart';
import 'entity_id.dart';

/// Port of Core/Models/PoomsaeAssessment.swift.

enum PoomsaeForm {
  // Coloured-belt syllabus (Kukkiwon Taegeuk series)
  taegeuk1,
  taegeuk2,
  taegeuk3,
  taegeuk4,
  taegeuk5,
  taegeuk6,
  taegeuk7,
  taegeuk8,

  // Black-belt syllabus
  koryo,
  keumgang,
  taebaek,
  pyongwon,
  sipjin,
  jitae,
  cheonkwon,
  hansoo,
  ilyeo;

  String get labelKey => 'poomsae.$name';

  bool get isBlackBelt => switch (this) {
    PoomsaeForm.taegeuk1 ||
    PoomsaeForm.taegeuk2 ||
    PoomsaeForm.taegeuk3 ||
    PoomsaeForm.taegeuk4 ||
    PoomsaeForm.taegeuk5 ||
    PoomsaeForm.taegeuk6 ||
    PoomsaeForm.taegeuk7 ||
    PoomsaeForm.taegeuk8 => false,
    _ => true,
  };

  /// Belt level this form is first introduced at, as (kind, number).
  (BeltKind kind, int number) get requiredAt => switch (this) {
    PoomsaeForm.taegeuk1 => (BeltKind.gup, 8),
    PoomsaeForm.taegeuk2 => (BeltKind.gup, 7),
    PoomsaeForm.taegeuk3 => (BeltKind.gup, 6),
    PoomsaeForm.taegeuk4 => (BeltKind.gup, 5),
    PoomsaeForm.taegeuk5 => (BeltKind.gup, 4),
    PoomsaeForm.taegeuk6 => (BeltKind.gup, 3),
    PoomsaeForm.taegeuk7 => (BeltKind.gup, 2),
    PoomsaeForm.taegeuk8 => (BeltKind.gup, 1),
    PoomsaeForm.koryo => (BeltKind.dan, 1),
    PoomsaeForm.keumgang => (BeltKind.dan, 2),
    PoomsaeForm.taebaek => (BeltKind.dan, 3),
    PoomsaeForm.pyongwon => (BeltKind.dan, 4),
    PoomsaeForm.sipjin => (BeltKind.dan, 5),
    PoomsaeForm.jitae => (BeltKind.dan, 6),
    PoomsaeForm.cheonkwon => (BeltKind.dan, 7),
    PoomsaeForm.hansoo => (BeltKind.dan, 8),
    PoomsaeForm.ilyeo => (BeltKind.dan, 9),
  };

  /// True when this form is part of the syllabus an athlete at [belt] should
  /// already know.
  bool isRequired(Belt belt) {
    final req = requiredAt;
    final reqKind = req.$1;
    final reqNumber = req.$2;

    if (reqKind == BeltKind.gup && belt.kind == BeltKind.gup) {
      return belt.number <= reqNumber;
    }
    if (reqKind == BeltKind.gup &&
        (belt.kind == BeltKind.poom || belt.kind == BeltKind.dan)) {
      return true;
    }
    if (reqKind == BeltKind.dan && belt.kind == BeltKind.dan) {
      return belt.number >= reqNumber;
    }
    if (reqKind == BeltKind.dan && belt.kind == BeltKind.poom) {
      return reqNumber == 1;
    }
    if (reqKind == BeltKind.dan && belt.kind == BeltKind.gup) {
      return false;
    }
    // reqKind == poom (unreachable in current data) → false
    return false;
  }

  static PoomsaeForm fromJson(String raw) => PoomsaeForm.values.firstWhere(
    (e) => e.name == raw,
    orElse: () => PoomsaeForm.taegeuk1,
  );
}

class PoomsaeAssessment {
  final EntityID id;
  final EntityID athleteId;
  final DateTime recordedAt;
  final EntityID recordedByCoachId;
  final PoomsaeForm form;

  /// 1…10 — stances, techniques, sequence.
  final int accuracy;

  /// 1…10 — power, speed, rhythm.
  final int presentation;

  /// 1…10 — overall stability and weight transfer.
  final int balance;

  /// 1…10 — kihap, intent, focus.
  final int expression;

  /// Time to complete the form, in seconds.
  final int timeSeconds;

  final String? videoUrl;
  final String? notes;

  PoomsaeAssessment({
    EntityID? id,
    required this.athleteId,
    required this.recordedAt,
    required this.recordedByCoachId,
    required this.form,
    required int accuracy,
    required int presentation,
    required int balance,
    required int expression,
    required int timeSeconds,
    this.videoUrl,
    this.notes,
  }) : id = id ?? newEntityId(),
       accuracy = accuracy.clamp(1, 10),
       presentation = presentation.clamp(1, 10),
       balance = balance.clamp(1, 10),
       expression = expression.clamp(1, 10),
       timeSeconds = timeSeconds < 0 ? 0 : timeSeconds;

  /// Mean of the four scoring axes, 1…10.
  double get averageScore =>
      (accuracy + presentation + balance + expression) / 4.0;

  factory PoomsaeAssessment.fromJson(Map<String, dynamic> json) =>
      PoomsaeAssessment(
        id: json['id'] as String,
        athleteId: json['athleteID'] as String,
        recordedAt: DateTime.parse(json['recordedAt'] as String),
        recordedByCoachId: json['recordedByCoachID'] as String,
        form: PoomsaeForm.fromJson(json['form'] as String),
        accuracy: json['accuracy'] as int,
        presentation: json['presentation'] as int,
        balance: json['balance'] as int,
        expression: json['expression'] as int,
        timeSeconds: json['timeSeconds'] as int,
        videoUrl: json['videoURL'] as String?,
        notes: json['notes'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'athleteID': athleteId,
    'recordedAt': recordedAt.toIso8601String(),
    'recordedByCoachID': recordedByCoachId,
    'form': form.name,
    'accuracy': accuracy,
    'presentation': presentation,
    'balance': balance,
    'expression': expression,
    'timeSeconds': timeSeconds,
    'videoURL': videoUrl,
    'notes': notes,
  };
}

extension PoomsaeAssessmentListExt on List<PoomsaeAssessment> {
  /// Latest assessment per form.
  List<PoomsaeAssessment> latestPerForm() {
    final seen = <PoomsaeForm, PoomsaeAssessment>{};
    final sorted = [...this]
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    for (final a in sorted) {
      seen.putIfAbsent(a.form, () => a);
    }
    return seen.values.toList();
  }
}
