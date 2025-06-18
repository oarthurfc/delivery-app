import 'package:dio/dio.dart';
import 'token_service.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/repository/UserRepository.dart';
import '../models/user.dart';
import '../database/database_helper.dart';

class AuthService {
  final Dio _dio = Dio();
  final TokenService _tokenService = TokenService();
  final UserRepository _userRepository = UserRepository();
  
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
    return 'https://8513-191-185-84-176.ngrok-free.app/api';
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
          
          final role = data['role'];
          final name = data['email'].split('@')[0]; // Fallback para nome
          
          // Verificar se o usuário já existe no banco de dados local
          final db = await DatabaseHelper().database;
          final result = await db.query(
            'users',
            where: 'username = ?',
            whereArgs: [email],
            limit: 1,
          );
          
          int userId;
          
          if (result.isEmpty) {
            // Usuário não existe localmente, vamos criá-lo
            userId = DateTime.now().millisecondsSinceEpoch;
            final userType = role.toLowerCase() == 'driver' ? UserType.DRIVER : UserType.CUSTOMER;
            
            final user = User(
              id: userId,
              username: email,
              name: name,
              type: userType,
            );
            
            // Salvar o usuário no repositório local
            await _userRepository.save(user);
          } else {
            // Usuário já existe, usar o ID existente
            userId = result.first['id'] as int;
          }
          
          // Salvar o ID do usuário nas preferências compartilhadas para acesso rápido
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('current_user_id', userId);
          
          return {
            'token': token,
            'email': data['email'],
            'role': role,
            'name': name,
            'userId': userId,
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
  Future<void> logout() async {
    await _tokenService.deleteToken();
    
    // Limpar o ID do usuário das preferências compartilhadas
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user_id');
  }
} 