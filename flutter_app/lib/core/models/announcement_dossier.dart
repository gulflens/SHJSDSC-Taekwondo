// Port of Core/Models/AnnouncementDossier.swift.
// Stage 1.9 — supporting types for the Announcements dashboard remodel.
// Pure data — no Flutter imports (logic-layer rule).

import 'entity_id.dart';

/// Lifecycle state of an announcement, surfaced as the status pill and the
/// top filter pills.
enum AnnouncementStatus {
  published,
  scheduled,
  draft,
  archived;

  String get labelKey => 'announcement.status.$name';

  static AnnouncementStatus fromJson(String raw) =>
      AnnouncementStatus.values.firstWhere(
        (e) => e.name == raw,
        orElse: () => AnnouncementStatus.published,
      );
}

/// Editorial category — drives the row's pastel icon tile.
enum AnnouncementCategory {
  general,
  event,
  registration,
  grading,
  tournament,
  policy,
  recognition;

  String get labelKey => 'announcement.category.$name';

  String get systemIcon => switch (this) {
    AnnouncementCategory.general => 'megaphone.fill',
    AnnouncementCategory.event => 'megaphone.fill',
    AnnouncementCategory.registration => 'calendar',
    AnnouncementCategory.grading => 'list.bullet.clipboard.fill',
    AnnouncementCategory.tournament => 'trophy.fill',
    AnnouncementCategory.policy => 'shield.lefthalf.filled',
    AnnouncementCategory.recognition => 'star.fill',
  };

  static AnnouncementCategory fromJson(String raw) =>
      AnnouncementCategory.values.firstWhere(
        (e) => e.name == raw,
        orElse: () => AnnouncementCategory.general,
      );
}

/// A delivery channel an announcement was broadcast on.
enum AnnouncementChannel {
  email,
  inApp,
  sms;

  String get labelKey => 'announcement.channel.$name';

  String get systemIcon => switch (this) {
    AnnouncementChannel.email => 'envelope',
    AnnouncementChannel.inApp => 'bell',
    AnnouncementChannel.sms => 'message',
  };

  static AnnouncementChannel fromJson(String raw) =>
      AnnouncementChannel.values.firstWhere(
        (e) => e.name == raw,
        orElse: () => AnnouncementChannel.inApp,
      );
}

/// Per-channel delivery outcome.
enum DeliveryState {
  sent,
  delivered,
  pending,
  failed;

  String get labelKey => 'announcement.delivery.$name';

  static DeliveryState fromJson(String raw) => DeliveryState.values.firstWhere(
    (e) => e.name == raw,
    orElse: () => DeliveryState.pending,
  );
}

/// One channel's delivery row in the detail panel.
class AnnouncementDelivery {
  final EntityID id;
  final AnnouncementChannel channel;
  final DeliveryState state;

  const AnnouncementDelivery({
    required this.id,
    required this.channel,
    required this.state,
  });

  factory AnnouncementDelivery.create({
    required AnnouncementChannel channel,
    required DeliveryState state,
  }) => AnnouncementDelivery(id: newEntityId(), channel: channel, state: state);

  factory AnnouncementDelivery.fromJson(Map<String, dynamic> json) =>
      AnnouncementDelivery(
        id: json['id'] as String,
        channel: AnnouncementChannel.fromJson(json['channel'] as String),
        state: DeliveryState.fromJson(json['state'] as String),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'channel': channel.name,
    'state': state.name,
  };
}

/// Reach + interaction counters shown in the Engagement section.
class AnnouncementEngagement {
  final int recipients;
  final int opened;
  final int read;
  final int clicks;

  const AnnouncementEngagement({
    this.recipients = 0,
    this.opened = 0,
    this.read = 0,
    this.clicks = 0,
  });

  int _pct(int n) => recipients > 0 ? ((n / recipients) * 100).round() : 0;

  int get openedPct => _pct(opened);
  int get readPct => _pct(read);
  int get clicksPct => _pct(clicks);

  factory AnnouncementEngagement.fromJson(Map<String, dynamic> json) =>
      AnnouncementEngagement(
        recipients: json['recipients'] as int? ?? 0,
        opened: json['opened'] as int? ?? 0,
        read: json['read'] as int? ?? 0,
        clicks: json['clicks'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
    'recipients': recipients,
    'opened': opened,
    'read': read,
    'clicks': clicks,
  };
}

/// A file attached to an announcement.
class AnnouncementAttachment {
  final EntityID id;
  final String name;

  /// Human-readable type + size, e.g. "PDF · 1.2 MB".
  final String detail;

  const AnnouncementAttachment({
    required this.id,
    required this.name,
    required this.detail,
  });

  factory AnnouncementAttachment.create({
    required String name,
    required String detail,
  }) => AnnouncementAttachment(id: newEntityId(), name: name, detail: detail);

  factory AnnouncementAttachment.fromJson(Map<String, dynamic> json) =>
      AnnouncementAttachment(
        id: json['id'] as String,
        name: json['name'] as String,
        detail: json['detail'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'detail': detail};
}
