// Runs only in a browser: flutter test --platform chrome test/web
@TestOn('browser')
library;

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:js_util' as js_util;
import 'dart:typed_data';

import 'package:al_wahat_farm_flutter/core/web/web_platform.dart' as web;
import 'package:flutter_test/flutter_test.dart';

Future<Uint8List> _photo(int width, int height, String type) async {
  final canvas = html.CanvasElement(width: width, height: height);
  canvas.context2D
    ..fillStyle = '#336633'
    ..fillRect(0, 0, width, height)
    ..fillStyle = '#cc6633'
    ..fillRect(width ~/ 4, height ~/ 4, width ~/ 2, height ~/ 2);
  final blob = await canvas.toBlob(type, 0.9);
  final buffer = await js_util.promiseToFuture<ByteBuffer>(
    js_util.callMethod<Object>(blob, 'arrayBuffer', const <Object>[]),
  );
  return buffer.asUint8List();
}

Future<(int, int)> _size(Uint8List jpeg) async {
  final url = html.Url.createObjectUrlFromBlob(html.Blob(<Object>[jpeg]));
  final image = html.ImageElement(src: url);
  await image.decode();
  html.Url.revokeObjectUrl(url);
  return (image.naturalWidth, image.naturalHeight);
}

void main() {
  test('a 12 MP portrait photo becomes a JPEG with its long side at 1920',
      () async {
    final source = await _photo(3024, 4032, 'image/jpeg');

    final jpeg = await web.encodeJpegForUpload(
      source,
      maxDimension: 1920,
      quality: 0.84,
    );

    expect(jpeg.sublist(0, 3), <int>[0xFF, 0xD8, 0xFF]);
    expect(await _size(jpeg), (1440, 1920));
  });

  test('a small PNG keeps its size and is re-encoded as JPEG', () async {
    final source = await _photo(800, 600, 'image/png');

    final jpeg = await web.encodeJpegForUpload(
      source,
      maxDimension: 1920,
      quality: 0.84,
    );

    expect(jpeg.sublist(0, 3), <int>[0xFF, 0xD8, 0xFF]);
    expect(await _size(jpeg), (800, 600));
  });

  test('bytes that are not an image are rejected', () async {
    await expectLater(
      web.encodeJpegForUpload(
        Uint8List.fromList(<int>[1, 2, 3, 4]),
        maxDimension: 1920,
        quality: 0.84,
      ),
      throwsA(anything),
    );
  });
}
