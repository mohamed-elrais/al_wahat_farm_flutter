import 'dart:typed_data';

import 'package:al_wahat_farm_flutter/core/errors/operation_failure.dart';
import 'package:al_wahat_farm_flutter/core/media/photo_compression.dart';
import 'package:al_wahat_farm_flutter/features/issues/domain/issue_photo.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DeviceIssuePhotoPicker implements IssuePhotoPicker {
  DeviceIssuePhotoPicker({ImagePicker? picker, PhotoCompressor? compressor})
      : _picker = picker ?? ImagePicker(),
        _compress = compressor ?? compressPhotoForUpload;

  static const maxBytes = 10 * 1024 * 1024;

  final ImagePicker _picker;
  final PhotoCompressor _compress;

  @override
  Future<PreparedIssuePhoto?> pick(IssuePhotoSource source) async {
    final picked = await _picker.pickImage(
      source: source == IssuePhotoSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
    );
    if (picked == null) return null;

    final Uint8List compressed;
    try {
      compressed = await _compress(await picked.readAsBytes());
    } catch (error) {
      // e.g. a decode failure, or a missing `pica` script on the web.
      throw OperationFailure(
        OperationFailureKind.invalidInput,
        'The selected image could not be prepared.',
        cause: error,
      );
    }
    if (compressed.isEmpty) {
      throw const OperationFailure(
        OperationFailureKind.invalidInput,
        'The selected image could not be prepared.',
      );
    }
    if (compressed.length > maxBytes) {
      throw const OperationFailure(
        OperationFailureKind.invalidInput,
        'The prepared image is larger than 10 MiB.',
      );
    }

    final originalName = picked.name.trim().isEmpty ? 'issue' : picked.name;
    final baseName = originalName.replaceFirst(RegExp(r'\.[^.]+$'), '');
    return PreparedIssuePhoto(
      bytes: compressed,
      filename: '${_safeFilename(baseName)}.jpg',
      contentType: 'image/jpeg',
    );
  }
}

class SupabaseIssuePhotoStorage implements IssuePhotoStorage {
  SupabaseIssuePhotoStorage(
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
    required PreparedIssuePhoto photo,
  }) async {
    final path = IssuePhotoPath.build(
      userId: userId,
      farmId: farmId,
      taskId: taskId,
      filename: photo.filename,
      timestamp: _timestamp(),
    );
    await _client.storage.from(bucket).uploadBinary(
          path,
          photo.bytes,
          fileOptions: FileOptions(
            contentType: photo.contentType,
            upsert: false,
          ),
        );
    return path;
  }

  @override
  Future<void> delete(String storagePath) async {
    await _client.storage.from(bucket).remove(<String>[storagePath]);
  }
}

class IssuePhotoPath {
  const IssuePhotoPath._();

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
  return safe.isEmpty ? 'issue-photo.jpg' : safe;
}
