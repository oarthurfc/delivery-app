// Implementação do repositório para Orders
import 'package:delivery/database/database_helper.dart';
import 'package:delivery/database/repository/SyncableRepository.dart';
import 'package:delivery/models/order.dart';


class OrderRepository extends SyncableRepository<Order> {
  OrderRepository() : super('orders');
  
  @override
  Order fromMap(Map<String, dynamic> map) => Order.fromMap(map);

  @override
  Map<String, dynamic> toMap(Order order) => order.toMap();
  
  @override
  int getId(Order order) => order.id;
  
  // Métodos específicos para pedidos
  Future<List<Order>> getOrdersByCustomerId(int customerId) async {
    final db = await DatabaseHelper().database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'customer_id = ?',
      whereArgs: [customerId],
    );
    
    return List.generate(maps.length, (i) => fromMap(maps[i]));
  }
  
  Future<List<Order>> getOrdersByDriverId(int driverId) async {
    final db = await DatabaseHelper().database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'driver_id = ?',
      whereArgs: [driverId],
    );
    
    return List.generate(maps.length, (i) => fromMap(maps[i]));
  }
  
  Future<List<Order>> getOrdersByStatus(OrderStatus status) async {
    final db = await DatabaseHelper().database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'status = ?',
      whereArgs: [status.toString().split('.').last],
    );
    
    return List.generate(maps.length, (i) => fromMap(maps[i]));
  }
  
  Future<int> updateOrderStatus(int orderId, OrderStatus newStatus) async {
    final order = await getById(orderId);
    if (order == null) return 0;
    
    order.status = newStatus;
    // order.updatedAt = DateTime.now();
    return await update(order);
  }

  @override
  Future<void> syncWithServer() async {
    final db = await DatabaseHelper().database;

    // Buscar pedidos com sync_status diferente de SYNCED
    final unsynced = await db.query(
      tableName,
      where: 'sync_status != ?',
      whereArgs: ['SYNCED'],
    );

    for (final map in unsynced) {
      final order = fromMap(map);
      final syncStatus = map['sync_status'];

      try {
        if (syncStatus == 'PENDING_SYNC') {
          // Enviar POST para o servidor
        } else if (syncStatus == 'PENDING_UPDATE') {
          // Enviar PUT para o servidor
        } else if (syncStatus == 'PENDING_DELETE') {
          // Enviar DELETE para o servidor
        }

        // Marcar como sincronizado
        await db.update(
          tableName,
          {'sync_status': 'SYNCED'},
          where: 'id = ?',
          whereArgs: [order.id],
        );
      } catch (e) {
        print('Erro ao sincronizar pedido ${order.id}: $e');
        // Lida com falhas, se necessário
      }
    }
  }
}
