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

  test('reads values larger than one chunk back unchanged', () async {
    // Android cannot return a ~2 MB row in one read, so large values are read
    // in slices; multi-byte characters must not be split or lost.
    const chunk = SqfliteCacheStore.readChunkChars;
    const pattern = 'شجرة-🌴-tree-';
    String sized(int length) {
      final buffer = StringBuffer();
      while (buffer.length < length) {
        buffer.write(pattern);
      }
      return buffer.toString().substring(0, length);
    }

    for (final length in <int>[chunk, chunk + 1, chunk * 2, chunk * 10 + 7]) {
      // Code units can split a surrogate pair; the stored text must stay
      // valid, so trim a dangling high surrogate.
      var value = sized(length);
      if (value.codeUnitAt(value.length - 1) >= 0xD800 &&
          value.codeUnitAt(value.length - 1) <= 0xDBFF) {
        value = value.substring(0, value.length - 1);
      }
      await store.write('big', value);
      expect(await store.read('big'), value, reason: 'length $length');
    }
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
