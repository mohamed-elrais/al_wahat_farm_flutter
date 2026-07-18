import 'dart:async';
import 'package:al_wahat_farm_flutter/features/sync/data/outbox_store.dart';

import 'package:al_wahat_farm_flutter/app/theme/app_theme.dart';
import 'package:al_wahat_farm_flutter/core/app_services.dart';
import 'package:al_wahat_farm_flutter/core/cache/local_cache_store.dart';
import 'package:al_wahat_farm_flutter/core/connectivity/connectivity_service.dart';
import 'package:al_wahat_farm_flutter/core/l10n/locale_controller.dart';
import 'package:al_wahat_farm_flutter/core/widgets/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeConnectivityService implements ConnectivityService {
  _FakeConnectivityService(this._current);

  NetworkStatus _current;
  final StreamController<NetworkStatus> _controller =
      StreamController<NetworkStatus>.broadcast();

  void emit(NetworkStatus status) {
    _current = status;
    _controller.add(status);
  }

  @override
  Future<NetworkStatus> current() async => _current;

  @override
  Stream<NetworkStatus> get changes => _controller.stream;

  Future<void> close() => _controller.close();
}

void main() {
  testWidgets('offline banner appears when offline and clears when online',
      (tester) async {
    final service = _FakeConnectivityService(NetworkStatus.offline);
    final connectivity = ConnectivityController(service);
    addTearDown(connectivity.dispose);
    addTearDown(service.close);
    await connectivity.start();

    final services = AppServices(
      cacheStore: InMemoryCacheStore(),
      outbox: InMemoryOutboxStore(),
      connectivity: connectivity,
      locale: LocaleController(InMemoryCacheStore()),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: AppServicesScope(
          services: services,
          child: const Scaffold(body: WahatConnectivityBanner()),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('offline-banner')), findsOneWidget);
    expect(find.text('Offline · showing cached farm and task data'),
        findsOneWidget);

    service.emit(NetworkStatus.online);
    await tester.pump(); // deliver the broadcast-stream event to the controller
    await tester.pump(); // render the rebuild triggered by notifyListeners

    expect(find.byKey(const Key('offline-banner')), findsNothing);
  });
}
