import 'dart:async';
import 'dart:typed_data';

import 'package:al_wahat_farm_flutter/core/cache/sqflite_cache_store.dart';
import 'package:al_wahat_farm_flutter/core/connectivity/connectivity_service.dart';
import 'package:al_wahat_farm_flutter/core/database/app_database.dart';
import 'package:al_wahat_farm_flutter/core/errors/operation_failure.dart';
import 'package:al_wahat_farm_flutter/features/inspections/data/inspection_repository.dart';
import 'package:al_wahat_farm_flutter/features/inspections/data/inspection_station_local_store.dart';
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
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../test/support/task_fakes.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'offline inspection survives restart and replays exactly once in order',
    (tester) async {
      final databasePath = p.join(
        await getDatabasesPath(),
        'awf_offline_inspection_restart_test.db',
      );
      await deleteDatabase(databasePath);
      AppDatabase? activeDatabase;
      addTearDown(() async {
        if (activeDatabase?.db.isOpen ?? false) {
          await activeDatabase!.close();
        }
        await deleteDatabase(databasePath);
      });

      final connectivityService = _TestConnectivityService();
      addTearDown(connectivityService.close);
      final connectivity = ConnectivityController(connectivityService);
      await connectivity.start();
      addTearDown(connectivity.dispose);
      final remote = _RecordingInspectionRepository();
      final storage = _RecordingEvidenceStorage();

      activeDatabase = await AppDatabase.open(filePath: databasePath);
      var cache = SqfliteCacheStore(activeDatabase);
      var outbox = SqfliteOutboxStore(activeDatabase);
      var pendingPhotos = SqflitePendingPhotoStore(activeDatabase);
      var engine = SyncEngine(
        outbox: outbox,
        executor: _RejectingExecutor(),
        connectivity: connectivity,
      );
      var repository = OfflineInspectionRepository(
        inner: remote,
        cache: cache,
        outbox: outbox,
        connectivity: connectivity,
        syncEngine: engine,
        evidenceStorage: storage,
        pendingPhotos: pendingPhotos,
        stationLocalStore: SqfliteInspectionStationLocalStore(activeDatabase),
        userId: 'manager-id',
      );

      final created = await repository.create(
        _creationDraft,
        opId: 'create-op',
      );
      await repository.setStatus(
        created.sessionId,
        InspectionSessionStatus.inProgress,
        opId: 'status-op',
      );
      await repository.saveStation(
        created.sessionId,
        1,
        _stationOneResults,
        opId: 'station-1-op',
        photos: <String, PreparedTaskEvidence>{
          'tree-1|pest_or_disease': PreparedTaskEvidence(
            bytes: Uint8List.fromList(<int>[1, 3, 5, 7]),
            filename: 'tree-1-pest.jpg',
            contentType: 'image/jpeg',
          ),
        },
        farmId: 'farm-id',
        taskId: created.taskId,
      );
      await repository.saveStation(
        created.sessionId,
        2,
        _stationTwoResults,
        opId: 'station-2-op',
        farmId: 'farm-id',
        taskId: created.taskId,
      );
      await repository.submit(
        created.sessionId,
        note: 'Offline section complete',
        opId: 'submit-op',
      );

      expect(
        (await outbox.pending()).map((operation) => operation.opId),
        <String>[
          'create-op',
          'status-op',
          'station-1-op',
          'station-2-op',
          'submit-op',
        ],
      );
      await activeDatabase.close();

      // This close/reopen boundary represents an app process restart. Every
      // service below is recreated over the same on-device SQLite file.
      activeDatabase = await AppDatabase.open(filePath: databasePath);
      cache = SqfliteCacheStore(activeDatabase);
      outbox = SqfliteOutboxStore(activeDatabase);
      pendingPhotos = SqflitePendingPhotoStore(activeDatabase);
      final executor = InspectionMutationExecutor(
        remote,
        evidenceStorage: storage,
        pendingPhotos: pendingPhotos,
        cache: cache,
        taskRepository: FakeTaskRepository(
          store: InMemoryTaskStore(),
          viewerProfileId: 'manager-id',
          canManage: true,
        ),
      );
      engine = SyncEngine(
        outbox: outbox,
        executor: executor,
        connectivity: connectivity,
      );
      repository = OfflineInspectionRepository(
        inner: remote,
        cache: cache,
        outbox: outbox,
        connectivity: connectivity,
        syncEngine: engine,
        evidenceStorage: storage,
        pendingPhotos: pendingPhotos,
        stationLocalStore: SqfliteInspectionStationLocalStore(activeDatabase),
        userId: 'manager-id',
      );

      final restored = await repository.loadByTask(created.taskId);
      expect(restored.session.status, InspectionSessionStatus.submitted);
      expect(restored.session.inspectedTrees, 4);
      expect(
        restored.items.map((item) => item.status),
        everyElement(InspectionItemStatus.inspected),
      );
      expect(
        restored.items
            .where((item) => item.noNewIssueFound)
            .map((item) => item.routeItem.treeId),
        <String>['tree-2', 'tree-4'],
      );
      expect(restored.observations, hasLength(2));
      expect(
        restored.observations
            .singleWhere((item) => item.itemId.contains(':item:1'))
            .observedSeverity,
        IssueSeverity.high,
      );
      expect(
        restored.observations
            .singleWhere((item) => item.itemId.contains(':item:1'))
            .notes,
        'White scale under leaves',
      );
      final photoRef = (await outbox.pending())
          .singleWhere(
            (operation) =>
                operation.kind == PendingMutationKind.saveInspectionStation &&
                operation.opId == 'station-1-op',
          )
          .payload['photoRefs']! as List<Object?>;
      final blobKey =
          Map<String, Object?>.from(photoRef.single! as Map)['blob_key']!
              as String;
      final restoredPhoto = await pendingPhotos.get(blobKey);
      expect(restoredPhoto?.bytes, <int>[1, 3, 5, 7]);
      expect(restoredPhoto?.filename, 'tree-1-pest.jpg');

      connectivityService.setStatus(NetworkStatus.online);
      expect(connectivity.isOnline, isTrue);
      expect(await engine.sync(), SyncOutcome.drained);

      expect(await outbox.pending(), isEmpty);
      expect(await outbox.failed(), isEmpty);
      expect(await pendingPhotos.get(blobKey), isNull);
      expect(
        remote.calls,
        <String>[
          'create:create-op',
          'status:status-op',
          'station:1:station-1-op',
          'station:2:station-2-op',
          'submit:submit-op',
        ],
      );
      expect(storage.uploads, 1);
      expect(storage.taskIds, <String>['remote-task-id']);
      expect(
          remote.savedStations[1]!.first.selectedIssues.single.photoStoragePath,
          'evidence/remote-task-id/tree-1-pest.jpg');
      expect(
        await OfflineInspectionRepository.resolveTaskId(
          cache,
          created.taskId,
        ),
        'remote-task-id',
      );
      expect(
        await OfflineInspectionRepository.resolveSessionId(
          cache,
          created.sessionId,
        ),
        'remote-session-id',
      );
    },
  );
}

class _TestConnectivityService implements ConnectivityService {
  NetworkStatus _status = NetworkStatus.offline;
  final StreamController<NetworkStatus> _changes =
      StreamController<NetworkStatus>.broadcast(sync: true);

  @override
  Future<NetworkStatus> current() async => _status;

  @override
  Stream<NetworkStatus> get changes => _changes.stream;

  void setStatus(NetworkStatus status) {
    _status = status;
    _changes.add(status);
  }

  Future<void> close() => _changes.close();
}

class _RejectingExecutor implements MutationExecutor {
  @override
  Future<void> execute(PendingMutation mutation) =>
      throw StateError('Offline mutations must not execute before reconnect.');
}

class _RecordingInspectionRepository implements InspectionRepository {
  final List<String> calls = <String>[];
  final Map<int, List<InspectionTreeResult>> savedStations =
      <int, List<InspectionTreeResult>>{};

  @override
  Future<InspectionCreationResult> create(
    InspectionCreationDraft draft, {
    String? opId,
  }) async {
    calls.add('create:$opId');
    return const InspectionCreationResult(
      sessionId: 'remote-session-id',
      taskId: 'remote-task-id',
    );
  }

  @override
  Future<InspectionDetails> loadByTask(String taskId) =>
      throw const OperationFailure(
          OperationFailureKind.offline, 'No remote fixture.');

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
    calls.add('station:$stationIndex:$opId');
    savedStations[stationIndex] = results;
  }

  @override
  Future<void> setStatus(
    String sessionId,
    InspectionSessionStatus status, {
    String? opId,
  }) async {
    calls.add('status:$opId');
  }

  @override
  Future<void> submit(
    String sessionId, {
    String? note,
    String? opId,
  }) async {
    calls.add('submit:$opId');
  }

  @override
  Future<void> takeOver(String sessionId, {String? opId}) async {}
}

class _RecordingEvidenceStorage implements TaskEvidenceStorage {
  int uploads = 0;
  final List<String> taskIds = <String>[];

  @override
  Future<String> upload({
    required String userId,
    required String farmId,
    required String taskId,
    required PreparedTaskEvidence evidence,
  }) async {
    uploads++;
    taskIds.add(taskId);
    return 'evidence/$taskId/${evidence.filename}';
  }
}

final _creationDraft = InspectionCreationDraft(
  farmId: 'farm-id',
  inspectorProfileId: 'worker-id',
  title: 'Section A restart pilot',
  route: InspectionRoute(
    sectionId: 'section-a',
    startingTreeId: 'tree-1',
    routeVersion: 2,
    items: const <InspectionRouteItem>[
      InspectionRouteItem(
        treeId: 'tree-1',
        treeCode: 'TREE-A-001',
        sequenceIndex: 1,
        corridorIndex: 1,
        stationIndex: 1,
        side: InspectionRouteSide.left,
      ),
      InspectionRouteItem(
        treeId: 'tree-2',
        treeCode: 'TREE-A-002',
        sequenceIndex: 2,
        corridorIndex: 1,
        stationIndex: 1,
        side: InspectionRouteSide.right,
      ),
      InspectionRouteItem(
        treeId: 'tree-3',
        treeCode: 'TREE-A-003',
        sequenceIndex: 3,
        corridorIndex: 1,
        stationIndex: 2,
        side: InspectionRouteSide.left,
      ),
      InspectionRouteItem(
        treeId: 'tree-4',
        treeCode: 'TREE-A-004',
        sequenceIndex: 4,
        corridorIndex: 1,
        stationIndex: 2,
        side: InspectionRouteSide.right,
      ),
    ],
  ),
);

final _stationOneResults = <InspectionTreeResult>[
  InspectionTreeResult(
    treeId: 'tree-1',
    noNewIssueFound: false,
    clientObservedAt: DateTime.utc(2026, 9, 5, 9),
    notes: 'First paired station',
    selectedIssues: const <InspectionSelectedIssue>[
      InspectionSelectedIssue(
        type: TreeIssueType.pestOrDisease,
        severity: IssueSeverity.high,
        notes: 'White scale under leaves',
      ),
    ],
  ),
  InspectionTreeResult(
    treeId: 'tree-2',
    noNewIssueFound: true,
    selectedIssues: const <InspectionSelectedIssue>[],
    clientObservedAt: DateTime.utc(2026, 9, 5, 9, 1),
    notes: 'No new issue',
  ),
];

final _stationTwoResults = <InspectionTreeResult>[
  InspectionTreeResult(
    treeId: 'tree-3',
    noNewIssueFound: false,
    clientObservedAt: DateTime.utc(2026, 9, 5, 9, 2),
    selectedIssues: const <InspectionSelectedIssue>[
      InspectionSelectedIssue(
        type: TreeIssueType.treeDamage,
        severity: IssueSeverity.medium,
        notes: 'Broken lower branch',
      ),
    ],
  ),
  InspectionTreeResult(
    treeId: 'tree-4',
    noNewIssueFound: true,
    selectedIssues: const <InspectionSelectedIssue>[],
    clientObservedAt: DateTime.utc(2026, 9, 5, 9, 3),
  ),
];
