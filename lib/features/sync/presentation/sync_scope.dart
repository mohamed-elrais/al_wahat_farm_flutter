import 'package:al_wahat_farm_flutter/features/sync/domain/sync_engine.dart';
import 'package:flutter/widgets.dart';

/// Provides the [SyncEngine] to the authenticated subtree. Backed by
/// [InheritedNotifier] so widgets that read it rebuild when sync state (pending
/// / failed counts, in-progress) changes.
class SyncScope extends InheritedNotifier<SyncEngine> {
  const SyncScope({
    required SyncEngine engine,
    required super.child,
    super.key,
  }) : super(notifier: engine);

  static SyncEngine? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SyncScope>()?.notifier;
}
