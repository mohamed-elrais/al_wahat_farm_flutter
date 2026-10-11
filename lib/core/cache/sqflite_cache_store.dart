import 'package:al_wahat_farm_flutter/core/cache/local_cache_store.dart';
import 'package:al_wahat_farm_flutter/core/database/app_database.dart';
import 'package:sqflite/sqflite.dart';

/// [LocalCacheStore] backed by the sqflite key/value table. Drop-in replacement
/// for [SharedPreferencesCacheStore]; moving to it migrates every read cache to
/// the on-device database that also holds the offline mutation outbox.
class SqfliteCacheStore implements LocalCacheStore {
  const SqfliteCacheStore(this._database);

  final AppDatabase _database;

  @override
  Future<String?> read(String key) async {
    final rows = await _database.db.query(
      AppDatabase.cacheTable,
      columns: <String>['value'],
      where: 'key = ?',
      whereArgs: <Object?>[key],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['value'] as String;
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
