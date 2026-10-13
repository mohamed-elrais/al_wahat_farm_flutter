import 'dart:async';

import 'package:al_wahat_farm_flutter/features/farm/data/farm_hierarchy_repository.dart';
import 'package:al_wahat_farm_flutter/features/farm/domain/farm_hierarchy.dart';
import 'package:al_wahat_farm_flutter/features/farm/presentation/farm_hierarchy_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/farm_hierarchy_fixture.dart';

/// A repository whose cache and network answers the test controls.
class _ScriptedRepository implements FarmHierarchyRepository {
  _ScriptedRepository({this.cached});

  final FarmHierarchy? cached;
  Completer<FarmHierarchySnapshot> network = Completer<FarmHierarchySnapshot>();
  final List<bool> fallbackFlags = <bool>[];

  @override
  Future<FarmHierarchySnapshot?> loadCached(String farmId) async =>
      cached == null
          ? null
          : FarmHierarchySnapshot(
              hierarchy: cached!,
              source: FarmHierarchySource.cache,
            );

  @override
  Future<FarmHierarchySnapshot> load(
    String farmId, {
    bool allowCachedFallback = true,
  }) {
    fallbackFlags.add(allowCachedFallback);
    return network.future;
  }
}

Future<FarmHierarchy> _canonical() async =>
    (await DefaultFarmHierarchyRepository(
      CanonicalFarmHierarchyDataSource.load(),
      MemoryFarmHierarchyCache(),
    ).load(CanonicalFarmHierarchyDataSource.farmId))
        .hierarchy;

void main() {
  const farmId = CanonicalFarmHierarchyDataSource.farmId;

  test('shows the cached hierarchy before the network answers', () async {
    final hierarchy = await _canonical();
    final repository = _ScriptedRepository(cached: hierarchy);
    final controller = FarmHierarchyController(repository);
    final states = <FarmHierarchyState>[];
    controller.addListener(() => states.add(controller.state));

    final loading = controller.load(farmId);
    await Future<void>.delayed(Duration.zero);
    expect(states.map((state) => state.runtimeType), <Type>[
      FarmHierarchyLoading,
      FarmHierarchyReady,
    ]);
    expect(
      (controller.state as FarmHierarchyReady).snapshot.source,
      FarmHierarchySource.cache,
    );

    repository.network.complete(FarmHierarchySnapshot(
      hierarchy: hierarchy,
      source: FarmHierarchySource.network,
    ));
    await loading;
    expect(
      (controller.state as FarmHierarchyReady).snapshot.source,
      FarmHierarchySource.network,
    );
    // The cache was already shown, so the network call does not re-read it.
    expect(repository.fallbackFlags, <bool>[false]);
  });

  test('a failed refresh keeps the cached hierarchy on screen', () async {
    final repository = _ScriptedRepository(cached: await _canonical());
    final controller = FarmHierarchyController(repository);

    final loading = controller.load(farmId);
    repository.network.completeError(StateError('offline'));
    await loading;

    expect(controller.state, isA<FarmHierarchyReady>());
  });

  test('without a cache, a failed load is reported', () async {
    final repository = _ScriptedRepository();
    final controller = FarmHierarchyController(repository);

    final loading = controller.load(farmId);
    repository.network.completeError(StateError('offline'));
    await loading;

    expect(controller.state, isA<FarmHierarchyFailure>());
    expect(repository.fallbackFlags, <bool>[true]);
  });

  test('a reload while data is shown refreshes without a loading state',
      () async {
    final hierarchy = await _canonical();
    final repository = _ScriptedRepository(cached: hierarchy);
    final controller = FarmHierarchyController(repository);
    final first = controller.load(farmId);
    repository.network.complete(FarmHierarchySnapshot(
      hierarchy: hierarchy,
      source: FarmHierarchySource.network,
    ));
    await first;

    final states = <FarmHierarchyState>[];
    controller.addListener(() => states.add(controller.state));
    repository.network = Completer<FarmHierarchySnapshot>()
      ..complete(FarmHierarchySnapshot(
        hierarchy: hierarchy,
        source: FarmHierarchySource.network,
      ));
    await controller.load(farmId);

    expect(states.whereType<FarmHierarchyLoading>(), isEmpty);
    expect(controller.state, isA<FarmHierarchyReady>());
  });

  test('controller publishes loading then the complete hierarchy', () async {
    final dataSource = CanonicalFarmHierarchyDataSource.load();
    final controller = FarmHierarchyController(
      DefaultFarmHierarchyRepository(
        dataSource,
        MemoryFarmHierarchyCache(),
      ),
    );
    final states = <FarmHierarchyState>[];
    controller.addListener(() => states.add(controller.state));

    await controller.load(CanonicalFarmHierarchyDataSource.farmId);

    expect(states.first, isA<FarmHierarchyLoading>());
    final ready = states.last as FarmHierarchyReady;
    expect(ready.snapshot.hierarchy.sections, hasLength(12));
    expect(ready.snapshot.hierarchy.trees, hasLength(1539));
  });
}
