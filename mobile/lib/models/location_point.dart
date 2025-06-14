class LocationPoint {
  final int id;
  final int orderId;
  final DateTime createdAt;
  final double latitude;
  final double longitude;

  LocationPoint({
    required this.id,
    required this.orderId,
    required this.createdAt,
    required this.latitude,
    required this.longitude,
  });

  factory LocationPoint.fromJson(Map<String, dynamic> json) {
    return LocationPoint(
      id: json['id'],
      orderId: json['order_id'],
      createdAt: DateTime.parse(json['created_at']),
      latitude: json['latitude'],
      longitude: json['longitude'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'created_at': createdAt.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory LocationPoint.fromMap(Map<String, dynamic> map) => LocationPoint.fromJson(map);
  Map<String, dynamic> toMap() => toJson();
}
