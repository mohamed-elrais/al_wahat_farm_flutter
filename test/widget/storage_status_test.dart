import 'package:al_wahat_farm_flutter/core/app_services.dart';
import 'package:al_wahat_farm_flutter/core/cache/local_cache_store.dart';
import 'package:al_wahat_farm_flutter/core/connectivity/connectivity_service.dart';
import 'package:al_wahat_farm_flutter/core/l10n/locale_controller.dart';
import 'package:al_wahat_farm_flutter/core/web/web_platform.dart';
import 'package:al_wahat_farm_flutter/core/widgets/storage_status.dart';
import 'package:al_wahat_farm_flutter/features/sync/data/outbox_store.dart';
import 'package:al_wahat_farm_flutter/features/sync/data/pending_photo_store.dart';
import 'package:al_wahat_farm_flutter/l10n/gen/app_localizations_en.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _en = AppLocalizationsEn();

AppServices _services({required bool persistent}) {
  final store = InMemoryCacheStore();
  return AppServices(
    cacheStore: store,
    outbox: InMemoryOutboxStore(),
    pendingPhotos: InMemoryPendingPhotoStore(),
    connectivity: ConnectivityController(PlatformConnectivityService()),
    locale: LocaleController(store),
    persistentStorageAvailable: persistent,
  );
}

Widget _host(Widget child, {AppServices? services}) => MaterialApp(
      home: Scaffold(
        body: services == null
            ? child
            : AppServicesScope(services: services, child: child),
      ),
    );

void main() {
  testWidgets('storage warning is hidden while persistent storage works',
      (tester) async {
    await tester.pumpWidget(
      _host(const StorageWarningBanner(),
          services: _services(persistent: true)),
    );

    expect(find.byKey(const Key('storage-warning-banner')), findsNothing);
  });

  testWidgets('storage warning explains the in-memory fallback',
      (tester) async {
    await tester.pumpWidget(
      _host(const StorageWarningBanner(),
          services: _services(persistent: false)),
    );

    expect(find.byKey(const Key('storage-warning-banner')), findsOneWidget);
    expect(find.text(_en.storageUnavailableWarning), findsOneWidget);
  });

  testWidgets('storage status tile is hidden without a browser storage API',
      (tester) async {
    await tester.pumpWidget(
      _host(StorageStatusTile(load: () async => null)),
    );
    await tester.pump();

    expect(find.byKey(const Key('storage-status-tile')), findsNothing);
  });

  testWidgets('storage status tile reports durable storage and usage',
      (tester) async {
    await tester.pumpWidget(
      _host(
        StorageStatusTile(
          load: () async => const StorageStatus(
            persisted: true,
            usageBytes: 3 * 1024 * 1024,
            quotaBytes: 512 * 1024 * 1024,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('storage-status-tile')), findsOneWidget);
    expect(find.text(_en.storageTitle), findsOneWidget);
    expect(
      find.text(
        '${_en.storagePersistent}\n${_en.storageUsage('3.0 MB', '512.0 MB')}',
      ),
      findsOneWidget,
    );
  });

  test('storage sizes switch from MB to GB at 1 GB', () {
    expect(formatStorageSize(30 * 1024 * 1024 + 314573), '30.3 MB');
    expect(formatStorageSize(1023 * 1024 * 1024), '1023.0 MB');
    expect(formatStorageSize(1024 * 1024 * 1024), '1.0 GB');
    // The quota iPhone Safari reported (39321.6 MB).
    expect(formatStorageSize(41231686041), '38.4 GB');
  });

  testWidgets('storage status tile warns when storage is best-effort',
      (tester) async {
    await tester.pumpWidget(
      _host(
        StorageStatusTile(
          load: () async => const StorageStatus(persisted: false),
        ),
      ),
    );
    await tester.pump();

    expect(find.text(_en.storageBestEffort), findsOneWidget);
  });
}
