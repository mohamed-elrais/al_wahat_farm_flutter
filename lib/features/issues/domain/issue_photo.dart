import 'dart:typed_data';

enum IssuePhotoSource { camera, gallery }

class PreparedIssuePhoto {
  const PreparedIssuePhoto({
    required this.bytes,
    required this.filename,
    required this.contentType,
  });

  final Uint8List bytes;
  final String filename;
  final String contentType;
}

abstract interface class IssuePhotoPicker {
  Future<PreparedIssuePhoto?> pick(IssuePhotoSource source);
}

abstract interface class IssuePhotoStorage {
  Future<String> upload({
    required String userId,
    required String farmId,
    required String taskId,
    required PreparedIssuePhoto photo,
  });

  Future<void> delete(String storagePath);
}
