// Only compiled for the web: imported by web_platform_html.dart.
import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:js_util' as js_util;
import 'dart:math' as math;

import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mobile_scanner/mobile_scanner_web.dart';

/// mobile_scanner 4.0.1's web reader with a sturdier decode loop.
///
/// The stock loop is ZXing 0.19.1's `decodeContinuously`, which stops for good
/// on any error other than "not found" (for example reading a 0x0 canvas while
/// the video has no frames yet) and sizes its capture canvas once, from the
/// first frame, so a later resolution or orientation change crops every frame.
/// The stock camera request also names no resolution, so Safari opens the
/// camera at 640x480. And ZXing's JavaScript port could not read a real tag
/// on an iPhone 11 at all (809 frames, all "not found"), while zxing-cpp
/// (vendored zxing-wasm) read the same tag from a screenshot of that preview.
///
/// This reader asks for a 1920x1080 camera, waits for real frames, sizes the
/// canvas from the current frame every time, alternates the whole frame
/// (scaled) with a full-resolution centre crop, decodes with zxing-cpp
/// (ZXing JS with TRY_HARDER only if the wasm cannot load) and keeps going
/// whatever a single attempt throws. Camera start and stop are the plugin's
/// own. [status] reports what the loop sees, for the scanner's diagnostics
/// panel.
class SturdyQrReader extends ZXingBarcodeReader {
  SturdyQrReader({required super.videoContainer});

  static const version = 'sturdy-3';

  /// Our copy of zxing-wasm's binary (its default is a CDN).
  static const _wasmPath = 'vendor/zxing_reader-3.1.4.wasm';

  /// Points zxing-wasm at [_wasmPath]. Call before the first scan.
  static void configureWasm() {
    final zxing = js_util.getProperty<Object?>(html.window, 'ZXingWASM');
    if (zxing == null) return;
    js_util.callMethod<Object?>(zxing, 'prepareZXingModule', <Object?>[
      js_util.jsify(<String, Object>{
        'overrides': <String, Object>{
          'locateFile': js_util.allowInterop(
            (String path, String prefix) =>
                path.endsWith('.wasm') ? _wasmPath : '$prefix$path',
          ),
        },
      }),
    ]);
  }

  /// Longest side of the canvas handed to ZXing; larger frames are scaled.
  static const _maxDecodeSide = 1280;

  /// ZXing `DecodeHintType.TRY_HARDER`.
  static const _tryHarderHint = 3;

  StreamController<Barcode?>? _results;
  Timer? _timer;
  bool _decoding = false;
  bool _cropTurn = false;
  final html.CanvasElement _canvas = html.CanvasElement();
  Object? _qrReader;
  Object? _tryHarder;
  Object? _wasmOptions;

  /// Why zxing-wasm is not used (missing script or a failed load), or null.
  String? _wasmUnavailable;

  int _ticks = 0;
  int _attempts = 0;
  int _notFound = 0;
  int _found = 0;
  int _otherErrors = 0;
  String _lastError = '-';
  String _luma = '-';
  String _camera = '-';

  /// One line per fact, for the scanner's diagnostics panel.
  String status() => <String>[
        'reader $version',
        'decoder ${_wasmUnavailable == null ? 'zxing-cpp' : 'zxing-js ($_wasmUnavailable)'}',
        'camera $_camera',
        'video ${video.videoWidth}x${video.videoHeight} '
            'ready ${video.readyState} paused ${video.paused}',
        'canvas ${_canvas.width}x${_canvas.height} luma $_luma',
        'ticks $_ticks tries $_attempts found $_found',
        'not found $_notFound other errors $_otherErrors',
        'last error $_lastError',
      ].join('\n');

  @override
  Future<html.MediaStream?> initMediaStream(CameraFacing cameraFacing) async {
    final devices = html.window.navigator.mediaDevices;
    if (devices == null) return null;
    final constraints = js_util.jsify(<String, Object>{
      'video': <String, Object>{
        'facingMode':
            cameraFacing == CameraFacing.front ? 'user' : 'environment',
        'width': <String, int>{'ideal': 1920},
        'height': <String, int>{'ideal': 1080},
      },
    }) as Object;
    try {
      final stream = await js_util.promiseToFuture<html.MediaStream>(
        js_util.callMethod<Object>(devices, 'getUserMedia', <Object>[
          constraints,
        ]),
      );
      _camera = _describe(stream);
      return stream;
    } catch (error) {
      // An over-constrained request: fall back to the plugin's plain one.
      _camera = 'fallback after ${_short(error)}';
      return super.initMediaStream(cameraFacing);
    }
  }

  @override
  Stream<Barcode?> detectBarcodeContinuously() {
    _results ??= StreamController<Barcode?>(
      onListen: () {
        _timer?.cancel();
        _timer = Timer.periodic(frameInterval, (_) => _tick());
      },
      onCancel: stopDetectBarcodeContinuously,
    );
    return _results!.stream;
  }

  @override
  Future<void> stopDetectBarcodeContinuously() async {
    _timer?.cancel();
    _timer = null;
    final results = _results;
    _results = null;
    await results?.close();
  }

  void _tick() {
    _ticks++;
    if (_decoding) return;
    final width = video.videoWidth;
    final height = video.videoHeight;
    // HAVE_CURRENT_DATA: a frame can be drawn.
    if (width == 0 || height == 0 || video.readyState < 2) return;
    _decoding = true;
    _attempts++;
    final crop = _cropTurn;
    _cropTurn = !_cropTurn;
    unawaited(
      _attempt(width, height, crop: crop).whenComplete(() => _decoding = false),
    );
  }

  Future<void> _attempt(int width, int height, {required bool crop}) async {
    try {
      final text = await _decodeFrame(width, height, crop: crop);
      if (text != null && text.isNotEmpty) {
        _found++;
        _results?.add(Barcode(rawValue: text, format: BarcodeFormat.qrCode));
      } else {
        _notFound++;
      }
    } catch (error) {
      // "Not found" from ZXing JS on most frames, or a transient canvas
      // error: try again on the next tick.
      if (_isNoCodeError(error)) {
        _notFound++;
      } else {
        _otherErrors++;
        _lastError = _short(error);
      }
    }
  }

  Future<String?> _decodeFrame(
    int width,
    int height, {
    required bool crop,
  }) async {
    var sx = 0;
    var sy = 0;
    var sw = width;
    var sh = height;
    if (crop) {
      // The middle of the frame, where the on-screen guide box points.
      final side = (math.min(width, height) * 0.6).round();
      sx = (width - side) ~/ 2;
      sy = (height - side) ~/ 2;
      sw = side;
      sh = side;
    }
    final scale = math.min(1.0, _maxDecodeSide / math.max(sw, sh));
    final dw = math.max(1, (sw * scale).round());
    final dh = math.max(1, (sh * scale).round());
    if (_canvas.width != dw) _canvas.width = dw;
    if (_canvas.height != dh) _canvas.height = dh;
    final context = _canvas.context2D;
    context.drawImageScaledFromSource(video, sx, sy, sw, sh, 0, 0, dw, dh);
    if (_attempts % 10 == 1) _luma = _lumaStats(context, dw, dh);

    final wasm = _wasmUnavailable == null
        ? js_util.getProperty<Object?>(html.window, 'ZXingWASM')
        : null;
    if (wasm == null) {
      _wasmUnavailable ??= 'script missing';
      return _decodeWithZxingJs(crop: crop);
    }
    final List<Object?> results;
    try {
      results = await js_util.promiseToFuture<List<Object?>>(
        js_util.callMethod<Object>(wasm, 'readBarcodes', <Object?>[
          context.getImageData(0, 0, dw, dh),
          _wasmOptions ??= js_util.jsify(<String, Object>{
            'tryHarder': true,
            'formats': <String>['QRCode'],
            'maxNumberOfSymbols': 1,
          }),
        ]),
      );
    } catch (error) {
      // The .wasm did not load (or crashed): use ZXing JS from now on.
      _wasmUnavailable = _short(error);
      rethrow;
    }
    for (final result in results) {
      if (result == null) continue;
      if (js_util.getProperty<Object?>(result, 'isValid') == false) continue;
      final text = js_util.getProperty<Object?>(result, 'text');
      if (text is String && text.isNotEmpty) return text;
    }
    return null;
  }

  String? _decodeWithZxingJs({required bool crop}) {
    final zxing = js_util.getProperty<Object>(html.window, 'ZXing');
    Object create(String name, List<Object?> arguments) =>
        js_util.callConstructor<Object>(
          js_util.getProperty<Object>(zxing, name),
          arguments,
        );
    final bitmap = create('BinaryBitmap', <Object?>[
      create('HybridBinarizer', <Object?>[
        create('HTMLCanvasElementLuminanceSource', <Object?>[_canvas]),
      ]),
    ]);
    final reader = _qrReader ??= create('QRCodeReader', const <Object?>[]);
    final hints = crop ? _tryHarder ??= _tryHarderHints() : null;
    final result = js_util.callMethod<Object?>(reader, 'decode', <Object?>[
      bitmap,
      hints,
    ]);
    return result == null ? null : js_util.getProperty<String?>(result, 'text');
  }

  /// ZXing's "no readable code in this frame" errors. The minified library
  /// renames its classes, so they are matched by constructor, not by name.
  static bool _isNoCodeError(Object error) {
    try {
      final zxing = js_util.getProperty<Object>(html.window, 'ZXing');
      return const <String>[
        'NotFoundException',
        'ChecksumException',
        'FormatException',
      ].any(
        (name) => js_util.instanceof(
          error,
          js_util.getProperty<Object>(zxing, name),
        ),
      );
    } catch (_) {
      return false;
    }
  }

  Object _tryHarderHints() {
    final hints = js_util.callConstructor<Object>(
      js_util.getProperty<Object>(html.window, 'Map'),
      const <Object?>[],
    );
    js_util.callMethod<Object?>(hints, 'set', <Object?>[_tryHarderHint, true]);
    return hints;
  }

  /// Mean and spread of brightness over a sparse sample: a black or frozen
  /// frame shows up as a mean near 0 or a spread near 0.
  static String _lumaStats(
    html.CanvasRenderingContext2D context,
    int width,
    int height,
  ) {
    try {
      final data = context.getImageData(0, 0, width, height).data;
      var count = 0;
      var sum = 0.0;
      var squares = 0.0;
      for (var i = 0; i + 2 < data.length; i += 4 * 97) {
        final value =
            (data[i] * 299 + data[i + 1] * 587 + data[i + 2] * 114) / 1000;
        sum += value;
        squares += value * value;
        count++;
      }
      if (count == 0) return 'empty';
      final mean = sum / count;
      final spread = math.sqrt(math.max(0, squares / count - mean * mean));
      return '${mean.round()}±${spread.round()}';
    } catch (error) {
      return 'unreadable (${_short(error)})';
    }
  }

  static String _describe(html.MediaStream stream) {
    final tracks = stream.getVideoTracks();
    if (tracks.isEmpty) return 'no video track';
    final settings = tracks.first.getSettings();
    return '${settings['width']}x${settings['height']} '
        '${settings['facingMode'] ?? ''}';
  }

  static String _short(Object error) {
    final text = error.toString().replaceAll('\n', ' ');
    return text.length > 90 ? '${text.substring(0, 90)}…' : text;
  }

  @override
  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    await super.stop();
  }
}
