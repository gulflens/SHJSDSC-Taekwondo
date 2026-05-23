// Port of Core/Models/DrillDossier.swift.
// Pure data — no Flutter imports (logic-layer rule).

import 'entity_id.dart';

/// One piece of equipment a drill needs, with an optional quantity note
/// ("2+", "1 per athlete"). Surfaced as a chip in the drill preview panel.
class DrillEquipmentItem {
  final EntityID id;
  final String name;
  final String? nameAr;
  final String? quantityNote;
  final String systemIcon;

  const DrillEquipmentItem({
    required this.id,
    required this.name,
    this.nameAr,
    this.quantityNote,
    this.systemIcon = 'shippingbox.fill',
  });

  factory DrillEquipmentItem.create({
    required String name,
    String? nameAr,
    String? quantityNote,
    String systemIcon = 'shippingbox.fill',
  }) => DrillEquipmentItem(
    id: newEntityId(),
    name: name,
    nameAr: nameAr,
    quantityNote: quantityNote,
    systemIcon: systemIcon,
  );

  factory DrillEquipmentItem.fromJson(Map<String, dynamic> json) =>
      DrillEquipmentItem(
        id: json['id'] as String,
        name: json['name'] as String,
        nameAr: json['nameAr'] as String?,
        quantityNote: json['quantityNote'] as String?,
        systemIcon: json['systemIcon'] as String? ?? 'shippingbox.fill',
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'nameAr': nameAr,
    'quantityNote': quantityNote,
    'systemIcon': systemIcon,
  };
}

/// Operational numbers a coach reads at a glance — rendered as the pastel
/// metric cards in the drill detail panel. Every field is optional; only the
/// populated ones get a card.
class DrillMetrics {
  final int? sets;
  final String? distance;
  final String? rest;
  final String? totalTime;
  final String? spaceRequired;
  final String? athleteLevelNote;

  const DrillMetrics({
    this.sets,
    this.distance,
    this.rest,
    this.totalTime,
    this.spaceRequired,
    this.athleteLevelNote,
  });

  /// True when no metric is populated — lets the detail panel hide the
  /// whole section rather than show an empty grid.
  bool get isEmpty =>
      sets == null &&
      distance == null &&
      rest == null &&
      totalTime == null &&
      spaceRequired == null &&
      athleteLevelNote == null;

  factory DrillMetrics.fromJson(Map<String, dynamic> json) => DrillMetrics(
    sets: json['sets'] as int?,
    distance: json['distance'] as String?,
    rest: json['rest'] as String?,
    totalTime: json['totalTime'] as String?,
    spaceRequired: json['spaceRequired'] as String?,
    athleteLevelNote: json['athleteLevelNote'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'sets': sets,
    'distance': distance,
    'rest': rest,
    'totalTime': totalTime,
    'spaceRequired': spaceRequired,
    'athleteLevelNote': athleteLevelNote,
  };
}

/// A named progression or variation on the base drill (e.g. "Add resistance
/// band", "Partner-fed tempo"). Shown in the Variations tab.
class DrillVariation {
  final EntityID id;
  final String title;
  final String? titleAr;
  final String detail;

  const DrillVariation({
    required this.id,
    required this.title,
    this.titleAr,
    required this.detail,
  });

  factory DrillVariation.create({
    required String title,
    String? titleAr,
    required String detail,
  }) => DrillVariation(
    id: newEntityId(),
    title: title,
    titleAr: titleAr,
    detail: detail,
  );

  factory DrillVariation.fromJson(Map<String, dynamic> json) => DrillVariation(
    id: json['id'] as String,
    title: json['title'] as String,
    titleAr: json['titleAr'] as String?,
    detail: json['detail'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'titleAr': titleAr,
    'detail': detail,
  };
}
