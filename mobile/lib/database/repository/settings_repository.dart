// // Implementação do repositório para Settings
// import 'package:delivery/database/database_helper.dart';
// import 'package:delivery/database/repository/SyncableRepository.dart';
// import 'package:delivery/models/settings.dart';

// class SettingsRepository extends SyncableRepository<Settings> {
//   SettingsRepository() : super('settings');


//    @override
//   Settings fromMap(Map<String, dynamic> map) => Settings.fromMap(map);

//   @override
//   Map<String, dynamic> toMap(Settings settings) => settings.toMap();

//   @override
//   int getId(Settings settings) => settings.id;

//   @override
//   Future<void> syncWithServer() async {
//     final db = await DatabaseHelper().database;

//     final unsynced = await db.query(
//       tableName,
//       where: 'sync_status != ?',
//       whereArgs: ['SYNCED'],
//     );

//     for (final map in unsynced) {
//       final settings = fromMap(map);
//       final syncStatus = map['sync_status'];

//       try {
//         if (syncStatus == 'PENDING_SYNC') {
//           // POST
//         } else if (syncStatus == 'PENDING_UPDATE') {
//           // PUT
//         } else if (syncStatus == 'PENDING_DELETE') {
//           // DELETE
//         }

//         await db.update(
//           tableName,
//           {'sync_status': 'SYNCED'},
//           where: 'id = ?',
//           whereArgs: [settings.id],
//         );
//       } catch (e) {
//         print('Erro ao sincronizar configurações ${settings.id}: $e');
//       }
//     }
//   }
// }
