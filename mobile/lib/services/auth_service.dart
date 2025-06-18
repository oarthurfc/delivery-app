import 'package:dio/dio.dart';
import 'token_service.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

class AuthService {
  final Dio _dio = Dio();
  final TokenService _tokenService = TokenService();
  
  // Altere esta flag para true se estiver rodando no emulador Android Studio
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
    return 'http://$_localIp:$_port/api';
  }

  AuthService() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          print('AuthService: Request URL: ${options.uri}');
          print('AuthService: Request Headers: ${options.headers}');
          print('AuthService: Request Data: ${options.data}');
          
          final token = await _tokenService.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print('AuthService: Response Status: ${response.statusCode}');
          print('AuthService: Response Data: ${response.data}');
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          print('AuthService: Error: ${e.message}');
          print('AuthService: Error Response: ${e.response?.data}');
          return handler.next(e);
        },
      ),
    );
  }

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
        await _tokenService.saveToken(token);
        
        // Decodificar o token JWT para obter informações do usuário
        final parts = token.split('.');
        if (parts.length == 3) {
          final payload = parts[1];
          final normalized = base64Url.normalize(payload);
          final decoded = utf8.decode(base64Url.decode(normalized));
          final data = json.decode(decoded);
          
          return {
            'token': token,
            'email': data['email'],
            'role': data['role'],
            'name': data['email'].split('@')[0], // Fallback para nome
          };
        }
        
        return response.data;
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
      final response = await _dio.post(
        '$_baseUrl/auth/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'role': role,
        },
      );

      if (response.statusCode == 201) {
        final token = response.data['token'];
        await _tokenService.saveToken(token);
        return {
          'token': token,
          'name': name,
          'email': email,
          'role': role,
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
            
            return {
              'email': data['email'],
              'role': data['role'],
              'name': data['email'].split('@')[0], // Fallback para nome
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

  Future<void> logout() async {
    await _tokenService.deleteToken();
  }
} 