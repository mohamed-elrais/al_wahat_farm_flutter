import 'package:al_wahat_farm_flutter/core/app_services.dart';
import 'package:al_wahat_farm_flutter/core/cache/local_cache_store.dart';
import 'package:al_wahat_farm_flutter/core/connectivity/connectivity_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('clearPrivateData removes session cache but keeps public preferences',
      () async {
    final store = InMemoryCacheStore();
    await store.write('${privateCachePrefix}hierarchy:farm', 'hierarchy-json');
    await store.write('${privateCachePrefix}tasks:farm', 'task-json');
    await store.write('${privateCachePrefix}task_detail:t1', 'detail-json');
    await store.write('locale_preference', 'en');

    final services = AppServices(
      cacheStore: store,
      connectivity: ConnectivityController(PlatformConnectivityService()),
    );
    addTearDown(services.connectivity.dispose);

    await services.clearPrivateData();

    expect(await store.read('${privateCachePrefix}hierarchy:farm'), isNull);
    expect(await store.read('${privateCachePrefix}tasks:farm'), isNull);
    expect(await store.read('${privateCachePrefix}task_detail:t1'), isNull);
    expect(await store.read('locale_preference'), 'en');
  });
}
