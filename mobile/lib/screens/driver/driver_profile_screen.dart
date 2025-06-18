import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../database/repository/UserRepository.dart';
import '../../database/repository/settings_repository.dart';
import '../../models/user.dart';
import '../../models/settings.dart';
import '../../widgets/common/app_bar_widget.dart';

class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  final UserRepository _userRepository = UserRepository();
  final SettingsRepository _settingsRepository = SettingsRepository();
  User? _currentUser;
  Settings? _userSettings;
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
          });

          // Carregar configurações do usuário
          final settings = await _settingsRepository.getSettingsByUserId(userId);
          if (settings != null) {
            setState(() {
              _userSettings = settings;
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

        // Em um aplicativo real, você atualizaria o tema do aplicativo aqui
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
          SnackBar(content: Text('${value ? 'Mostrar' : 'Ocultar'} pedidos concluídos')),
        );
      }
    } catch (e) {
      print('Erro ao atualizar configuração: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar configurações: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentUser == null
              ? const Center(
                  child: Text('Usuário não encontrado'),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Foto de perfil (avatar)
                      const CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.blue,
                        child: Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Nome do usuário
                      Text(
                        _currentUser!.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _currentUser!.username,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Tipo de usuário
                      Chip(
                        backgroundColor: Colors.blue[100],
                        label: Text(
                          _currentUser!.type == UserType.DRIVER ? 'Motorista' : 'Cliente',
                          style: TextStyle(
                            color: Colors.blue[800],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        avatar: Icon(
                          _currentUser!.type == UserType.DRIVER
                              ? Icons.directions_car
                              : Icons.person,
                          color: Colors.blue[800],
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Seção de configurações
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
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
                            
                            // Configuração de tema
                            SwitchListTile(
                              title: const Text('Tema Escuro'),
                              subtitle: const Text('Alterar para tema escuro'),
                              value: _isDarkMode,
                              onChanged: _toggleTheme,
                              secondary: Icon(
                                _isDarkMode ? Icons.dark_mode : Icons.light_mode,
                              ),
                            ),
                            
                            const Divider(),
                            
                            // Configuração para mostrar pedidos concluídos
                            SwitchListTile(
                              title: const Text('Mostrar Pedidos Concluídos'),
                              subtitle: const Text('Exibir pedidos já finalizados'),
                              value: _showCompletedOrders,
                              onChanged: _toggleShowCompletedOrders,
                              secondary: const Icon(Icons.visibility),
                            ),
                            
                            const Divider(),
                            
                            // Outras configurações podem ser adicionadas aqui
                            ListTile(
                              leading: const Icon(Icons.notifications),
                              title: const Text('Notificações'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                // Navegação para configurações de notificação
                              },
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Botão para atualizar dados
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _loadUserData,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Atualizar Dados'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 2, // Perfil é o terceiro item
        onTap: (index) {
          // lógica de navegação
        },
      ),
    );
  }
}