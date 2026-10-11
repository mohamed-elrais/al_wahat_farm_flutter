import 'dart:async';
import 'dart:typed_data';

import 'package:al_wahat_farm_flutter/core/cache/local_cache_store.dart';
import 'package:al_wahat_farm_flutter/core/connectivity/connectivity_service.dart';
import 'package:al_wahat_farm_flutter/core/errors/operation_failure.dart';
import 'package:al_wahat_farm_flutter/features/inspections/data/inspection_repository.dart';
import 'package:al_wahat_farm_flutter/features/inspections/domain/inspection_models.dart';
import 'package:al_wahat_farm_flutter/features/inspections/domain/inspection_route.dart';
import 'package:al_wahat_farm_flutter/features/issues/domain/tree_issue_draft.dart';
import 'package:al_wahat_farm_flutter/features/sync/data/outbox_store.dart';
import 'package:al_wahat_farm_flutter/features/sync/data/pending_photo_store.dart';
import 'package:al_wahat_farm_flutter/features/sync/domain/mutation_executor.dart';
import 'package:al_wahat_farm_flutter/features/sync/domain/pending_mutation.dart';
import 'package:al_wahat_farm_flutter/features/sync/domain/sync_engine.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/task_evidence.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/task_fakes.dart';

class _OfflineConnectivity implements ConnectivityService {
  @override
  Future<NetworkStatus> current() async => NetworkStatus.offline;

  @override
  Stream<NetworkStatus> get changes => const Stream<NetworkStatus>.empty();
}

class _OnlineConnectivity implements ConnectivityService {
  @override
  Future<NetworkStatus> current() async => NetworkStatus.online;

  @override
  Stream<NetworkStatus> get changes => const Stream<NetworkStatus>.empty();
}

class _NoopExecutor implements MutationExecutor {
  @override
  Future<void> execute(PendingMutation mutation) async {}
}

class _FakeInspectionRepository implements InspectionRepository {
  List<InspectionTreeResult>? savedResults;
  String? savedSessionId;
  String? savedOpId;
  String? submittedSessionId;
  String? submittedOpId;
  String? statusSessionId;
  String? statusOpId;

  @override
  Future<InspectionCreationResult> create(
    InspectionCreationDraft draft, {
    String? opId,
  }) async =>
      const InspectionCreationResult(
          sessionId: 'session-id', taskId: 'task-id');

  @override
  Future<InspectionDetails> loadByTask(String taskId) =>
      throw UnimplementedError();

  @override
  Future<void> takeOver(String sessionId, {String? opId}) async {}

  @override
  Future<void> saveStation(
    String sessionId,
    int stationIndex,
    List<InspectionTreeResult> results, {
    String? opId,
    Map<String, PreparedTaskEvidence> photos = const {},
    String? userId,
    String? farmId,
    String? taskId,
  }) async {
    savedResults = results;
    savedSessionId = sessionId;
    savedOpId = opId;
  }

  @override
  Future<void> setStatus(
    String sessionId,
    InspectionSessionStatus status, {
    String? opId,
  }) async {
    statusSessionId = sessionId;
    statusOpId = opId;
  }

  @override
  Future<void> submit(
    String sessionId, {
    String? note,
    String? opId,
  }) async {
    submittedSessionId = sessionId;
    submittedOpId = opId;
  }
}

class _FakeEvidenceStorage implements TaskEvidenceStorage {
  int uploads = 0;
  String? lastTaskId;

  @override
  Future<String> upload({
    required String userId,
    required String farmId,
    required String taskId,
    required PreparedTaskEvidence evidence,
  }) async {
    uploads++;
    lastTaskId = taskId;
    return '$userId/$farmId/$taskId/${evidence.filename}';
  }
}

void main() {
  test('offline station queues and replays one photo per selected issue',
      () async {
    final connectivity = ConnectivityController(_OfflineConnectivity());
    await connectivity.start();
    addTearDown(connectivity.dispose);
    final outbox = InMemoryOutboxStore();
    final pendingPhotos = InMemoryPendingPhotoStore();
    final base = _FakeInspectionRepository();
    final storage = _FakeEvidenceStorage();
    final cache = InMemoryCacheStore();
    final repository = OfflineInspectionRepository(
      inner: base,
      cache: cache,
      outbox: outbox,
      connectivity: connectivity,
      syncEngine: SyncEngine(
        outbox: outbox,
        executor: _NoopExecutor(),
        connectivity: connectivity,
      ),
      evidenceStorage: storage,
      pendingPhotos: pendingPhotos,
      userId: 'user-id',
    );
    final created = await repository.create(_creationDraft());
    final observedAt = DateTime.utc(2026, 9, 2);
    final results = <InspectionTreeResult>[
      InspectionTreeResult(
        treeId: 'tree-1',
        noNewIssueFound: false,
        clientObservedAt: observedAt,
        selectedIssues: const <InspectionSelectedIssue>[
          InspectionSelectedIssue(
            type: TreeIssueType.pestOrDisease,
            severity: IssueSeverity.high,
          ),
          InspectionSelectedIssue(
            type: TreeIssueType.treeDamage,
            severity: IssueSeverity.medium,
          ),
        ],
      ),
    ];
    final photos = <String, PreparedTaskEvidence>{
      'tree-1|pest_or_disease': PreparedTaskEvidence(
        bytes: Uint8List.fromList(<int>[1]),
        filename: 'pest.jpg',
        contentType: 'image/jpeg',
      ),
      'tree-1|tree_damage': PreparedTaskEvidence(
        bytes: Uint8List.fromList(<int>[2]),
        filename: 'fungus.jpg',
        contentType: 'image/jpeg',
      ),
    };

    await repository.saveStation(
      created.sessionId,
      1,
      results,
      photos: photos,
      farmId: 'farm-id',
      taskId: created.taskId,
      opId: 'station-save-op',
    );

    final pendingOperations = await outbox.pending();
    final createMutation = pendingOperations.singleWhere(
      (operation) => operation.kind == PendingMutationKind.createInspection,
    );
    final mutation = pendingOperations.singleWhere(
      (operation) =>
          operation.kind == PendingMutationKind.saveInspectionStation,
    );
    final refs = mutation.payload['photoRefs']! as List<Object?>;
    expect(mutation.kind, PendingMutationKind.saveInspectionStation);
    expect(mutation.opId, 'station-save-op');
    expect(refs, hasLength(2));
    for (final raw in refs) {
      final ref = Map<String, Object?>.from(raw! as Map);
      expect(await pendingPhotos.get(ref['blob_key']! as String), isNotNull);
    }

    final executor = InspectionMutationExecutor(
      base,
      evidenceStorage: storage,
      pendingPhotos: pendingPhotos,
      cache: cache,
      taskRepository: FakeTaskRepository(
        store: InMemoryTaskStore(),
        viewerProfileId: 'user-id',
        canManage: true,
      ),
    );
    await executor.execute(createMutation);
    await executor.execute(mutation);

    expect(storage.uploads, 2);
    expect(base.savedOpId, 'station-save-op');
    expect(
      base.savedResults!.single.selectedIssues
          .map((issue) => issue.photoStoragePath),
      everyElement(isNotNull),
    );
    for (final raw in refs) {
      final ref = Map<String, Object?>.from(raw! as Map);
      expect(await pendingPhotos.get(ref['blob_key']! as String), isNull);
    }
  });

  test('offline creation remains loadable after repository recreation',
      () async {
    final connectivity = ConnectivityController(_OfflineConnectivity());
    await connectivity.start();
    addTearDown(connectivity.dispose);
    final cache = InMemoryCacheStore();
    final outbox = InMemoryOutboxStore();
    final pendingPhotos = InMemoryPendingPhotoStore();
    final base = _FakeInspectionRepository();
    final engine = SyncEngine(
      outbox: outbox,
      executor: _NoopExecutor(),
      connectivity: connectivity,
    );
    final repository = OfflineInspectionRepository(
      inner: base,
      cache: cache,
      outbox: outbox,
      connectivity: connectivity,
      syncEngine: engine,
      evidenceStorage: _FakeEvidenceStorage(),
      pendingPhotos: pendingPhotos,
      userId: 'manager-id',
    );

    final result = await repository.create(_creationDraft());
    expect(result.taskId, startsWith('local:'));
    expect((await outbox.pending()).single.kind,
        PendingMutationKind.createInspection);

    final recreated = OfflineInspectionRepository(
      inner: base,
      cache: cache,
      outbox: outbox,
      connectivity: connectivity,
      syncEngine: engine,
      evidenceStorage: _FakeEvidenceStorage(),
      pendingPhotos: pendingPhotos,
      userId: 'manager-id',
    );
    final details = await recreated.loadByTask(result.taskId);
    expect(details.session.id, result.sessionId);
    expect(details.session.totalTrees, 2);
    expect(details.items.map((item) => item.routeItem.treeId),
        <String>['tree-1', 'tree-2']);

    final cachedTasks = await cache.read('awf_private:tasks:farm-id');
    expect(cachedTasks, contains(result.taskId));
    expect(cachedTasks, contains('inspection_route_version'));
  });

  test('replay remaps every dependent local inspection and photo id', () async {
    final connectivity = ConnectivityController(_OfflineConnectivity());
    await connectivity.start();
    addTearDown(connectivity.dispose);
    final cache = InMemoryCacheStore();
    final outbox = InMemoryOutboxStore();
    final pendingPhotos = InMemoryPendingPhotoStore();
    final base = _FakeInspectionRepository();
    final storage = _FakeEvidenceStorage();
    final engine = SyncEngine(
      outbox: outbox,
      executor: _NoopExecutor(),
      connectivity: connectivity,
    );
    final repository = OfflineInspectionRepository(
      inner: base,
      cache: cache,
      outbox: outbox,
      connectivity: connectivity,
      syncEngine: engine,
      evidenceStorage: storage,
      pendingPhotos: pendingPhotos,
      userId: 'manager-id',
    );
    final created = await repository.create(_creationDraft());
    await repository.setStatus(
      created.sessionId,
      InspectionSessionStatus.inProgress,
    );
    await repository.saveStation(
      created.sessionId,
      1,
      <InspectionTreeResult>[
        InspectionTreeResult(
          treeId: 'tree-1',
          noNewIssueFound: false,
          clientObservedAt: DateTime.utc(2026, 9, 3),
          selectedIssues: const <InspectionSelectedIssue>[
            InspectionSelectedIssue(
              type: TreeIssueType.treeDamage,
              severity: IssueSeverity.medium,
            ),
          ],
        ),
      ],
      photos: <String, PreparedTaskEvidence>{
        'tree-1|tree_damage': PreparedTaskEvidence(
          bytes: Uint8List.fromList(<int>[9, 8, 7]),
          filename: 'damage.jpg',
          contentType: 'image/jpeg',
        ),
      },
      farmId: 'farm-id',
      taskId: created.taskId,
    );
    await repository.submit(created.sessionId);

    final cachedBeforeReplay = await repository.loadByTask(created.taskId);
    final cachedObservation = cachedBeforeReplay.observations.single;
    expect(cachedObservation.type, TreeIssueType.treeDamage);
    expect(cachedObservation.localPhotoBlobKey, isNotNull);

    final executor = InspectionMutationExecutor(
      base,
      evidenceStorage: storage,
      pendingPhotos: pendingPhotos,
      cache: cache,
      taskRepository: FakeTaskRepository(
        store: InMemoryTaskStore(),
        viewerProfileId: 'manager-id',
        canManage: true,
      ),
    );
    for (final mutation in await outbox.pending()) {
      await executor.execute(mutation);
    }

    expect(base.statusSessionId, 'session-id');
    expect(base.savedSessionId, 'session-id');
    expect(base.submittedSessionId, 'session-id');
    expect(storage.lastTaskId, 'task-id');
    expect(
      await OfflineInspectionRepository.resolveTaskId(cache, created.taskId),
      'task-id',
    );
    expect(
      await OfflineInspectionRepository.resolveSessionId(
        cache,
        created.sessionId,
      ),
      'session-id',
    );
  });

  test('manager takeover clearly requires a connection', () async {
    final connectivity = ConnectivityController(_OfflineConnectivity());
    await connectivity.start();
    addTearDown(connectivity.dispose);
    final outbox = InMemoryOutboxStore();
    final pendingPhotos = InMemoryPendingPhotoStore();
    final repository = OfflineInspectionRepository(
      inner: _FakeInspectionRepository(),
      cache: InMemoryCacheStore(),
      outbox: outbox,
      connectivity: connectivity,
      syncEngine: SyncEngine(
        outbox: outbox,
        executor: _NoopExecutor(),
        connectivity: connectivity,
      ),
      evidenceStorage: _FakeEvidenceStorage(),
      pendingPhotos: pendingPhotos,
      userId: 'manager-id',
    );

    await expectLater(
      repository.takeOver('session-id'),
      throwsA(
        isA<OperationFailure>().having(
          (failure) => failure.kind,
          'kind',
          OperationFailureKind.offline,
        ),
      ),
    );
    expect(await outbox.pending(), isEmpty);
  });

  test('online status and submit preserve caller operation ids', () async {
    final connectivity = ConnectivityController(_OnlineConnectivity());
    await connectivity.start();
    addTearDown(connectivity.dispose);
    final outbox = InMemoryOutboxStore();
    final base = _FakeInspectionRepository();
    final repository = OfflineInspectionRepository(
      inner: base,
      cache: InMemoryCacheStore(),
      outbox: outbox,
      connectivity: connectivity,
      syncEngine: SyncEngine(
        outbox: outbox,
        executor: _NoopExecutor(),
        connectivity: connectivity,
      ),
      evidenceStorage: _FakeEvidenceStorage(),
      pendingPhotos: InMemoryPendingPhotoStore(),
      userId: 'manager-id',
    );

    await repository.setStatus(
      'session-id',
      InspectionSessionStatus.inProgress,
      opId: 'status-op',
    );
    await repository.submit(
      'session-id',
      note: 'Complete',
      opId: 'submit-op',
    );

    expect(base.statusOpId, 'status-op');
    expect(base.submittedOpId, 'submit-op');
    expect(await outbox.pending(), isEmpty);
  });
}

InspectionCreationDraft _creationDraft() => InspectionCreationDraft(
      farmId: 'farm-id',
      inspectorProfileId: 'worker-id',
      title: 'Section A inspection',
      route: InspectionRoute(
        sectionId: 'section-id',
        startingTreeId: 'tree-1',
        routeVersion: 1,
        items: const <InspectionRouteItem>[
          InspectionRouteItem(
            treeId: 'tree-1',
            treeCode: 'A-001',
            sequenceIndex: 1,
            corridorIndex: 1,
            stationIndex: 1,
            side: InspectionRouteSide.left,
          ),
          InspectionRouteItem(
            treeId: 'tree-2',
            treeCode: 'A-002',
            sequenceIndex: 2,
            corridorIndex: 1,
            stationIndex: 1,
            side: InspectionRouteSide.right,
          ),
        ],
      ),
    );
