import 'address.dart';

enum OrderStatus { PENDING, ACCEPTED, ON_COURSE, DELIVERIED }

class Order {
  final int id;
  final int customerId;
   int? driverId;
   OrderStatus status;
  final Address originAddress;
  final Address destinationAddress;
  final String description;
   String imageUrl;

  Order({
    required this.id,
    required this.customerId,
    this.driverId,
    required this.status,
    required this.originAddress,
    required this.destinationAddress,
    required this.description,
    required this.imageUrl,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      customerId: json['customer_id'],
      driverId: json['driver_id'],
      status: OrderStatus.values.firstWhere((e) => e.name == json['status']),
      originAddress: Address.fromJson(json['origin_address']),
      destinationAddress: Address.fromJson(json['destination_address']),
      description: json['description'],
      imageUrl: json['image_url'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'customer_id': customerId,
    'driver_id': driverId,
    'status': status.name,
    'origin_address': originAddress.toJson(),
    'destination_address': destinationAddress.toJson(),
    'description': description,
    'image_url': imageUrl,
  };

  factory Order.fromMap(Map<String, dynamic> map) =>  Order.fromJson(map);
  Map<String, dynamic> toMap() => toJson();
}

