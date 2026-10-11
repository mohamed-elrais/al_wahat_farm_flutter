import 'package:al_wahat_farm_flutter/core/database/app_database.dart';
import 'package:al_wahat_farm_flutter/core/database/database_platform.dart';
import 'package:al_wahat_farm_flutter/core/web/web_platform.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('configureDatabaseFactory keeps the existing factory off the web',
      () async {
    await configureDatabaseFactory();

    expect(identical(databaseFactory, databaseFactoryFfi), isTrue);
  });

  test('defaultDatabasePath places the file in the databases directory',
      () async {
    expect(
      await defaultDatabasePath(AppDatabase.fileName),
      p.join(await getDatabasesPath(), AppDatabase.fileName),
    );
  });

  test('the web storage API is absent off the web', () async {
    expect(await requestPersistentStorage(), isNull);
    expect(await storageStatus(), isNull);
  });
}
