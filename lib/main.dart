import 'package:al_wahat_farm_flutter/app/app.dart';
import 'package:al_wahat_farm_flutter/core/app_services.dart';
import 'package:al_wahat_farm_flutter/core/cache/local_cache_store.dart';
import 'package:al_wahat_farm_flutter/core/cache/sqflite_cache_store.dart';
import 'package:al_wahat_farm_flutter/core/connectivity/connectivity_service.dart';
import 'package:al_wahat_farm_flutter/core/config/app_config.dart';
import 'package:al_wahat_farm_flutter/core/database/app_database.dart';
import 'package:al_wahat_farm_flutter/core/l10n/locale_controller.dart';
import 'package:al_wahat_farm_flutter/features/sync/data/outbox_store.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const config = AppConfig.fromEnvironment();
  if (config.isConfigured) {
    await Supabase.initialize(url: config.supabaseUrl, anonKey: config.anonKey);
  }
  final services = await _bootstrapServices();
  runApp(AlWahatApp(config: config, services: services));
}

Future<AppServices> _bootstrapServices() async {
  LocalCacheStore store;
  OutboxStore outbox;
  try {
    final database = await AppDatabase.open();
    store = SqfliteCacheStore(database);
    outbox = SqfliteOutboxStore(database);
  } catch (_) {
    // Fall back to memory so a storage failure never blocks app launch.
    store = InMemoryCacheStore();
    outbox = InMemoryOutboxStore();
  }
  final connectivity = ConnectivityController(PlatformConnectivityService());
  await connectivity.start();
  final locale = LocaleController(store);
  await locale.load();
  return AppServices(
    cacheStore: store,
    outbox: outbox,
    connectivity: connectivity,
    locale: locale,
  );
}
