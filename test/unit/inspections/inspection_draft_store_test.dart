import 'dart:typed_data';

import 'package:al_wahat_farm_flutter/core/cache/local_cache_store.dart';
import 'package:al_wahat_farm_flutter/features/inspections/data/inspection_draft_store.dart';
import 'package:al_wahat_farm_flutter/features/inspections/data/inspection_repository.dart';
import 'package:al_wahat_farm_flutter/features/inspections/domain/inspection_models.dart';
import 'package:al_wahat_farm_flutter/features/issues/domain/tree_issue_draft.dart';
import 'package:al_wahat_farm_flutter/features/sync/data/pending_photo_store.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/task_evidence.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('station draft and photo survive restart and local id remapping',
      () async {
    final cache = InMemoryCacheStore();
    final pendingPhotos = InMemoryPendingPhotoStore();
    final first = InspectionDraftStore(
      cache: cache,
      pendingPhotos: pendingPhotos,
      userId: 'worker-id',
      clock: () => 123,
    );
    final result = InspectionTreeResult(
      treeId: 'tree-id',
      noNewIssueFound: false,
      clientObservedAt: DateTime.utc(2026, 9, 3),
      notes: 'damaged branch',
      selectedIssues: const <InspectionSelectedIssue>[
        InspectionSelectedIssue(
          type: TreeIssueType.treeDamage,
          severity: IssueSeverity.high,
        ),
      ],
    );
    await first.save(
      sessionId: 'local:create-op',
      stationIndex: 1,
      farmId: 'farm-id',
      taskId: 'local:create-op',
      results: <InspectionTreeResult>[result],
      photos: <String, PreparedTaskEvidence>{
        'tree-id|tree_damage': PreparedTaskEvidence(
          bytes: Uint8List.fromList(<int>[1, 2, 3]),
          filename: 'damage.jpg',
          contentType: 'image/jpeg',
        ),
      },
    );
    await cache.write(
      OfflineInspectionRepository.reverseSessionKey('remote-session'),
      'local:create-op',
    );

    final afterRestart = InspectionDraftStore(
      cache: cache,
      pendingPhotos: pendingPhotos,
      userId: 'worker-id',
    );
    final restored = await afterRestart.load('remote-session', 1);

    expect(restored, isNotNull);
    expect(restored!.results.single.notes, 'damaged branch');
    expect(
      restored.results.single.selectedIssues.single.severity,
      IssueSeverity.high,
    );
    expect(
      restored.photos['tree-id|tree_damage']!.bytes,
      orderedEquals(<int>[1, 2, 3]),
    );

    await afterRestart.clear('remote-session', 1);
    expect(await afterRestart.load('local:create-op', 1), isNull);
  });
}
