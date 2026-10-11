import 'package:al_wahat_farm_flutter/core/web/web_platform_types.dart';

/// Native platforms keep app data in private storage the OS does not evict.
Future<bool?> requestPersistentStorage() async => null;

Future<StorageStatus?> storageStatus() async => null;
