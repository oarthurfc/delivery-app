import 'dart:async';
import 'dart:io';
// import 'package:delivery/database/repository/OrderRepository2.dart';
import 'package:delivery/models/address.dart';
import 'package:delivery/models/order.dart';
import 'package:delivery/screens/driver/driver_end_delivey.dart';
import 'package:delivery/services/api/ApiService.dart';
import 'package:delivery/services/api/repos/OrderRepository2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class DriverDeliveryDetailsScreen extends StatefulWidget {
  final Order order;

  const DriverDeliveryDetailsScreen({super.key, required this.order});

  @override
  State<DriverDeliveryDetailsScreen> createState() =>
      _DriverDeliveryDetailsScreenState();
}

class _DriverDeliveryDetailsScreenState
    extends State<DriverDeliveryDetailsScreen> {
  bool _isImageExpanded = false;
  LatLng? _currentPosition;
  bool _isLoadingLocation = true;
  final MapController _mapController = MapController();

  // Serviços
  final OrderRepository2 _orderRepository = OrderRepository2();
  final ApiService _apiService = ApiService();

  // Timer para envio periódico da localização
  Timer? _locationTimer;

  // Estado de início de viagem
  bool _isOnCourse = false;
  bool _isSendingLocation = false;
  DateTime? _lastLocationSent;
  String _locationStatus = 'GPS desativado';

  // ID do motorista
  int? _driverId;

  @override
  void initState() {
    super.initState();
    _loadDriverId();
    _getCurrentLocation();
    _checkOrderStatus();
  }

  Future<void> _loadDriverId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _driverId = prefs.getInt('current_user_id');
      print('DriverDelivery: ID do motorista: $_driverId');
    } catch (e) {
      print('DriverDelivery: Erro ao carregar ID do motorista: $e');
    }
  }

  void _checkOrderStatus() {
    setState(() {
      _isOnCourse = widget.order.status == OrderStatus.ON_COURSE;
    });

    // Se já estiver em curso, inicia o envio de localização
    if (_isOnCourse) {
      print(
        'DriverDelivery: Pedido em transporte, iniciando envio de localização...',
      );
      _startLocationTracking();
    } else {
      print(
        'DriverDelivery: Pedido não está em transporte (${widget.order.status})',
      );
      setState(() {
        _locationStatus = _getLocationStatusMessage(widget.order.status);
      });
    }
  }

  String _getLocationStatusMessage(OrderStatus status) {
    switch (status) {
      case OrderStatus.PENDING:
        return 'Aguardando aceitação do pedido';
      case OrderStatus.ACCEPTED:
        return 'Pronto para iniciar entrega';
      case OrderStatus.ON_COURSE:
        return 'Enviando localização...';
      case OrderStatus.DELIVERIED:
        return 'Entrega finalizada';
      default:
        return 'Status desconhecido';
    }
  }

  // Função para solicitar e verificar permissões de localização
  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Verifica se o serviço de localização está habilitado
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Os serviços de localização estão desativados. Por favor, ative-os.',
          ),
        ),
      );
      return false;
    }

    // Verifica as permissões de localização
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permissões de localização negadas')),
        );
        return false;
      }
    }

    // Se a permissão for permanentemente negada
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Permissões de localização permanentemente negadas. Por favor, habilite-as nas configurações.',
          ),
        ),
      );
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
        _locationStatus = 'Permissão de localização negada';
      });
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
        _locationStatus = 'GPS ativado';
      });

      // Centralize o mapa na posição atual, se disponível
      if (_currentPosition != null) {
        _mapController.move(_currentPosition!, 15.0);
      }
    } on PlatformException catch (e) {
      debugPrint('Erro ao obter localização: ${e.message}');
      setState(() {
        _isLoadingLocation = false;
        _locationStatus = 'Erro ao obter localização';
      });
    }
  }

  // Iniciar a viagem e o envio automático de localização
  Future<void> _startDelivery() async {
    if (_driverId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro: ID do motorista não encontrado')),
      );
      return;
    }

    try {
      // Atualizar o status do pedido para EM CURSO
      final order = widget.order;
      order.status = OrderStatus.ON_COURSE;
      await _orderRepository.update(order);

      setState(() {
        _isOnCourse = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Entrega iniciada! Sua localização será enviada automaticamente.',
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Iniciar o envio automático de localização
      _startLocationTracking();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao iniciar entrega: $e')));
    }
  }

  // Iniciar o envio periódico de localização para o servidor
  void _startLocationTracking() {
    print('DriverDelivery: Iniciando envio automático de localização');

    // Cancela o timer existente, se houver
    _stopLocationTracking();

    // Configura um novo timer para enviar localização a cada 1 minuto
    _locationTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      print('DriverDelivery: Timer executado - enviando localização');
      _sendLocationToServer();
    });

    // Envia a localização imediatamente
    _sendLocationToServer();

    setState(() {
      _isSendingLocation = true;
      _locationStatus = 'Enviando localização para o servidor...';
    });
  }

  // Parar o envio de localização
  void _stopLocationTracking() {
    _locationTimer?.cancel();
    _locationTimer = null;

    // Não chama setState no dispose para evitar erro
    _isSendingLocation = false;
    _locationStatus = 'Envio de localização parado';
  }

  // Enviar localização atual para o servidor
  Future<void> _sendLocationToServer() async {
    if (_driverId == null) {
      print('DriverDelivery: ID do motorista não encontrado');
      return;
    }

    try {
      // Obter localização atual
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Atualizar posição no mapa
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });

      // Preparar dados para envio
      final locationData = {
        'orderId': widget.order.id,
        'driverId': _driverId,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'speed': position.speed,
        'heading': position.heading,
      };

      print('DriverDelivery: Enviando localização: $locationData');

      // Enviar para o servidor
      await _apiService.updateLocation(locationData);

      // Atualizar status
      setState(() {
        _lastLocationSent = DateTime.now();
        _locationStatus =
            'Localização enviada: ${_formatTime(_lastLocationSent!)}';
      });

      print('DriverDelivery: Localização enviada com sucesso');

      // Centralizar mapa na nova posição
      if (_currentPosition != null) {
        _mapController.move(_currentPosition!, 15.0);
      }
    } catch (e) {
      print('DriverDelivery: Erro ao enviar localização: $e');
      setState(() {
        _locationStatus = 'Erro ao enviar localização: $e';
      });
    }
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // Finalizar a entrega
  void _finishDelivery() {
    // Parar o envio de localização
    _stopLocationTracking();

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
    // Para o timer antes de fazer dispose
    _locationTimer?.cancel();
    _locationTimer = null;
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
        actions: [
          if (_isOnCourse)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _sendLocationToServer,
              tooltip: 'Enviar localização agora',
            ),
        ],
      ),
      body:
          _isLoadingLocation
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Obtendo localização GPS...'),
                  ],
                ),
              )
              : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mapa com a localização atual e destino
                    SizedBox(
                      height: 300,
                      child: Stack(
                        children: [
                          FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              center:
                                  _currentPosition ??
                                  LatLng(
                                    (order.originAddress.latitude +
                                            order.destinationAddress.latitude) /
                                        2,
                                    (order.originAddress.longitude +
                                            order
                                                .destinationAddress
                                                .longitude) /
                                        2,
                                  ),
                              zoom: 13,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName:
                                    'br.com.delivery.app/1.0 (contact: renatomatosapbusiness@gmail.com)',
                              ),
                              MarkerLayer(
                                markers: [
                                  // Marcador da posição atual do motorista
                                  if (_currentPosition != null)
                                    Marker(
                                      point: _currentPosition!,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color:
                                              _isSendingLocation
                                                  ? Colors.green
                                                  : Colors.blue,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.directions_car,
                                          color: Colors.white,
                                          size: 30,
                                        ),
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
                               RichAttributionWidget(
                      attributions: [
                        TextSourceAttribution(
                        '© OpenStreetMap contributors',
                        onTap: () async {
                          final uri = Uri.parse('https://www.openstreetmap.org/copyright');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                        ),
                      ],
                      ),
                            ],
                          ),

                          // Status do GPS/Localização
                          if (_isOnCourse)
                            Positioned(
                              top: 16,
                              left: 16,
                              right: 16,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.95),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color:
                                            _isSendingLocation
                                                ? Colors.green
                                                : Colors.orange,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _locationStatus,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
                              const Icon(
                                Icons.local_shipping,
                                size: 28,
                                color: Colors.blue,
                              ),
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

                          // Info do envio automático de localização
                          if (_isOnCourse) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.green.shade200,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.gps_fixed,
                                        color: Colors.green.shade700,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Rastreamento Ativo',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Sua localização está sendo enviada automaticamente a cada 1 minuto para o cliente acompanhar a entrega.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green.shade600,
                                    ),
                                  ),
                                  if (_lastLocationSent != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Último envio: ${_formatTime(_lastLocationSent!)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.green.shade500,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

                          // Descrição do pedido
                          Text(
                            'Descrição:',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(order.description, style: textTheme.bodyLarge),
                          const SizedBox(height: 16),

                          // Endereço de origem
                          Text(
                            'Endereço de Coleta:',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
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
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
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
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isImageExpanded = !_isImageExpanded;
                                    });
                                  },
                                  child:
                                      order.imageUrl.startsWith('http')
                                          ? Image.network(
                                            order.imageUrl,
                                            width: double.infinity,
                                            height:
                                                _isImageExpanded ? null : 200,
                                            fit:
                                                _isImageExpanded
                                                    ? BoxFit.contain
                                                    : BoxFit.cover,
                                          )
                                          : Image.file(
                                            File(order.imageUrl),
                                            width: double.infinity,
                                            height:
                                                _isImageExpanded ? null : 200,
                                            fit:
                                                _isImageExpanded
                                                    ? BoxFit.contain
                                                    : BoxFit.cover,
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
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
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
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
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
