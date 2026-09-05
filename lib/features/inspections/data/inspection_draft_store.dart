import 'dart:convert';

import 'package:al_wahat_farm_flutter/core/cache/local_cache_store.dart';
import 'package:al_wahat_farm_flutter/features/inspections/data/inspection_repository.dart';
import 'package:al_wahat_farm_flutter/features/inspections/domain/inspection_models.dart';
import 'package:al_wahat_farm_flutter/features/sync/data/pending_photo_store.dart';
import 'package:al_wahat_farm_flutter/features/sync/domain/pending_photo.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/task_evidence.dart';

class InspectionStationDraft {
  const InspectionStationDraft({
    required this.results,
    required this.photos,
  });

  final List<InspectionTreeResult> results;
  final Map<String, PreparedTaskEvidence> photos;
}

/// Persists an in-progress station form independently of the outbox. This
/// protects issue selections, notes, and captured photo bytes if the process is
/// killed before the inspector taps "Save and next".
class InspectionDraftStore {
  const InspectionDraftStore({
    required LocalCacheStore cache,
    required PendingPhotoStore pendingPhotos,
    required String userId,
    int Function()? clock,
  })  : _cache = cache,
        _pendingPhotos = pendingPhotos,
        _userId = userId,
        _clock = clock;

  static const _draftPrefix = '${privateCachePrefix}inspection_draft:';
  static const _photoPrefix = 'inspection-draft:';

  final LocalCacheStore _cache;
  final PendingPhotoStore _pendingPhotos;
  final String _userId;
  final int Function()? _clock;

  Future<PreparedTaskEvidence?> loadPreparedPhoto(String blobKey) async {
    final pending = await _pendingPhotos.get(blobKey);
    if (pending == null) return null;
    return PreparedTaskEvidence(
      bytes: pending.bytes,
      filename: pending.filename,
      contentType: pending.contentType,
    );
  }

  Future<InspectionStationDraft?> load(
    String sessionId,
    int stationIndex,
  ) async {
    final canonical = await _canonicalSessionId(sessionId);
    final raw = await _cache.read(_key(canonical, stationIndex));
    if (raw == null) return null;
    try {
      final json = Map<String, Object?>.from(jsonDecode(raw) as Map);
      final results = (json['results']! as List<Object?>)
          .map(
            (item) => InspectionTreeResult.fromJson(
              Map<String, Object?>.from(item! as Map),
            ),
          )
          .toList(growable: false);
      final photos = <String, PreparedTaskEvidence>{};
      for (final rawRef in json['photos']! as List<Object?>) {
        final ref = Map<String, Object?>.from(rawRef! as Map);
        final pending = await _pendingPhotos.get(ref['blob_key']! as String);
        if (pending == null) continue;
        photos[ref['logical_key']! as String] = PreparedTaskEvidence(
          bytes: pending.bytes,
          filename: pending.filename,
          contentType: pending.contentType,
        );
      }
      return InspectionStationDraft(results: results, photos: photos);
    } catch (_) {
      await clear(canonical, stationIndex);
      return null;
    }
  }

  Future<void> save({
    required String sessionId,
    required int stationIndex,
    required String farmId,
    required String taskId,
    required List<InspectionTreeResult> results,
    required Map<String, PreparedTaskEvidence> photos,
  }) async {
    final canonical = await _canonicalSessionId(sessionId);
    await clear(canonical, stationIndex);
    final refs = <Map<String, Object?>>[];
    for (final entry in photos.entries) {
      final blobKey = _photoKey(canonical, stationIndex, entry.key);
      refs.add(<String, Object?>{
        'logical_key': entry.key,
        'blob_key': blobKey,
      });
      await _pendingPhotos.put(PendingPhoto(
        opId: blobKey,
        taskId: taskId,
        userId: _userId,
        farmId: farmId,
        photoType: 'issue_draft',
        filename: entry.value.filename,
        contentType: entry.value.contentType,
        bytes: entry.value.bytes,
        createdAt: _clock?.call() ?? DateTime.now().millisecondsSinceEpoch,
      ));
    }
    await _cache.write(
      _key(canonical, stationIndex),
      jsonEncode(<String, Object?>{
        'results': results.map((item) => item.toJson()).toList(growable: false),
        'photos': refs,
      }),
    );
  }

  Future<void> clear(String sessionId, int stationIndex) async {
    final canonical = await _canonicalSessionId(sessionId);
    final key = _key(canonical, stationIndex);
    final raw = await _cache.read(key);
    if (raw != null) {
      try {
        final json = Map<String, Object?>.from(jsonDecode(raw) as Map);
        for (final rawRef
            in (json['photos'] as List<Object?>?) ?? const <Object?>[]) {
          final ref = Map<String, Object?>.from(rawRef! as Map);
          await _pendingPhotos.delete(ref['blob_key']! as String);
        }
      } catch (_) {
        // Removing the metadata is still safer than retaining a corrupt draft.
      }
    }
    await _cache.remove(key);
  }

  Future<String> _canonicalSessionId(String sessionId) async {
    if (sessionId.startsWith(OfflineInspectionRepository.localPrefix)) {
      return sessionId;
    }
    return await _cache.read(
          OfflineInspectionRepository.reverseSessionKey(sessionId),
        ) ??
        sessionId;
  }

  static String _key(String sessionId, int stationIndex) =>
      '$_draftPrefix$sessionId:$stationIndex';

  static String _photoKey(
    String sessionId,
    int stationIndex,
    String logicalKey,
  ) =>
      '$_photoPrefix$sessionId:$stationIndex:$logicalKey';
}
