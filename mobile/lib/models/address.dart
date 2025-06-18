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

  // Para compatibilidade com o backend (JSON) - COM TRATAMENTO DE NULL
  factory Address.fromJson(Map<String, dynamic> json) {
    try {
      return Address(
        id: _safeGetInt(json, 'id', defaultValue: 0),
        street: _safeGetString(json, 'street'),
        number: _safeGetString(json, 'number'),
        neighborhood: _safeGetString(json, 'neighborhood'),
        city: _safeGetString(json, 'city'),
        latitude: _safeGetDouble(json, 'latitude'),
        longitude: _safeGetDouble(json, 'longitude'),
      );
    } catch (e) {
      print('Address.fromJson: Erro ao converter JSON: $e');
      print('Address.fromJson: JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'street': street,
    'number': number,
    'neighborhood': neighborhood,
    'city': city,
    'latitude': latitude,
    'longitude': longitude,
  };

  // Para compatibilidade com código existente
  factory Address.fromMap(Map<String, dynamic> map) => Address.fromJson(map);
  Map<String, dynamic> toMap() => toJson();

  // Método para obter endereço completo como string
  String get fullAddress {
    final parts = <String>[];
    if (street.isNotEmpty) parts.add(street);
    if (number.isNotEmpty) parts.add(number);
    if (neighborhood.isNotEmpty) parts.add(neighborhood);
    if (city.isNotEmpty) parts.add(city);
    return parts.join(', ');
  }

  @override
  String toString() => fullAddress;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Address &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  // ===== MÉTODOS AUXILIARES PARA CONVERSÃO SEGURA =====
  
  static int _safeGetInt(Map<String, dynamic> map, String key, {int defaultValue = 0}) {
    final value = map[key];
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String && value.isNotEmpty) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }
    print('Address: Valor inválido para $key: $value, usando padrão: $defaultValue');
    return defaultValue;
  }
  
  static String _safeGetString(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value == null) return '';
    return value.toString().trim();
  }
  
  static double _safeGetDouble(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value == null) {
      print('Address: Campo obrigatório $key é null');
      return 0.0;
    }
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String && value.isNotEmpty) {
      final parsed = double.tryParse(value);
      if (parsed != null) return parsed;
    }
    print('Address: Erro ao converter $key para double: $value');
    return 0.0;
  }
}