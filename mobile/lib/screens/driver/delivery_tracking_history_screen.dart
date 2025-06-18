import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/order.dart';
import '../../services/api/repos/DriverTrackingRepository.dart';

class DeliveryTrackingHistoryScreen extends StatefulWidget {
  final Order order;

  const DeliveryTrackingHistoryScreen({super.key, required this.order});

  @override
  State<DeliveryTrackingHistoryScreen> createState() => _DeliveryTrackingHistoryScreenState();
}

class _DeliveryTrackingHistoryScreenState extends State<DeliveryTrackingHistoryScreen> {
  final DriverTrackingRepository _trackingRepository = DriverTrackingRepository();
  bool _isLoading = true;
  String? _errorMessage;
  List<LatLng> _trackingPoints = [];
  double _totalDistance = 0.0;

  @override
  void initState() {
    super.initState();
    _loadTrackingHistory();
  }

  Future<void> _loadTrackingHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _trackingRepository.getOrderLocationHistory(widget.order.id);
      
      // Processar os pontos de localização
      final List<dynamic> locationHistory = response['locationHistory'] ?? [];
      final List<LatLng> points = locationHistory.map((point) {
        return LatLng(
          point['latitude']?.toDouble() ?? 0.0,
          point['longitude']?.toDouble() ?? 0.0,
        );
      }).toList();
      
      setState(() {
        _trackingPoints = points;
        _totalDistance = response['totalDistance']?.toDouble() ?? 0.0;
        _isLoading = false;
      });
      
      print('Carregados ${points.length} pontos de rastreamento');
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar histórico de rastreamento: $e';
        _isLoading = false;
      });
      print('Erro ao carregar histórico de rastreamento: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Rota'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTrackingHistory,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadTrackingHistory,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Informações da rota
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.blue.shade50,
                      child: Row(
                        children: [
                          const Icon(Icons.route, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Entrega #${widget.order.id}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  '${_trackingPoints.length} pontos registrados',
                                  style: const TextStyle(
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Distância Total',
                                style: TextStyle(
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                '${_totalDistance.toStringAsFixed(1)} km',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Mapa com a rota
                    Expanded(
                      child: _trackingPoints.isEmpty
                          ? const Center(
                              child: Text(
                                'Nenhum ponto de rastreamento disponível.',
                                style: TextStyle(fontSize: 16),
                              ),
                            )
                          : FlutterMap(
                              options: MapOptions(
                                center: _getMapCenter(),
                                zoom: 14.0,
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.example.app',
                                ),
                                PolylineLayer(
                                  polylines: [
                                    Polyline(
                                      points: _trackingPoints,
                                      strokeWidth: 4.0,
                                      color: Colors.blue,
                                    ),
                                  ],
                                ),
                                MarkerLayer(
                                  markers: _buildMarkers(),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
    );
  }

  LatLng _getMapCenter() {
    if (_trackingPoints.isEmpty) {
      // Se não houver pontos, centraliza nas coordenadas da origem
      return LatLng(
        widget.order.originAddress.latitude,
        widget.order.originAddress.longitude,
      );
    } else if (_trackingPoints.length == 1) {
      // Se houver apenas um ponto, centraliza nele
      return _trackingPoints.first;
    } else {
      // Centraliza entre os pontos para mostrar toda a rota
      double minLat = _trackingPoints.map((p) => p.latitude).reduce((a, b) => a < b ? a : b);
      double maxLat = _trackingPoints.map((p) => p.latitude).reduce((a, b) => a > b ? a : b);
      double minLng = _trackingPoints.map((p) => p.longitude).reduce((a, b) => a < b ? a : b);
      double maxLng = _trackingPoints.map((p) => p.longitude).reduce((a, b) => a > b ? a : b);
      
      return LatLng(
        (minLat + maxLat) / 2,
        (minLng + maxLng) / 2,
      );
    }
  }

  List<Marker> _buildMarkers() {
    List<Marker> markers = [];
    
    // Adiciona marcador de origem
    markers.add(
      Marker(
        point: LatLng(
          widget.order.originAddress.latitude,
          widget.order.originAddress.longitude,
        ),
        child: const Icon(
          Icons.location_on,
          color: Colors.blue,
          size: 30,
        ),
      ),
    );
    
    // Adiciona marcador de destino
    markers.add(
      Marker(
        point: LatLng(
          widget.order.destinationAddress.latitude,
          widget.order.destinationAddress.longitude,
        ),
        child: const Icon(
          Icons.flag,
          color: Colors.red,
          size: 30,
        ),
      ),
    );
    
    // Se houver pontos de rastreamento, adiciona marcador para o último ponto
    if (_trackingPoints.isNotEmpty) {
      markers.add(
        Marker(
          point: _trackingPoints.last,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(
              Icons.local_shipping,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      );
    }
    
    return markers;
  }
}
