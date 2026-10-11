import 'dart:async';

import 'package:al_wahat_farm_flutter/core/web/web_platform.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Emits whenever the app returns to the foreground: a resumed lifecycle on
/// native, a visible page (tab switched back, installed app reopened) on web.
Stream<void> appForegroundEvents() =>
    kIsWeb ? pageVisibleEvents() : _lifecycleResumes();

Stream<void> _lifecycleResumes() {
  late final StreamController<void> controller;
  AppLifecycleListener? listener;
  controller = StreamController<void>(
    onListen: () {
      listener = AppLifecycleListener(onResume: () => controller.add(null));
    },
    onCancel: () {
      listener?.dispose();
      listener = null;
    },
  );
  return controller.stream;
}
