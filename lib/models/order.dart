enum OrderStatus { PENDING, ACCEPTED, ON_COURSE, DELIVERIED }

class Order {
  final int id;
  final int customerId;
  final int? driverId;
  final OrderStatus status;
  final String address;
  final String description;
  final String imageUrl;

  Order({
    required this.id,
    required this.customerId,
    this.driverId,
    required this.status,
    required this.address,
    required this.description,
    required this.imageUrl,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      customerId: json['customer_id'],
      driverId: json['driver_id'],
      status: OrderStatus.values.firstWhere((e) => e.name == json['status']),
      address: json['address'],
      description: json['description'],
      imageUrl: json['image_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'driver_id': driverId,
      'status': status.name,
      'address': address,
      'description': description,
      'image_url': imageUrl,
    };
  }

  factory Order.fromMap(Map<String, dynamic> map) => fromJson(map);
  Map<String, dynamic> toMap() => toJson();
}
