import 'dart:typed_data';

import 'package:al_wahat_farm_flutter/core/database/app_database.dart';
import 'package:al_wahat_farm_flutter/features/sync/data/pending_photo_store.dart';
import 'package:al_wahat_farm_flutter/features/sync/domain/pending_photo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

PendingPhoto _photo(String opId, {String? uploadedPath}) => PendingPhoto(
      opId: opId,
      taskId: 't1',
      userId: 'u1',
      farmId: 'f1',
      photoType: 'after',
      caption: 'done',
      filename: 'e.jpg',
      contentType: 'image/jpeg',
      bytes: Uint8List.fromList(<int>[1, 2, 3, 4]),
      uploadedPath: uploadedPath,
      createdAt: 0,
    );

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late AppDatabase database;
  late SqflitePendingPhotoStore store;

  setUp(() async {
    database = await AppDatabase.open(filePath: inMemoryDatabasePath);
    store = SqflitePendingPhotoStore(database);
  });
  tearDown(() async => database.close());

  test('stores and reads a photo blob with its metadata', () async {
    await store.put(_photo('a'));
    final photo = await store.get('a');
    expect(photo, isNotNull);
    expect(photo!.taskId, 't1');
    expect(photo.photoType, 'after');
    expect(photo.caption, 'done');
    expect(photo.bytes, <int>[1, 2, 3, 4]);
    expect(photo.uploadedPath, isNull);
  });

  test('markUploaded records the path; delete and clear remove blobs',
      () async {
    await store.put(_photo('a'));
    await store.markUploaded('a', 'u1/f1/t1/e.jpg');
    expect((await store.get('a'))!.uploadedPath, 'u1/f1/t1/e.jpg');

    await store.delete('a');
    expect(await store.get('a'), isNull);

    await store.put(_photo('b'));
    await store.put(_photo('c'));
    await store.clear();
    expect(await store.get('b'), isNull);
    expect(await store.get('c'), isNull);
  });
}
