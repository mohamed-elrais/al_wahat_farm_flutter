import 'package:al_wahat_farm_flutter/core/cache/local_cache_store.dart';
import 'package:al_wahat_farm_flutter/core/errors/operation_failure.dart';
import 'package:al_wahat_farm_flutter/features/tasks/data/caching_task_repository.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/task_draft.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/task_fakes.dart';

void main() {
  group('CachingTaskRepository', () {
    test('serves the task list from cache when a later read fails', () async {
      final store = InMemoryTaskStore();
      final inner = FakeTaskRepository(
        store: store,
        viewerProfileId: 'manager-id',
        canManage: true,
      );
      await inner.create(
        const TaskDraft(
          farmId: 'farm-id',
          type: TaskType.irrigation,
          title: 'Open the north valve',
          assigneeProfileIds: <String>['worker-id'],
        ),
      );
      final caching = CachingTaskRepository(
        inner: inner,
        store: InMemoryCacheStore(),
      );

      final online = await caching.listForFarm('farm-id');
      expect(online, hasLength(1));

      inner.listFailure = const OperationFailure(
        OperationFailureKind.offline,
        'No connection.',
      );
      final offline = await caching.listForFarm('farm-id');

      expect(
          offline.map((task) => task.title), <String>['Open the north valve']);
    });

    test('serves task detail from cache when a later read fails', () async {
      final store = InMemoryTaskStore();
      final inner = FakeTaskRepository(
        store: store,
        viewerProfileId: 'manager-id',
        canManage: true,
      );
      final taskId = await inner.create(
        const TaskDraft(
          farmId: 'farm-id',
          type: TaskType.general,
          title: 'Inspect drip lines',
          assigneeProfileIds: <String>['worker-id'],
        ),
      );
      final caching = CachingTaskRepository(
        inner: inner,
        store: InMemoryCacheStore(),
      );

      final online = await caching.loadDetails(taskId);
      expect(online.task.title, 'Inspect drip lines');

      inner.detailFailure = const OperationFailure(
        OperationFailureKind.offline,
        'No connection.',
      );
      final offline = await caching.loadDetails(taskId);

      expect(offline.task.title, 'Inspect drip lines');
      expect(offline.task.status, online.task.status);
      expect(offline.assignments.length, online.assignments.length);
    });

    test('rethrows when a read fails and nothing is cached', () async {
      final inner = FakeTaskRepository(
        store: InMemoryTaskStore(),
        viewerProfileId: 'manager-id',
        canManage: true,
      )..listFailure = const OperationFailure(
          OperationFailureKind.offline,
          'No connection.',
        );
      final caching = CachingTaskRepository(
        inner: inner,
        store: InMemoryCacheStore(),
      );

      expect(
        () => caching.listForFarm('farm-id'),
        throwsA(isA<OperationFailure>()),
      );
    });

    test('mutations pass straight through to the backend', () async {
      final store = InMemoryTaskStore();
      final inner = FakeTaskRepository(
        store: store,
        viewerProfileId: 'manager-id',
        canManage: true,
      );
      final caching = CachingTaskRepository(
        inner: inner,
        store: InMemoryCacheStore(),
      );

      await caching.create(
        const TaskDraft(
          farmId: 'farm-id',
          type: TaskType.general,
          title: 'Passed through',
        ),
      );

      expect(inner.createCalls, 1);
    });
  });
}
