import 'package:al_wahat_farm_flutter/features/map/domain/farm_map_data.dart';
import 'package:al_wahat_farm_flutter/features/map/domain/map_projection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const bounds = FarmBounds(
    minLongitude: 28.747598,
    maxLongitude: 28.7546,
    minLatitude: 28.293348,
    maxLatitude: 28.300016,
  );

  test('projection uses north-up orientation and one common scale', () {
    final projection = MapProjection(bounds);
    final northWest = projection.project(
      const GeoCoordinate(longitude: 28.747598, latitude: 28.300016),
    );
    final southEast = projection.project(
      const GeoCoordinate(longitude: 28.7546, latitude: 28.293348),
    );

    expect(northWest.dx, greaterThanOrEqualTo(24));
    expect(northWest.dy, greaterThanOrEqualTo(24));
    expect(southEast.dx, lessThanOrEqualTo(796));
    expect(southEast.dy, lessThanOrEqualTo(856));
    expect(northWest.dx, lessThan(southEast.dx));
    expect(northWest.dy, lessThan(southEast.dy));
  });

  test('section bounds include padding and stay inside the logical canvas', () {
    final projection = MapProjection(bounds);
    final rect = projection.boundsFor(const <GeoCoordinate>[
      GeoCoordinate(longitude: 28.749, latitude: 28.299),
      GeoCoordinate(longitude: 28.750, latitude: 28.298),
    ]);
    expect(
      (Offset.zero & MapProjection.canvasSize).contains(rect.topLeft),
      isTrue,
    );
    expect(rect.width, greaterThan(90));
    expect(rect.height, greaterThan(90));
  });
}
