// Implementação do repositório para Address
import 'package:delivery/database/repository/SyncableRepository.dart';
import 'package:delivery/models/address.dart';
import 'package:delivery/database/database_helper.dart';

class AddressRepository extends SyncableRepository<Address> {
  AddressRepository() : super('addresses');

  

  @override
  Address fromMap(Map<String, dynamic> map) => Address.fromMap(map);

  @override
  Map<String, dynamic> toMap(Address address) => address.toMap();

  @override
  int getId(Address address) => address.id;

  @override
  Future<void> syncWithServer() async {
    final db = await DatabaseHelper().database;

    final unsynced = await db.query(
      tableName,
      where: 'sync_status != ?',
      whereArgs: ['SYNCED'],
    );

    for (final map in unsynced) {
      final address = fromMap(map);
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
          whereArgs: [address.id],
        );
      } catch (e) {
        print('Erro ao sincronizar endereço ${address.id}: $e');
      }
    }
  }
}
