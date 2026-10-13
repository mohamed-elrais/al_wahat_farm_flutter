import 'package:al_wahat_farm_flutter/core/cache/local_cache_store.dart';
import 'package:al_wahat_farm_flutter/core/database/app_database.dart';
import 'package:sqflite/sqflite.dart';

/// [LocalCacheStore] backed by the sqflite key/value table. Drop-in replacement
/// for [SharedPreferencesCacheStore]; moving to it migrates every read cache to
/// the on-device database that also holds the offline mutation outbox.
class SqfliteCacheStore implements LocalCacheStore {
  const SqfliteCacheStore(this._database);

  final AppDatabase _database;

  /// Characters per read. Android returns query results through a
  /// CursorWindow of about 2 MB, so reading a larger value in one row fails
  /// ("Row too big to fit into CursorWindow"); the farm hierarchy alone is
  /// about 2.6 MB. 256K characters stay under 1 MB of UTF-8 even when every
  /// character takes 4 bytes.
  static const readChunkChars = 256 * 1024;

  @override
  Future<String?> read(String key) async {
    final db = _database.db;
    final sizes = await db.rawQuery(
      'SELECT length(value) AS size FROM ${AppDatabase.cacheTable} '
      'WHERE key = ? LIMIT 1',
      <Object?>[key],
    );
    if (sizes.isEmpty) return null;
    final size = sizes.first['size']! as int;
    if (size <= readChunkChars) {
      final rows = await db.query(
        AppDatabase.cacheTable,
        columns: <String>['value'],
        where: 'key = ?',
        whereArgs: <Object?>[key],
        limit: 1,
      );
      return rows.isEmpty ? null : rows.first['value'] as String;
    }
    // One transaction, so a concurrent write cannot mix two versions.
    return db.transaction((txn) async {
      final value = StringBuffer();
      for (var start = 1; start <= size; start += readChunkChars) {
        final rows = await txn.rawQuery(
          'SELECT substr(value, ?, ?) AS part FROM ${AppDatabase.cacheTable} '
          'WHERE key = ? LIMIT 1',
          <Object?>[start, readChunkChars, key],
        );
        if (rows.isEmpty) return null;
        value.write(rows.first['part']! as String);
      }
      return value.toString();
    });
  }

  @override
  Future<void> write(String key, String value) =>
      writeWithExecutor(_database.db, key, value);

  static Future<void> writeWithExecutor(
    DatabaseExecutor executor,
    String key,
    String value,
  ) async {
    await executor.insert(
      AppDatabase.cacheTable,
      <String, Object?>{'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> remove(String key) async {
    await _database.db.delete(
      AppDatabase.cacheTable,
      where: 'key = ?',
      whereArgs: <Object?>[key],
    );
  }

  @override
  Future<void> removeWithPrefix(String prefix) async {
    // substr avoids LIKE wildcard escaping (the private prefix contains '_').
    await _database.db.delete(
      AppDatabase.cacheTable,
      where: 'substr(key, 1, ?) = ?',
      whereArgs: <Object?>[prefix.length, prefix],
    );
  }
}
