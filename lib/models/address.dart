class Address {
  final int id;
  final String street;
  final String number;
  final String neighborhood;
  final String city;
  final double latitude;
  final double longitude;

  Address({
    required this.id,
    required this.street,
    required this.number,
    required this.neighborhood,
    required this.city,
    required this.latitude,
    required this.longitude,
  });

  factory Address.fromJson(Map<String, dynamic> json) => Address(
    id: json['id'],
    street: json['street'],
    number: json['number'],
    neighborhood: json['neighborhood'],
    city: json['city'],
    latitude: json['latitude'],
    longitude: json['longitude'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'street': street,
    'number': number,
    'neighborhood': neighborhood,
    'city': city,
    'latitude': latitude,
    'longitude': longitude,
  };

  factory Address.fromMap(Map<String, dynamic> map) => Address.fromJson(map);
  Map<String, dynamic> toMap() => toJson();
}
