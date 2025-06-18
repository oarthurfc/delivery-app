import 'package:delivery/models/order.dart';
import 'package:delivery/services/api/ApiService.dart';

class DriverTrackingRepository {
  final ApiService _apiService = ApiService();

  // Buscar resumo do motorista (pedidos ativos e localizações)
  Future<Map<String, dynamic>> getDriverSummary(int driverId) async {
    try {
      print('DriverTrackingRepository: Buscando resumo do motorista $driverId...');
      final response = await _apiService.getDriverSummary(driverId);
      print('DriverTrackingRepository: Resumo recebido: $response');
      return response;
    } catch (e) {
      print('DriverTrackingRepository: Erro ao buscar resumo do motorista: $e');
      throw Exception('Erro ao buscar resumo do motorista: $e');
    }
  }

  // Atualizar localização do motorista
  Future<void> updateLocation({
    required int driverId,
    required int orderId,
    required double latitude,
    required double longitude,
    double? accuracy,
    double? speed,
    double? heading,
  }) async {
    try {
      print('DriverTrackingRepository: Atualizando localização do motorista $driverId...');
      
      final locationData = {
        'driverId': driverId,
        'orderId': orderId,
        'latitude': latitude,
        'longitude': longitude,
        if (accuracy != null) 'accuracy': accuracy,
        if (speed != null) 'speed': speed,
        if (heading != null) 'heading': heading,
      };
      
      print('DriverTrackingRepository: Dados de localização: $locationData');
      await _apiService.updateLocation(locationData);
      print('DriverTrackingRepository: Localização atualizada com sucesso');
    } catch (e) {
      print('DriverTrackingRepository: Erro ao atualizar localização: $e');
      throw Exception('Erro ao atualizar localização: $e');
    }
  }

  // Buscar localização atual de um pedido
  Future<Map<String, dynamic>> getCurrentOrderLocation(int orderId) async {
    try {
      print('DriverTrackingRepository: Buscando localização atual do pedido $orderId...');
      final response = await _apiService.getCurrentOrderLocation(orderId);
      print('DriverTrackingRepository: Localização recebida: $response');
      return response;
    } catch (e) {
      print('DriverTrackingRepository: Erro ao buscar localização do pedido: $e');
      throw Exception('Erro ao buscar localização do pedido: $e');
    }
  }

  // Buscar histórico de localizações de um pedido
  Future<Map<String, dynamic>> getOrderLocationHistory(
    int orderId, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      print('DriverTrackingRepository: Buscando histórico de localização do pedido $orderId...');
      final response = await _apiService.getOrderLocationHistory(
        orderId,
        limit: limit,
        offset: offset,
      );
      
      print('DriverTrackingRepository: Histórico recebido: ${response["locationHistory"]?.length ?? 0} pontos');
      return response;
    } catch (e) {
      print('DriverTrackingRepository: Erro ao buscar histórico de localização: $e');
      throw Exception('Erro ao buscar histórico de localização: $e');
    }
  }

  // Converter resposta do histórico para objeto Dart (opcional)
  List<LocationPoint> _locationHistoryFromResponse(List<dynamic> response) {
    return response.map((point) => LocationPoint.fromJson(point)).toList();
  }
}

// Classe para representar um ponto de localização
class LocationPoint {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? speed;
  final double? heading;
  final DateTime timestamp;

  LocationPoint({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.speed,
    this.heading,
    required this.timestamp,
  });

  factory LocationPoint.fromJson(Map<String, dynamic> json) {
    return LocationPoint(
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      accuracy: json['accuracy']?.toDouble(),
      speed: json['speed']?.toDouble(),
      heading: json['heading']?.toDouble(),
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      if (accuracy != null) 'accuracy': accuracy,
      if (speed != null) 'speed': speed,
      if (heading != null) 'heading': heading,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'LocationPoint(lat: $latitude, lng: $longitude, speed: $speed)';
  }
}
