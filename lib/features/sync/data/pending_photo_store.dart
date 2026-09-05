import 'dart:typed_data';

import 'package:al_wahat_farm_flutter/core/database/app_database.dart';
import 'package:al_wahat_farm_flutter/features/sync/domain/pending_photo.dart';
import 'package:sqflite/sqflite.dart';

/// Stores offline-captured photo bytes keyed by the outbox op id.
abstract interface class PendingPhotoStore {
  Future<void> put(PendingPhoto photo);
  Future<PendingPhoto?> get(String opId);
  Future<void> markUploaded(String opId, String path);
  Future<void> delete(String opId);
  Future<void> deleteForOperation(String opId);
  Future<void> clear();
}

class SqflitePendingPhotoStore implements PendingPhotoStore {
  const SqflitePendingPhotoStore(this._database);

  final AppDatabase _database;

  @override
  Future<void> put(PendingPhoto photo) async {
    await _database.db.insert(
      AppDatabase.pendingPhotosTable,
      <String, Object?>{
        'op_id': photo.opId,
        'task_id': photo.taskId,
        'user_id': photo.userId,
        'farm_id': photo.farmId,
        'photo_type': photo.photoType,
        'caption': photo.caption,
        'filename': photo.filename,
        'content_type': photo.contentType,
        'bytes': photo.bytes,
        'uploaded_path': photo.uploadedPath,
        'created_at': photo.createdAt,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  @override
  Future<PendingPhoto?> get(String opId) async {
    final rows = await _database.db.query(
      AppDatabase.pendingPhotosTable,
      where: 'op_id = ?',
      whereArgs: <Object?>[opId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _fromRow(rows.first);
  }

  @override
  Future<void> markUploaded(String opId, String path) async {
    await _database.db.update(
      AppDatabase.pendingPhotosTable,
      <String, Object?>{'uploaded_path': path},
      where: 'op_id = ?',
      whereArgs: <Object?>[opId],
    );
  }

  @override
  Future<void> delete(String opId) async {
    await _database.db.delete(
      AppDatabase.pendingPhotosTable,
      where: 'op_id = ?',
      whereArgs: <Object?>[opId],
    );
  }

  @override
  Future<void> deleteForOperation(String opId) async {
    await _database.db.delete(
      AppDatabase.pendingPhotosTable,
      where: 'op_id = ? OR op_id LIKE ?',
      whereArgs: <Object?>[opId, '$opId::%'],
    );
  }

  @override
  Future<void> clear() async {
    await _database.db.delete(AppDatabase.pendingPhotosTable);
  }

  PendingPhoto _fromRow(Map<String, Object?> row) => PendingPhoto(
        opId: row['op_id']! as String,
        taskId: row['task_id']! as String,
        userId: row['user_id']! as String,
        farmId: row['farm_id']! as String,
        photoType: row['photo_type']! as String,
        caption: row['caption'] as String?,
        filename: row['filename']! as String,
        contentType: row['content_type']! as String,
        bytes: _bytes(row['bytes']),
        uploadedPath: row['uploaded_path'] as String?,
        createdAt: (row['created_at']! as num).toInt(),
      );

  Uint8List _bytes(Object? value) =>
      value is Uint8List ? value : Uint8List.fromList((value! as List).cast());
}

/// In-memory pending-photo store for tests.
class InMemoryPendingPhotoStore implements PendingPhotoStore {
  final Map<String, PendingPhoto> _entries = <String, PendingPhoto>{};

  @override
  Future<void> put(PendingPhoto photo) async {
    _entries.putIfAbsent(photo.opId, () => photo);
  }

  @override
  Future<PendingPhoto?> get(String opId) async => _entries[opId];

  @override
  Future<void> markUploaded(String opId, String path) async {
    final existing = _entries[opId];
    if (existing == null) return;
    _entries[opId] = PendingPhoto(
      opId: existing.opId,
      taskId: existing.taskId,
      userId: existing.userId,
      farmId: existing.farmId,
      photoType: existing.photoType,
      caption: existing.caption,
      filename: existing.filename,
      contentType: existing.contentType,
      bytes: existing.bytes,
      uploadedPath: path,
      createdAt: existing.createdAt,
    );
  }

  @override
  Future<void> delete(String opId) async {
    _entries.remove(opId);
  }

  @override
  Future<void> deleteForOperation(String opId) async {
    _entries.removeWhere(
      (key, _) => key == opId || key.startsWith('$opId::'),
    );
  }

  @override
  Future<void> clear() async {
    _entries.clear();
  }
}
