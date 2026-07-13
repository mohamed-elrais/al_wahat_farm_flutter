import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

enum NetworkStatus { online, offline, unknown }

/// A thin, fakeable seam over `connectivity_plus` so presentation code never
/// depends on the plugin directly and tests can drive network transitions.
abstract interface class ConnectivityService {
  Future<NetworkStatus> current();

  Stream<NetworkStatus> get changes;
}

class PlatformConnectivityService implements ConnectivityService {
  PlatformConnectivityService([Connectivity? connectivity])
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Future<NetworkStatus> current() async =>
      _map(await _connectivity.checkConnectivity());

  @override
  Stream<NetworkStatus> get changes =>
      _connectivity.onConnectivityChanged.map(_map);

  static NetworkStatus _map(ConnectivityResult result) =>
      result == ConnectivityResult.none
          ? NetworkStatus.offline
          : NetworkStatus.online;
}

/// Observable connectivity state. Treats `unknown` optimistically as online so
/// the app never blocks work before the first probe resolves.
class ConnectivityController extends ChangeNotifier {
  ConnectivityController(this._service);

  final ConnectivityService _service;
  NetworkStatus _status = NetworkStatus.unknown;
  StreamSubscription<NetworkStatus>? _subscription;

  NetworkStatus get status => _status;
  bool get isOffline => _status == NetworkStatus.offline;
  bool get isOnline => !isOffline;

  Future<void> start() async {
    try {
      _setStatus(await _service.current());
    } catch (_) {
      // Leave the optimistic unknown/online state if the probe fails.
    }
    _subscription ??= _service.changes.listen(
      _setStatus,
      onError: (_) {},
    );
  }

  void _setStatus(NetworkStatus next) {
    if (next == _status) return;
    _status = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
