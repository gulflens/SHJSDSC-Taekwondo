import 'entity_id.dart';

/// Port of Core/Models/Branch/BranchHours.swift.

/// Swift: `enum DayOfWeek: Int` with raw values sun=1..sat=7.
enum DayOfWeek {
  sun(1),
  mon(2),
  tue(3),
  wed(4),
  thu(5),
  fri(6),
  sat(7);

  const DayOfWeek(this.rawValue);
  final int rawValue;

  String get labelKey => 'day.$name';

  static DayOfWeek fromJson(int raw) => DayOfWeek.values.firstWhere(
    (d) => d.rawValue == raw,
    orElse: () => DayOfWeek.sun,
  );
}

class DayHours {
  final DayOfWeek day;
  final bool isOpen;

  /// "06:00" 24-hour format.
  final String? opensAt;

  /// "23:00" 24-hour format.
  final String? closesAt;

  const DayHours({
    required this.day,
    required this.isOpen,
    this.opensAt,
    this.closesAt,
  });

  factory DayHours.fromJson(Map<String, dynamic> json) => DayHours(
    day: DayOfWeek.fromJson(json['day'] as int),
    isOpen: json['isOpen'] as bool,
    opensAt: json['opensAt'] as String?,
    closesAt: json['closesAt'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'day': day.rawValue,
    'isOpen': isOpen,
    'opensAt': opensAt,
    'closesAt': closesAt,
  };
}

/// A date range (inclusive) used for term breaks.
class DateInterval {
  final DateTime start;
  final DateTime end;

  const DateInterval({required this.start, required this.end});

  factory DateInterval.fromJson(Map<String, dynamic> json) => DateInterval(
    start: DateTime.parse(json['start'] as String),
    end: DateTime.parse(json['end'] as String),
  );

  Map<String, dynamic> toJson() => {
    'start': start.toIso8601String(),
    'end': end.toIso8601String(),
  };
}

class BranchHours {
  final EntityID id;
  final EntityID branchId;
  final List<DayHours> regular;
  final List<DayHours>? ramadan;
  final DateTime? ramadanStart;
  final DateTime? ramadanEnd;
  final List<DateTime> holidayClosures;
  final List<DateInterval> termBreaks;

  const BranchHours({
    required this.id,
    required this.branchId,
    required this.regular,
    this.ramadan,
    this.ramadanStart,
    this.ramadanEnd,
    this.holidayClosures = const [],
    this.termBreaks = const [],
  });

  /// True when [now] falls inside the configured Ramadan window.
  bool isRamadanActive({DateTime? now}) {
    final checkNow = now ?? DateTime.now();
    if (ramadanStart == null || ramadanEnd == null) return false;
    return !checkNow.isBefore(ramadanStart!) && !checkNow.isAfter(ramadanEnd!);
  }

  /// Currently-applicable hours table — Ramadan overrides regular when active.
  List<DayHours> currentSchedule({DateTime? now}) {
    final checkNow = now ?? DateTime.now();
    if (isRamadanActive(now: checkNow) && ramadan != null) return ramadan!;
    return regular;
  }

  /// Today's hours entry (nil if the schedule is missing it).
  /// [DateTime.weekday] is Mon=1..Sun=7; Swift's DayOfWeek Sun=1..Sat=7.
  DayHours? today({DateTime? now}) {
    final checkNow = now ?? DateTime.now();
    // Convert Dart weekday (Mon=1, Sun=7) → Swift rawValue (Sun=1..Sat=7)
    final dartWeekday = checkNow.weekday; // 1=Mon..7=Sun
    final swiftRaw = dartWeekday == 7 ? 1 : dartWeekday + 1;
    final schedule = currentSchedule(now: checkNow);
    try {
      return schedule.firstWhere((d) => d.day.rawValue == swiftRaw);
    } catch (_) {
      return null;
    }
  }

  /// Whether the branch is currently within its open hours. Falls back to
  /// false on any parse failure.
  bool isOpenNow({DateTime? now}) {
    final checkNow = now ?? DateTime.now();
    final todayEntry = today(now: checkNow);
    if (todayEntry == null || !todayEntry.isOpen) return false;
    final opens = todayEntry.opensAt;
    final closes = todayEntry.closesAt;
    if (opens == null || closes == null) return false;
    final nowMinutes = checkNow.hour * 60 + checkNow.minute;
    final openMins = _parseHHmm(opens);
    final closeMins = _parseHHmm(closes);
    if (openMins == null || closeMins == null) return false;
    if (closeMins >= openMins) {
      return nowMinutes >= openMins && nowMinutes < closeMins;
    } else {
      // Late-night close that wraps past midnight.
      return nowMinutes >= openMins || nowMinutes < closeMins;
    }
  }

  static int? _parseHHmm(String s) {
    final parts = s.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return h * 60 + m;
  }

  factory BranchHours.fromJson(Map<String, dynamic> json) => BranchHours(
    id: json['id'] as String,
    branchId: json['branchID'] as String,
    regular: ((json['regular'] as List?) ?? [])
        .map((e) => DayHours.fromJson(e as Map<String, dynamic>))
        .toList(),
    ramadan: json['ramadan'] == null
        ? null
        : (json['ramadan'] as List)
              .map((e) => DayHours.fromJson(e as Map<String, dynamic>))
              .toList(),
    ramadanStart: json['ramadanStart'] == null
        ? null
        : DateTime.parse(json['ramadanStart'] as String),
    ramadanEnd: json['ramadanEnd'] == null
        ? null
        : DateTime.parse(json['ramadanEnd'] as String),
    holidayClosures: ((json['holidayClosures'] as List?) ?? [])
        .map((e) => DateTime.parse(e as String))
        .toList(),
    termBreaks: ((json['termBreaks'] as List?) ?? [])
        .map((e) => DateInterval.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'branchID': branchId,
    'regular': regular.map((d) => d.toJson()).toList(),
    'ramadan': ramadan?.map((d) => d.toJson()).toList(),
    'ramadanStart': ramadanStart?.toIso8601String(),
    'ramadanEnd': ramadanEnd?.toIso8601String(),
    'holidayClosures': holidayClosures.map((d) => d.toIso8601String()).toList(),
    'termBreaks': termBreaks.map((t) => t.toJson()).toList(),
  };
}
