import 'dart:typed_data';

import 'package:al_wahat_farm_flutter/core/errors/operation_failure.dart';
import 'package:al_wahat_farm_flutter/features/issues/data/issue_photo_service.dart';
import 'package:al_wahat_farm_flutter/features/issues/domain/issue_photo.dart';
import 'package:al_wahat_farm_flutter/features/tasks/data/task_evidence_service.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/task_evidence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

class _FakePicker extends ImagePicker {
  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async =>
      // On the VM XFile.name comes from the path (the name argument is
      // web-only), so pass both.
      XFile.fromData(
        Uint8List.fromList(<int>[1, 2, 3]),
        name: 'IMG 01.heic',
        path: '/picked/IMG 01.heic',
      );
}

Future<Uint8List> _failingCompressor(Uint8List _) async =>
    throw StateError('The image has no pixels.');

Future<Uint8List> _workingCompressor(Uint8List _) async =>
    Uint8List.fromList(<int>[0xFF, 0xD8, 0xFF]);

Matcher _preparationFailure(String message) => isA<OperationFailure>()
    .having(
        (failure) => failure.kind, 'kind', OperationFailureKind.invalidInput)
    .having((failure) => failure.message, 'message', message)
    .having((failure) => failure.cause, 'cause', isA<StateError>());

void main() {
  test('an issue photo encoder failure becomes an invalid-input failure', () {
    final picker = DeviceIssuePhotoPicker(
      picker: _FakePicker(),
      compressor: _failingCompressor,
    );

    expect(
      picker.pick(IssuePhotoSource.camera),
      throwsA(_preparationFailure('The selected image could not be prepared.')),
    );
  });

  test('a task evidence encoder failure becomes an invalid-input failure', () {
    final picker = DeviceTaskEvidencePicker(
      picker: _FakePicker(),
      compressor: _failingCompressor,
    );

    expect(
      picker.pick(TaskEvidenceSource.gallery),
      throwsA(_preparationFailure(
          'The selected evidence image could not be prepared.')),
    );
  });

  test('a prepared photo is a JPEG with a safe file name', () async {
    final photo = await DeviceIssuePhotoPicker(
      picker: _FakePicker(),
      compressor: _workingCompressor,
    ).pick(IssuePhotoSource.gallery);

    expect(photo!.bytes, <int>[0xFF, 0xD8, 0xFF]);
    expect(photo.filename, 'IMG-01.jpg');
    expect(photo.contentType, 'image/jpeg');
  });
}
