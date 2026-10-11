import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// The device plugin is sqflite's default factory, so nothing to configure.
Future<void> configureDatabaseFactory() async {}

/// The database file inside the platform's databases directory.
Future<String> defaultDatabasePath(String fileName) async =>
    p.join(await getDatabasesPath(), fileName);
