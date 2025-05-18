// Implementação do repositório para User
import 'package:delivery/database/database_helper.dart';
import 'package:delivery/database/repository/SyncableRepository.dart';
import 'package:delivery/models/user.dart';

class UserRepository extends SyncableRepository<User> {
  UserRepository() : super('users');

  @override
  User fromMap(Map<String, dynamic> map) => User.fromMap(map);

  @override
  Map<String, dynamic> toMap(User user) => user.toMap();

  @override
  int getId(User user) => user.id;

  @override
  Future<void> syncWithServer() async {
    final db = await DatabaseHelper().database;

    final unsynced = await db.query(
      tableName,
      where: 'sync_status != ?',
      whereArgs: ['SYNCED'],
    );

    for (final map in unsynced) {
      final user = fromMap(map);
      final syncStatus = map['sync_status'];

      try {
        if (syncStatus == 'PENDING_SYNC') {
          // POST
        } else if (syncStatus == 'PENDING_UPDATE') {
          // PUT
        } else if (syncStatus == 'PENDING_DELETE') {
          // DELETE
        }

        await db.update(
          tableName,
          {'sync_status': 'SYNCED'},
          where: 'id = ?',
          whereArgs: [user.id],
        );
      } catch (e) {
        print('Erro ao sincronizar usuário ${user.id}: $e');
      }
    }
  }
}
