import 'dart:async';

import 'package:al_wahat_farm_flutter/app/theme/app_theme.dart';
import 'package:al_wahat_farm_flutter/core/location/location_service.dart';
import 'package:al_wahat_farm_flutter/features/map/domain/farm_map_data.dart';
import 'package:al_wahat_farm_flutter/features/map/domain/projected_map.dart';
import 'package:al_wahat_farm_flutter/features/map/presentation/farm_map_screen.dart';
import 'package:al_wahat_farm_flutter/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/projected_farm_map_fixture.dart';

class _Location implements LocationService {
  _Location(this.stream);

  final Stream<LocationFix> stream;

  @override
  Stream<LocationFix> watch() => stream;
}

void main() {
  test('distance outside the farm is zero inside and metres beyond it', () {
    const bounds = FarmBounds(
      minLongitude: 28.74,
      maxLongitude: 28.75,
      minLatitude: 28.29,
      maxLatitude: 28.30,
    );
    expect(
      metersOutsideFarm(
        bounds,
        const LocationFix(
          latitude: 28.295,
          longitude: 28.745,
          accuracyMeters: 5,
        ),
      ),
      0,
    );
    expect(
      metersOutsideFarm(
        bounds,
        const LocationFix(
            latitude: 28.301, longitude: 28.745, accuracyMeters: 5),
      ),
      closeTo(111.3, 0.5),
    );
  });

  testWidgets('the locate button shows the dot, centres it, and explains gaps',
      (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final map = (await tester.runAsync(loadComposedFarmMap))!;
    final fixes = StreamController<LocationFix>.broadcast();
    addTearDown(fixes.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: FarmMapScreen(
            mapFuture: Future<ProjectedFarmMap>.value(map),
            location: _Location(fixes.stream),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('map-location-notice')), findsNothing);

    await tester.tap(find.byKey(const Key('map-locate')));
    await tester.pumpAndSettle();
    expect(find.text('Finding your location…'), findsOneWidget);

    final viewer = tester.widget<InteractiveViewer>(
      find.byType(InteractiveViewer),
    );
    final fittedScale =
        viewer.transformationController!.value.getMaxScaleOnAxis();
    final bounds = map.data.bounds;
    fixes.add(LocationFix(
      latitude: (bounds.minLatitude + bounds.maxLatitude) / 2,
      longitude: (bounds.minLongitude + bounds.maxLongitude) / 2,
      accuracyMeters: 5,
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('map-location-notice')), findsNothing);
    expect(find.byKey(const Key('map-user-location')), findsOneWidget);
    expect(
      viewer.transformationController!.value.getMaxScaleOnAxis(),
      greaterThan(fittedScale),
    );

    fixes.add(LocationFix(
      latitude: bounds.maxLatitude + 0.01,
      longitude: bounds.minLongitude,
      accuracyMeters: 5,
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('outside the farm map'), findsOneWidget);

    await tester.tap(find.byKey(const Key('map-locate')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('map-location-notice')), findsNothing);
  });
}
