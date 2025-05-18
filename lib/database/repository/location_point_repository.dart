// Implementação do repositório para LocationPoint
import 'package:delivery/database/database_helper.dart';
import 'package:delivery/database/repository/SyncableRepository.dart';
import 'package:delivery/models/location_point.dart';

class LocationPointRepository extends SyncableRepository<LocationPoint> {
  LocationPointRepository() : super('location_points');

  // @override
  // Map<String, dynamic> toMap(LocationPoint point) {
  //   return {
  //     'id': point.id,
  //     'latitude': point.latitude,
  //     'longitude': point.longitude,
  //     'timestamp': point.timestamp.toIso8601String(),
  //     'created_at': point.createdAt.toIso8601String(),
  //     'updated_at': point.updatedAt.toIso8601String(),
  //   };
  // }

  // @override
  // LocationPoint fromMap(Map<String, dynamic> map) {
  //   return LocationPoint(
  //     id: map['id'],
  //     latitude: map['latitude'],
  //     longitude: map['longitude'],
  //     timestamp: DateTime.parse(map['timestamp']),
  //     createdAt: DateTime.parse(map['created_at']),
  //     updatedAt: DateTime.parse(map['updated_at']),
  //   );
  // }

@override
  LocationPoint fromMap(Map<String, dynamic> map) => LocationPoint.fromMap(map);

  @override
  Map<String, dynamic> toMap(LocationPoint locationPoint) => locationPoint.toMap();
  

  @override
  int getId(LocationPoint point) => point.id;

  @override
  Future<void> syncWithServer() async {
    final db = await DatabaseHelper().database;

    final unsynced = await db.query(
      tableName,
      where: 'sync_status != ?',
      whereArgs: ['SYNCED'],
    );

    for (final map in unsynced) {
      final point = fromMap(map);
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
          whereArgs: [point.id],
        );
      } catch (e) {
        print('Erro ao sincronizar ponto de localização ${point.id}: $e');
      }
    }
  }
}
