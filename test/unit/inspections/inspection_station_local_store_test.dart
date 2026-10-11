import 'dart:io';
import 'dart:typed_data';

import 'package:al_wahat_farm_flutter/core/cache/sqflite_cache_store.dart';
import 'package:al_wahat_farm_flutter/core/database/app_database.dart';
import 'package:al_wahat_farm_flutter/features/inspections/data/inspection_station_local_store.dart';
import 'package:al_wahat_farm_flutter/features/sync/data/outbox_store.dart';
import 'package:al_wahat_farm_flutter/features/sync/data/pending_photo_store.dart';
import 'package:al_wahat_farm_flutter/features/sync/domain/pending_mutation.dart';
import 'package:al_wahat_farm_flutter/features/sync/domain/pending_photo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late AppDatabase database;
  late SqfliteCacheStore cache;
  late SqfliteOutboxStore outbox;
  late SqflitePendingPhotoStore pendingPhotos;
  late SqfliteInspectionStationLocalStore store;

  setUp(() async {
    database = await AppDatabase.open(filePath: inMemoryDatabasePath);
    cache = SqfliteCacheStore(database);
    outbox = SqfliteOutboxStore(database);
    pendingPhotos = SqflitePendingPhotoStore(database);
    store = SqfliteInspectionStationLocalStore(database);
    await cache.write('inspection', 'before');
  });

  tearDown(() => database.close());

  test('commits snapshot, outbox operation, and photos together', () async {
    await store.commit(
      mutation: _mutation,
      photos: <PendingPhoto>[_photo],
      cacheKey: 'inspection',
      cacheValue: 'after',
    );

    expect(await cache.read('inspection'), 'after');
    expect((await outbox.pending()).single.opId, _mutation.opId);
    expect(await pendingPhotos.get(_photo.opId), isNotNull);
  });

  test('rolls back every record when any write fails', () async {
    await database.db.execute('''
      CREATE TRIGGER reject_inspection_cache
      BEFORE INSERT ON ${AppDatabase.cacheTable}
      WHEN NEW.key = 'inspection' AND NEW.value = 'after'
      BEGIN
        SELECT RAISE(ABORT, 'forced cache failure');
      END
    ''');

    await expectLater(
      store.commit(
        mutation: _mutation,
        photos: <PendingPhoto>[_photo],
        cacheKey: 'inspection',
        cacheValue: 'after',
      ),
      throwsA(isA<DatabaseException>()),
    );

    expect(await cache.read('inspection'), 'before');
    expect(await outbox.pending(), isEmpty);
    expect(await pendingPhotos.get(_photo.opId), isNull);
  });

  test('complete station commit survives closing and reopening SQLite',
      () async {
    final directory = await Directory.systemTemp.createTemp('awf-station-');
    addTearDown(() => directory.delete(recursive: true));
    final path = p.join(directory.path, 'offline.db');
    final firstDatabase = await AppDatabase.open(filePath: path);
    final firstCache = SqfliteCacheStore(firstDatabase);
    await firstCache.write('inspection', 'before');

    await SqfliteInspectionStationLocalStore(firstDatabase).commit(
      mutation: _mutation,
      photos: <PendingPhoto>[_photo],
      cacheKey: 'inspection',
      cacheValue: 'after',
    );
    await firstDatabase.close();

    final reopenedDatabase = await AppDatabase.open(filePath: path);
    final reopenedCache = SqfliteCacheStore(reopenedDatabase);
    final reopenedOutbox = SqfliteOutboxStore(reopenedDatabase);
    final reopenedPhotos = SqflitePendingPhotoStore(reopenedDatabase);

    expect(await reopenedCache.read('inspection'), 'after');
    expect((await reopenedOutbox.pending()).single.opId, _mutation.opId);
    expect(await reopenedPhotos.get(_photo.opId), isNotNull);
    await reopenedDatabase.close();
  });
}

const _mutation = PendingMutation(
  opId: 'station-op',
  kind: PendingMutationKind.saveInspectionStation,
  payload: <String, Object?>{
    'sessionId': 'session-id',
    'stationIndex': 1,
  },
  createdAt: 1,
);

final _photo = PendingPhoto(
  opId: 'station-op::tree-1|tree_damage',
  taskId: 'task-id',
  userId: 'user-id',
  farmId: 'farm-id',
  photoType: 'issue',
  filename: 'damage.jpg',
  contentType: 'image/jpeg',
  bytes: Uint8List.fromList(<int>[1, 2, 3]),
  createdAt: 1,
);
