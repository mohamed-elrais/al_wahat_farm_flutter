/// Which service-worker resources the offline download fetches.
///
/// Skips the skwasm engine, which this CanvasKit build never loads, and the
/// CanvasKit variant this browser will not use (about 6 MB each). In auto
/// mode Flutter 3.13 loads `canvaskit/chromium/` when the browser has
/// `Intl.v8BreakIterator` and `Intl.Segmenter` (Chromium), and
/// `canvaskit/canvaskit.*` otherwise (Safari, Firefox); see
/// `browserSupportsCanvaskitChromium` in the engine's browser_detection.dart.
/// The engine falls back to the full variant if the Chromium one fails, and
/// the service worker caches whatever the engine loads online, so a skipped
/// file is fetched when it is actually used.
List<String> offlinePrecacheKeys(
  Iterable<String> keys, {
  required bool chromiumCanvasKit,
}) =>
    keys.where((key) {
      if (key.startsWith('canvaskit/skwasm')) return false;
      final chromium = key.startsWith('canvaskit/chromium/');
      final full = key.startsWith('canvaskit/canvaskit.');
      if (chromiumCanvasKit && full) return false;
      if (!chromiumCanvasKit && chromium) return false;
      return true;
    }).toList(growable: false);
