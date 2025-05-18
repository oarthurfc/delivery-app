// Serviço de sincronização que roda periodicamente
import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:delivery/database/repository/SyncableRepository.dart';

class SyncService {
  final List<SyncableRepository> repositories;
  Timer? _syncTimer;
  final StreamController<bool> _syncController = StreamController<bool>.broadcast();
  
  Stream<bool> get syncStream => _syncController.stream;
  
  SyncService(this.repositories);
  
  // Iniciar sincronização automática
  void startPeriodicSync({Duration duration = const Duration(minutes: 15)}) {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(duration, (_) => syncAll());
    
    // Monitorar conectividade e sincronizar quando ficar online
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.any((result) => result != ConnectivityResult.none)) {
        syncAll();
      }
    });
  }
  
  // Parar sincronização automática
  void stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }
  
  // Sincronizar todos os repositórios
  Future<void> syncAll() async {
    try {
      _syncController.add(true); // Indicar início da sincronização
      
      for (var repository in repositories) {
        await repository.syncWithServer();
      }
      
      _syncController.add(false); // Indicar fim da sincronização
    } catch (e) {
      print('Erro na sincronização: $e');
      _syncController.add(false);
    }
  }
  
  // Liberar recursos ao encerrar
  void dispose() {
    stopPeriodicSync();
    _syncController.close();
  }
}