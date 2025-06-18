import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../database/repository/OrderRepository.dart';
import '../../models/order.dart';
import '../../models/address.dart';
import '../../widgets/common/app_bar_widget.dart';
import 'client_delivery_details_screen.dart';

class CustomerDeliveryHistoryScreen extends StatefulWidget {
  const CustomerDeliveryHistoryScreen({super.key});

  @override
  State<CustomerDeliveryHistoryScreen> createState() => _CustomerDeliveryHistoryScreenState();
}

class _CustomerDeliveryHistoryScreenState extends State<CustomerDeliveryHistoryScreen> {
  final OrderRepository _orderRepository = OrderRepository();
  List<Order> _orders = [];
  bool _isLoading = true;
  String? _errorMessage;

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
        final orders = await _orderRepository.getOrdersByCustomerId(userId);
        setState(() {
          _orders = orders;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar pedidos: $e';
      });
      print('Erro ao carregar pedidos: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String getFormattedAddress(Address address) {
    return '${address.street}, ${address.number} - ${address.neighborhood}, ${address.city}';
  }

  String getFormattedDate(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
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
      default:
        return status.name;
    }
  }

  Widget buildHistoryCard(BuildContext context, Order order) {
    final textTheme = Theme.of(context).textTheme;
    final isDelivered = order.status == OrderStatus.DELIVERIED;
    final statusText = getStatusText(order.status);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CustomerDeliveryDetailsScreen(order: order),
          ),
        ).then((_) => _loadOrders()); // Recarregar ao voltar
      },
      child: Card(
        elevation: 5,
        margin: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Entrega Número: ${order.id}',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    isDelivered ? Icons.check_circle : Icons.error,
                    color: isDelivered ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    statusText,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDelivered ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.description, size: 18, color: Colors.grey),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      'Descrição: ${order.description}',
                      style: textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on, size: 18, color: Colors.grey),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      'Origem: ${getFormattedAddress(order.originAddress)}',
                      style: textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.flag, size: 18, color: Colors.grey),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      'Destino: ${getFormattedAddress(order.destinationAddress)}',
                      style: textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
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
        title: const Text('Histórico de Entregas'),
        centerTitle: true,
        actions: [
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
                        'Você não tem entregas registradas.',
                        style: TextStyle(fontSize: 18),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _orders.length,
                      itemBuilder: (context, index) => buildHistoryCard(context, _orders[index]),
                    ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 1, // Assumindo que histórico é o segundo item
        onTap: (index) {
          // lógica de navegação
        },
      ),
    );
  }
}