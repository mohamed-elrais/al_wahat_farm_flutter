import 'package:al_wahat_farm_flutter/app/theme/app_theme.dart';
import 'package:al_wahat_farm_flutter/features/auth/domain/operational_context.dart';
import 'package:al_wahat_farm_flutter/features/auth/presentation/authenticated_gate.dart';
import 'package:al_wahat_farm_flutter/features/farm/data/farm_hierarchy_repository.dart';
import 'package:al_wahat_farm_flutter/features/farm/domain/farm_hierarchy.dart';
import 'package:al_wahat_farm_flutter/features/farm/presentation/farm_hierarchy_gate.dart';
import 'package:al_wahat_farm_flutter/features/inspections/data/inspection_repository.dart';
import 'package:al_wahat_farm_flutter/features/inspections/domain/inspection_models.dart';
import 'package:al_wahat_farm_flutter/features/inspections/presentation/inspection_create_screen.dart';
import 'package:al_wahat_farm_flutter/features/inspections/presentation/inspection_repository_scope.dart';
import 'package:al_wahat_farm_flutter/features/inspections/presentation/inspection_route_preview.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/task_evidence.dart';
import 'package:al_wahat_farm_flutter/features/tasks/presentation/task_workspace_controller.dart';
import 'package:al_wahat_farm_flutter/l10n/gen/app_localizations.dart';
import 'package:al_wahat_farm_flutter/shared/models/farm_role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../support/task_fakes.dart';

class _InspectionRepository implements InspectionRepository {
  InspectionCreationDraft? createdDraft;

  @override
  Future<InspectionCreationResult> create(
    InspectionCreationDraft draft, {
    String? opId,
  }) async {
    createdDraft = draft;
    return const InspectionCreationResult(
      sessionId: 'session-id',
      taskId: 'created-task-id',
    );
  }

  @override
  Future<InspectionDetails> loadByTask(String taskId) =>
      throw UnimplementedError();

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
  }) =>
      throw UnimplementedError();

  @override
  Future<void> setStatus(
    String sessionId,
    InspectionSessionStatus status, {
    String? opId,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> submit(
    String sessionId, {
    String? note,
    String? opId,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> takeOver(String sessionId, {String? opId}) =>
      throw UnimplementedError();
}

void main() {
  testWidgets(
      'preselected section previews route and submits schedule and priority',
      (tester) async {
    final semantics = tester.ensureSemantics();
    final inspectionRepository = _InspectionRepository();
    final taskController = TaskWorkspaceController(
      repository: FakeTaskRepository(
        store: InMemoryTaskStore(),
        viewerProfileId: 'manager-id',
        canManage: true,
      ),
      farmId: 'farm-id',
    );
    addTearDown(taskController.dispose);
    final router = GoRouter(
      initialLocation: '/create',
      routes: <RouteBase>[
        GoRoute(
          path: '/create',
          builder: (context, state) => OperationalContextScope(
            contextData: _operationalContext,
            child: FarmHierarchyScope(
              snapshot: FarmHierarchySnapshot(
                hierarchy: _hierarchy,
                source: FarmHierarchySource.network,
              ),
              child: TaskWorkspaceScope(
                controller: taskController,
                child: const InspectionCreateScreen(
                  initialSectionId: 'section-a',
                ),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/tasks/:taskId',
          builder: (context, state) => const Scaffold(body: Text('Created')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      InspectionRepositoryScope(
        repository: inspectionRepository,
        child: MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(InspectionRoutePreviewMap), findsOneWidget);
    expect(find.textContaining('TREE-A-001'), findsWidgets);
    expect(find.text('A scheduled date is required.'), findsOneWidget);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));

    await tester.tap(find.byType(DropdownButtonFormField<String>).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Field Worker').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('inspection-scheduled-date')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('inspection-create-submit')),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('inspection-create-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Created'), findsOneWidget);
    expect(inspectionRepository.createdDraft?.route.sectionId, 'section-a');
    expect(inspectionRepository.createdDraft?.inspectorProfileId, 'worker-id');
    expect(inspectionRepository.createdDraft?.scheduledFor, isNotNull);
    expect(inspectionRepository.createdDraft?.priority, 'medium');
    semantics.dispose();
  });
}

final OperationalContext _operationalContext = OperationalContext(
  profile: const UserProfile(
    id: 'manager-id',
    fullName: 'Farm Manager',
    isActive: true,
  ),
  memberships: <FarmMembership>[
    const FarmMembership(
      id: 'membership-id',
      profileId: 'manager-id',
      role: FarmRole.owner,
      isActive: true,
      farm: FarmSummary(
        id: 'farm-id',
        name: 'Al Wahat',
        code: 'AL-WAHAT',
        timezone: 'Africa/Cairo',
      ),
    ),
  ],
);

final FarmSection _section = FarmSection(
  id: 'section-a',
  farmId: 'farm-id',
  code: 'A',
  name: 'Section A',
  sortOrder: 1,
  isActive: true,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

final FarmHierarchy _hierarchy = FarmHierarchy(
  farmId: 'farm-id',
  sections: <FarmSection>[_section],
  zones: const [],
  trees: <FarmTreeRecord>[
    _tree('tree-1', 'TREE-A-001', 1, 1, 29, 30),
    _tree('tree-2', 'TREE-A-002', 1, 2, 29, 30.00001),
    _tree('tree-3', 'TREE-A-003', 2, 1, 29.00001, 30),
    _tree('tree-4', 'TREE-A-004', 2, 2, 29.00001, 30.00001),
  ],
);

FarmTreeRecord _tree(
  String id,
  String code,
  int row,
  int number,
  double latitude,
  double longitude,
) =>
    FarmTreeRecord(
      id: id,
      farmId: 'farm-id',
      sectionId: 'section-a',
      treeCode: code,
      rowNumber: row,
      treeNumber: number,
      latitude: latitude,
      longitude: longitude,
      healthStatus: TreeHealthStatus.healthy,
      type: 'Medjool',
      isActive: true,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );
