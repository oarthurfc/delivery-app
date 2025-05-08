class NotificationPreference {
  final int userId;
  final bool enabled;

  NotificationPreference({
    required this.userId,
    required this.enabled,
  });

  factory NotificationPreference.fromJson(Map<String, dynamic> json) {
    return NotificationPreference(
      userId: json['user_id'],
      enabled: json['enabled'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'enabled': enabled,
    };
  }

  factory NotificationPreference.fromMap(Map<String, dynamic> map) => fromJson(map);
  Map<String, dynamic> toMap() => toJson();
}
