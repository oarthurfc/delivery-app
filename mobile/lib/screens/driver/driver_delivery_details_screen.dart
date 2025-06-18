import 'dart:async';
import 'dart:io';
import 'package:delivery/database/repository/OrderRepository.dart';
import 'package:delivery/database/repository/location_point_repository.dart';
import 'package:delivery/models/address.dart';
import 'package:delivery/models/location_point.dart';
import 'package:delivery/models/order.dart';
import 'package:delivery/screens/driver/driver_end_delivey.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';

class DriverDeliveryDetailsScreen extends StatefulWidget {
  final Order order;

  const DriverDeliveryDetailsScreen({super.key, required this.order});

  @override
  State<DriverDeliveryDetailsScreen> createState() => _DriverDeliveryDetailsScreenState();
}

class _DriverDeliveryDetailsScreenState extends State<DriverDeliveryDetailsScreen> {
  bool _isImageExpanded = false;
  LatLng? _currentPosition;
  bool _isLoadingLocation = true;
  final MapController _mapController = MapController();
  
  // Repositórios
  final OrderRepository _orderRepository = OrderRepository();
  final LocationPointRepository _locationPointRepository = LocationPointRepository();
  
  // Timer para atualização periódica da localização
  Timer? _locationTimer;
  
  // Estado de início de viagem
  bool _isOnCourse = false;
  
  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _checkOrderStatus();
  }
  
  void _checkOrderStatus() {
    setState(() {
      _isOnCourse = widget.order.status == OrderStatus.ON_COURSE;
    });
    
    // Se já estiver em curso, inicia o monitoramento de localização
    if (_isOnCourse) {
      _startLocationTracking();
    }
  }

  // Função para solicitar e verificar permissões de localização
  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Verifica se o serviço de localização está habilitado
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Os serviços de localização estão desativados. Por favor, ative-os.')));
      return false;
    }

    // Verifica as permissões de localização
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permissões de localização negadas')));
        return false;
      }
    }

    // Se a permissão for permanentemente negada
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Permissões de localização permanentemente negadas. Por favor, habilite-as nas configurações.')));
      return false;
    }

    return true;
  }

  // Função para obter a localização atual
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) {
      setState(() {
        _isLoadingLocation = false;
      });
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });

      // Centralize o mapa na posição atual, se disponível
      if (_currentPosition != null) {
        _mapController.move(_currentPosition!, 15.0);
      }
    } on PlatformException catch (e) {
      debugPrint('Erro ao obter localização: ${e.message}');
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }
  
  // Iniciar a viagem e o monitoramento de localização
  Future<void> _startDelivery() async {
    try {
      // Atualizar o status do pedido para EM CURSO
      final order = widget.order;
      order.status = OrderStatus.ON_COURSE;
      await _orderRepository.update(order);
      
      setState(() {
        _isOnCourse = true;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entrega iniciada! Sua localização será monitorada.')),
      );
      
      // Iniciar o monitoramento de localização
      _startLocationTracking();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao iniciar entrega: $e')),
      );
    }
  }
  
  // Iniciar o monitoramento periódico de localização
  void _startLocationTracking() {
    // Cancela o timer existente, se houver
    _locationTimer?.cancel();
    
    // Configura um novo timer para atualizar a localização a cada minuto
    _locationTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _updateLocationPoint();
    });
    
    // Atualiza imediatamente a primeira vez
    _updateLocationPoint();
  }
  
  // Registrar um novo ponto de localização
  Future<void> _updateLocationPoint() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      
      final locationPoint = LocationPoint(
        id: DateTime.now().millisecondsSinceEpoch,
        orderId: widget.order.id,
        createdAt: DateTime.now(),
        latitude: position.latitude,
        longitude: position.longitude,
      );
      
      await _locationPointRepository.save(locationPoint);
      
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });
      
      if (_currentPosition != null) {
        _mapController.move(_currentPosition!, 15.0);
      }
    } catch (e) {
      print('Erro ao atualizar localização: $e');
    }
  }
  
  // Finalizar a entrega
  void _finishDelivery() {
    // Parar o monitoramento de localização
    _locationTimer?.cancel();
    
    // Navegar para a tela de finalização
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DriverEndDeliveryScreen(order: widget.order),
      ),
    ).then((value) {
      // Se retornou da tela de finalização, fechar esta tela
      if (value == true) {
        Navigator.pop(context, true);
      }
    });
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da Entrega'),
        centerTitle: true,
      ),
      body: _isLoadingLocation 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mapa com a localização atual e destino
                SizedBox(
                  height: 300,
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      center: _currentPosition ?? 
                        LatLng(
                          (order.originAddress.latitude + order.destinationAddress.latitude) / 2,
                          (order.originAddress.longitude + order.destinationAddress.longitude) / 2,
                        ),
                      zoom: 13,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.app',
                      ),
                      MarkerLayer(
                        markers: [
                          // Marcador da posição atual do motorista
                          if (_currentPosition != null)
                            Marker(
                              point: _currentPosition!,
                              child: const Icon(
                                Icons.directions_car,
                                color: Colors.green,
                                size: 40,
                              ),
                            ),
                          // Marcador do ponto de origem
                          Marker(
                            point: LatLng(
                              order.originAddress.latitude,
                              order.originAddress.longitude,
                            ),
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.blue,
                              size: 40,
                            ),
                          ),
                          // Marcador do ponto de destino
                          Marker(
                            point: LatLng(
                              order.destinationAddress.latitude,
                              order.destinationAddress.longitude,
                            ),
                            child: const Icon(
                              Icons.flag,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                      // Linha entre origem e destino
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: [
                              LatLng(
                                order.originAddress.latitude,
                                order.originAddress.longitude,
                              ),
                              LatLng(
                                order.destinationAddress.latitude,
                                order.destinationAddress.longitude,
                              ),
                            ],
                            strokeWidth: 4,
                            color: Colors.blue.withOpacity(0.7),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Informações do pedido
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.local_shipping, size: 28, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            _getStatusText(order.status),
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(order.status),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Descrição do pedido
                      Text(
                        'Descrição:',
                        style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.description,
                        style: textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 16),
                      
                      // Endereço de origem
                      Text(
                        'Endereço de Coleta:',
                        style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getFormattedAddress(order.originAddress),
                        style: textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 16),
                      
                      // Endereço de destino
                      Text(
                        'Endereço de Entrega:',
                        style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getFormattedAddress(order.destinationAddress),
                        style: textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 16),
                      
                      // Imagem da encomenda
                      if (order.imageUrl.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Imagem da Encomenda:',
                              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isImageExpanded = !_isImageExpanded;
                                });
                              },
                              child: order.imageUrl.startsWith('http')
                                  ? Image.network(
                                      order.imageUrl,
                                      width: double.infinity,
                                      height: _isImageExpanded ? null : 200,
                                      fit: _isImageExpanded ? BoxFit.contain : BoxFit.cover,
                                    )
                                  : Image.file(
                                      File(order.imageUrl),
                                      width: double.infinity,
                                      height: _isImageExpanded ? null : 200,
                                      fit: _isImageExpanded ? BoxFit.contain : BoxFit.cover,
                                    ),
                            ),
                          ],
                        ),
                      
                      const SizedBox(height: 24),
                      
                      // Botões de ação
                      Center(
                        child: Column(
                          children: [
                            if (order.status == OrderStatus.ACCEPTED)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _startDelivery,
                                  icon: const Icon(Icons.play_arrow),
                                  label: const Text('Iniciar Entrega'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                            
                            if (order.status == OrderStatus.ON_COURSE)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _finishDelivery,
                                  icon: const Icon(Icons.check_circle),
                                  label: const Text('Finalizar Entrega'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                            
                            if (order.status == OrderStatus.DELIVERIED)
                              const Text(
                                'Entrega finalizada com sucesso!',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }

  String _getFormattedAddress(Address address) {
    return '${address.street}, ${address.number} - ${address.neighborhood}, ${address.city}';
  }

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.ACCEPTED:
        return 'Aceito - Aguardando Início';
      case OrderStatus.ON_COURSE:
        return 'Em Transporte';
      case OrderStatus.DELIVERIED:
        return 'Entregue';
      case OrderStatus.PENDING:
        return 'Pendente';
    }
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.ACCEPTED:
        return Colors.blue;
      case OrderStatus.ON_COURSE:
        return Colors.orange;
      case OrderStatus.DELIVERIED:
        return Colors.green;
      case OrderStatus.PENDING:
        return Colors.amber;
    }
  }
}