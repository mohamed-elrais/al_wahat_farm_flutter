import 'dart:async';

import 'package:al_wahat_farm_flutter/core/web/tab_lease.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory stand-in for a BroadcastChannel: delivers to every other member,
/// never back to the sender, asynchronously.
class _Bus {
  final List<_BusChannel> _members = <_BusChannel>[];

  _BusChannel join() {
    final channel = _BusChannel(this);
    _members.add(channel);
    return channel;
  }

  void deliver(_BusChannel from, String message) {
    for (final member in List<_BusChannel>.of(_members)) {
      if (!identical(member, from)) {
        scheduleMicrotask(() => member.receive(message));
      }
    }
  }
}

class _BusChannel implements TabChannel {
  _BusChannel(this._bus);

  final _Bus _bus;
  final StreamController<String> _incoming =
      StreamController<String>.broadcast();
  final List<String> sent = <String>[];

  void receive(String message) {
    if (!_incoming.isClosed) _incoming.add(message);
  }

  @override
  void post(String message) {
    sent.add(message);
    _bus.deliver(this, message);
  }

  @override
  Stream<String> get messages => _incoming.stream;

  @override
  void close() {
    _bus._members.remove(this);
    _incoming.close();
  }
}

const _window = Duration(milliseconds: 30);

void main() {
  test('a lone tab becomes the owner', () async {
    final lease = TabLease(_Bus().join(), tabId: 'a', claimWindow: _window);

    expect(await lease.tryAcquire(), isTrue);
    expect(lease.isOwner, isTrue);
    await lease.dispose();
  });

  test('a second tab is refused while the first owns the app', () async {
    final bus = _Bus();
    final first = TabLease(bus.join(), tabId: 'b', claimWindow: _window);
    final second = TabLease(bus.join(), tabId: 'a', claimWindow: _window);

    expect(await first.tryAcquire(), isTrue);
    expect(await second.tryAcquire(), isFalse);
    expect(first.isOwner, isTrue);
    await first.dispose();
    await second.dispose();
  });

  test('simultaneous claims leave exactly one owner, the lower id', () async {
    final bus = _Bus();
    final high = TabLease(bus.join(), tabId: 'tab-2', claimWindow: _window);
    final low = TabLease(bus.join(), tabId: 'tab-1', claimWindow: _window);

    final results =
        await Future.wait(<Future<bool>>[high.tryAcquire(), low.tryAcquire()]);

    expect(results, <bool>[false, true]);
    await high.dispose();
    await low.dispose();
  });

  test('takeOver demotes the owner and lets the new tab win', () async {
    final bus = _Bus();
    final owner = TabLease(bus.join(), tabId: 'a', claimWindow: _window);
    expect(await owner.tryAcquire(), isTrue);
    final lost = owner.lostOwnership.first;

    final waiting = TabLease(bus.join(), tabId: 'b', claimWindow: _window);
    expect(await waiting.tryAcquire(), isFalse);
    waiting.takeOver();
    await lost;

    expect(owner.isOwner, isFalse);
    // The tab that asked restarts (a fresh lease) and nobody answers 'owned'.
    final restarted = TabLease(bus.join(), tabId: 'c', claimWindow: _window);
    expect(await restarted.tryAcquire(), isTrue);
    await owner.dispose();
    await waiting.dispose();
    await restarted.dispose();
  });

  test('malformed messages and its own echoes are ignored', () async {
    final bus = _Bus();
    final lease = TabLease(bus.join(), tabId: 'a', claimWindow: _window);
    final noise = bus.join();
    final claim = lease.tryAcquire();
    noise.post('not json');
    noise.post('{"type":"owned"}'); // no id
    noise.post('{"type":"owned","id":"a"}'); // pretends to be us

    expect(await claim, isTrue);
    await lease.dispose();
    noise.close();
  });
}
