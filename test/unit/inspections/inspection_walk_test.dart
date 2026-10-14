import 'package:al_wahat_farm_flutter/core/location/location_service.dart';
import 'package:al_wahat_farm_flutter/features/farm/data/farm_hierarchy_repository.dart';
import 'package:al_wahat_farm_flutter/features/inspections/domain/inspection_route.dart';
import 'package:al_wahat_farm_flutter/features/inspections/domain/inspection_route_planner.dart';
import 'package:al_wahat_farm_flutter/features/inspections/domain/inspection_walk.dart';
import 'package:al_wahat_farm_flutter/features/inspections/presentation/inspection_runner_screen.dart';
import 'package:al_wahat_farm_flutter/l10n/gen/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/farm_hierarchy_fixture.dart';

void main() {
  late InspectionWalk walk;
  final en = AppLocalizationsEn();

  setUpAll(() async {
    final snapshot = await DefaultFarmHierarchyRepository(
      CanonicalFarmHierarchyDataSource.load(),
      MemoryFarmHierarchyCache(),
    ).load(CanonicalFarmHierarchyDataSource.farmId);
    final hierarchy = snapshot.hierarchy;
    final route = const InspectionRoutePlanner().plan(
      section: hierarchy.sectionByCode('A')!,
      trees: hierarchy.trees,
    );
    walk = InspectionWalk(route.items);
  });

  int firstOfAisle(int aisle) =>
      walk.stations.firstWhere((station) => walk.aisleOf(station) == aisle);
  int lastOfAisle(int aisle) =>
      walk.stations.lastWhere((station) => walk.aisleOf(station) == aisle);

  test('section A splits its 153 stations into 8 aisles', () {
    expect(walk.stations, List<int>.generate(153, (index) => index + 1));
    expect(walk.aisleCount, 8);
    expect(walk.hasCoordinates, isTrue);
    var total = 0;
    for (var aisle = 1; aisle <= walk.aisleCount; aisle++) {
      final step = walk.step(firstOfAisle(aisle));
      expect(step.aisle, aisle);
      expect(step.aisleCount, 8);
      expect(step.startsAisle, isTrue);
      expect(step.stationInAisle, 1);
      total += step.stationsInAisle;
    }
    expect(total, 153);
  });

  test('the end of an aisle names the next one; the walk ends cleanly', () {
    final end = walk.step(lastOfAisle(1));
    expect(end.endsAisle, isTrue);
    expect(end.nextAisle, 2);
    expect(end.next.map((item) => item.corridorIndex), everyElement(2));
    expect(walk.step(lastOfAisle(1) + 1).startsAisle, isTrue);

    final middle = walk.step(firstOfAisle(2) + 3);
    expect(middle.startsAisle, isFalse);
    expect(middle.endsAisle, isFalse);
    expect(middle.nextAisle, isNull);
    expect(middle.next, isNotEmpty);

    final last = walk.step(153);
    expect(last.next, isEmpty);
    expect(last.nextAisle, isNull);
  });

  test('station trees are listed left side first, with their rows', () {
    final first = walk.step(1);
    expect(first.items.map((item) => item.treeCode), contains('TREE-A-001'));
    for (final station in walk.stations) {
      final sides = walk.station(station).map((item) => item.side.index);
      expect(sides, orderedEquals(sides.toList()..sort()));
    }
    final paired = walk.stations
        .map(walk.step)
        .firstWhere((step) => step.items.length == 2);
    expect(paired.items.first.side, InspectionRouteSide.left);
    expect(paired.rows, hasLength(2));
  });

  test('locate measures from the current station to the nearest one', () {
    final station = firstOfAisle(2) + 8;
    final center = walk.centerOf(station)!;

    final there = walk.locate(
      center.latitude,
      center.longitude,
      current: station,
    )!;
    expect(there.metersToStation, lessThan(0.01));
    expect(there.nearestStation, station);
    expect(there.nearestAisle, 2);
    expect(there.metersOutside, lessThan(8));

    // Five stations further along the same aisle, ~8 m apart.
    final behind = walk.locate(
      center.latitude,
      center.longitude,
      current: station - 5,
    )!;
    expect(behind.nearestStation, station);
    expect(behind.metersToStation, closeTo(40, 8));

    final far = walk.locate(
      center.latitude + 0.01,
      center.longitude,
      current: station,
    )!;
    expect(far.metersOutside, greaterThan(1000));
  });

  test('distanceMeters is metres on the ground', () {
    expect(
      InspectionWalk.distanceMeters(28.29, 28.74, 28.291, 28.74),
      closeTo(111.32, 0.01),
    );
  });

  group('GPS guidance text', () {
    LocationFix at(int station, {double accuracy = 4, double dLat = 0}) {
      final center = walk.centerOf(station)!;
      return LocationFix(
        latitude: center.latitude + dLat,
        longitude: center.longitude,
        accuracyMeters: accuracy,
      );
    }

    test('at the station', () {
      final station = firstOfAisle(2) + 8;
      expect(
        inspectionLocationText(en, walk, station, at(station)),
        'You are at this station (GPS ±4 m).',
      );
    });

    test('further along the same aisle', () {
      final station = firstOfAisle(2) + 3;
      final text = inspectionLocationText(en, walk, station, at(station + 5));
      expect(text, startsWith('This station is about'));
      expect(text, endsWith('You seem to be 5 stations past this one.'));
    });

    test('not yet at the station', () {
      final station = firstOfAisle(2) + 8;
      final text = inspectionLocationText(en, walk, station, at(station - 2));
      expect(text, endsWith('You seem to be 2 stations before this one.'));
    });

    test('in another aisle', () {
      final station = firstOfAisle(3) + 2;
      final text = inspectionLocationText(
        en,
        walk,
        station,
        at(firstOfAisle(1) + 2),
      );
      expect(text, contains('this station is in aisle 3'));
    });

    test('weak signal and outside the section', () {
      final station = firstOfAisle(2);
      expect(
        inspectionLocationText(en, walk, station, at(station, accuracy: 40)),
        startsWith('Weak GPS signal (±40 m).'),
      );
      expect(
        inspectionLocationText(en, walk, station, at(station, dLat: 0.002)),
        startsWith('You are about'),
      );
    });
  });
}
