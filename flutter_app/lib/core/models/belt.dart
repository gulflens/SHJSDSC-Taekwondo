// Port of Core/Models/Belt.swift. Pure data — no Flutter imports (logic layer
// rule carries over from the Swift app: Core must not import the UI toolkit).

enum BeltColor {
  white,
  yellow,
  green,
  blue,
  red,
  black;

  /// Hex used by the design layer when tinting a belt chip.
  String get hex => switch (this) {
        BeltColor.white => '#F5F5F5',
        BeltColor.yellow => '#FFD23F',
        BeltColor.green => '#2E9E5B',
        BeltColor.blue => '#1F6FEB',
        BeltColor.red => '#E53935',
        BeltColor.black => '#1A1A1A',
      };

  String get labelKey => 'belt.$name';

  static BeltColor fromJson(String raw) =>
      BeltColor.values.firstWhere((c) => c.name == raw, orElse: () => BeltColor.white);
}

enum BeltKind {
  gup,
  poom,
  dan;

  String get labelKey => 'belt.$name';

  static BeltKind fromJson(String raw) =>
      BeltKind.values.firstWhere((k) => k.name == raw, orElse: () => BeltKind.gup);
}

class Belt {
  final BeltColor color;
  final BeltKind kind;
  final int number;
  final DateTime awardedAt;

  const Belt({
    required this.color,
    required this.kind,
    required this.number,
    required this.awardedAt,
  });

  String get label => 'belt.${kind.name}.$number';

  BeltRank get rank => BeltRank(kind: kind, number: number);

  factory Belt.fromJson(Map<String, dynamic> json) => Belt(
        color: BeltColor.fromJson(json['color'] as String),
        kind: BeltKind.fromJson(json['kind'] as String),
        number: json['number'] as int,
        awardedAt: DateTime.parse(json['awardedAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'color': color.name,
        'kind': kind.name,
        'number': number,
        'awardedAt': awardedAt.toIso8601String(),
      };
}

/// Lightweight, awardless belt rank with a total ordering across the
/// gup → poom → dan ladder. Mirrors Swift's `Comparable` conformance.
class BeltRank implements Comparable<BeltRank> {
  final BeltKind kind;
  final int number;

  const BeltRank({required this.kind, required this.number});

  String get label => 'belt.${kind.name}.$number';

  /// Monotonic index across the full ladder.
  /// gup 10 = 0 … gup 1 = 9 ; poom 1 = 10 … poom 4 = 13 ; dan 1 = 14 …
  int get rankIndex => switch (kind) {
        BeltKind.gup => (10 - number).clamp(0, 100),
        BeltKind.poom => 10 + (number - 1).clamp(0, 100),
        BeltKind.dan => 14 + (number - 1).clamp(0, 100),
      };

  @override
  int compareTo(BeltRank other) => rankIndex.compareTo(other.rankIndex);

  bool operator <(BeltRank other) => rankIndex < other.rankIndex;
  bool operator >(BeltRank other) => rankIndex > other.rankIndex;

  @override
  bool operator ==(Object other) =>
      other is BeltRank && other.kind == kind && other.number == number;

  @override
  int get hashCode => Object.hash(kind, number);
}
