import 'dart:async';

import 'package:al_wahat_farm_flutter/core/cache/local_cache_store.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// One position reading from the phone.
class LocationFix {
  const LocationFix({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
  });

  final double latitude;
  final double longitude;

  /// Radius of the 68% confidence circle reported by the platform.
  final double accuracyMeters;
}

enum LocationUnavailableReason { serviceOff, denied, failed }

class LocationUnavailable implements Exception {
  const LocationUnavailable(this.reason, [this.cause]);

  final LocationUnavailableReason reason;
  final Object? cause;

  @override
  String toString() => 'LocationUnavailable($reason)';
}

abstract interface class LocationService {
  /// Asks for permission when needed, then streams fixes until cancelled.
  /// Failures arrive as [LocationUnavailable] errors on the stream.
  Stream<LocationFix> watch();
}

/// Device GPS through geolocator. On the web this is the browser's
/// `navigator.geolocation`, which needs `Permissions-Policy: geolocation=(self)`.
class DeviceLocationService implements LocationService {
  const DeviceLocationService();

  @override
  Stream<LocationFix> watch() async* {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw const LocationUnavailable(LocationUnavailableReason.serviceOff);
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw const LocationUnavailable(LocationUnavailableReason.denied);
      }
    } on LocationUnavailable {
      rethrow;
    } catch (error) {
      throw LocationUnavailable(_reasonFor(error), error);
    }
    yield* Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 1,
      ),
    )
        .map(
          (position) => LocationFix(
            latitude: position.latitude,
            longitude: position.longitude,
            accuracyMeters: position.accuracy,
          ),
        )
        .handleError(
          (Object error) => throw LocationUnavailable(_reasonFor(error), error),
        );
  }

  static LocationUnavailableReason _reasonFor(Object error) => switch (error) {
        LocationServiceDisabledException() =>
          LocationUnavailableReason.serviceOff,
        PermissionDeniedException() => LocationUnavailableReason.denied,
        _ => LocationUnavailableReason.failed,
      };
}

/// Remembers whether the user turned "show my location" on, per device.
/// Outside [privateCachePrefix] so it survives logout, like the language.
class LocationPreference {
  const LocationPreference(this._store);

  static const storageKey = 'awf_show_my_location';

  final LocalCacheStore _store;

  Future<bool> load() async => await _store.read(storageKey) == 'true';

  Future<void> save(bool enabled) =>
      enabled ? _store.write(storageKey, 'true') : _store.remove(storageKey);
}

/// Turns the device location on and off for one screen and holds the latest
/// fix. Fixes go through [fix] so a map can redraw just its marker.
class LocationWatcher extends ChangeNotifier {
  LocationWatcher(this._service);

  final LocationService _service;
  final ValueNotifier<LocationFix?> fix = ValueNotifier<LocationFix?>(null);
  StreamSubscription<LocationFix>? _subscription;
  bool _on = false;
  bool _disposed = false;
  LocationUnavailableReason? _error;

  bool get isOn => _on;
  LocationUnavailableReason? get error => _error;

  void start() {
    unawaited(_subscription?.cancel());
    _on = true;
    _error = null;
    notifyListeners();
    _subscription = _service.watch().listen(
      (value) {
        fix.value = value;
        if (_error != null) {
          _error = null;
          notifyListeners();
        }
      },
      onError: (Object error) {
        if (_disposed) return;
        fix.value = null;
        _error = error is LocationUnavailable
            ? error.reason
            : LocationUnavailableReason.failed;
        notifyListeners();
      },
    );
  }

  void stop() {
    unawaited(_subscription?.cancel());
    _subscription = null;
    fix.value = null;
    _on = false;
    _error = null;
    notifyListeners();
  }

  /// Flips location on or off and remembers the choice in [store].
  Future<void> toggle(LocalCacheStore? store) async {
    _on ? stop() : start();
    if (store != null) await LocationPreference(store).save(_on);
  }

  /// Starts watching when the user left location on last time.
  Future<void> restore(LocalCacheStore store) async {
    final enabled = await LocationPreference(store).load();
    if (enabled && !_disposed && !_on) start();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_subscription?.cancel());
    fix.dispose();
    super.dispose();
  }
}
