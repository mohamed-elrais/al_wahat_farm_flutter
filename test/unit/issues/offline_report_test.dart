import 'dart:async';
import 'dart:typed_data';

import 'package:al_wahat_farm_flutter/core/connectivity/connectivity_service.dart';
import 'package:al_wahat_farm_flutter/features/issues/data/issue_mutation_executor.dart';
import 'package:al_wahat_farm_flutter/features/issues/data/offline_issue_queue.dart';
import 'package:al_wahat_farm_flutter/features/issues/data/tree_issue_repository.dart';
import 'package:al_wahat_farm_flutter/features/issues/domain/issue_photo.dart';
import 'package:al_wahat_farm_flutter/features/issues/domain/tree_issue_draft.dart';
import 'package:al_wahat_farm_flutter/features/issues/presentation/issue_report_controller.dart';
import 'package:al_wahat_farm_flutter/features/sync/data/outbox_store.dart';
import 'package:al_wahat_farm_flutter/features/sync/data/pending_photo_store.dart';
import 'package:al_wahat_farm_flutter/features/sync/domain/composite_mutation_executor.dart';
import 'package:al_wahat_farm_flutter/features/sync/domain/mutation_executor.dart';
import 'package:al_wahat_farm_flutter/features/sync/domain/pending_mutation.dart';
import 'package:al_wahat_farm_flutter/features/sync/domain/pending_photo.dart';
import 'package:al_wahat_farm_flutter/features/sync/domain/sync_engine.dart';
import 'package:al_wahat_farm_flutter/l10n/gen/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/phase4_fakes.dart';

final _en = AppLocalizationsEn();

class _OfflineConnectivity implements ConnectivityService {
  @override
  Future<NetworkStatus> current() async => NetworkStatus.offline;
  @override
  Stream<NetworkStatus> get changes => const Stream<NetworkStatus>.empty();
}

Future<ConnectivityController> _offline() async {
  final controller = ConnectivityController(_OfflineConnectivity());
  await controller.start();
  return controller;
}

const _draft = TreeIssueDraft(
  treeId: 'tree-id',
  type: TreeIssueType.pestOrDisease,
  severity: IssueSeverity.high,
  description: 'Aphids on new growth',
);

PreparedIssuePhoto _photo() => PreparedIssuePhoto(
      bytes: Uint8List.fromList(<int>[9, 8, 7]),
      filename: 'issue.jpg',
      contentType: 'image/jpeg',
    );

void main() {
  test('replaying a report sends the op id and reports without a photo',
      () async {
    final repo = FakeTreeIssueRepository();
    final photos = InMemoryPendingPhotoStore();
    final executor = IssueMutationExecutor(
      repository: repo,
      photoStorage: FakeIssuePhotoStorage(),
      pendingPhotos: photos,
    );

    await executor.execute(PendingMutation(
      opId: 'op1',
      kind: PendingMutationKind.reportIssue,
      payload: <String, Object?>{'draft': _draft.toJson()},
      createdAt: 0,
    ));

    expect(repo.events, <String>['report']);
    expect(repo.lastReportOpId, 'op1'); // p_op_id sent for ledger dedup
    expect(repo.reportedDraft?.type, TreeIssueType.pestOrDisease);
  });

  test('replaying a report uploads the photo to the real task path', () async {
    final repo = FakeTreeIssueRepository(
      reportResult: const ReportedTreeIssue(
        issueId: 'real-issue',
        taskId: 'real-task',
      ),
    );
    final storage = FakeIssuePhotoStorage();
    final photos = InMemoryPendingPhotoStore();
    await photos.put(PendingPhoto(
      opId: 'op2',
      taskId: '', // unknown at capture time; executor uses the report result
      userId: 'user-id',
      farmId: 'farm-id',
      photoType: 'issue',
      filename: 'issue.jpg',
      contentType: 'image/jpeg',
      bytes: Uint8List.fromList(<int>[9, 8, 7]),
      createdAt: 0,
    ));
    final executor = IssueMutationExecutor(
      repository: repo,
      photoStorage: storage,
      pendingPhotos: photos,
    );

    await executor.execute(PendingMutation(
      opId: 'op2',
      kind: PendingMutationKind.reportIssue,
      payload: <String, Object?>{'draft': _draft.toJson()},
      createdAt: 0,
    ));

    expect(repo.events, <String>['report', 'add-photo']);
    expect(storage.lastUploadTaskId, 'real-task'); // real id from the report
    expect(repo.attachedIssueId, 'real-issue');
    expect(repo.attachedStoragePath, storage.uploadedPath);
    expect(await photos.get('op2'), isNull); // blob cleared after registration
  });

  test('CompositeMutationExecutor routes reportIssue and rejects the unknown',
      () async {
    final repo = FakeTreeIssueRepository();
    final issueExecutor = IssueMutationExecutor(
      repository: repo,
      photoStorage: FakeIssuePhotoStorage(),
      pendingPhotos: InMemoryPendingPhotoStore(),
    );
    final composite = CompositeMutationExecutor(
      <PendingMutationKind, MutationExecutor>{
        PendingMutationKind.reportIssue: issueExecutor,
      },
    );

    await composite.execute(PendingMutation(
      opId: 'op3',
      kind: PendingMutationKind.reportIssue,
      payload: <String, Object?>{'draft': _draft.toJson()},
      createdAt: 0,
    ));
    expect(repo.events, contains('report'));

    expect(
      () => composite.execute(const PendingMutation(
        opId: 'op4',
        kind: PendingMutationKind.startTask,
        payload: <String, Object?>{'taskId': 't'},
        createdAt: 0,
      )),
      throwsStateError,
    );
  });

  test('offline submit queues a report + photo and reports the offline message',
      () async {
    final connectivity = await _offline();
    addTearDown(connectivity.dispose);
    final outbox = InMemoryOutboxStore();
    final photos = InMemoryPendingPhotoStore();
    final repo = FakeTreeIssueRepository();
    final syncEngine = SyncEngine(
      outbox: outbox,
      executor: IssueMutationExecutor(
        repository: repo,
        photoStorage: FakeIssuePhotoStorage(),
        pendingPhotos: photos,
      ),
      connectivity: connectivity,
    );
    final controller = IssueReportController(
      repository: repo,
      photoPicker: FakeIssuePhotoPicker(photo: _photo()),
      photoStorage: FakeIssuePhotoStorage(),
      userId: 'user-id',
      farmId: 'farm-id',
      treeId: 'tree-id',
      connectivity: connectivity,
      offlineQueue: OutboxIssueQueue(
        outbox: outbox,
        pendingPhotos: photos,
        syncEngine: syncEngine,
      ),
    );
    addTearDown(controller.dispose);

    await controller.pickPhoto(IssuePhotoSource.camera);
    final ok = await controller.submit(
      type: TreeIssueType.pestOrDisease,
      severity: IssueSeverity.high,
      description: 'Aphids',
    );

    expect(ok, isTrue);
    expect(repo.events, isEmpty); // nothing hit the backend while offline
    final pending = await outbox.pending();
    expect(pending, hasLength(1));
    expect(pending.single.kind, PendingMutationKind.reportIssue);
    expect(await photos.get(pending.single.opId), isNotNull); // photo stored
    expect(
      controller.message?.call(_en),
      _en.issueMsgReportedOffline,
    );
  });
}
