// Implementação do repositório para NotificationPreference
import 'package:delivery/database/database_helper.dart';
import 'package:delivery/database/repository/SyncableRepository.dart';
import 'package:delivery/models/notification_preference.dart';

class NotificationPreferenceRepository extends SyncableRepository<NotificationPreference> {
  NotificationPreferenceRepository() : super('notification_preferences');

  // @override
  // Map<String, dynamic> toMap(NotificationPreference pref) {
  //   return {
  //     'id': pref.id,
  //     'user_id': pref.userId,
  //     'email_enabled': pref.emailEnabled ? 1 : 0,
  //     'push_enabled': pref.pushEnabled ? 1 : 0,
  //     'created_at': pref.createdAt.toIso8601String(),
  //     'updated_at': pref.updatedAt.toIso8601String(),
  //   };
  // }

  // @override
  // NotificationPreference fromMap(Map<String, dynamic> map) {
  //   return NotificationPreference(
  //     id: map['id'],
  //     userId: map['user_id'],
  //     emailEnabled: map['email_enabled'] == 1,
  //     pushEnabled: map['push_enabled'] == 1,
  //     createdAt: DateTime.parse(map['created_at']),
  //     updatedAt: DateTime.parse(map['updated_at']),
  //   );
  // }

  @override
  NotificationPreference fromMap(Map<String, dynamic> map) => NotificationPreference.fromMap(map);

  @override
  Map<String, dynamic> toMap(NotificationPreference notificationPreference) => notificationPreference.toMap();

  @override
  int getId(NotificationPreference pref) => pref.id;

  @override
  Future<void> syncWithServer() async {
    final db =  await DatabaseHelper().database;

    final unsynced = await db.query(
      tableName,
      where: 'sync_status != ?',
      whereArgs: ['SYNCED'],
    );

    for (final map in unsynced) {
      final pref = fromMap(map);
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
          whereArgs: [pref.id],
        );
      } catch (e) {
        print('Erro ao sincronizar preferências ${pref.id}: $e');
      }
    }
  }
}
