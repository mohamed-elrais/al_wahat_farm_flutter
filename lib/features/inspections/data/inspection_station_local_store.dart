import 'package:al_wahat_farm_flutter/core/cache/local_cache_store.dart';
import 'package:al_wahat_farm_flutter/core/cache/sqflite_cache_store.dart';
import 'package:al_wahat_farm_flutter/core/database/app_database.dart';
import 'package:al_wahat_farm_flutter/features/sync/data/outbox_store.dart';
import 'package:al_wahat_farm_flutter/features/sync/data/pending_photo_store.dart';
import 'package:al_wahat_farm_flutter/features/sync/domain/pending_mutation.dart';
import 'package:al_wahat_farm_flutter/features/sync/domain/pending_photo.dart';

/// Persists every durable part of an offline inspection-station save as one
/// unit. The UI must never advance with only one tree, an outbox operation, or
/// a photo blob saved independently from the rest of the station.
abstract interface class InspectionStationLocalStore {
  Future<void> commit({
    required PendingMutation mutation,
    required List<PendingPhoto> photos,
    required String cacheKey,
    required String cacheValue,
  });
}

/// Device implementation. All writes share the same SQLite transaction and
/// are rolled back automatically if any insert fails.
class SqfliteInspectionStationLocalStore
    implements InspectionStationLocalStore {
  const SqfliteInspectionStationLocalStore(this._database);

  final AppDatabase _database;

  @override
  Future<void> commit({
    required PendingMutation mutation,
    required List<PendingPhoto> photos,
    required String cacheKey,
    required String cacheValue,
  }) =>
      _database.db.transaction((transaction) async {
        for (final photo in photos) {
          await SqflitePendingPhotoStore.putWithExecutor(transaction, photo);
        }
        await SqfliteOutboxStore.enqueueWithExecutor(transaction, mutation);
        await SqfliteCacheStore.writeWithExecutor(
          transaction,
          cacheKey,
          cacheValue,
        );
      });
}

/// Compensating implementation for the in-memory startup fallback and unit
/// tests. Persistent app sessions use [SqfliteInspectionStationLocalStore].
class CoordinatedInspectionStationLocalStore
    implements InspectionStationLocalStore {
  const CoordinatedInspectionStationLocalStore({
    required LocalCacheStore cache,
    required OutboxStore outbox,
    required PendingPhotoStore pendingPhotos,
  })  : _cache = cache,
        _outbox = outbox,
        _pendingPhotos = pendingPhotos;

  final LocalCacheStore _cache;
  final OutboxStore _outbox;
  final PendingPhotoStore _pendingPhotos;

  @override
  Future<void> commit({
    required PendingMutation mutation,
    required List<PendingPhoto> photos,
    required String cacheKey,
    required String cacheValue,
  }) async {
    final previousCacheValue = await _cache.read(cacheKey);
    final existingOperations = <String>{
      ...(await _outbox.pending()).map((operation) => operation.opId),
      ...(await _outbox.failed()).map((operation) => operation.opId),
    };
    final existingPhotoIds = <String>{};
    for (final photo in photos) {
      if (await _pendingPhotos.get(photo.opId) != null) {
        existingPhotoIds.add(photo.opId);
      }
    }

    try {
      for (final photo in photos) {
        await _pendingPhotos.put(photo);
      }
      await _outbox.enqueue(mutation);
      await _cache.write(cacheKey, cacheValue);
    } catch (_) {
      if (!existingOperations.contains(mutation.opId)) {
        await _outbox.discard(mutation.opId);
      }
      for (final photo in photos) {
        if (!existingPhotoIds.contains(photo.opId)) {
          await _pendingPhotos.delete(photo.opId);
        }
      }
      if (previousCacheValue == null) {
        await _cache.remove(cacheKey);
      } else {
        await _cache.write(cacheKey, previousCacheValue);
      }
      rethrow;
    }
  }
}
