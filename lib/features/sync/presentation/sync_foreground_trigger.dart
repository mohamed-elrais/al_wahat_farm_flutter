import 'dart:async';

/// Drains the outbox whenever the app comes back to the foreground. On the web
/// there is no background sync, so returning to the app is the main moment
/// queued work can go out (alongside connectivity changes and enqueues).
class SyncForegroundTrigger {
  SyncForegroundTrigger({
    required Stream<void> foreground,
    required Future<void> Function() sync,
  }) : _subscription = foreground.listen((_) => unawaited(sync()));

  final StreamSubscription<void> _subscription;

  Future<void> dispose() => _subscription.cancel();
}
