import 'dart:typed_data';
import 'package:al_wahat_farm_flutter/l10n/gen/app_localizations_en.dart';

import 'package:al_wahat_farm_flutter/core/errors/operation_failure.dart';
import 'package:al_wahat_farm_flutter/features/issues/data/tree_issue_repository.dart';
import 'package:al_wahat_farm_flutter/features/issues/domain/issue_photo.dart';
import 'package:al_wahat_farm_flutter/features/issues/domain/tree_issue_draft.dart';
import 'package:al_wahat_farm_flutter/features/issues/presentation/issue_report_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/phase4_fakes.dart';

final _enMessages = AppLocalizationsEn();

void main() {
  group('IssueReportController', () {
    late List<String> events;
    late FakeTreeIssueRepository repository;
    late FakeIssuePhotoPicker picker;
    late FakeIssuePhotoStorage storage;
    late IssueReportController controller;

    setUp(() {
      events = <String>[];
      repository = FakeTreeIssueRepository(events: events);
      picker = FakeIssuePhotoPicker(events: events);
      storage = FakeIssuePhotoStorage(events: events);
      controller = IssueReportController(
        repository: repository,
        photoPicker: picker,
        photoStorage: storage,
        userId: 'user-id',
        farmId: 'farm-id',
        treeId: 'tree-id',
        onPersisted: () async => events.add('refresh'),
      );
      addTearDown(controller.dispose);
    });

    test('reports issue and generated review task without a photo', () async {
      final saved = await controller.submit(
        type: TreeIssueType.cloggedDripper,
        severity: IssueSeverity.high,
        description: '  blocked emitter  ',
      );

      expect(saved, isTrue);
      expect(controller.stage, IssueSubmissionStage.success);
      expect(controller.result?.taskId, 'task-id');
      expect(repository.reportedDraft?.description, 'blocked emitter');
      expect(events, <String>['report', 'refresh']);
      expect(controller.canSubmit, isFalse);
      expect(
        await controller.submit(
          type: TreeIssueType.other,
          severity: IssueSeverity.low,
        ),
        isFalse,
      );
      expect(events.where((event) => event == 'report'), hasLength(1));
    });

    test('explains when a report confirms an existing active bucket', () async {
      final confirmed = IssueReportController(
        repository: FakeTreeIssueRepository(
          reportResult: const ReportedTreeIssue(
            issueId: 'existing-issue-id',
            taskId: 'review-task-id',
            confirmedExisting: true,
          ),
        ),
        photoPicker: picker,
        photoStorage: storage,
        userId: 'user-id',
        farmId: 'farm-id',
        treeId: 'tree-id',
      );
      addTearDown(confirmed.dispose);

      expect(
        await confirmed.submit(
          type: TreeIssueType.cloggedDripper,
          severity: IssueSeverity.high,
        ),
        isTrue,
      );
      expect(
        confirmed.message?.call(_enMessages),
        contains('existing active issue was confirmed'),
      );
      expect(
        confirmed.message?.call(_enMessages),
        contains('severity was not changed'),
      );
    });

    test('reports before uploading and registering selected evidence',
        () async {
      picker.photo = PreparedIssuePhoto(
        bytes: Uint8List.fromList(<int>[1, 2, 3]),
        filename: 'issue.jpg',
        contentType: 'image/jpeg',
      );
      await controller.pickPhoto(IssuePhotoSource.camera);
      final saved = await controller.submit(
        type: TreeIssueType.treeDamage,
        severity: IssueSeverity.urgent,
      );

      expect(saved, isTrue);
      expect(controller.stage, IssueSubmissionStage.success);
      expect(repository.attachedIssueId, 'issue-id');
      expect(
        events,
        <String>[
          'pick-photo',
          'report',
          'refresh',
          'upload-photo',
          'add-photo',
          'refresh',
        ],
      );
    });

    test('keeps persisted issue when evidence upload fails', () async {
      picker.photo = PreparedIssuePhoto(
        bytes: Uint8List.fromList(<int>[1]),
        filename: 'issue.jpg',
        contentType: 'image/jpeg',
      );
      storage.uploadFailure = const OperationFailure(
        OperationFailureKind.offline,
        'No connection.',
      );
      await controller.pickPhoto(IssuePhotoSource.gallery);
      final saved = await controller.submit(
        type: TreeIssueType.pestOrDisease,
        severity: IssueSeverity.medium,
      );

      expect(saved, isFalse);
      expect(controller.result?.issueId, 'issue-id');
      expect(controller.stage, IssueSubmissionStage.partialSuccess);
      expect(controller.message?.call(_enMessages),
          contains('issue and review task were saved'));
      expect(
          events, <String>['pick-photo', 'report', 'refresh', 'upload-photo']);
    });

    test('retries ambiguous registration with the same uploaded path',
        () async {
      picker.photo = PreparedIssuePhoto(
        bytes: Uint8List.fromList(<int>[1, 2, 3]),
        filename: 'issue.jpg',
        contentType: 'image/jpeg',
      );
      repository.addPhotoFailure = const OperationFailure(
        OperationFailureKind.unexpected,
        'The registration response was lost.',
      );
      await controller.pickPhoto(IssuePhotoSource.camera);

      expect(
        await controller.submit(
          type: TreeIssueType.treeDamage,
          severity: IssueSeverity.high,
        ),
        isFalse,
      );
      expect(controller.stage, IssueSubmissionStage.partialSuccess);
      expect(storage.uploadAttempts, 1);
      expect(storage.deletedPath, isNull);
      expect(repository.attachedStoragePath, storage.uploadedPath);

      repository.addPhotoFailure = null;
      expect(await controller.retryPhoto(), isTrue);

      expect(controller.stage, IssueSubmissionStage.success);
      expect(storage.uploadAttempts, 1);
      expect(storage.deletedPath, isNull);
      expect(
        events.where((event) => event == 'add-photo'),
        hasLength(2),
      );
      expect(repository.attachedStoragePath, storage.uploadedPath);
    });

    test('surfaces authorization denial without claiming success', () async {
      repository.reportFailure = const OperationFailure(
        OperationFailureKind.authorization,
        'Not authorized for this farm.',
      );

      final saved = await controller.submit(
        type: TreeIssueType.other,
        severity: IssueSeverity.low,
      );

      expect(saved, isFalse);
      expect(controller.stage, IssueSubmissionStage.failure);
      expect(controller.result, isNull);
      expect(controller.message?.call(_enMessages),
          'Not authorized for this farm.');
    });

    test('rejects a missing tree identity before repository access', () async {
      final invalid = IssueReportController(
        repository: repository,
        photoPicker: picker,
        photoStorage: storage,
        userId: 'user-id',
        farmId: 'farm-id',
        treeId: ' ',
      );
      addTearDown(invalid.dispose);

      final saved = await invalid.submit(
        type: TreeIssueType.other,
        severity: IssueSeverity.low,
      );

      expect(saved, isFalse);
      expect(invalid.message?.call(_enMessages), 'Tree identity is required');
      expect(events, isEmpty);
    });
  });
}
