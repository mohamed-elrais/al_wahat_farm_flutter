// Platform-specific sqflite setup: the device plugin on Android/iOS/macOS, and
// the IndexedDB-backed `sqflite_common_ffi_web` factory in the browser, so the
// same `Sqflite*Store` classes persist offline data on every platform.
export 'database_platform_io.dart'
    if (dart.library.html) 'database_platform_web.dart';
