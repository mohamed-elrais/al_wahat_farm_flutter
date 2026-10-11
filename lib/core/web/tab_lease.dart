import 'dart:async';
import 'dart:convert';

/// A broadcast message channel shared by every tab of this origin (a
/// `BroadcastChannel` on the web). Messages are JSON strings.
abstract interface class TabChannel {
  void post(String message);

  Stream<String> get messages;

  void close();
}

/// Lets exactly one browser tab own the offline database and sync engine.
///
/// The browser database is not safe across tabs where SharedWorker is missing
/// (Android Chrome), and even where it is, two tabs would each run a sync
/// engine over the same outbox. A new tab claims ownership and waits
/// [claimWindow]; an existing owner answers that it owns the app, so the new
/// tab shows a "use here" screen instead. Simultaneous claims are settled by
/// the lower tab id. [takeOver] moves ownership to this tab; the previous owner
/// is told through [lostOwnership].
class TabLease {
  TabLease(
    this._channel, {
    required this.tabId,
    this.claimWindow = const Duration(milliseconds: 300),
  });

  final TabChannel _channel;
  final String tabId;
  final Duration claimWindow;

  final StreamController<void> _lost = StreamController<void>.broadcast();
  StreamSubscription<String>? _subscription;
  bool _owner = false;
  bool _claiming = false;
  bool _beaten = false;

  bool get isOwner => _owner;

  /// Fires when another tab took ownership via [takeOver].
  Stream<void> get lostOwnership => _lost.stream;

  /// Claims ownership; returns false when another tab already owns the app.
  Future<bool> tryAcquire() async {
    _subscription ??= _channel.messages.listen(_onMessage);
    _claiming = true;
    _beaten = false;
    _send('claim');
    await Future<void>.delayed(claimWindow);
    _claiming = false;
    _owner = !_beaten;
    return _owner;
  }

  /// Asks the current owner to step aside; the caller then restarts as owner.
  void takeOver() {
    _subscription ??= _channel.messages.listen(_onMessage);
    _send('takeover');
  }

  void _onMessage(String raw) {
    final Map<String, Object?> message;
    try {
      message = (jsonDecode(raw) as Map).cast<String, Object?>();
    } catch (_) {
      return;
    }
    final from = message['id'];
    if (from is! String || from == tabId) return;
    switch (message['type']) {
      case 'claim':
        if (_owner) {
          _send('owned');
        } else if (_claiming && from.compareTo(tabId) < 0) {
          _beaten = true;
        }
      case 'owned':
        if (_claiming) _beaten = true;
      case 'takeover':
        if (_owner) {
          _owner = false;
          _lost.add(null);
        }
    }
  }

  void _send(String type) =>
      _channel.post(jsonEncode(<String, String>{'type': type, 'id': tabId}));

  Future<void> dispose() async {
    await _subscription?.cancel();
    _channel.close();
    await _lost.close();
  }
}
