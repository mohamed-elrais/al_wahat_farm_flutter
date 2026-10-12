import 'dart:typed_data';

import 'package:al_wahat_farm_flutter/core/errors/operation_failure.dart';
import 'package:al_wahat_farm_flutter/core/media/photo_compression.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/task_evidence.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DeviceTaskEvidencePicker implements TaskEvidencePicker {
  DeviceTaskEvidencePicker({ImagePicker? picker, PhotoCompressor? compressor})
      : _picker = picker ?? ImagePicker(),
        _compress = compressor ?? compressPhotoForUpload;

  static const maxBytes = 10 * 1024 * 1024;

  final ImagePicker _picker;
  final PhotoCompressor _compress;

  @override
  Future<PreparedTaskEvidence?> pick(TaskEvidenceSource source) async {
    final picked = await _picker.pickImage(
      source: source == TaskEvidenceSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
    );
    if (picked == null) return null;

    final Uint8List compressed;
    try {
      compressed = await _compress(await picked.readAsBytes());
    } catch (error) {
      // e.g. a file the platform cannot decode as an image.
      throw OperationFailure(
        OperationFailureKind.invalidInput,
        'The selected evidence image could not be prepared.',
        cause: error,
      );
    }
    if (compressed.isEmpty) {
      throw const OperationFailure(
        OperationFailureKind.invalidInput,
        'The selected evidence image could not be prepared.',
      );
    }
    if (compressed.length > maxBytes) {
      throw const OperationFailure(
        OperationFailureKind.invalidInput,
        'The prepared evidence is larger than 10 MiB.',
      );
    }

    final originalName = picked.name.trim().isEmpty ? 'evidence' : picked.name;
    final baseName = originalName.replaceFirst(RegExp(r'\.[^.]+$'), '');
    return PreparedTaskEvidence(
      bytes: compressed,
      filename: '${_safeFilename(baseName)}.jpg',
      contentType: 'image/jpeg',
    );
  }
}

class SupabaseTaskEvidenceStorage implements TaskEvidenceStorage {
  SupabaseTaskEvidenceStorage(
    this._client, {
    int Function()? timestamp,
  }) : _timestamp =
            timestamp ?? (() => DateTime.now().toUtc().microsecondsSinceEpoch);

  static const bucket = 'farm-evidence';

  final SupabaseClient _client;
  final int Function() _timestamp;

  @override
  Future<String> upload({
    required String userId,
    required String farmId,
    required String taskId,
    required PreparedTaskEvidence evidence,
  }) async {
    final path = TaskEvidencePath.build(
      userId: userId,
      farmId: farmId,
      taskId: taskId,
      filename: evidence.filename,
      timestamp: _timestamp(),
    );
    try {
      await _client.storage.from(bucket).uploadBinary(
            path,
            evidence.bytes,
            fileOptions: FileOptions(
              contentType: evidence.contentType,
              upsert: false,
            ),
          );
      return path;
    } on StorageException catch (error) {
      throw OperationFailure(
        OperationFailureKind.unexpected,
        'The private task evidence could not be uploaded.',
        cause: error,
      );
    }
  }
}

class TaskEvidencePath {
  const TaskEvidencePath._();

  static String build({
    required String userId,
    required String farmId,
    required String taskId,
    required String filename,
    required int timestamp,
  }) =>
      '$userId/$farmId/$taskId/${timestamp}_${_safeFilename(filename)}';
}

String _safeFilename(String value) {
  final safe = value
      .replaceAll(RegExp('[^A-Za-z0-9._-]+'), '-')
      .replaceAll(RegExp('-+'), '-')
      .replaceAll(RegExp(r'^[-.]+|[-.]+$'), '');
  return safe.isEmpty ? 'task-evidence.jpg' : safe;
}
