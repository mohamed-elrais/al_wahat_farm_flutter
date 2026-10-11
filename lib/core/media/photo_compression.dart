import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';

/// Re-encodes a picked photo for upload. Injectable so tests can simulate a
/// failing encoder (on the web it depends on the vendored `pica` script).
typedef PhotoCompressor = Future<Uint8List> Function(Uint8List bytes);

/// JPEG at quality 84 with EXIF stripped. On native the image is scaled to fit
/// 1920x1080; on the web the plugin caps the width at 1920 and keeps the aspect
/// ratio.
Future<Uint8List> compressPhotoForUpload(Uint8List bytes) =>
    FlutterImageCompress.compressWithList(
      bytes,
      minWidth: 1920,
      minHeight: 1080,
      quality: 84,
      format: CompressFormat.jpeg,
      keepExif: false,
    );
