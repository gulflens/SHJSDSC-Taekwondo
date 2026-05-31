import 'entity_id.dart';

/// Port of Core/Models/Branch/BranchInventory.swift.

enum ItemCategory {
  hogu,
  helmet,
  shinGuard,
  forearmGuard,
  mouthGuard,
  groinGuard,
  kickingPad,
  targetPad,
  breakingBoard,
  doboK,
  beltStock,
  mat,
  scoreboard,
  medkit,
  aed,
  other;

  String get labelKey => 'inventory.$name';

  static ItemCategory fromJson(String raw) => ItemCategory.values.firstWhere(
    (c) => c.name == raw,
    orElse: () => ItemCategory.other,
  );
}

class InventoryItem {
  final EntityID id;
  final ItemCategory category;
  final String labelKey;
  final String? size;
  final int quantity;
  final int conditionGood;
  final int conditionFair;
  final int conditionPoor;
  final String? notes;

  const InventoryItem({
    required this.id,
    required this.category,
    required this.labelKey,
    this.size,
    required this.quantity,
    this.conditionGood = 0,
    this.conditionFair = 0,
    this.conditionPoor = 0,
    this.notes,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) => InventoryItem(
    id: json['id'] as String,
    category: ItemCategory.fromJson(json['category'] as String),
    labelKey: json['labelKey'] as String,
    size: json['size'] as String?,
    quantity: json['quantity'] as int,
    conditionGood: json['conditionGood'] as int? ?? 0,
    conditionFair: json['conditionFair'] as int? ?? 0,
    conditionPoor: json['conditionPoor'] as int? ?? 0,
    notes: json['notes'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category.name,
    'labelKey': labelKey,
    'size': size,
    'quantity': quantity,
    'conditionGood': conditionGood,
    'conditionFair': conditionFair,
    'conditionPoor': conditionPoor,
    'notes': notes,
  };
}

class BranchInventory {
  final EntityID id;
  final EntityID branchId;
  final List<InventoryItem> items;
  final DateTime lastAuditAt;
  final EntityID lastAuditByUserId;

  const BranchInventory({
    required this.id,
    required this.branchId,
    this.items = const [],
    required this.lastAuditAt,
    required this.lastAuditByUserId,
  });

  factory BranchInventory.fromJson(Map<String, dynamic> json) =>
      BranchInventory(
        id: json['id'] as String,
        branchId: json['branchID'] as String,
        items: ((json['items'] as List?) ?? [])
            .map((e) => InventoryItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        lastAuditAt: DateTime.parse(json['lastAuditAt'] as String),
        lastAuditByUserId: json['lastAuditByUserID'] as String,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'branchID': branchId,
    'items': items.map((i) => i.toJson()).toList(),
    'lastAuditAt': lastAuditAt.toIso8601String(),
    'lastAuditByUserID': lastAuditByUserId,
  };
}
