import 'package:al_wahat_farm_flutter/app/theme/app_theme.dart';
import 'package:al_wahat_farm_flutter/features/sync/data/pending_photo_store.dart';
import 'package:al_wahat_farm_flutter/features/sync/data/outbox_store.dart';
import 'package:al_wahat_farm_flutter/core/app_services.dart';
import 'package:al_wahat_farm_flutter/core/cache/local_cache_store.dart';
import 'package:al_wahat_farm_flutter/core/connectivity/connectivity_service.dart';
import 'package:al_wahat_farm_flutter/core/l10n/locale_controller.dart';
import 'package:al_wahat_farm_flutter/features/profile/presentation/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child, {double textScaleFactor = 1.0}) {
    final services = AppServices(
      cacheStore: InMemoryCacheStore(),
      outbox: InMemoryOutboxStore(),
      pendingPhotos: InMemoryPendingPhotoStore(),
      connectivity: ConnectivityController(PlatformConnectivityService()),
      locale: LocaleController(InMemoryCacheStore()),
    );
    return MaterialApp(
      theme: AppTheme.light,
      home: MediaQuery(
        data: MediaQueryData(textScaleFactor: textScaleFactor),
        child: AppServicesScope(services: services, child: child),
      ),
    );
  }

  testWidgets('More screen meets tap-target and labelled-target guidelines',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(wrap(const ProfileScreen()));
    await tester.pumpAndSettle();

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });

  testWidgets('core logout action survives 200% text scaling without overflow',
      (tester) async {
    await tester.pumpWidget(
      wrap(const ProfileScreen(), textScaleFactor: 2),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('logout-button')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sync status exposes an accessible label', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(wrap(const ProfileScreen()));
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsLabel(RegExp('Sync status')),
      findsOneWidget,
    );
    handle.dispose();
  });
}
