import 'dart:async';

import 'package:al_wahat_farm_flutter/core/connectivity/connectivity_service.dart';
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
  test('controller starts optimistic then reflects the probed status',
      () async {
    final service = _FakeConnectivityService(NetworkStatus.online);
    final controller = ConnectivityController(service);
    addTearDown(controller.dispose);
    addTearDown(service.close);

    expect(controller.isOnline, isTrue);
    expect(controller.status, NetworkStatus.unknown);

    await controller.start();
    expect(controller.status, NetworkStatus.online);
    expect(controller.isOffline, isFalse);
  });

  test('controller notifies on offline and online transitions', () async {
    final service = _FakeConnectivityService(NetworkStatus.online);
    final controller = ConnectivityController(service);
    addTearDown(controller.dispose);
    addTearDown(service.close);
    var notifications = 0;
    controller.addListener(() => notifications++);
    await controller.start();

    service.emit(NetworkStatus.offline);
    await Future<void>.delayed(Duration.zero);
    expect(controller.isOffline, isTrue);

    service.emit(NetworkStatus.online);
    await Future<void>.delayed(Duration.zero);
    expect(controller.isOnline, isTrue);

    // start(online) + offline + online = 3 distinct changes.
    expect(notifications, 3);
  });

  test('a repeated status does not notify twice', () async {
    final service = _FakeConnectivityService(NetworkStatus.offline);
    final controller = ConnectivityController(service);
    addTearDown(controller.dispose);
    addTearDown(service.close);
    await controller.start();
    var notifications = 0;
    controller.addListener(() => notifications++);

    service.emit(NetworkStatus.offline);
    await Future<void>.delayed(Duration.zero);

    expect(notifications, 0);
  });
}
