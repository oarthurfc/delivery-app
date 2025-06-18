import 'package:delivery/services/api/repos/OrderRepository2.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  final OrderRepository2 _orderRepository = OrderRepository2(); // Mudança aqui
  List<Order> _orders = [];
  bool _isLoading = true;
  String? _errorMessage;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentUserId = prefs.getInt('current_user_id');
      print('CustomerHistory: ID do usuário atual: $_currentUserId');
      _loadOrders();
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar dados do usuário: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadOrders() async {
    if (_currentUserId == null) {
      setState(() {
        _errorMessage = 'Usuário não encontrado. Faça login novamente.';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('CustomerHistory: Carregando pedidos para usuário $_currentUserId...');
      
      // Usar o novo repositório com API
      final orders = await _orderRepository.getOrdersByCustomerId(_currentUserId!);
      
      print('CustomerHistory: ${orders.length} pedidos encontrados');
      
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar pedidos: $e';
        _isLoading = false;
      });
      print('CustomerHistory: Erro ao carregar pedidos: $e');
    }
  }

  Future<void> _refreshOrders() async {
    print('CustomerHistory: Atualizando lista de pedidos...');
    await _loadOrders();
  }

  String getFormattedAddress(Address address) {
    final parts = <String>[];
    if (address.street.isNotEmpty) parts.add(address.street);
    if (address.number.isNotEmpty) parts.add(address.number);
    if (address.neighborhood.isNotEmpty) parts.add(address.neighborhood);
    if (address.city.isNotEmpty) parts.add(address.city);
    return parts.join(', ');
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

  Color getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.DELIVERIED:
        return Colors.green;
      case OrderStatus.PENDING:
        return Colors.orange;
      case OrderStatus.ACCEPTED:
        return Colors.blue;
      case OrderStatus.ON_COURSE:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.DELIVERIED:
        return Icons.check_circle;
      case OrderStatus.PENDING:
        return Icons.hourglass_empty;
      case OrderStatus.ACCEPTED:
        return Icons.thumbs_up_down;
      case OrderStatus.ON_COURSE:
        return Icons.local_shipping;
      default:
        return Icons.help_outline;
    }
  }

  Widget buildHistoryCard(BuildContext context, Order order) {
    final textTheme = Theme.of(context).textTheme;
    final statusText = getStatusText(order.status);
    final statusColor = getStatusColor(order.status);
    final statusIcon = getStatusIcon(order.status);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CustomerDeliveryDetailsScreen(order: order),
          ),
        ).then((_) => _refreshOrders()); // Recarregar ao voltar
      },
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header do card
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pedido #${order.id}',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          statusIcon,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Descrição
              if (order.description.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.description, size: 18, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        order.description,
                        style: textTheme.bodyMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              
              // Endereço de origem
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.my_location, size: 18, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'De: ${getFormattedAddress(order.originAddress)}',
                      style: textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              
              // Endereço de destino
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on, size: 18, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Para: ${getFormattedAddress(order.destinationAddress)}',
                      style: textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              
              // Botão de ação (se não estiver entregue)
              if (order.status != OrderStatus.DELIVERIED) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CustomerDeliveryDetailsScreen(order: order),
                          ),
                        ).then((_) => _refreshOrders());
                      },
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('Ver detalhes'),
                      style: TextButton.styleFrom(
                        foregroundColor: statusColor,
                      ),
                    ),
                  ],
                ),
              ],
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
            onPressed: _isLoading ? null : _refreshOrders,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Carregando pedidos...'),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _refreshOrders,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Tentar novamente'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : _orders.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Você não tem entregas registradas.',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Suas entregas aparecerão aqui quando você criar um pedido.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _refreshOrders,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _orders.length,
                        itemBuilder: (context, index) => buildHistoryCard(context, _orders[index]),
                      ),
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