// Only compiled for the web via the conditional export in web_platform.dart.
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:al_wahat_farm_flutter/core/web/tab_lease.dart';
import 'package:al_wahat_farm_flutter/core/web/web_platform_types.dart';

/// A `BroadcastChannel` shared by every tab of this origin, or null where the
/// browser lacks it (then each tab acts alone, as before).
TabChannel? openTabChannel(String name) {
  try {
    return _BroadcastTabChannel(html.BroadcastChannel(name));
  } catch (_) {
    return null;
  }
}

class _BroadcastTabChannel implements TabChannel {
  _BroadcastTabChannel(this._channel);

  final html.BroadcastChannel _channel;

  @override
  void post(String message) => _channel.postMessage(message);

  @override
  Stream<String> get messages => _channel.onMessage
      .map((event) => event.data)
      .where((data) => data is String)
      .cast<String>();

  @override
  void close() => _channel.close();
}

void reloadPage() => html.window.location.reload();

/// Fires when the tab or installed app comes back to the foreground.
Stream<void> pageVisibleEvents() => html.document.onVisibilityChange
    .where((_) => html.document.visibilityState == 'visible')
    .map((_) {});

/// Asks the browser to keep IndexedDB data even under storage pressure.
/// Returns null when the Storage API is unavailable or the call fails.
Future<bool?> requestPersistentStorage() async {
  final storage = html.window.navigator.storage;
  if (storage == null) return null;
  try {
    if (await storage.persisted()) return true;
    return await storage.persist();
  } catch (_) {
    return null;
  }
}

Future<StorageStatus?> storageStatus() async {
  final storage = html.window.navigator.storage;
  if (storage == null) return null;
  try {
    final persisted = await storage.persisted();
    final estimate = await storage.estimate();
    return StorageStatus(
      persisted: persisted,
      usageBytes: (estimate?['usage'] as num?)?.toInt(),
      quotaBytes: (estimate?['quota'] as num?)?.toInt(),
    );
  } catch (_) {
    return null;
  }
}
