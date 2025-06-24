import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/token_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final TokenService _tokenService = TokenService();
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _user;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get user => _user;

  AuthProvider() {
    print('AuthProvider: Inicializando...');
    checkAuthStatus();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> checkAuthStatus() async {
    print('AuthProvider: Verificando status de autenticação');
    _isLoading = true;
    notifyListeners();

    try {
      final hasToken = await _tokenService.hasToken();
      print('AuthProvider: Token existe? $hasToken');
      
      if (hasToken) {
        // Tenta obter dados do usuário
        _user = await _authService.getCurrentUser();
        print('AuthProvider: Dados do usuário obtidos: $_user');
        _isAuthenticated = true;
      } else {
        _isAuthenticated = false;
        _user = null;
      }
    } catch (e) {
      print('AuthProvider: Erro ao verificar autenticação: $e');
      // Se houver erro ao verificar token, considera não autenticado
      _isAuthenticated = false;
      _user = null;
      await _tokenService.deleteToken();
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _authService.login(email, password);
      _user = {
        'email': email,
        'role': response['role'] ?? 'customer',
        'name': response['name'] ?? email.split('@')[0],
      };
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      _user = null;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('AuthProvider: Iniciando registro com FCM token');
      final response = await _authService.register(
        name: name,
        email: email,
        password: password,
        role: role,
      );
      _user = {
        'email': email,
        'role': role,
        'name': name,
      };
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      _user = null;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateFcmToken() async {
    try {
      print('AuthProvider: Atualizando FCM token');
      final success = await _authService.updateFcmToken();
      if (success) {
        print('AuthProvider: FCM token atualizado com sucesso');
      } else {
        print('AuthProvider: Falha ao atualizar FCM token');
      }
      return success;
    } catch (e) {
      print('AuthProvider: Erro ao atualizar FCM token: $e');
      return false;
    }
  }

  Future<void> logout() async {
    print('AuthProvider: Iniciando logout');
    await _authService.logout();
    _isAuthenticated = false;
    _user = null;
    notifyListeners();
  }
} 