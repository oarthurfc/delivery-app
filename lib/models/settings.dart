class Settings {
  final int userId;
  final bool isDarkTheme;
  final bool showCompletedOrders;

  Settings({
    required this.userId,
    required this.isDarkTheme,
    required this.showCompletedOrders,
  });

  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
      userId: json['user_id'],
      isDarkTheme: json['is_dark_theme'],
      showCompletedOrders: json['show_completed_orders'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'is_dark_theme': isDarkTheme,
      'show_completed_orders': showCompletedOrders,
    };
  }

  factory Settings.fromMap(Map<String, dynamic> map) => fromJson(map);
  Map<String, dynamic> toMap() => toJson();
}
