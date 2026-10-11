// Only compiled for the web via the conditional export in web_platform.dart.
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:al_wahat_farm_flutter/core/web/web_platform_types.dart';

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
