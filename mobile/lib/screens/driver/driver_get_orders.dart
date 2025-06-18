import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:delivery/services/api/repos/OrderRepository2.dart';
import '../../models/order.dart';
import '../../widgets/common/app_bar_widget.dart';
import 'driver_delivery_details_screen.dart';

class GetOrderScreen extends StatefulWidget {
  const GetOrderScreen({super.key});

  @override
  State<GetOrderScreen> createState() => _GetOrderScreenState();
}

class _GetOrderScreenState extends State<GetOrderScreen> {
  final OrderRepository2 _orderRepository = OrderRepository2();
  List<Order> _availableOrders = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAvailableOrders();
  }

  Future<void> _loadAvailableOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Busca pedidos PENDING paginados
      final orders = await _orderRepository.getPendingOrdersPaged(page: 0, size: 10);
      setState(() {
        _availableOrders = orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar pedidos disponíveis: $e';
        _isLoading = false;
      });
      print('Erro ao carregar pedidos disponíveis: $e');
    }
  }

  String getFormattedAddress(address) {
    return '${address.street}, ${address.number} - ${address.neighborhood}, ${address.city}';
  }

  Widget buildOrderCard(BuildContext context, Order order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DriverDeliveryDetailsScreen(order: order),
            ),
          ).then((_) => _loadAvailableOrders());
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mapa com origem e destino
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: SizedBox(
                height: 150,
                width: double.infinity,
                child: FlutterMap(
                  options: MapOptions(
                    center: LatLng(
                      (order.originAddress.latitude + order.destinationAddress.latitude) / 2,
                      (order.originAddress.longitude + order.destinationAddress.longitude) / 2,
                    ),
                    zoom: 12,
                    interactiveFlags: InteractiveFlag.none,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(
                            order.originAddress.latitude,
                            order.originAddress.longitude,
                          ),
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.blue,
                            size: 30,
                          ),
                        ),
                        Marker(
                          point: LatLng(
                            order.destinationAddress.latitude,
                            order.destinationAddress.longitude,
                          ),
                          child: const Icon(
                            Icons.flag,
                            color: Colors.red,
                            size: 30,
                          ),
                        ),
                      ],
                    ),
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
                          strokeWidth: 3,
                          color: Colors.blue.withOpacity(0.7),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Informações do pedido
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.description,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'De: ${getFormattedAddress(order.originAddress)}',
                          style: const TextStyle(fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.flag, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Para: ${getFormattedAddress(order.destinationAddress)}',
                          style: const TextStyle(fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: ElevatedButton(
                      onPressed: () => _acceptOrder(order),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Aceitar Entrega'),
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

  Future<void> _acceptOrder(Order order) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final driverId = prefs.getInt('current_user_id');
      
      if (driverId != null) {
        // Atualiza o status do pedido via API
        final result = await _orderRepository.updateOrderStatus(order.id, OrderStatus.ACCEPTED);
        if (result == 1) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Entrega aceita com sucesso!')),
          );
          // Redireciona para os detalhes da entrega
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DriverDeliveryDetailsScreen(order: order),
            ),
          );
        } else {
          throw Exception('Falha ao aceitar entrega');
        }
      } else {
        throw Exception('Usuário não autenticado');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao aceitar entrega: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entregas Disponíveis'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAvailableOrders,
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
                        onPressed: _loadAvailableOrders,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                )
              : _availableOrders.isEmpty
                  ? RefreshIndicator(
                      onRefresh: _loadAvailableOrders,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: const [
                          Center(
                            child: Text(
                              'Não há entregas disponíveis no momento.',
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadAvailableOrders,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _availableOrders.length,
                        itemBuilder: (context, index) => buildOrderCard(context, _availableOrders[index]),
                      ),
                    ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 1, // Índice do bottomNavigationBar
        onTap: (index) {
          // lógica de navegação
        },
      ),
    );
  }
}