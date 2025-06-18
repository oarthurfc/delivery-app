import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../database/repository/OrderRepository.dart';
import '../../models/order.dart';
import '../../services/api/repos/OrderRepository2.dart';
import '../../services/api/repos/DriverTrackingRepository.dart';
import '../../widgets/common/app_bar_widget.dart';
import 'driver_delivery_details_screen.dart' as details;
import 'delivery_tracking_history_screen.dart';

class DriverHistoryScreen extends StatefulWidget {
  const DriverHistoryScreen({super.key});

  @override
  State<DriverHistoryScreen> createState() => _DriverHistoryScreenState();
}

class _DriverHistoryScreenState extends State<DriverHistoryScreen> {
  final OrderRepository _orderRepository = OrderRepository();
  final OrderRepository2 _orderRepository2 = OrderRepository2(); // Novo repositório
  final DriverTrackingRepository _trackingRepository = DriverTrackingRepository();
  
  List<Order> _orders = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _useApiRepository = true; // Flag para usar o novo repositório

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('current_user_id');

      if (userId != null) {
        List<Order> orders;
        
        if (_useApiRepository) {
          // Tentar usar o repositório da API primeiro
          try {
            print('Tentando buscar entregas do motorista via API...');
            orders = await _orderRepository2.getOrdersByDriverId(userId);
            print('Sucesso! ${orders.length} entregas encontradas via API');
          } catch (e) {
            print('Erro ao buscar via API: $e');
            print('Fallback para repositório local...');
            orders = await _orderRepository.getOrdersByDriverId(userId);
          }
        } else {
          // Usar diretamente o repositório local
          orders = await _orderRepository.getOrdersByDriverId(userId);
        }
        
        setState(() {
          _orders = orders;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Usuário não encontrado';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar entregas: $e';
        _isLoading = false;
      });
      print('Erro ao carregar entregas: $e');
    }
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

  Future<bool> _checkIfTrackingExists(int orderId) async {
    try {
      final history = await _trackingRepository.getOrderLocationHistory(orderId);
      final List<dynamic> locations = history['locationHistory'] ?? [];
      return locations.isNotEmpty;
    } catch (e) {
      print('Erro ao verificar histórico de rastreamento: $e');
      return false;
    }
  }

  void _viewTrackingHistory(Order order) async {
    // Verificar se existe histórico de rastreamento
    final hasTracking = await _checkIfTrackingExists(order.id);
    
    if (!mounted) return;
    
    if (hasTracking) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => details.DriverDeliveryDetailsScreen(order: order),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nenhum histórico de rastreamento disponível para esta entrega'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Widget buildOrderCard(BuildContext context, Order order) {
    final textTheme = Theme.of(context).textTheme;
    final statusText = getStatusText(order.status);
    final statusColor = getStatusColor(order.status);

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DriverDeliveryDetailsScreen(order: order),
            ),
          ).then((_) => _loadOrders());
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ID da entrega e status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Entrega #${order.id}',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Descrição
              Text(
                'Descrição: ${order.description}',
                style: textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              
              // Endereço de origem
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.blue),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'De: ${getFormattedAddress(order.originAddress)}',
                      style: textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              
              // Endereço de destino
              Row(
                children: [
                  const Icon(Icons.flag, size: 16, color: Colors.red),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Para: ${getFormattedAddress(order.destinationAddress)}',
                      style: textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              
              // Botão para visualizar rota, apenas para entregas em transporte ou concluídas
              if (order.status == OrderStatus.ON_COURSE || order.status == OrderStatus.DELIVERIED)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.map, size: 18),
                        label: const Text('Ver Rota'),
                        onPressed: () => _viewTrackingHistory(order),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Entregas'),
        centerTitle: true,
        actions: [
          // Botão para alternar entre API e DB local
          IconButton(
            icon: Icon(_useApiRepository ? Icons.cloud : Icons.storage),
            tooltip: _useApiRepository ? 'Usando API' : 'Usando DB Local',
            onPressed: () {
              setState(() {
                _useApiRepository = !_useApiRepository;
                _loadOrders();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
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
                        onPressed: _loadOrders,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                )
              : _orders.isEmpty
                  ? const Center(
                      child: Text(
                        'Você ainda não tem entregas registradas.',
                        style: TextStyle(fontSize: 18),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _orders.length,
                      itemBuilder: (context, index) => buildOrderCard(context, _orders[index]),
                    ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 1, // Histórico é o segundo item
        onTap: (index) {
          // lógica de navegação
        },
      ),
    );
  }
}