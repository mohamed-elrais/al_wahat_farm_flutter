import 'package:al_wahat_farm_flutter/core/web/web_platform.dart' as web;
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

/// Re-encodes a picked photo for upload. Injectable so tests can simulate a
/// failing encoder.
typedef PhotoCompressor = Future<Uint8List> Function(Uint8List bytes);

/// JPEG at quality 84 with EXIF stripped. On native the image is scaled to fit
/// 1920x1080. On the web the browser decodes it (applying EXIF orientation) and
/// the longest side is capped at 1920; flutter_image_compress_web 0.1.4+1 is
/// not used because its pica resize fails on iPhone Safari.
Future<Uint8List> compressPhotoForUpload(Uint8List bytes) => kIsWeb
    ? web.encodeJpegForUpload(bytes, maxDimension: 1920, quality: 0.84)
    : FlutterImageCompress.compressWithList(
        bytes,
        minWidth: 1920,
        minHeight: 1080,
        quality: 84,
        format: CompressFormat.jpeg,
        keepExif: false,
      );
