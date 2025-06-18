// Implementação do repositório para Settings
import 'package:delivery/database/database_helper.dart';
import 'package:delivery/models/settings.dart';
import 'package:sqflite/sqflite.dart';

class SettingsRepository {
  final String tableName = 'settings';
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Método específico para buscar configurações pelo ID do usuário
  Future<Settings?> getSettingsByUserId(int userId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    
    if (maps.isEmpty) {
      // Se não existir, criar configurações padrão
      final defaultSettings = Settings(
        userId: userId,
        isDarkTheme: false,
        showCompletedOrders: true,
      );
      await saveSettings(defaultSettings);
      return defaultSettings;
    }
    
    return Settings.fromMap(maps.first);
  }

  // Salvar as configurações
  Future<int> saveSettings(Settings settings) async {
    final db = await _dbHelper.database;
    
    return await db.insert(
      tableName,
      {
        'user_id': settings.userId,
        'is_dark_theme': settings.isDarkTheme ? 1 : 0,
        'show_completed_orders': settings.showCompletedOrders ? 1 : 0,
        'sync_status': 'SYNCED',
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Atualizar as configurações do usuário
  Future<int> updateSettings(int userId, bool isDarkTheme, bool showCompletedOrders) async {
    final db = await _dbHelper.database;
    
    final settings = {
      'is_dark_theme': isDarkTheme ? 1 : 0,
      'show_completed_orders': showCompletedOrders ? 1 : 0,
      'sync_status': 'PENDING_UPDATE',
    };
    
    return await db.update(
      tableName,
      settings,
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  // Criar nova configuração com base nos valores fornecidos
  Future<Settings> createSettings(int userId, {bool isDarkTheme = false, bool showCompletedOrders = true}) async {
    final settings = Settings(
      userId: userId,
      isDarkTheme: isDarkTheme,
      showCompletedOrders: showCompletedOrders,
    );
    
    await saveSettings(settings);
    return settings;
  }
}
