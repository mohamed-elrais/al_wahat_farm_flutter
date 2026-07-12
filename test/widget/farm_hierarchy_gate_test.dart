import 'package:al_wahat_farm_flutter/features/farm/data/farm_hierarchy_repository.dart';
import 'package:al_wahat_farm_flutter/features/farm/presentation/farm_hierarchy_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/farm_hierarchy_fixture.dart';

void main() {
  testWidgets('authenticated farm gate exposes the loaded hierarchy',
      (tester) async {
    final repository = DefaultFarmHierarchyRepository(
      CanonicalFarmHierarchyDataSource.load(),
      MemoryFarmHierarchyCache(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: FarmHierarchyGate(
          farmId: CanonicalFarmHierarchyDataSource.farmId,
          repository: repository,
          child: Builder(
            builder: (context) {
              final hierarchy = FarmHierarchyScope.maybeOf(context)?.hierarchy;
              return Text(
                hierarchy == null
                    ? 'missing'
                    : '${hierarchy.sections.length}/${hierarchy.trees.length}',
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('12/1567'), findsOneWidget);
  });
}
