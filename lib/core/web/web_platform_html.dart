// Only compiled for the web via the conditional export in web_platform.dart.
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:js_util' as js_util;

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

/// Browsers only grant camera access (and service workers) on HTTPS or
/// localhost; elsewhere the scanner would fail with a generic error.
bool isSecureContext() => html.window.isSecureContext ?? true;

final RegExp _resourceKey = RegExp(r'"([^"]+)":\s*"[0-9a-f]{32}"');
final RegExp _buildVersion = RegExp(r'serviceWorkerVersion = "(\d+)"');

/// Fetches every app-shell file listed by Flutter's service worker so the app
/// can cold-start offline. Each request passes through the service worker,
/// which caches it; files already cached are answered locally, so repeating
/// this every launch is cheap. Skips the skwasm engine, which this CanvasKit
/// build never loads. Returns how many files were fetched, or null when no
/// service worker controls the page yet (the next launch retries).
Future<int?> precacheAppShell() async {
  if (html.window.navigator.serviceWorker?.controller == null) return null;
  final String worker;
  try {
    // Not a cached resource itself, so this needs the network: offline there
    // is nothing new to fetch anyway.
    worker = await html.HttpRequest.getString('flutter_service_worker.js');
  } catch (_) {
    return null;
  }
  final keys = _resourceKey
      .allMatches(worker)
      .map((match) => match.group(1)!)
      .where((key) => !key.startsWith('canvaskit/skwasm'))
      .toList(growable: false);
  var fetched = 0;
  for (final key in keys) {
    try {
      final request = await html.HttpRequest.request(key == '/' ? './' : key);
      if (request.status == 200) fetched++;
    } catch (_) {
      // Offline or a transient failure: the next launch tries again.
    }
  }
  return fetched;
}

/// The build id `flutter build` wrote into this page's index.html.
String? currentAppVersion() {
  final value = js_util.getProperty<Object?>(html.window, 'awfAppVersion');
  return value is String ? value : null;
}

/// Compares the running build with the deployed index.html. The query string
/// keeps the service worker from answering with its cached copy.
Future<bool> isNewerAppVersionAvailable() async {
  final current = currentAppVersion();
  if (current == null || !(html.window.navigator.onLine ?? true)) return false;
  try {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final page = await html.HttpRequest.getString('index.html?awf=$stamp');
    final deployed = _buildVersion.firstMatch(page)?.group(1);
    return deployed != null && deployed != current;
  } catch (_) {
    return false;
  }
}

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
