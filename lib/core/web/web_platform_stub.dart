import 'dart:typed_data';

import 'package:al_wahat_farm_flutter/core/web/tab_lease.dart';
import 'package:al_wahat_farm_flutter/core/web/web_platform_types.dart';

/// Native platforms keep app data in private storage the OS does not evict.
Future<bool?> requestPersistentStorage() async => null;

Future<StorageStatus?> storageStatus() async => null;

/// Native apps run as a single instance, so there is nothing to coordinate.
TabChannel? openTabChannel(String name) => null;

void reloadPage() {}

bool isSecureContext() => true;

/// Native builds ship every asset inside the app package.
Future<int?> precacheAppShell() async => null;

String? currentAppVersion() => null;

/// Native apps are already installed.
bool isStandalone() => true;

bool isIos() => false;

bool canPromptInstall() => false;

Stream<void> installAvailableEvents() => const Stream<void>.empty();

Future<bool> promptInstall() async => false;

/// Native updates arrive through the app stores.
Future<bool> isNewerAppVersionAvailable() async => false;

/// Native foreground changes come from the app lifecycle instead.
Stream<void> pageVisibleEvents() => const Stream<void>.empty();

/// Native builds compress photos with flutter_image_compress instead.
Future<Uint8List> encodeJpegForUpload(
  Uint8List bytes, {
  required int maxDimension,
  required double quality,
}) =>
    throw UnsupportedError('encodeJpegForUpload is only available on the web');

/// Native builds scan with the platform's own barcode APIs.
void installQrReader() {}

String? qrReaderStatus() => null;
