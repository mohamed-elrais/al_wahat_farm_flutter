import 'dart:async';

import 'package:al_wahat_farm_flutter/app/app.dart';
import 'package:al_wahat_farm_flutter/core/app_services.dart';
import 'package:al_wahat_farm_flutter/core/cache/local_cache_store.dart';
import 'package:al_wahat_farm_flutter/core/cache/sqflite_cache_store.dart';
import 'package:al_wahat_farm_flutter/core/connectivity/connectivity_service.dart';
import 'package:al_wahat_farm_flutter/core/config/app_config.dart';
import 'package:al_wahat_farm_flutter/core/database/app_database.dart';
import 'package:al_wahat_farm_flutter/core/database/database_platform.dart';
import 'package:al_wahat_farm_flutter/core/l10n/locale_controller.dart';
import 'package:al_wahat_farm_flutter/core/logging/safe_log.dart';
import 'package:al_wahat_farm_flutter/core/web/second_tab_app.dart';
import 'package:al_wahat_farm_flutter/core/web/web_platform.dart';
import 'package:al_wahat_farm_flutter/features/inspections/data/inspection_station_local_store.dart';
import 'package:al_wahat_farm_flutter/features/sync/data/outbox_store.dart';
import 'package:al_wahat_farm_flutter/features/sync/data/pending_photo_store.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const config = AppConfig.fromEnvironment();
  if (config.isConfigured) {
    await Supabase.initialize(url: config.supabaseUrl, anonKey: config.anonKey);
  }
  // Only one tab may own the offline database and sync engine (web only;
  // native has no channel and always owns).
  final lease = await _acquireTabLease();
  if (lease != null && !lease.isOwner) {
    runApp(SecondTabApp(onUseHere: () => _takeOver(lease)));
    return;
  }
  // Another tab took over: replace the app in place (disposing the sync
  // engine) instead of reloading, so this tab never competes for the claim.
  lease?.lostOwnership.listen(
    (_) => runApp(SecondTabApp(onUseHere: () => _takeOver(lease))),
  );
  final services = await _bootstrapServices();
  runApp(AlWahatApp(config: config, services: services));
  unawaited(_warmOfflineCache());
}

/// Web only: after the first screen has had time to load, fetch the rest of
/// the app shell so the next launch works offline. A no-op on native.
Future<void> _warmOfflineCache() async {
  await Future<void>.delayed(const Duration(seconds: 5));
  try {
    final fetched = await precacheAppShell();
    if (fetched != null) {
      SafeLog.event('offline_precache', data: <String, Object?>{
        'fetched': fetched,
      });
    }
  } catch (error) {
    SafeLog.event('offline_precache_failed', data: <String, Object?>{
      'error': error,
    });
  }
}

Future<TabLease?> _acquireTabLease() async {
  final channel = openTabChannel('awf-tab');
  if (channel == null) return null;
  final lease = TabLease(channel, tabId: const Uuid().v4());
  final owner = await lease.tryAcquire();
  SafeLog.event('tab_lease', data: <String, Object?>{'owner': owner});
  return lease;
}

/// Asks the owning tab to step aside (it switches to the "open in another tab"
/// screen and stops claiming), then restarts this tab, which now wins.
Future<void> _takeOver(TabLease lease) async {
  lease.takeOver();
  await Future<void>.delayed(const Duration(milliseconds: 500));
  reloadPage();
}

Future<AppServices> _bootstrapServices() async {
  LocalCacheStore store;
  OutboxStore outbox;
  PendingPhotoStore pendingPhotos;
  InspectionStationLocalStore? inspectionStationLocalStore;
  var persistentStorageAvailable = true;
  try {
    await configureDatabaseFactory();
    final database = await AppDatabase.open();
    store = SqfliteCacheStore(database);
    outbox = SqfliteOutboxStore(database);
    pendingPhotos = SqflitePendingPhotoStore(database);
    inspectionStationLocalStore = SqfliteInspectionStationLocalStore(database);
  } catch (error) {
    // Fall back to memory so a storage failure never blocks app launch; the
    // flag lets the UI warn that offline work will not survive a restart.
    SafeLog.event('storage_fallback', data: <String, Object?>{'error': error});
    persistentStorageAvailable = false;
    store = InMemoryCacheStore();
    outbox = InMemoryOutboxStore();
    pendingPhotos = InMemoryPendingPhotoStore();
    inspectionStationLocalStore = null;
  }
  final connectivity = ConnectivityController(PlatformConnectivityService());
  await connectivity.start();
  final locale = LocaleController(store);
  await locale.load();
  return AppServices(
    cacheStore: store,
    outbox: outbox,
    pendingPhotos: pendingPhotos,
    connectivity: connectivity,
    locale: locale,
    inspectionStationLocalStore: inspectionStationLocalStore,
    persistentStorageAvailable: persistentStorageAvailable,
  );
}
