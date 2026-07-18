import 'package:path/path.dart' as p;
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
  static const schemaVersion = 1;

  /// Generic key/value cache table. It backs [LocalCacheStore], so every Phase 7
  /// read cache (farm hierarchy, task list/detail) persists here.
  static const cacheTable = 'cache_entries';

  final Database db;

  static Future<AppDatabase> open({String? filePath}) async {
    final path = filePath ?? p.join(await getDatabasesPath(), fileName);
    final db = await openDatabase(
      path,
      version: schemaVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    return AppDatabase._(db);
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $cacheTable (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  static Future<void> _onUpgrade(Database db, int from, int to) async {
    // Schema is at v1; future offline phases (outbox, pending photos) add their
    // tables here guarded by version ranges.
  }

  Future<void> close() => db.close();
}
