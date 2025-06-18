import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/order.dart';
import '../../services/api/ApiService.dart';

class CustomerDeliveryDetailsScreen extends StatefulWidget {
  final Order order;

  const CustomerDeliveryDetailsScreen({super.key, required this.order});

  @override
  State<CustomerDeliveryDetailsScreen> createState() => _CustomerDeliveryDetailsScreenState();
}

class _CustomerDeliveryDetailsScreenState extends State<CustomerDeliveryDetailsScreen> {
  bool _isImageExpanded = false;
  Timer? _trackingTimer;
  final ApiService _apiService = ApiService(); // Usando ApiService existente
  
  // Estado do rastreamento
  LatLng? _currentDriverLocation;
  bool _isTracking = false;
  DateTime? _lastUpdate;
  String _trackingStatus = 'Verificando rastreamento...';

  @override
  void initState() {
    super.initState();
    _initializeTracking();
  }

  @override
  void dispose() {
    // Para o timer antes de fazer dispose
    _trackingTimer?.cancel();
    _trackingTimer = null;
    super.dispose();
  }

  void _initializeTracking() {
    // Só inicia rastreamento se o pedido estiver em transporte
    if (widget.order.status == OrderStatus.ON_COURSE) {
      print('DeliveryDetails: Pedido em transporte, iniciando rastreamento...');
      _startTracking();
    } else {
      print('DeliveryDetails: Pedido não está em transporte (${widget.order.status})');
      setState(() {
        _trackingStatus = _getStatusMessage(widget.order.status);
      });
    }
  }

  String _getStatusMessage(OrderStatus status) {
    switch (status) {
      case OrderStatus.PENDING:
        return 'Aguardando motorista aceitar o pedido';
      case OrderStatus.ACCEPTED:
        return 'Motorista a caminho para coleta';
      case OrderStatus.ON_COURSE:
        return 'Em transporte - rastreamento ativo';
      case OrderStatus.DELIVERIED:
        return 'Entrega concluída';
      default:
        return 'Status desconhecido';
    }
  }

  void _startTracking() {
    print('DeliveryDetails: Iniciando rastreamento em tempo real');
    setState(() {
      _isTracking = true;
      _trackingStatus = 'Conectando ao rastreamento...';
    });

    // Busca localização imediatamente
    _updateDriverLocation();

    // Configura timer para atualizar a cada 2 minutos (120 segundos)
    _trackingTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      print('DeliveryDetails: Timer de rastreamento executado');
      _updateDriverLocation();
    });
  }

  void _stopTracking() {
    print('DeliveryDetails: Parando rastreamento');
    _trackingTimer?.cancel();
    _trackingTimer = null;
    
    // Não chama setState no dispose para evitar erro
    _isTracking = false;
  }

  Future<void> _updateDriverLocation() async {
  if (!mounted) return;

  try {
    print('DeliveryDetails: ===== INICIANDO ATUALIZAÇÃO DE LOCALIZAÇÃO =====');
    print('DeliveryDetails: ID do pedido: ${widget.order.id}');
    
    // Primeiro verifica se o pedido está sendo rastreado
    print('DeliveryDetails: Verificando se pedido está sendo rastreado...');
    final isBeingTracked = await _apiService.isOrderBeingTracked(widget.order.id);
    print('DeliveryDetails: Pedido está sendo rastreado: $isBeingTracked');
    
    if (!isBeingTracked) {
      print('DeliveryDetails: Pedido NÃO está sendo rastreado');
      setState(() {
        _trackingStatus = 'Motorista ainda não iniciou o rastreamento';
        _currentDriverLocation = null;
      });
      return;
    }

    // Busca a localização atual
    print('DeliveryDetails: Pedido ESTÁ sendo rastreado, buscando localização...');
    final locationData = await _apiService.getCurrentLocation(widget.order.id);
    print('DeliveryDetails: Dados brutos recebidos: $locationData');
    
    // Verificar a estrutura completa dos dados
    if (locationData == null) {
      print('DeliveryDetails: ERRO - locationData é null');
      setState(() {
        _trackingStatus = 'Erro: nenhum dado retornado';
        _currentDriverLocation = null;
      });
      return;
    }
    
    print('DeliveryDetails: Verificando estrutura dos dados...');
    print('DeliveryDetails: locationData.keys: ${locationData.keys}');
    
    if (!locationData.containsKey('data')) {
      print('DeliveryDetails: ERRO - Chave "data" não encontrada');
      setState(() {
        _trackingStatus = 'Erro: estrutura de dados inválida';
        _currentDriverLocation = null;
      });
      return;
    }
    
    final dataSection = locationData['data'];
    print('DeliveryDetails: Seção "data": $dataSection');
    
    if (dataSection == null) {
      print('DeliveryDetails: ERRO - Seção "data" é null');
      setState(() {
        _trackingStatus = 'Erro: seção data vazia';
        _currentDriverLocation = null;
      });
      return;
    }
    
    if (!dataSection.containsKey('currentLocation')) {
      print('DeliveryDetails: ERRO - Chave "currentLocation" não encontrada');
      print('DeliveryDetails: Chaves disponíveis em data: ${dataSection.keys}');
      setState(() {
        _trackingStatus = 'Erro: localização atual não encontrada';
        _currentDriverLocation = null;
      });
      return;
    }
    
    final location = dataSection['currentLocation'];
    print('DeliveryDetails: Dados de localização: $location');
    
    if (location == null) {
      print('DeliveryDetails: ERRO - currentLocation é null');
      setState(() {
        _trackingStatus = 'Nenhuma localização recente encontrada';
        _currentDriverLocation = null;
      });
      return;
    }
    
    // Extrair coordenadas
    final lat = location['latitude'];
    final lng = location['longitude'];
    print('DeliveryDetails: Latitude bruta: $lat (${lat.runtimeType})');
    print('DeliveryDetails: Longitude bruta: $lng (${lng.runtimeType})');
    
    if (lat == null || lng == null) {
      print('DeliveryDetails: ERRO - Coordenadas são null');
      setState(() {
        _trackingStatus = 'Erro: coordenadas inválidas';
      });
      return;
    }
    
    final latDouble = lat is double ? lat : double.tryParse(lat.toString());
    final lngDouble = lng is double ? lng : double.tryParse(lng.toString());
    
    print('DeliveryDetails: Latitude convertida: $latDouble');
    print('DeliveryDetails: Longitude convertida: $lngDouble');
    
    if (latDouble == null || lngDouble == null) {
      print('DeliveryDetails: ERRO - Não foi possível converter coordenadas');
      setState(() {
        _trackingStatus = 'Erro: conversão de coordenadas falhou';
      });
      return;
    }
    
    // Sucesso! Atualizar localização
    print('DeliveryDetails: SUCESSO - Atualizando localização no mapa');
    setState(() {
      _currentDriverLocation = LatLng(latDouble, lngDouble);
      _lastUpdate = DateTime.now();
      _trackingStatus = 'Motorista localizado - última atualização: ${_formatTime(_lastUpdate!)}';
    });
    print('DeliveryDetails: Localização atualizada com sucesso: $latDouble, $lngDouble');
    
  } catch (e, stackTrace) {
    print('DeliveryDetails: ERRO EXCEPTION ao atualizar localização: $e');
    print('DeliveryDetails: Stack trace: $stackTrace');
    setState(() {
      _trackingStatus = 'Erro ao buscar localização do motorista: $e';
    });
  }
  
  print('DeliveryDetails: ===== FIM DA ATUALIZAÇÃO DE LOCALIZAÇÃO =====');
}


  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String getFormattedAddress(address) {
    return '${address.street}, ${address.number} - ${address.neighborhood}, ${address.city}';
  }

  String getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.DELIVERIED:
        return 'Entregue';
      case OrderStatus.PENDING:
        return 'Pendente';
      case OrderStatus.ACCEPTED:
        return 'Aceito';
      case OrderStatus.ON_COURSE:
        return 'Em transporte';
    }
  }

  Color getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.DELIVERIED:
        return Colors.green;
      case OrderStatus.PENDING:
        return Colors.amber;
      case OrderStatus.ACCEPTED:
        return Colors.blue;
      case OrderStatus.ON_COURSE:
        return Colors.orange;
    }
  }

  List<Marker> _buildMarkers() {
    List<Marker> markers = [
      // Marcador de origem
      Marker(
        point: LatLng(
          widget.order.originAddress.latitude,
          widget.order.originAddress.longitude,
        ),
        child: const Icon(
          Icons.location_on,
          color: Colors.blue,
          size: 40,
        ),
      ),
      // Marcador de destino
      Marker(
        point: LatLng(
          widget.order.destinationAddress.latitude,
          widget.order.destinationAddress.longitude,
        ),
        child: const Icon(
          Icons.flag,
          color: Colors.red,
          size: 40,
        ),
      ),
    ];

    // Adiciona marcador do motorista se disponível
    if (_currentDriverLocation != null) {
      markers.add(
        Marker(
          point: _currentDriverLocation!,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(
              Icons.local_shipping,
              color: Colors.white,
              size: 30,
            ),
          ),
        ),
      );
    }

    return markers;
  }

  List<Polyline> _buildPolylines() {
    List<Polyline> polylines = [
      // Linha da rota original (origem → destino)
      Polyline(
        points: [
          LatLng(
            widget.order.originAddress.latitude,
            widget.order.originAddress.longitude,
          ),
          LatLng(
            widget.order.destinationAddress.latitude,
            widget.order.destinationAddress.longitude,
          ),
        ],
        strokeWidth: 2,
        color: Colors.blue.withOpacity(0.5),
        isDotted: true,
      ),
    ];

    // Adiciona linha até a posição atual do motorista
    if (_currentDriverLocation != null) {
      polylines.add(
        Polyline(
          points: [
            _currentDriverLocation!,
            LatLng(
              widget.order.destinationAddress.latitude,
              widget.order.destinationAddress.longitude,
            ),
          ],
          strokeWidth: 4,
          color: Colors.green,
        ),
      );
    }

    return polylines;
  }

  LatLng _getMapCenter() {
    if (_currentDriverLocation != null) {
      // Centraliza entre motorista e destino
      return LatLng(
        (_currentDriverLocation!.latitude + widget.order.destinationAddress.latitude) / 2,
        (_currentDriverLocation!.longitude + widget.order.destinationAddress.longitude) / 2,
      );
    } else {
      // Centraliza entre origem e destino
      return LatLng(
        (widget.order.originAddress.latitude + widget.order.destinationAddress.latitude) / 2,
        (widget.order.originAddress.longitude + widget.order.destinationAddress.longitude) / 2,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final textTheme = Theme.of(context).textTheme;
    final statusText = getStatusText(order.status);
    final statusColor = getStatusColor(order.status);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da Entrega'),
        centerTitle: true,
        actions: [
          if (_isTracking)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _updateDriverLocation,
              tooltip: 'Atualizar localização',
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mapa com rastreamento
            SizedBox(
              height: 300,
              child: Stack(
                children: [
                  FlutterMap(
                    options: MapOptions(
                      center: _getMapCenter(),
                      zoom: _currentDriverLocation != null ? 14 : 13,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.app',
                      ),
                      MarkerLayer(markers: _buildMarkers()),
                      PolylineLayer(polylines: _buildPolylines()),
                    ],
                  ),
                  // Status do rastreamento
                  if (order.status == OrderStatus.ON_COURSE)
                    Positioned(
                      top: 16,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            if (_isTracking)
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: _currentDriverLocation != null ? Colors.green : Colors.orange,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _trackingStatus,
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
                  // Status da entrega
                  Row(
                    children: [
                      Icon(
                        order.status == OrderStatus.DELIVERIED 
                            ? Icons.check_circle 
                            : Icons.delivery_dining,
                        color: statusColor,
                        size: 30,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Status: $statusText',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Info de rastreamento para pedidos em transporte
                  if (order.status == OrderStatus.ON_COURSE) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.gps_fixed, color: Colors.blue.shade700, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Rastreamento em Tempo Real',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _currentDriverLocation != null
                                ? 'Motorista localizado! A localização é atualizada automaticamente a cada 2 minutos.'
                                : 'Aguardando localização do motorista...',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade600,
                            ),
                          ),
                          if (_lastUpdate != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Última atualização: ${_formatTime(_lastUpdate!)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.blue.shade500,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Descrição do pedido
                  Text(
                    'Descrição:',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
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
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    getFormattedAddress(order.originAddress),
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
                    getFormattedAddress(order.destinationAddress),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}