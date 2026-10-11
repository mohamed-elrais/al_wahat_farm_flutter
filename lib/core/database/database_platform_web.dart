import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// Routes sqflite to SQLite compiled to WebAssembly, persisted in IndexedDB.
/// It loads `web/sqlite3.wasm` and `web/sqflite_sw.js` (see web/vendor/README.md).
Future<void> configureDatabaseFactory() async {
  databaseFactory = databaseFactoryFfiWeb;
}

/// IndexedDB has no directories; the database is addressed by name.
Future<String> defaultDatabasePath(String fileName) async => fileName;
