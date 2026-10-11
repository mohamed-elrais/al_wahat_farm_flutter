import 'package:al_wahat_farm_flutter/core/database/database_platform.dart';
import 'package:sqflite/sqflite.dart';

/// The on-device SQLite database backing offline caches and (from O1) the
/// mutation outbox. Opened once at startup and shared process-wide.
///
/// Tests set the global `databaseFactory` to `databaseFactoryFfi` and open with
/// `filePath: inMemoryDatabasePath`, so the schema is exercised in `flutter
/// test` without a device.
class AppDatabase {
  AppDatabase._(this.db);

  static const fileName = 'al_wahat_farm.db';
  static const schemaVersion = 3;

  /// Generic key/value cache table. It backs [LocalCacheStore], so every Phase 7
  /// read cache (farm hierarchy, task list/detail) persists here.
  static const cacheTable = 'cache_entries';

  /// Durable, ordered queue of mutations awaiting sync (offline outbox).
  static const outboxTable = 'outbox';

  /// Photo bytes captured offline, awaiting upload+register on sync. Keyed by
  /// the outbox op id so the executor can pair a queued photo op with its blob.
  static const pendingPhotosTable = 'pending_photos';

  final Database db;

  static Future<AppDatabase> open({String? filePath}) async {
    final path = filePath ?? await defaultDatabasePath(fileName);
    final db = await openDatabase(
      path,
      version: schemaVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    return AppDatabase._(db);
  }

  static Future<void> _onCreate(Database db, int version) async {
    await _createCacheTable(db);
    await _createOutboxTable(db);
    await _createPendingPhotosTable(db);
  }

  static Future<void> _onUpgrade(Database db, int from, int to) async {
    if (from < 2) await _createOutboxTable(db);
    if (from < 3) await _createPendingPhotosTable(db);
  }

  static Future<void> _createCacheTable(Database db) => db.execute('''
      CREATE TABLE $cacheTable (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

  static Future<void> _createOutboxTable(Database db) => db.execute('''
      CREATE TABLE $outboxTable (
        seq INTEGER PRIMARY KEY AUTOINCREMENT,
        op_id TEXT NOT NULL UNIQUE,
        kind TEXT NOT NULL,
        payload TEXT NOT NULL,
        status TEXT NOT NULL,
        attempts INTEGER NOT NULL DEFAULT 0,
        last_error TEXT,
        created_at INTEGER NOT NULL
      )
    ''');

  static Future<void> _createPendingPhotosTable(Database db) => db.execute('''
      CREATE TABLE $pendingPhotosTable (
        op_id TEXT PRIMARY KEY,
        task_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        farm_id TEXT NOT NULL,
        photo_type TEXT NOT NULL,
        caption TEXT,
        filename TEXT NOT NULL,
        content_type TEXT NOT NULL,
        bytes BLOB NOT NULL,
        uploaded_path TEXT,
        created_at INTEGER NOT NULL
      )
    ''');

  Future<void> close() => db.close();
}
