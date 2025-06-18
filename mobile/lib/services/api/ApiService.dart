import 'package:delivery/services/token_service.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiService {
  final Dio _dio = Dio();
  final TokenService _tokenService = TokenService();

  // Configuração de ambiente
  static const bool runningOnEmulator = true;
  static const String _localIp = '192.168.167.87';
  static const String _emulatorIp = '10.0.2.2';
  static const int _port = 8000; // Porta do API Gateway

  String get _baseUrl {
    if (kIsWeb) {
      return 'http://localhost:$_port/api';
    } else if (Platform.isAndroid && runningOnEmulator) {
      return 'http://$_emulatorIp:$_port/api';
    }
    return 'https://8513-191-185-84-176.ngrok-free.app/api';
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

  // ===== AUTH SERVICE API =====

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      print('ApiService: Realizando login');
      final response = await _dio.post(
        '$_baseUrl/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );
      return response.data;
    } on DioException catch (e) {
      _handleError(e, 'Erro ao fazer login');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      print('ApiService: Registrando novo usuário');
      final response = await _dio.post(
        '$_baseUrl/auth/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'role': role,
        },
      );
      return response.data;
    } on DioException catch (e) {
      _handleError(e, 'Erro ao registrar usuário');
      rethrow;
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

  // ===== ORDER SERVICE API =====

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

  // ===== TRACKING SERVICE API =====

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
      final response = await _dio.get('$_baseUrl/tracking/order/$orderId/status');
      return response.data['isTracking'] ?? false;
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

  // ===== ERROR HANDLING MELHORADO =====

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

  // Buscar pedidos por status com paginação
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
}