import 'package:al_wahat_farm_flutter/core/web/precache_keys.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const keys = <String>[
    'main.dart.js',
    'canvaskit/canvaskit.js',
    'canvaskit/canvaskit.wasm',
    'canvaskit/chromium/canvaskit.js',
    'canvaskit/chromium/canvaskit.wasm',
    'canvaskit/skwasm.js',
    'canvaskit/skwasm.wasm',
    'canvaskit/skwasm.worker.js',
    'sqlite3.wasm',
  ];

  test('Chromium browsers fetch only the Chromium CanvasKit', () {
    expect(offlinePrecacheKeys(keys, chromiumCanvasKit: true), <String>[
      'main.dart.js',
      'canvaskit/chromium/canvaskit.js',
      'canvaskit/chromium/canvaskit.wasm',
      'sqlite3.wasm',
    ]);
  });

  test('other browsers (Safari) fetch only the full CanvasKit', () {
    expect(offlinePrecacheKeys(keys, chromiumCanvasKit: false), <String>[
      'main.dart.js',
      'canvaskit/canvaskit.js',
      'canvaskit/canvaskit.wasm',
      'sqlite3.wasm',
    ]);
  });
}
