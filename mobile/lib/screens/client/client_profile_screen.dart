import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../database/repository/UserRepository.dart';
import '../../database/repository/settings_repository.dart';
import '../../models/user.dart';
import '../../widgets/common/app_bar_widget.dart';

class ClientProfileScreen extends StatefulWidget {
  const ClientProfileScreen({super.key});

  @override
  State<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen> {
  final UserRepository _userRepository = UserRepository();  final SettingsRepository _settingsRepository = SettingsRepository();
  User? _currentUser;
  bool _isLoading = true;
  bool _isDarkMode = false;
  bool _showCompletedOrders = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('current_user_id');

      if (userId != null) {
        final user = await _userRepository.getById(userId);
        if (user != null) {
          setState(() {
            _currentUser = user;
          });          // Carregar configurações do usuário
          final settings = await _settingsRepository.getSettingsByUserId(userId);
          if (settings != null) {
            setState(() {
              _isDarkMode = settings.isDarkTheme;
              _showCompletedOrders = settings.showCompletedOrders;
            });
          }
        }
      }
    } catch (e) {
      print('Erro ao carregar dados do usuário: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleTheme(bool value) async {
    try {
      if (_currentUser != null) {
        await _settingsRepository.updateSettings(
          _currentUser!.id,
          value,
          _showCompletedOrders,
        );

        setState(() {
          _isDarkMode = value;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tema ${value ? 'escuro' : 'claro'} ativado')),
        );
      }
    } catch (e) {
      print('Erro ao atualizar tema: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar configurações: $e')),
      );
    }
  }

  Future<void> _toggleShowCompletedOrders(bool value) async {
    try {
      if (_currentUser != null) {
        await _settingsRepository.updateSettings(
          _currentUser!.id,
          _isDarkMode,
          value,
        );

        setState(() {
          _showCompletedOrders = value;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${value ? 'Mostrando' : 'Ocultando'} pedidos concluídos')),
        );
      }
    } catch (e) {
      print('Erro ao atualizar configuração de pedidos: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar configurações: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Informações do usuário
                  Card(
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Informações do Usuário',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Icon(Icons.person, size: 24),
                              const SizedBox(width: 8),
                              Text(
                                'Nome: ${_currentUser?.name ?? 'Não disponível'}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.alternate_email, size: 24),
                              const SizedBox(width: 8),
                              Text(
                                'Usuário: ${_currentUser?.username ?? 'Não disponível'}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.category, size: 24),
                              const SizedBox(width: 8),
                              Text(
                                'Tipo: Cliente',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Configurações
                  Card(
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Configurações',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SwitchListTile(
                            title: const Text('Tema Escuro'),
                            subtitle: const Text(
                              'Ativar tema escuro para o aplicativo',
                            ),
                            value: _isDarkMode,
                            onChanged: _toggleTheme,
                          ),
                          const Divider(),
                          SwitchListTile(
                            title: const Text('Mostrar Pedidos Concluídos'),
                            subtitle: const Text(
                              'Exibir pedidos já concluídos no histórico',
                            ),
                            value: _showCompletedOrders,
                            onChanged: _toggleShowCompletedOrders,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Ajuda e Suporte
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ajuda e Suporte',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ListTile(
                            leading: const Icon(Icons.help_outline),
                            title: const Text('Central de Ajuda'),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              // Navegar para a central de ajuda
                            },
                          ),
                          const Divider(),
                          ListTile(
                            leading: const Icon(Icons.mail_outline),
                            title: const Text('Contato'),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              // Navegar para a página de contato
                            },
                          ),
                          const Divider(),
                          ListTile(
                            leading: const Icon(Icons.info_outline),
                            title: const Text('Sobre o App'),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              // Mostrar informações sobre o aplicativo
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 2, // Índice correspondente à tela de perfil
        onTap: (index) {
          // Lógica de navegação
        },
      ),
    );
  }
}
