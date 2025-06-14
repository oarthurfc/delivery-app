class NotificationPreference {
  final int id;
  final int userId;
  final bool enabled;

  NotificationPreference({
    required this.id,
    required this.userId,
    required this.enabled,
  });

  factory NotificationPreference.fromJson(Map<String, dynamic> json) {
    return NotificationPreference(
      id: json['id'],
      userId: json['user_id'],
      enabled: json['enabled'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'enabled': enabled,
    };
  }

  factory NotificationPreference.fromMap(Map<String, dynamic> map) => NotificationPreference.fromJson(map);
  Map<String, dynamic> toMap() => toJson();
}
