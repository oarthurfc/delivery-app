// Classe base para operações CRUD com sincronização
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:delivery/database/database_helper.dart';
import 'package:sqflite/sqflite.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

abstract class SyncableRepository<T> {
  final String tableName;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  SyncableRepository(this.tableName);

  // Converte objeto para map para armazenar no banco
  Map<String, dynamic> toMap(T item);
  
  // Converte map do banco para objeto
  T fromMap(Map<String, dynamic> map);
  
  // ID do item para identificação
  int getId(T item);

  // Salva um item no banco local e marca para sincronização
  Future<int> save(T item) async {
    final db = await _dbHelper.database;
    final map = toMap(item);
    map['sync_status'] = SyncStatus.PENDING_SYNC.toString().split('.').last;
    
    // Insere ou atualiza o registro
    int id = await db.insert(
      tableName,
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    // Adiciona ao log de sincronização
    await _addToSyncLog(id, 'INSERT');
    
    // Tenta sincronizar imediatamente se estiver online
    _trySyncNow();
    
    return id;
  }

  // Atualiza um item existente
  Future<int> update(T item) async {
    final db = await _dbHelper.database;
    final map = toMap(item);
    final id = getId(item);
    map['sync_status'] = SyncStatus.PENDING_UPDATE.toString().split('.').last;
    
    int result = await db.update(
      tableName,
      map,
      where: 'id = ?',
      whereArgs: [id],
    );
    
    await _addToSyncLog(id, 'UPDATE');
    _trySyncNow();
    
    return result;
  }

  // Deleta um item do banco
  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    
    // Primeiro marcamos como pendente de exclusão
    await db.update(
      tableName,
      {'sync_status': SyncStatus.PENDING_DELETE.toString().split('.').last},
      where: 'id = ?',
      whereArgs: [id],
    );
    
    await _addToSyncLog(id, 'DELETE');
    _trySyncNow();
    
    // Não removemos fisicamente até sincronizar
    return 1;
  }

  // Obtém um item por ID
  Future<T?> getById(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isEmpty) return null;
    return fromMap(maps.first);
  }

  // Lista todos os itens
  Future<List<T>> getAll() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(tableName);
    
    return List.generate(maps.length, (i) => fromMap(maps[i]));
  }

  // Adiciona registro no log de sincronização
  Future<void> _addToSyncLog(int recordId, String action) async {
    final db = await _dbHelper.database;
    await db.insert(
      'sync_log',
      {
        'table_name': tableName,
        'record_id': recordId,
        'action': action,
        'timestamp': DateTime.now().toIso8601String()
      },
    );
  }

  // Tenta sincronizar agora se estiver online
  Future<void> _trySyncNow() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult != ConnectivityResult.none) {
      syncWithServer();
    }
  }

  // Sincroniza com o servidor
  Future<void> syncWithServer() async {
    try {
      final db = await _dbHelper.database;
      
      // Busca registros pendentes de sincronização
      final pending = await db.query(
        tableName,
        where: "sync_status != ?",
        whereArgs: [SyncStatus.SYNCED.toString().split('.').last],
      );
      
      for (var record in pending) {
        final syncStatus = SyncStatus.values.firstWhere(
          (e) => e.toString().split('.').last == record['sync_status'],
          orElse: () => SyncStatus.SYNCED,
        );
        
        final recordId = record['id'] as int;
        
        switch (syncStatus) {
          case SyncStatus.PENDING_SYNC:
            await _createOnServer(record);
            break;
          case SyncStatus.PENDING_UPDATE:
            await _updateOnServer(record);
            break;
          case SyncStatus.PENDING_DELETE:
            await _deleteOnServer(recordId);
            break;
          default:
            break;
        }
        
        // Atualiza o status para sincronizado
        if (syncStatus != SyncStatus.PENDING_DELETE) {
          await db.update(
            tableName,
            {'sync_status': SyncStatus.SYNCED.toString().split('.').last},
            where: 'id = ?',
            whereArgs: [recordId],
          );
        } else {
          // Se era para deletar, agora podemos remover fisicamente
          await db.delete(
            tableName,
            where: 'id = ?',
            whereArgs: [recordId],
          );
        }
      }
      
      // Obtém dados novos do servidor
      await _fetchFromServer();
      
    } catch (e) {
      print('Erro ao sincronizar com o servidor: $e');
      // Aqui poderia implementar retry ou notificação para o usuário
    }
  }
  
  // Envia novo registro para o servidor
  Future<void> _createOnServer(Map<String, dynamic> record) async {
    // Remove o status de sincronização antes de enviar
    record.remove('sync_status');
    
    final response = await http.post(
      Uri.parse('$apiBaseUrl/$tableName'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(record),
    );
    
    if (response.statusCode != 201) {
      throw Exception('Falha ao criar registro no servidor');
    }
  }
  
  // Atualiza registro no servidor
  Future<void> _updateOnServer(Map<String, dynamic> record) async {
    record.remove('sync_status');
    final id = record['id'];
    
    final response = await http.put(
      Uri.parse('$apiBaseUrl/$tableName/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(record),
    );
    
    if (response.statusCode != 200) {
      throw Exception('Falha ao atualizar registro no servidor');
    }
  }
  
  // Exclui registro no servidor
  Future<void> _deleteOnServer(int id) async {
    final response = await http.delete(
      Uri.parse('$apiBaseUrl/$tableName/$id'),
    );
    
    if (response.statusCode != 200) {
      throw Exception('Falha ao excluir registro no servidor');
    }
  }
  
  // Busca todos os dados do servidor
  Future<void> _fetchFromServer() async {
    final db = await _dbHelper.database;
    final response = await http.get(Uri.parse('$apiBaseUrl/$tableName'));
    
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      
      // Obtém o timestamp da última sincronização
      final prefs = await SharedPreferences.getInstance();
      final lastSync = prefs.getString('last_sync_$tableName');
      
      for (var item in data) {
        // Verifica se o item foi atualizado após a última sincronização
        if (lastSync == null || item['updated_at'].toString().compareTo(lastSync) > 0) {
          // Verifica se o registro já existe localmente
          final existingRecords = await db.query(
            tableName,
            where: 'id = ?',
            whereArgs: [item['id']],
          );
          
          if (existingRecords.isEmpty) {
            // Insere novo registro
            item['sync_status'] = SyncStatus.SYNCED.toString().split('.').last;
            await db.insert(tableName, Map<String, dynamic>.from(item));
          } else {
            // Só atualiza se não tiver alterações locais pendentes
            final existing = existingRecords.first;
            final localStatus = existing['sync_status'].toString();
            
            if (localStatus == SyncStatus.SYNCED.toString().split('.').last) {
              item['sync_status'] = SyncStatus.SYNCED.toString().split('.').last;
              await db.update(
                tableName,
                Map<String, dynamic>.from(item),
                where: 'id = ?',
                whereArgs: [item['id']],
              );
            }
          }
        }
      }
      
      // Atualiza timestamp da sincronização
      await prefs.setString('last_sync_$tableName', DateTime.now().toIso8601String());
    } else {
      throw Exception('Falha ao obter dados do servidor');
    }
  }
}
