import 'package:al_wahat_farm_flutter/app/theme/app_theme.dart';
import 'package:al_wahat_farm_flutter/features/map/data/map_asset_repository.dart';
import 'package:al_wahat_farm_flutter/features/map/domain/projected_map.dart';
import 'package:al_wahat_farm_flutter/features/map/presentation/farm_map_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('map remains interactive with all 1567 points', (tester) async {
    final map = ProjectedFarmMap(await const MapAssetRepository().load());
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: FarmMapScreen(
            mapFuture: Future<ProjectedFarmMap>.value(map),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(map.trees, hasLength(1567));
    expect(find.byType(InteractiveViewer), findsOneWidget);

    Future<void> interactWithMap() async {
      final viewer = find.byType(InteractiveViewer);
      await tester.drag(viewer, const Offset(-120, -90));
      await tester.pumpAndSettle();
      await tester.drag(viewer, const Offset(90, 60));
      await tester.pumpAndSettle();
    }

    if (kProfileMode) {
      await binding.traceAction(
        interactWithMap,
        reportKey: 'map_interaction_timeline',
      );
    } else {
      await interactWithMap();
    }

    expect(tester.takeException(), isNull);
  });
}
