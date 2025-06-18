import 'dart:async';
import 'dart:convert';
import 'package:delivery/database/SyncService.dart';
import 'package:delivery/database/repository/OrderRepository.dart';
import 'package:delivery/database/repository/SyncableRepository.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/order.dart';

// Enumerações do modelo
// enum UserType { CUSTOMER, DRIVER }
// enum OrderStatus { PENDING, ACCEPTED, ON_COURSE, DELIVERIED }
enum SyncStatus { SYNCED, PENDING_SYNC, PENDING_UPDATE, PENDING_DELETE }

// URL Base da API
const String apiBaseUrl = 'https://seu-backend-api.com';

// Classe responsável pelo banco de dados local
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'delivery_app.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDb,
    );
  }

  // Criando as tabelas do banco de dados
  Future<void> _createDb(Database db, int version) async {
    // Tabela de usuários
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY,
        username TEXT NOT NULL,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'SYNCED'
      )
    ''');

    // Tabela de endereços
    await db.execute('''
      CREATE TABLE addresses(
        id INTEGER PRIMARY KEY,
        street TEXT NOT NULL,
        number TEXT NOT NULL,
        neighborhood TEXT NOT NULL,
        city TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'SYNCED'
      )
    ''');

    // Tabela de pedidos
    await db.execute('''
  CREATE TABLE orders(
    id INTEGER PRIMARY KEY,
    customer_id INTEGER NOT NULL,
    driver_id INTEGER,
    status TEXT NOT NULL,
    origin_address TEXT NOT NULL,        
    destination_address TEXT NOT NULL,   
    description TEXT NOT NULL,
    image_url TEXT,
    price REAL NOT NULL DEFAULT 0.0,
    receiver_name TEXT NOT NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    sync_status TEXT NOT NULL DEFAULT 'SYNCED',
    FOREIGN KEY (customer_id) REFERENCES users (id),
    FOREIGN KEY (driver_id) REFERENCES users (id)
  )
''');

    // Tabela de pontos de localização
    await db.execute('''
      CREATE TABLE location_points(
        id INTEGER PRIMARY KEY,
        order_id INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'SYNCED',
        FOREIGN KEY (order_id) REFERENCES orders (id)
      )
    ''');

    // Tabela de preferências de notificação
    await db.execute('''
      CREATE TABLE notification_preferences(
        user_id INTEGER PRIMARY KEY,
        enabled INTEGER NOT NULL DEFAULT 1,
        sync_status TEXT NOT NULL DEFAULT 'SYNCED',
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // Tabela de configurações
    await db.execute('''
      CREATE TABLE settings(
        user_id INTEGER PRIMARY KEY,
        is_dark_theme INTEGER NOT NULL DEFAULT 0,
        show_completed_orders INTEGER NOT NULL DEFAULT 1,
        sync_status TEXT NOT NULL DEFAULT 'SYNCED',
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // Tabela de log de sincronização
    await db.execute('''
      CREATE TABLE sync_log(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        record_id INTEGER NOT NULL,
        action TEXT NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');
  }
}



//Possiveis exemplos que talvez sejam uteis para o futuro

// // Widget para exibir indicador de sincronização
// class SyncIndicator extends StatelessWidget {
//   final SyncService syncService;
  
//   const SyncIndicator({Key? key, required this.syncService}) : super(key: key);
  
//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder<bool>(
//       stream: syncService.syncStream,
//       initialData: false,
//       builder: (context, snapshot) {
//         final isSyncing = snapshot.data ?? false;
        
//         return AnimatedContainer(
//           duration: Duration(milliseconds: 300),
//           height: 4,
//           width: double.infinity,
//           color: isSyncing ? Colors.blue : Colors.transparent,
//           child: isSyncing 
//             ? LinearProgressIndicator(
//                 backgroundColor: Colors.blue.withOpacity(0.3),
//               )
//             : null,
//         );
//       },
//     );
//   }
// }

// // Exemplo de uso em um aplicativo Flutter
// class DeliveryApp extends StatefulWidget {
//   @override
//   _DeliveryAppState createState() => _DeliveryAppState();
// }

// class _DeliveryAppState extends State<DeliveryApp> {
//   late OrderRepository _orderRepository;
//   late SyncService _syncService;
  
//   @override
//   void initState() {
//     super.initState();
    
//     // Inicializar repositórios
//     _orderRepository = OrderRepository();
    
//     // Configurar serviço de sincronização
//     _syncService = SyncService([_orderRepository]);
//     _syncService.startPeriodicSync();
    
//     // Verificar conectividade e sincronizar na inicialização
//     Connectivity().checkConnectivity().then((result) {
//       if (result != ConnectivityResult.none) {
//         _syncService.syncAll();
//       }
//     });
//   }
  
//   @override
//   void dispose() {
//     _syncService.dispose();
//     super.dispose();
//   }
  
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Delivery App',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//       ),
//       home: OrdersScreen(orderRepository: _orderRepository, syncService: _syncService),
//     );
//   }
// }

// class OrdersScreen extends StatefulWidget {
//   final OrderRepository orderRepository;
//   final SyncService syncService;
  
//   const OrdersScreen({
//     Key? key,
//     required this.orderRepository,
//     required this.syncService,
//   }) : super(key: key);
  
//   @override
//   _OrdersScreenState createState() => _OrdersScreenState();
// }

// class _OrdersScreenState extends State<OrdersScreen> {
//   List<Order> _orders = [];
//   bool _isLoading = true;
  
//   @override
//   void initState() {
//     super.initState();
//     _loadOrders();
    
//     // Recarregar ordens após sincronização
//     widget.syncService.syncStream.listen((isSyncing) {
//       if (!isSyncing) {
//         _loadOrders();
//       }
//     });
//   }
  
//   Future<void> _loadOrders() async {
//     setState(() {
//       _isLoading = true;
//     });
    
//     try {
//       final orders = await widget.orderRepository.getAll();
//       setState(() {
//         _orders = orders;
//         _isLoading = false;
//       });
//     } catch (e) {
//       setState(() {
//         _isLoading = false;
//       });
//       ScaffoldMessenger.of(context as BuildContext).showSnackBar(
//         SnackBar(content: Text('Erro ao carregar pedidos: $e')),
//       );
//     }
//   }
  
//   Future<void> _syncNow() async {
//     await widget.syncService.syncAll();
//   }
  
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Pedidos'),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.sync),
//             onPressed: _syncNow,
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           SyncIndicator(syncService: widget.syncService),
//           Expanded(
//             child: _isLoading
//                 ? Center(child: CircularProgressIndicator())
//                 : _orders.isEmpty
//                     ? Center(child: Text('Nenhum pedido encontrado'))
//                     : ListView.builder(
//                         itemCount: _orders.length,
//                         itemBuilder: (context, index) {
//                           final order = _orders[index];
//                           return ListTile(
//                             title: Text('Pedido #${order.id}'),
//                             subtitle: Text(order.description),
//                             trailing: Icon(_getStatusIcon(order.status)),
//                             onTap: () {
//                               // Navegar para detalhes do pedido
//                             },
//                           );
//                         },
//                       ),
//           ),
//         ],
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           // Adicionar novo pedido
//         },
//         child: Icon(Icons.add),
//       ),
//     );
//   }
  
//   IconData _getStatusIcon(OrderStatus status) {
//     switch (status) {
//       case OrderStatus.PENDING:
//         return Icons.hourglass_empty;
//       case OrderStatus.ACCEPTED:
//         return Icons.thumbs_up_down;
//       case OrderStatus.ON_COURSE:
//         return Icons.local_shipping;
//       case OrderStatus.DELIVERIED:
//         return Icons.check_circle;
//     }
//   }
// }