import 'package:delivery/models/address.dart';
import 'package:delivery/models/order.dart';
import 'package:delivery/services/api/ApiService.dart';

class OrderRepository2 {
  final ApiService _apiService = ApiService();

  // Criar um novo pedido
  Future<Order> save(Order order) async {
    try {
      print('OrderRepository2: Salvando pedido...');
      
      // Converter Order para o formato esperado pelo backend
      final orderData = _orderToCreateDTO(order);
      print('OrderRepository2: Dados enviados: $orderData');
      
      final response = await _apiService.createOrder(orderData);
      print('OrderRepository2: Resposta recebida: $response');
      
      // Converter resposta do backend para Order
      final savedOrder = _orderFromResponseDTO(response);
      print('OrderRepository2: Pedido salvo com sucesso - ID: ${savedOrder.id}');
      
      return savedOrder;
    } catch (e, stackTrace) {
      print('OrderRepository2: Erro ao salvar pedido: $e');
      print('OrderRepository2: Stack trace: $stackTrace');
      throw Exception('Erro ao salvar pedido: $e');
    }
  }

  // Buscar pedido por ID
  Future<Order?> getById(int id) async {
    try {
      print('OrderRepository2: Buscando pedido $id...');
      final response = await _apiService.getOrderById(id);
      final order = _orderFromResponseDTO(response);
      print('OrderRepository2: Pedido $id encontrado');
      return order;
    } catch (e) {
      print('OrderRepository2: Erro ao buscar pedido $id: $e');
      return null;
    }
  }

  // Listar todos os pedidos
  Future<List<Order>> getAll() async {
    try {
      print('OrderRepository2: Listando todos os pedidos...');
      final response = await _apiService.getAllOrders();
      
      // Verifica se a resposta está no formato de paginação
      final List<dynamic> ordersList;
      if (response is Map<String, dynamic> && response.containsKey('content')) {
        ordersList = response['content'] as List<dynamic>;
      } else {
        ordersList = response['orders'] as List<dynamic>;
      }
      
      final orders = ordersList
          .map((item) => _orderFromResponseDTO(item as Map<String, dynamic>))
          .toList();
          
      print('OrderRepository2: ${orders.length} pedidos encontrados');
      return orders;
    } catch (e) {
      print('OrderRepository2: Erro ao listar pedidos: $e');
      return [];
    }
  }

  // Buscar pedidos por cliente
  Future<List<Order>> getOrdersByCustomerId(int customerId) async {
    try {
      print('OrderRepository2: Buscando pedidos do cliente $customerId...');
      final allOrders = await getAll();
      final customerOrders = allOrders.where((order) => order.customerId == customerId).toList();
      print('OrderRepository2: ${customerOrders.length} pedidos encontrados para cliente $customerId');
      return customerOrders;
    } catch (e) {
      print('OrderRepository2: Erro ao buscar pedidos do cliente $customerId: $e');
      return [];
    }
  }

  // Buscar pedidos por motorista
  Future<List<Order>> getOrdersByDriverId(int driverId) async {
    try {
      print('OrderRepository2: Buscando pedidos do motorista $driverId...');
      final allOrders = await getAll();
      final driverOrders = allOrders.where((order) => order.driverId == driverId).toList();
      print('OrderRepository2: ${driverOrders.length} pedidos encontrados para motorista $driverId');
      return driverOrders;
    } catch (e) {
      print('OrderRepository2: Erro ao buscar pedidos do motorista $driverId: $e');
      return [];
    }
  }

  // Buscar pedidos por status
  Future<List<Order>> getOrdersByStatus(OrderStatus status) async {
    try {
      print('OrderRepository2: Buscando pedidos com status $status...');
      final allOrders = await getAll();
      final statusOrders = allOrders.where((order) => order.status == status).toList();
      print('OrderRepository2: ${statusOrders.length} pedidos encontrados com status $status');
      return statusOrders;
    } catch (e) {
      print('OrderRepository2: Erro ao buscar pedidos com status $status: $e');
      return [];
    }
  }

  // Buscar pedidos PENDING paginados
  Future<List<Order>> getPendingOrdersPaged({int page = 0, int size = 10}) async {
    try {
      print('OrderRepository2: Buscando pedidos PENDING paginados...');
      final response = await _apiService.getOrdersByStatusPaged(status: 'PENDING', page: page, size: size);
      final orders = response.map((item) => _orderFromResponseDTO(item)).toList();
      final pendingOrders = orders.where((order) => order.status == OrderStatus.PENDING).toList();
      print('OrderRepository2: ${pendingOrders.length} pedidos PENDING encontrados (filtrados localmente)');
      return pendingOrders;
    } catch (e) {
      print('OrderRepository2: Erro ao buscar pedidos PENDING paginados: $e');
      return [];
    }
  }

  // Atualizar um pedido
  Future<int> update(Order order) async {
    try {
      print('OrderRepository2: Atualizando pedido ${order.id}...');
      final orderData = _orderToUpdateDTO(order);
      await _apiService.updateOrder(order.id, orderData);
      print('OrderRepository2: Pedido ${order.id} atualizado com sucesso');
      return 1;
    } catch (e) {
      print('OrderRepository2: Erro ao atualizar pedido ${order.id}: $e');
      return 0;
    }
  }

  // Atualizar status do pedido
  Future<int> updateOrderStatus(int orderId, OrderStatus newStatus) async {
    try {
      print('OrderRepository2: Atualizando status do pedido $orderId para $newStatus...');
      final order = await getById(orderId);
      if (order == null) {
        print('OrderRepository2: Pedido $orderId não encontrado');
        return 0;
      }
      order.status = newStatus;
      return await update(order);
    } catch (e) {
      print('OrderRepository2: Erro ao atualizar status do pedido $orderId: $e');
      return 0;
    }
  }

  // Deletar pedido
  Future<int> delete(int id) async {
    try {
      print('OrderRepository2: Deletando pedido $id...');
      await _apiService.deleteOrder(id);
      print('OrderRepository2: Pedido $id deletado com sucesso');
      return 1;
    } catch (e) {
      print('OrderRepository2: Erro ao deletar pedido $id: $e');
      return 0;
    }
  }

  // ===== CONVERSÕES DTO =====

  Map<String, dynamic> _orderToCreateDTO(Order order) {
    return {
      'customerId': order.customerId,
      'status': order.status.name,
      'originAddress': {
        'street': order.originAddress.street,
        'number': order.originAddress.number,
        'neighborhood': order.originAddress.neighborhood,
        'city': order.originAddress.city,
        'latitude': order.originAddress.latitude,
        'longitude': order.originAddress.longitude,
      },
      'destinationAddress': {
        'street': order.destinationAddress.street,
        'number': order.destinationAddress.number,
        'neighborhood': order.destinationAddress.neighborhood,
        'city': order.destinationAddress.city,
        'latitude': order.destinationAddress.latitude,
        'longitude': order.destinationAddress.longitude,
      },
      'description': order.description,
      'imageUrl': order.imageUrl,
    };
  }

  Map<String, dynamic> _orderToUpdateDTO(Order order) {
    return {
      'customerId': order.customerId,
      'driverId': order.driverId,
      'status': order.status.name,
      'originAddress': {
        'street': order.originAddress.street,
        'number': order.originAddress.number,
        'neighborhood': order.originAddress.neighborhood,
        'city': order.originAddress.city,
        'latitude': order.originAddress.latitude,
        'longitude': order.originAddress.longitude,
      },
      'destinationAddress': {
        'street': order.destinationAddress.street,
        'number': order.destinationAddress.number,
        'neighborhood': order.destinationAddress.neighborhood,
        'city': order.destinationAddress.city,
        'latitude': order.destinationAddress.latitude,
        'longitude': order.destinationAddress.longitude,
      },
      'description': order.description,
      'imageUrl': order.imageUrl,
    };
  }

  // Converter OrderResponseDTO para Order - COM DEBUG DETALHADO
  Order _orderFromResponseDTO(Map<String, dynamic> response) {
    try {
      print('OrderRepository2: === INÍCIO DA CONVERSÃO DTO ===');
      print('OrderRepository2: Response completo: $response');
      
      // Validar campos principais
      print('OrderRepository2: Validando ID...');
      final id = _safeGetInt(response, 'id');
      print('OrderRepository2: ID validado: $id');
      
      print('OrderRepository2: Validando customerId...');
      final customerId = _safeGetInt(response, 'customerId');
      print('OrderRepository2: customerId validado: $customerId');
      
      print('OrderRepository2: Validando driverId...');
      final driverId = _safeGetNullableInt(response, 'driverId');
      print('OrderRepository2: driverId validado: $driverId');
      
      print('OrderRepository2: Validando status...');
      final status = OrderStatus.values.firstWhere(
        (e) => e.name == response['status'],
        orElse: () => OrderStatus.PENDING,
      );
      print('OrderRepository2: status validado: $status');
      
      print('OrderRepository2: Validando originAddress...');
      final originAddressData = _safeGetMap(response, 'originAddress');
      print('OrderRepository2: originAddress data: $originAddressData');
      final originAddress = Address.fromJson(originAddressData);
      print('OrderRepository2: originAddress criado: $originAddress');
      
      print('OrderRepository2: Validando destinationAddress...');
      final destinationAddressData = _safeGetMap(response, 'destinationAddress');
      print('OrderRepository2: destinationAddress data: $destinationAddressData');
      final destinationAddress = Address.fromJson(destinationAddressData);
      print('OrderRepository2: destinationAddress criado: $destinationAddress');
      
      print('OrderRepository2: Validando description...');
      final description = _safeGetString(response, 'description');
      print('OrderRepository2: description validado: $description');
      
      print('OrderRepository2: Validando imageUrl...');
      final imageUrl = _safeGetString(response, 'imageUrl');
      print('OrderRepository2: imageUrl validado: $imageUrl');
      
      print('OrderRepository2: Criando objeto Order...');
      final order = Order(
        id: id,
        customerId: customerId,
        driverId: driverId,
        status: status,
        originAddress: originAddress,
        destinationAddress: destinationAddress,
        description: description,
        imageUrl: imageUrl,
      );
      
      print('OrderRepository2: === CONVERSÃO CONCLUÍDA COM SUCESSO ===');
      return order;
      
    } catch (e, stackTrace) {
      print('OrderRepository2: === ERRO NA CONVERSÃO DTO ===');
      print('OrderRepository2: Erro: $e');
      print('OrderRepository2: Stack trace: $stackTrace');
      print('OrderRepository2: Response data: $response');
      rethrow;
    }
  }

  // ===== MÉTODOS AUXILIARES PARA CONVERSÃO SEGURA =====
  
  int _safeGetInt(Map<String, dynamic> map, String key) {
    final value = map[key];
    print('OrderRepository2: _safeGetInt - $key: $value (${value.runtimeType})');
    if (value == null) {
      throw Exception('Campo obrigatório $key é null');
    }
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.parse(value);
    throw Exception('Campo $key não é um int válido: $value');
  }
  
  int? _safeGetNullableInt(Map<String, dynamic> map, String key) {
    final value = map[key];
    print('OrderRepository2: _safeGetNullableInt - $key: $value (${value.runtimeType})');
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String && value.isNotEmpty) return int.parse(value);
    return null;
  }
  
  String _safeGetString(Map<String, dynamic> map, String key) {
    final value = map[key];
    print('OrderRepository2: _safeGetString - $key: $value (${value.runtimeType})');
    if (value == null) return '';
    return value.toString();
  }
  
  Map<String, dynamic> _safeGetMap(Map<String, dynamic> map, String key) {
    final value = map[key];
    print('OrderRepository2: _safeGetMap - $key: $value (${value.runtimeType})');
    if (value == null) {
      throw Exception('Campo obrigatório $key é null');
    }
    if (value is Map<String, dynamic>) return value;
    throw Exception('Campo $key não é um Map válido: $value');
  }

  Future<void> syncWithServer() async {
    print('OrderRepository2: Já sincronizado com servidor');
  }
}