// Port of the REMAINDER of Core/Models/CoreEntities.swift that was not yet
// ported: PreferredLanguage and UserNotificationPreferences.
//
// Role, User, Branch, EntityID are already in their own files.
// Pure Dart — no Flutter imports (logic-layer rule).

/// Mirrors Swift's `PreferredLanguage` enum from CoreEntities.swift.
enum PreferredLanguage {
  system,
  english,
  arabic;

  String get labelKey => 'language.$name';

  static PreferredLanguage fromJson(String raw) => PreferredLanguage.values
      .firstWhere((e) => e.name == raw, orElse: () => PreferredLanguage.system);
}

/// Mirrors Swift's `UserNotificationPreferences` struct from CoreEntities.swift.
class UserNotificationPreferences {
  final bool classReminders;
  final bool announcements;
  final bool weeklyDigest;
  final bool promotionAlerts;

  const UserNotificationPreferences({
    this.classReminders = true,
    this.announcements = true,
    this.weeklyDigest = false,
    this.promotionAlerts = true,
  });

  static const UserNotificationPreferences defaults =
      UserNotificationPreferences();

  factory UserNotificationPreferences.fromJson(Map<String, dynamic> json) =>
      UserNotificationPreferences(
        classReminders: json['classReminders'] as bool? ?? true,
        announcements: json['announcements'] as bool? ?? true,
        weeklyDigest: json['weeklyDigest'] as bool? ?? false,
        promotionAlerts: json['promotionAlerts'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
    'classReminders': classReminders,
    'announcements': announcements,
    'weeklyDigest': weeklyDigest,
    'promotionAlerts': promotionAlerts,
  };
}
