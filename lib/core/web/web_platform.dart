// Browser-only capabilities behind a conditional import, so Android/iOS and
// `flutter test` compile against a no-op stub and never touch `dart:html`.
export 'tab_lease.dart';
export 'web_platform_stub.dart' if (dart.library.html) 'web_platform_html.dart';
export 'web_platform_types.dart';
