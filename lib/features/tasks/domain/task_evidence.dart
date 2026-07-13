import 'dart:typed_data';

import 'package:al_wahat_farm_flutter/features/tasks/domain/farm_task.dart';

enum TaskEvidenceSource { camera, gallery }

class PreparedTaskEvidence {
  const PreparedTaskEvidence({
    required this.bytes,
    required this.filename,
    required this.contentType,
  });

  final Uint8List bytes;
  final String filename;
  final String contentType;
}

abstract interface class TaskEvidencePicker {
  Future<PreparedTaskEvidence?> pick(TaskEvidenceSource source);
}

abstract interface class TaskEvidenceStorage {
  Future<String> upload({
    required String userId,
    required String farmId,
    required String taskId,
    required PreparedTaskEvidence evidence,
  });
}

class TaskEvidenceRegistration {
  const TaskEvidenceRegistration({
    required this.taskId,
    required this.storagePath,
    required this.type,
    this.caption,
  });

  final String taskId;
  final String storagePath;
  final TaskPhotoType type;
  final String? caption;

  Map<String, Object?> toRpcParameters() => <String, Object?>{
        'p_task_id': taskId,
        'p_storage_path': storagePath,
        'p_photo_type': type.wireValue,
        'p_caption': caption,
      };
}
