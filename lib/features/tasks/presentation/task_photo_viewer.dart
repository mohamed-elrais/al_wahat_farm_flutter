import 'dart:async';

import 'package:al_wahat_farm_flutter/app/theme/app_tokens.dart';
import 'package:al_wahat_farm_flutter/core/errors/operation_failure.dart';
import 'package:al_wahat_farm_flutter/core/l10n/domain_labels.dart';
import 'package:al_wahat_farm_flutter/core/l10n/l10n.dart';
import 'package:al_wahat_farm_flutter/core/media/photo_api.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/farm_task.dart';
import 'package:al_wahat_farm_flutter/features/tasks/presentation/task_widgets.dart';
import 'package:flutter/material.dart';

/// Resolves a viewable URL for a task evidence photo. Photos are private, so
/// display goes through short-lived signed URLs.
abstract interface class TaskPhotoUrlProvider {
  /// A URL that can be fetched right now. [refresh] discards any cached
  /// URL first (used when a cached one has expired).
  Future<String> urlFor(TaskPhoto photo, {bool refresh = false});
}

/// Links from the app's photo service (R2_PHOTOS_PLAN.md). Photos still in
/// the Supabase bucket get a Supabase signed link from the same service.
class R2PhotoUrlProvider implements TaskPhotoUrlProvider {
  R2PhotoUrlProvider(this._api);

  /// The service signs at most this many paths per request.
  static const _maxBatch = 100;

  final PhotoApi _api;

  /// One in-flight/settled future per path so the list thumbnail and the
  /// full-screen viewer share a URL (and therefore the image cache).
  final Map<String, Future<String>> _cache = <String, Future<String>>{};

  /// Paths asked for in the same frame (a list of thumbnails) go out together.
  final Map<String, Completer<String>> _waiting = <String, Completer<String>>{};
  Timer? _flush;

  @override
  Future<String> urlFor(TaskPhoto photo, {bool refresh = false}) {
    final path = photo.storagePath;
    if (refresh) _cache.remove(path);
    return _cache.putIfAbsent(path, () {
      final completer = _waiting.putIfAbsent(path, Completer<String>.new);
      _flush ??= Timer(Duration.zero, _send);
      return completer.future.catchError((Object error) {
        // Never cache a failure: the next attempt should retry.
        _cache.remove(path);
        throw error; // ignore: only_throw_errors
      });
    });
  }

  Future<void> _send() async {
    _flush = null;
    final batch = Map<String, Completer<String>>.of(_waiting);
    _waiting.clear();
    final paths = batch.keys.toList(growable: false);
    for (var start = 0; start < paths.length; start += _maxBatch) {
      final chunk = paths.sublist(
        start,
        start + _maxBatch > paths.length ? paths.length : start + _maxBatch,
      );
      try {
        final urls = await _api.sign(chunk);
        for (final path in chunk) {
          final url = urls[path];
          if (url == null) {
            batch[path]!.completeError(const OperationFailure(
              OperationFailureKind.notFound,
              'The photo is not available.',
            ));
          } else {
            batch[path]!.complete(url);
          }
        }
      } catch (error) {
        for (final path in chunk) {
          batch[path]!.completeError(error);
        }
      }
    }
  }
}

/// Full-screen, swipeable, zoomable viewer for a task's evidence photos.
/// Pushed on the root navigator so the task detail state underneath is
/// untouched when it closes.
class TaskPhotoViewer extends StatefulWidget {
  const TaskPhotoViewer({
    required this.photos,
    required this.initialIndex,
    required this.urls,
    super.key,
  });

  final List<TaskPhoto> photos;
  final int initialIndex;
  final TaskPhotoUrlProvider urls;

  static Future<void> open(
    BuildContext context, {
    required List<TaskPhoto> photos,
    required int initialIndex,
    required TaskPhotoUrlProvider urls,
  }) =>
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => TaskPhotoViewer(
            photos: photos,
            initialIndex: initialIndex,
            urls: urls,
          ),
        ),
      );

  @override
  State<TaskPhotoViewer> createState() => _TaskPhotoViewerState();
}

class _TaskPhotoViewerState extends State<TaskPhotoViewer> {
  late final PageController _pages =
      PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photo = widget.photos[_index];
    return Scaffold(
      key: const Key('photo-viewer'),
      backgroundColor: Colors.black,
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: PageView.builder(
              controller: _pages,
              onPageChanged: (index) => setState(() => _index = index),
              itemCount: widget.photos.length,
              itemBuilder: (context, index) => _PhotoPage(
                photo: widget.photos[index],
                urls: widget.urls,
              ),
            ),
          ),
          // Top bar: close + counter, above the photo.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  children: <Widget>[
                    Material(
                      color: Colors.black45,
                      shape: const CircleBorder(),
                      child: IconButton(
                        key: const Key('photo-viewer-close'),
                        tooltip: context.l10n.commonBack,
                        color: Colors.white,
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ),
                    const Spacer(),
                    if (widget.photos.length > 1)
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: Text(
                            '${_index + 1} / ${widget.photos.length}',
                            key: const Key('photo-viewer-counter'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          // Bottom bar: caption / type and capture time.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Container(
                width: double.infinity,
                color: Colors.black45,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      photo.caption ??
                          photo.photoType.localizedLabel(context.l10n),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      taskDateTimeLabel(photo.createdAt),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One page of the viewer: signed-URL fetch -> full-resolution image with
/// pinch zoom and pan. Failures (offline, expired URL, missing object)
/// show a retry that re-requests a fresh signed URL.
class _PhotoPage extends StatefulWidget {
  const _PhotoPage({required this.photo, required this.urls});

  final TaskPhoto photo;
  final TaskPhotoUrlProvider urls;

  @override
  State<_PhotoPage> createState() => _PhotoPageState();
}

class _PhotoPageState extends State<_PhotoPage> {
  late Future<String> _url = widget.urls.urlFor(widget.photo);

  void _retry() {
    setState(() {
      _url = widget.urls.urlFor(widget.photo, refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<String>(
        future: _url,
        builder: (context, snapshot) {
          if (snapshot.hasError) return _error(context);
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }
          final url = snapshot.data!;
          return InteractiveViewer(
            minScale: 1,
            maxScale: 6,
            child: Center(
              child: Image.network(
                url,
                fit: BoxFit.contain,
                width: double.infinity,
                // Evict a possibly-expired cached response before retrying.
                errorBuilder: (context, error, stackTrace) {
                  NetworkImage(url).evict();
                  return _error(context);
                },
                loadingBuilder: (context, child, progress) => progress == null
                    ? child
                    : Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          value: progress.expectedTotalBytes == null
                              ? null
                              : progress.cumulativeBytesLoaded /
                                  progress.expectedTotalBytes!,
                        ),
                      ),
              ),
            ),
          );
        },
      );

  Widget _error(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.broken_image_outlined,
              color: Colors.white70,
              size: 44,
            ),
            const SizedBox(height: 10),
            Text(
              context.l10n.photoLoadFailed,
              key: const Key('photo-viewer-error'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: const Key('photo-viewer-retry'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white54),
              ),
              onPressed: _retry,
              icon: const Icon(Icons.refresh),
              label: Text(context.l10n.commonRetry),
            ),
          ],
        ),
      );
}

/// Small rounded thumbnail for evidence list tiles; falls back to the
/// generic photo icon while loading or when the image can't be fetched.
class TaskPhotoThumbnail extends StatelessWidget {
  const TaskPhotoThumbnail({
    required this.photo,
    required this.urls,
    super.key,
  });

  final TaskPhoto photo;
  final TaskPhotoUrlProvider? urls;

  @override
  Widget build(BuildContext context) {
    const fallback = CircleAvatar(
      backgroundColor: AppColors.softGreen,
      child: Icon(Icons.photo_outlined),
    );
    final provider = urls;
    if (provider == null) return fallback;
    return FutureBuilder<String>(
      future: provider.urlFor(photo),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return fallback;
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            snapshot.data!,
            width: 44,
            height: 44,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => fallback,
          ),
        );
      },
    );
  }
}
