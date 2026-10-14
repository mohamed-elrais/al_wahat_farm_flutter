import 'dart:async';

import 'package:al_wahat_farm_flutter/core/cache/local_cache_store.dart';
import 'package:al_wahat_farm_flutter/core/location/location_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _ControlledLocation implements LocationService {
  final controllers = <StreamController<LocationFix>>[];

  StreamController<LocationFix> get current => controllers.last;

  @override
  Stream<LocationFix> watch() {
    final controller = StreamController<LocationFix>();
    controllers.add(controller);
    return controller.stream;
  }
}

const _fix = LocationFix(latitude: 28.29, longitude: 28.74, accuracyMeters: 5);

void main() {
  test('toggle starts, remembers, and stops the location', () async {
    final service = _ControlledLocation();
    final store = InMemoryCacheStore();
    final watcher = LocationWatcher(service);
    addTearDown(watcher.dispose);

    await watcher.toggle(store);
    expect(watcher.isOn, isTrue);
    expect(await store.read(LocationPreference.storageKey), 'true');

    service.current.add(_fix);
    await pumpEventQueue();
    expect(watcher.fix.value, same(_fix));

    await watcher.toggle(store);
    expect(watcher.isOn, isFalse);
    expect(watcher.fix.value, isNull);
    expect(await store.read(LocationPreference.storageKey), isNull);
    expect(service.current.hasListener, isFalse);
  });

  test('errors are reported and cleared by the next fix', () async {
    final service = _ControlledLocation();
    final watcher = LocationWatcher(service)..start();
    addTearDown(watcher.dispose);

    service.current.addError(
      const LocationUnavailable(LocationUnavailableReason.denied),
    );
    await pumpEventQueue();
    expect(watcher.error, LocationUnavailableReason.denied);
    expect(watcher.isOn, isTrue);

    service.current.addError(StateError('boom'));
    await pumpEventQueue();
    expect(watcher.error, LocationUnavailableReason.failed);

    service.current.add(_fix);
    await pumpEventQueue();
    expect(watcher.error, isNull);
  });

  test('restore starts only when the user left location on', () async {
    final store = InMemoryCacheStore();
    final off = LocationWatcher(_ControlledLocation());
    addTearDown(off.dispose);
    await off.restore(store);
    expect(off.isOn, isFalse);

    await LocationPreference(store).save(true);
    final on = LocationWatcher(_ControlledLocation());
    addTearDown(on.dispose);
    await on.restore(store);
    expect(on.isOn, isTrue);
  });
}
