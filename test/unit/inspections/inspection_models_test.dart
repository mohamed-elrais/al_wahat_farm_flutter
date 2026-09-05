import 'package:al_wahat_farm_flutter/features/inspections/domain/inspection_models.dart';
import 'package:al_wahat_farm_flutter/features/inspections/domain/inspection_route.dart';
import 'package:al_wahat_farm_flutter/features/issues/domain/tree_issue_draft.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('station result serializes no-new-issue without resolving anything', () {
    final result = InspectionTreeResult(
      treeId: 'tree-id',
      noNewIssueFound: true,
      selectedIssues: const <InspectionSelectedIssue>[],
      clientObservedAt: DateTime.utc(2026, 9, 2),
    );

    final json = result.toJson();
    expect(json['no_new_issue_found'], isTrue);
    expect(json['selected_issues'], isEmpty);
    expect(json, isNot(contains('resolved')));
  });

  test('existing issue severity only changes with an explicit flag', () {
    const unchanged = InspectionSelectedIssue(
      type: TreeIssueType.cloggedDripper,
      severity: IssueSeverity.high,
    );
    const changed = InspectionSelectedIssue(
      type: TreeIssueType.cloggedDripper,
      severity: IssueSeverity.urgent,
      severityChanged: true,
    );

    expect(unchanged.toJson()['severity_changed'], isFalse);
    expect(changed.toJson()['severity_changed'], isTrue);
  });

  test('creation draft round-trips the immutable route and policies', () {
    final route = InspectionRoute(
      sectionId: 'section-id',
      startingTreeId: 'tree-id',
      routeVersion: 1,
      items: const <InspectionRouteItem>[
        InspectionRouteItem(
          treeId: 'tree-id',
          treeCode: 'TREE-A-001',
          sequenceIndex: 1,
          corridorIndex: 1,
          stationIndex: 1,
          side: InspectionRouteSide.single,
        ),
      ],
    );
    final draft = InspectionCreationDraft(
      farmId: 'farm-id',
      inspectorProfileId: 'worker-id',
      title: 'Section A inspection',
      route: route,
      requiresEngineerReview: true,
      requiresIssuePhoto: false,
    );

    final restored = InspectionCreationDraft.fromJson(draft.toJson());
    expect(restored.route.items.single.treeCode, 'TREE-A-001');
    expect(restored.route.startingTreeId, 'tree-id');
    expect(restored.requiresEngineerReview, isTrue);
  });

  test('saved station observation round-trips remote and local photo state',
      () {
    final observation = InspectionStationObservation.fromJson(
      <String, Object?>{
        'id': 'observation-id',
        'session_id': 'session-id',
        'item_id': 'item-id',
        'tree_issue_id': 'issue-id',
        'issue_type': 'tree_damage',
        'outcome': 'confirmed',
        'observed_severity': 'high',
        'severity_changed': false,
        'notes': 'Broken branch',
        'photo_storage_path': 'user/farm/task/damage.jpg',
        'local_photo_blob_key': 'queued-photo-key',
        'observed_at': '2026-09-04T08:00:00.000Z',
      },
    );

    expect(observation.outcome, InspectionStationObservationOutcome.confirmed);
    expect(observation.observedSeverity, IssueSeverity.high);
    expect(observation.toJson()['local_photo_blob_key'], 'queued-photo-key');
  });
}
