import 'dart:typed_data';

/// Photo evidence captured offline, awaiting upload + registration on sync.
/// Paired with an outbox op via [opId]. Kept free of task-domain types so the
/// sync layer stays decoupled; [photoType] is the backend wire value.
class PendingPhoto {
  const PendingPhoto({
    required this.opId,
    required this.taskId,
    required this.userId,
    required this.farmId,
    required this.photoType,
    required this.filename,
    required this.contentType,
    required this.bytes,
    required this.createdAt,
    this.caption,
    this.uploadedPath,
  });

  final String opId;
  final String taskId;
  final String userId;
  final String farmId;
  final String photoType;
  final String filename;
  final String contentType;
  final Uint8List bytes;
  final int createdAt;
  final String? caption;

  /// Set once the blob has been uploaded to Storage, so a register retry does
  /// not re-upload under a new path (keeps the flow duplicate-safe).
  final String? uploadedPath;
}
