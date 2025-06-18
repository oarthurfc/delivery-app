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

  // Para compatibilidade com o backend (JSON)
  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      customerId: json['customerId'],
      driverId: json['driverId'],
      status: OrderStatus.values.firstWhere(
        (e) => e.name == json['status'],
        // orElse: () => OrderStatus.PENDING,
      ),
      originAddress: Address.fromJson(json['originAddress']),
      destinationAddress: Address.fromJson(json['destinationAddress']),
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'customerId': customerId,
    'driverId': driverId,
    'status': status.name,
    'originAddress': originAddress.toJson(),
    'destinationAddress': destinationAddress.toJson(),
    'description': description,
    'imageUrl': imageUrl,
  };

  // Para compatibilidade com código existente
  factory Order.fromMap(Map<String, dynamic> map) => Order.fromJson(map);
  Map<String, dynamic> toMap() => toJson();
}