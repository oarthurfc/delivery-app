import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'auth/login_screen.dart';
import 'client/client_home_screen.dart';
import 'driver/driver_home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    print('SplashScreen: Iniciando verificação de autenticação');
    await Future.delayed(const Duration(seconds: 2)); // Simula carregamento
    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();
    await authProvider.checkAuthStatus();
    print('SplashScreen: Status de autenticação: ${authProvider.isAuthenticated}');
    print('SplashScreen: Dados do usuário: ${authProvider.user}');

    if (!mounted) return;

    if (authProvider.isAuthenticated) {
      // Redireciona baseado no papel do usuário
      final userRole = authProvider.user?['role'];
      print('SplashScreen: Papel do usuário: $userRole');
      
      if (userRole == 'driver') {
        print('SplashScreen: Redirecionando para tela do motorista');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DriverHomeScreen()),
        );
      } else {
        print('SplashScreen: Redirecionando para tela do cliente');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ClienteHomePage()),
        );
      }
    } else {
      print('SplashScreen: Redirecionando para tela de login');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Temporariamente removendo a imagem para debug
            const Icon(
              Icons.delivery_dining,
              size: 150,
              color: Colors.blue,
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
} 