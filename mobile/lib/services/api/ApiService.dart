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
    return 'http://$_localIp:$_port/api';
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

  // ===== ORDERS API =====
  
  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> orderData) async {
    try {
      print('ApiService: Enviando pedido para ${_baseUrl}/orders');
      final response = await _dio.post('$_baseUrl/orders', data: orderData);
      return response.data;
    } on DioException catch (e) {
      print('ApiService: Erro detalhado - ${e.type}: ${e.message}');
      _handleError(e, 'Erro ao criar pedido');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getOrderById(int id) async {
    try {
      final response = await _dio.get('$_baseUrl/orders/$id');
      return response.data;
    } on DioException catch (e) {
      _handleError(e, 'Erro ao buscar pedido');
      rethrow;
    }
  }

  Future<List<dynamic>> getAllOrders({int page = 0, int size = 20}) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/orders',
        queryParameters: {'page': page, 'size': size},
      );
      
      // Se for paginado, extrair o conteúdo
      if (response.data is Map && response.data.containsKey('content')) {
        return response.data['content'];
      }
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      _handleError(e, 'Erro ao listar pedidos');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateOrder(int id, Map<String, dynamic> orderData) async {
    try {
      final response = await _dio.put('$_baseUrl/orders/$id', data: orderData);
      return response.data;
    } on DioException catch (e) {
      _handleError(e, 'Erro ao atualizar pedido');
      rethrow;
    }
  }

  Future<void> deleteOrder(int id) async {
    try {
      await _dio.delete('$_baseUrl/orders/$id');
    } on DioException catch (e) {
      _handleError(e, 'Erro ao deletar pedido');
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
}