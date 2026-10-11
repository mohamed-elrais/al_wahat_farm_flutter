import 'package:al_wahat_farm_flutter/core/web/tab_lease.dart';
import 'package:al_wahat_farm_flutter/core/web/web_platform_types.dart';

/// Native platforms keep app data in private storage the OS does not evict.
Future<bool?> requestPersistentStorage() async => null;

Future<StorageStatus?> storageStatus() async => null;

/// Native apps run as a single instance, so there is nothing to coordinate.
TabChannel? openTabChannel(String name) => null;

void reloadPage() {}

/// Native foreground changes come from the app lifecycle instead.
Stream<void> pageVisibleEvents() => const Stream<void>.empty();
