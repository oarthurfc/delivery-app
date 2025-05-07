import 'package:flutter/material.dart';
import 'config/theme_config.dart';
import 'config/routes.dart';
import 'services/theme_service.dart';
import 'screens/client/client_home_screen.dart';
import 'screens/driver/driver_home_screen.dart';

class DeliveryApp extends StatefulWidget {
  final ThemeService themeService;

  const DeliveryApp({Key? key, required this.themeService}) : super(key: key);

  @override
  State<DeliveryApp> createState() => _DeliveryAppState();
}

class _DeliveryAppState extends State<DeliveryApp> {
  late bool _isDarkMode;
  bool _isDriver = false; // Para alternar entre visualizações de cliente e motorista

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.themeService.isDarkMode;
    widget.themeService.addListener(() {
      setState(() {
        _isDarkMode = widget.themeService.isDarkMode;
      });
    });
  }

  void _toggleUserMode() {
    setState(() {
      _isDriver = !_isDriver;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DeliveryApp',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      debugShowCheckedModeBanner: false,
      //routes: appRoutes,
      home: Scaffold(
        appBar: AppBar(
          title: Text(_isDriver ? 'EntregasApp - Motorista' : 'EntregasApp - Cliente'),
          actions: [
            IconButton(
              icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
              onPressed: () {
                widget.themeService.toggleTheme();
              },
            ),
            IconButton(
              icon: Icon(_isDriver ? Icons.person : Icons.delivery_dining),
              onPressed: _toggleUserMode,
              tooltip: 'Alternar entre cliente e motorista',
            ),
          ],
        ),
        body: _isDriver ? DriverHomeScreen() : ClienteHomePage(),
      ),
    );
  }
}