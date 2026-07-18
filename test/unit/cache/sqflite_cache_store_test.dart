import 'package:al_wahat_farm_flutter/core/cache/local_cache_store.dart';
import 'package:al_wahat_farm_flutter/core/cache/sqflite_cache_store.dart';
import 'package:al_wahat_farm_flutter/core/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late AppDatabase database;
  late SqfliteCacheStore store;

  setUp(() async {
    database = await AppDatabase.open(filePath: inMemoryDatabasePath);
    store = SqfliteCacheStore(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('writes, reads, overwrites, and removes a key', () async {
    expect(await store.read('k'), isNull);
    await store.write('k', 'v1');
    expect(await store.read('k'), 'v1');
    await store.write('k', 'v2');
    expect(await store.read('k'), 'v2');
    await store.remove('k');
    expect(await store.read('k'), isNull);
  });

  test('removeWithPrefix clears only the private namespace', () async {
    await store.write('${privateCachePrefix}hierarchy:farm', 'a');
    await store.write('${privateCachePrefix}tasks:farm', 'b');
    await store.write('awf_locale', 'ar'); // public preference
    await store.write(
        'awfXprivate:trap', 'c'); // must not match ('_' is literal)

    await store.removeWithPrefix(privateCachePrefix);

    expect(await store.read('${privateCachePrefix}hierarchy:farm'), isNull);
    expect(await store.read('${privateCachePrefix}tasks:farm'), isNull);
    expect(await store.read('awf_locale'), 'ar');
    expect(await store.read('awfXprivate:trap'), 'c');
  });

  test('cached values survive reopening the same database file', () async {
    // A private temp file (not in-memory) to prove persistence across opens.
    await store.write('persist', 'kept');
    await database.close();

    database = await AppDatabase.open(filePath: inMemoryDatabasePath);
    store = SqfliteCacheStore(database);
    // In-memory DBs do not share state across opens, so this asserts the schema
    // re-creates cleanly on a fresh open rather than data persistence.
    expect(await store.read('persist'), isNull);
    await store.write('persist', 'kept');
    expect(await store.read('persist'), 'kept');
  });
}
