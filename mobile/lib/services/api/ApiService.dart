import 'package:delivery/database/repository/UserRepository.dart';
import 'package:delivery/services/notification_service.dart';
import 'package:delivery/services/token_service.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user.dart';
import '../../database/database_helper.dart';

class ApiService {
  final Dio _dio = Dio();
  final TokenService _tokenService = TokenService();
  final UserRepository _userRepository = UserRepository();
  
  // Configuração de ambiente
  static const bool runningOnEmulator = false; // <--- MUDE PARA TRUE NO EMULADOR
  static const String _localIp = '192.168.167.87'; // IP do seu computador
  static const String _emulatorIp = '10.0.2.2'; // IP especial para emulador Android
  static const int _port = 8000;
  
  String get _baseUrl {
    if (kIsWeb) {
      return 'http://localhost:$_port/api';
    } else if (Platform.isAndroid && runningOnEmulator) {
      return 'http://$_emulatorIp:$_port/api';
    }
    return 'https://70252f94f287.ngrok-free.app/api';
  }

  ApiService() {
    // CONFIGURAR TIMEOUTS ADEQUADOS
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.sendTimeout = const Duration(seconds: 30);

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          print('ApiService: Request URL: ${options.uri}');
          print('ApiService: Request Headers: ${options.headers}');
          print('ApiService: Request Data: ${options.data}');
          
          final token = await _tokenService.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print('ApiService: Response Status: ${response.statusCode}');
          print('ApiService: Response Data: ${response.data}');
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          print('ApiService: Error Type: ${e.type}');
          print('ApiService: Error Message: ${e.message}');
          print('ApiService: Error Response: ${e.response?.data}');
          print('ApiService: Request URL: ${e.requestOptions.uri}');
          return handler.next(e);
        },
      ),
    );
  }

  // ===== AUTHENTICATION METHODS =====

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final token = response.data['token'];
        final userData = response.data['user'];
        
        await _tokenService.saveToken(token);
        
        // Usar o ID retornado pela API
        final userId = userData['id'] as int;
        final userEmail = userData['email'] as String;
        final userName = userData['name'] as String;
        final userRole = userData['role'] as String;
        
        // Verificar se o usuário já existe no banco de dados local
        final db = await DatabaseHelper().database;
        final result = await db.query(
          'users',
          where: 'username = ?',
          whereArgs: [userEmail],
          limit: 1,
        );
        
        final userType = userRole.toLowerCase() == 'driver' ? UserType.DRIVER : UserType.CUSTOMER;
        
        final user = User(
          id: userId, // Usar o ID da API
          username: userEmail,
          name: userName,
          type: userType,
        );
        
        if (result.isEmpty) {
          // Usuário não existe localmente, vamos criá-lo
          await _userRepository.save(user);
        } else {
          // Usuário já existe, vamos atualizá-lo com os dados mais recentes
          await _userRepository.update(user);
        }
        
        // Salvar o ID do usuário nas preferências compartilhadas para acesso rápido
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('current_user_id', userId);
        
        return {
          'token': token,
          'email': userEmail,
          'role': userRole,
          'name': userName,
          'userId': userId,
        };
      }
      throw Exception('Falha no login');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Email ou senha incorretos');
      } else if (e.response?.statusCode == 404) {
        throw Exception('Usuário não encontrado');
      } else if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception('Erro de conexão. Verifique sua internet');
      } else {
        throw Exception('Erro ao fazer login. Tente novamente');
      }
    } catch (e) {
      throw Exception('Erro ao fazer login. Tente novamente');
    }
  }


  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      // Obter o FCM token
      final fcmToken = await NotificationService.getFcmToken();
      if (fcmToken == null) {
        throw Exception('Não foi possível obter o token de notificação. Verifique as permissões.');
      }

      print('ApiService: Registrando com FCM token: $fcmToken');

      final response = await _dio.post(
        '$_baseUrl/auth/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'role': role,
          'fcmToken': fcmToken,
        },
      );

      if (response.statusCode == 201) {
        final token = response.data['token'];
        await _tokenService.saveToken(token);
        
        // Criar um objeto User para salvar no banco de dados local
        final userId = DateTime.now().millisecondsSinceEpoch; // ID temporário, será atualizado na sincronização
        final userType = role.toLowerCase() == 'driver' ? UserType.DRIVER : UserType.CUSTOMER;
        
        final user = User(
          id: userId,
          username: email,
          name: name,
          type: userType,
        );
        
        // Salvar o usuário no repositório local
        await _userRepository.save(user);
        
        // Salvar o ID do usuário nas preferências compartilhadas para acesso rápido
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('current_user_id', userId);
        
        return {
          'token': token,
          'name': name,
          'email': email,
          'role': role,
          'userId': userId,
        };
      }
      throw Exception('Falha no registro');
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw Exception('Este email já está cadastrado');
      } else if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception('Erro de conexão. Verifique sua internet');
      } else {
        throw Exception('Erro ao fazer registro. Tente novamente');
      }
    } catch (e) {
      throw Exception('Erro ao fazer registro. Tente novamente');
    }
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      // Primeiro, verificar se temos um usuário atual nas preferências
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('current_user_id');
      
      if (userId != null) {
        // Buscar o usuário no banco de dados local
        final user = await _userRepository.getById(userId);
        if (user != null) {
          return {
            'email': user.username,
            'role': user.type == UserType.DRIVER ? 'DRIVER' : 'CUSTOMER',
            'name': user.name,
            'userId': user.id,
          };
        }
      }
      
      // Se não encontramos no banco local, tentamos validar o token
      final response = await _dio.get('$_baseUrl/validate');
      
      if (response.statusCode == 200) {
        // Como a rota /validate não retorna o nome, vamos buscar do token
        final token = await _tokenService.getToken();
        if (token != null) {
          // Decodificar o token JWT para obter o email
          final parts = token.split('.');
          if (parts.length == 3) {
            final payload = parts[1];
            final normalized = base64Url.normalize(payload);
            final decoded = utf8.decode(base64Url.decode(normalized));
            final data = json.decode(decoded);
            
            final email = data['email'];
            final role = data['role'];
            final name = email.split('@')[0]; // Fallback para nome
            
            // Verificar se o usuário já existe no banco de dados local
            final db = await DatabaseHelper().database;
            final result = await db.query(
              'users',
              where: 'username = ?',
              whereArgs: [email],
              limit: 1,
            );
            
            int newUserId;
            
            if (result.isEmpty) {
              // Usuário não existe localmente, vamos criá-lo
              newUserId = DateTime.now().millisecondsSinceEpoch;
              final userType = role.toLowerCase() == 'driver' ? UserType.DRIVER : UserType.CUSTOMER;
              
              final user = User(
                id: newUserId,
                username: email,
                name: name,
                type: userType,
              );
              
              // Salvar o usuário no repositório local
              await _userRepository.save(user);
              
              // Atualizar preferências compartilhadas
              await prefs.setInt('current_user_id', newUserId);
            } else {
              // Usuário já existe, usar o ID existente
              newUserId = result.first['id'] as int;
              await prefs.setInt('current_user_id', newUserId);
            }
            
            return {
              'email': email,
              'role': role,
              'name': name,
              'userId': newUserId,
            };
          }
        }
        return response.data;
      }
      throw Exception('Falha ao obter dados do usuário');
    } catch (e) {
      throw Exception('Erro ao obter dados do usuário: $e');
    }
  }

  Future<bool> updateFcmToken() async {
    try {
      final fcmToken = await NotificationService.getFcmToken();
      if (fcmToken == null) {
        print('ApiService: Não foi possível obter FCM token para atualização');
        return false;
      }

      print('ApiService: Atualizando FCM token: $fcmToken');

      final response = await _dio.put(
        '$_baseUrl/auth/update-fcm-token',
        data: {
          'fcmToken': fcmToken,
        },
      );

      if (response.statusCode == 200) {
        print('ApiService: FCM token atualizado com sucesso');
        return true;
      }
      return false;
    } catch (e) {
      print('ApiService: Erro ao atualizar FCM token: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> validateToken() async {
    try {
      print('ApiService: Validando token');
      final response = await _dio.post('$_baseUrl/auth/validate');
      return response.data;
    } on DioException catch (e) {
      _handleError(e, 'Erro ao validar token');
      rethrow;
    }
  }

  Future<void> logout() async {
    await _tokenService.deleteToken();
    
    // Limpar o ID do usuário das preferências compartilhadas
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user_id');
  }

  Future<Map<String, dynamic>> checkAuthHealth() async {
    try {
      print('ApiService: Verificando saúde do auth-service');
      final response = await _dio.get('$_baseUrl/auth/health');
      return response.data;
    } on DioException catch (e) {
      _handleError(e, 'Erro ao verificar saúde do auth-service');
      rethrow;
    }
  }

  // ===== ORDER SERVICE METHODS =====

  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> orderData) async {
    try {
      print('ApiService: Criando novo pedido');
      final response = await _dio.post('$_baseUrl/orders', data: orderData);
      return response.data;
    } on DioException catch (e) {
      _handleError(e, 'Erro ao criar pedido');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getOrderById(int id) async {
    try {
      print('ApiService: Buscando pedido $id');
      final response = await _dio.get('$_baseUrl/orders/$id');
      return response.data;
    } on DioException catch (e) {
      _handleError(e, 'Erro ao buscar pedido');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getAllOrders({int page = 0, int size = 10}) async {
    try {
      print('ApiService: Listando todos os pedidos');
      final response = await _dio.get(
        '$_baseUrl/orders',
        queryParameters: {
          'page': page,
          'size': size,
        },
      );
      
      if (response.data is List) {
        // Se a resposta for uma lista direta, converte para o formato esperado
        return {
          'orders': response.data,
          'totalElements': (response.data as List).length,
          'totalPages': 1,
          'currentPage': 0
        };
      } else if (response.data is Map) {
        // Se já for um Map, retorna diretamente
        return response.data;
      } else {
        throw Exception('Formato de resposta inválido');
      }
    } on DioException catch (e) {
      _handleError(e, 'Erro ao listar pedidos');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateOrder(int id, Map<String, dynamic> orderData) async {
    try {
      print('ApiService: Atualizando pedido $id');
      final response = await _dio.put('$_baseUrl/orders/$id', data: orderData);
      return response.data;
    } on DioException catch (e) {
      _handleError(e, 'Erro ao atualizar pedido');
      rethrow;
    }
  }

  Future<void> deleteOrder(int id) async {
    try {
      print('ApiService: Deletando pedido $id');
      await _dio.delete('$_baseUrl/orders/$id');
    } on DioException catch (e) {
      _handleError(e, 'Erro ao deletar pedido');
      rethrow;
    }
  }

  Future<String> checkOrderHealth() async {
    try {
      print('ApiService: Verificando saúde do order-service');
      final response = await _dio.get('$_baseUrl/orders/ok');
      return response.data;
    } on DioException catch (e) {
      _handleError(e, 'Erro ao verificar saúde do order-service');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getOrdersByStatusPaged({
    required String status,
    int page = 0,
    int size = 10,
  }) async {
    try {
      print('ApiService: Buscando pedidos com status $status (página $page, tamanho $size)');
      final response = await _dio.get(
        '$_baseUrl/orders',
        queryParameters: {'status': status, 'page': page, 'size': size},
      );
      
      List<dynamic> orders;
      if (response.data is Map && response.data.containsKey('content')) {
        orders = response.data['content'] as List<dynamic>;
      } else if (response.data is List) {
        orders = response.data as List<dynamic>;
      } else {
        throw Exception('Formato de resposta inválido');
      }
      
      return orders.map((item) => item as Map<String, dynamic>).toList();
    } on DioException catch (e) {
      _handleError(e, 'Erro ao buscar pedidos por status paginado');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getOrdersByDriverId(int driverId, {bool paged = false, int page = 0, int size = 10}) async {
    try {
      print('ApiService: Buscando pedidos do motorista $driverId');
      
      final String endpoint = paged 
          ? '$_baseUrl/orders/driver/$driverId/paged?page=$page&size=$size' 
          : '$_baseUrl/orders/driver/$driverId';
          
      final response = await _dio.get(endpoint);
      
      if (paged) {
        // Se for paginado, o retorno é um objeto com 'content'
        if (response.data is Map && response.data.containsKey('content')) {
          final content = response.data['content'] as List<dynamic>;
          return content.map((item) => item as Map<String, dynamic>).toList();
        } else {
          throw Exception('Formato de resposta inválido');
        }
      } else {
        // Se não for paginado, o retorno é uma lista direta
        if (response.data is List) {
          final orders = response.data as List<dynamic>;
          return orders.map((item) => item as Map<String, dynamic>).toList();
        } else {
          throw Exception('Formato de resposta inválido');
        }
      }
    } on DioException catch (e) {
      _handleError(e, 'Erro ao buscar pedidos do motorista');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> completeOrder(int id, String imageUrl) async {
    try {
      print('ApiService: Finalizando entrega do pedido $id com imagem $imageUrl');
      final response = await _dio.put(
        '$_baseUrl/orders/$id/complete',
        queryParameters: {'imageUrl': imageUrl},
      );
      return response.data;
    } on DioException catch (e) {
      _handleError(e, 'Erro ao finalizar entrega');
      rethrow;
    }
  }

  // ===== TRACKING SERVICE METHODS =====

  Future<void> updateLocation(Map<String, dynamic> locationData) async {
    try {
      print('ApiService: Atualizando localização');
      await _dio.post('$_baseUrl/tracking/location', data: locationData);
    } on DioException catch (e) {
      _handleError(e, 'Erro ao atualizar localização');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getDriverSummary(int driverId) async {
    try {
      print('ApiService: Buscando resumo do motorista $driverId');
      final response = await _dio.get('$_baseUrl/tracking/driver/$driverId/summary');
      return response.data;
    } on DioException catch (e) {
      _handleError(e, 'Erro ao buscar resumo do motorista');
      rethrow;
    }
  }

  Future<bool> isOrderBeingTracked(int orderId) async {
    try {
      print('ApiService: Verificando se pedido $orderId está sendo rastreado');
      final response = await _dio.get('$_baseUrl/tracking/order/$orderId/check');
      
      // A resposta tem a estrutura: { "success": true, "data": { "orderId": 1, "isBeingTracked": true } }
      // Então precisamos acessar response.data['data']['isBeingTracked']
      final isTracked = response.data['data']['isBeingTracked'] ?? false;
      print('ApiService: Resultado do rastreamento: $isTracked');
      return isTracked;
    } on DioException catch (e) {
      print('ApiService: Erro ao verificar status de rastreamento: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getCurrentLocation(int orderId) async {
    try {
      print('ApiService: Buscando localização atual do pedido $orderId');
      final response = await _dio.get('$_baseUrl/tracking/order/$orderId/current');
      return response.data;
    } on DioException catch (e) {
      print('ApiService: Erro ao buscar localização atual: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> getCurrentOrderLocation(int orderId) async {
    try {
      print('ApiService: Buscando localização atual do pedido $orderId');
      final response = await _dio.get('$_baseUrl/tracking/order/$orderId/current');
      return response.data;
    } on DioException catch (e) {
      _handleError(e, 'Erro ao buscar localização atual do pedido');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getOrderLocationHistory(int orderId, {int limit = 50, int offset = 0}) async {
    try {
      print('ApiService: Buscando histórico de localização do pedido $orderId');
      final response = await _dio.get(
        '$_baseUrl/tracking/order/$orderId/history',
        queryParameters: {
          'limit': limit,
          'offset': offset,
        },
      );
      return response.data;
    } on DioException catch (e) {
      _handleError(e, 'Erro ao buscar histórico de localização');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> checkTrackingHealth() async {
    try {
      print('ApiService: Verificando saúde do tracking-service');
      final response = await _dio.get('$_baseUrl/tracking/health');
      return response.data;
    } on DioException catch (e) {
      _handleError(e, 'Erro ao verificar saúde do tracking-service');
      rethrow;
    }
  }

  // ===== ERROR HANDLING =====

  void _handleError(DioException e, String context) {
    print('ApiService: Handling error - Type: ${e.type}, Message: ${e.message}');

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        throw Exception('Timeout de conexão. Verifique se o servidor está rodando.');
      case DioExceptionType.sendTimeout:
        throw Exception('Timeout ao enviar dados. Tente novamente.');
      case DioExceptionType.receiveTimeout:
        throw Exception('Timeout ao receber resposta. Tente novamente.');
      case DioExceptionType.connectionError:
        throw Exception('Erro de conexão. Verifique sua internet e se o servidor está acessível.');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode == 401) {
          throw Exception('Não autorizado. Faça login novamente.');
        } else if (statusCode == 404) {
          throw Exception('Recurso não encontrado');
        } else if (statusCode == 422) {
          final errors = e.response?.data['errors'] ?? e.response?.data['message'];
          throw Exception('Dados inválidos: $errors');
        } else {
          throw Exception('Erro do servidor ($statusCode): ${e.response?.data}');
        }
      case DioExceptionType.cancel:
        throw Exception('Requisição cancelada');
      case DioExceptionType.unknown:
        throw Exception('Erro desconhecido: ${e.message}');
      case DioExceptionType.badCertificate:
        throw Exception('Erro de certificado SSL');
    }
  }

  // ===== HEALTH CHECK =====

  Future<bool> checkHealth() async {
    try {
      print('ApiService: Verificando saúde do servidor...');
      final response = await _dio.get(
        '$_baseUrl/orders/ok',
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      print('ApiService: Servidor está saudável!');
      return response.statusCode == 200;
    } catch (e) {
      print('ApiService: Servidor não está respondendo: $e');
      return false;
    }
  }

  // ===== TESTE DE CONECTIVIDADE =====

  Future<void> testConnection() async {
    print('ApiService: Testando conectividade...');
    print('ApiService: URL base: $_baseUrl');

    try {
      // Teste simples de conectividade
      final response = await _dio.get(
        '$_baseUrl/orders/ok',
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      print('ApiService: Teste de conectividade PASSOU ✅');
      print('ApiService: Status: ${response.statusCode}');
    } catch (e) {
      print('ApiService: Teste de conectividade FALHOU ❌');
      print('ApiService: Erro: $e');
      rethrow;
    }
  }

  // Buscar usuário por ID no auth-service
  Future<Map<String, dynamic>?> getUserById(int userId) async {
    try {
      final response = await _dio.get('$_baseUrl/auth/user/$userId');
      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      print('ApiService: Erro ao buscar usuário $userId: $e');
      return null;
    }
  }

  // Completar entrega com body customizado
  Future<int> completeOrderWithBody(int orderId, Map<String, dynamic> body) async {
    try {
      final response = await _dio.put(
        '$_baseUrl/orders/$orderId/complete',
        data: body,
        options: Options(contentType: Headers.jsonContentType),
      );
      return response.statusCode == 200 ? 1 : 0;
    } catch (e) {
      print('ApiService: Erro ao completar entrega: $e');
      return 0;
    }
  }
}