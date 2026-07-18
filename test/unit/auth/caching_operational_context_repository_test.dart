import 'package:al_wahat_farm_flutter/core/cache/local_cache_store.dart';
import 'package:al_wahat_farm_flutter/core/errors/operation_failure.dart';
import 'package:al_wahat_farm_flutter/features/auth/data/operational_context_repository.dart';
import 'package:al_wahat_farm_flutter/features/auth/domain/operational_context.dart';
import 'package:al_wahat_farm_flutter/shared/models/farm_role.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeInner implements OperationalContextRepository {
  Object? result; // an OperationalContext to return, or an error to throw
  int calls = 0;

  @override
  Future<OperationalContext> load(String userId) async {
    calls++;
    final r = result;
    if (r is OperationalContext) return r;
    throw r as Object;
  }
}

OperationalContext _context({bool active = true}) => OperationalContext(
      profile: UserProfile(
        id: 'u1',
        fullName: 'Owner One',
        isActive: active,
        phoneNumber: '0100',
      ),
      memberships: const <FarmMembership>[
        FarmMembership(
          id: 'm1',
          profileId: 'u1',
          role: FarmRole.owner,
          isActive: true,
          farm: FarmSummary(
            id: 'f1',
            name: 'Al Wahat',
            code: 'AW',
            timezone: 'Africa/Cairo',
            totalAreaM2: 252000,
          ),
        ),
      ],
    );

void main() {
  test('OperationalContext round-trips through cache JSON', () {
    final restored = OperationalContext.fromCacheJson(_context().toCacheJson());
    expect(restored.profile.id, 'u1');
    expect(restored.profile.fullName, 'Owner One');
    expect(restored.selectedMembership.role, FarmRole.owner);
    expect(restored.selectedMembership.farm.name, 'Al Wahat');
    expect(restored.selectedMembership.farm.totalAreaM2, 252000);
  });

  group('CachingOperationalContextRepository', () {
    test('writes through online, then serves cache when the network fails',
        () async {
      final store = InMemoryCacheStore();
      final inner = _FakeInner()..result = _context();
      final repo =
          CachingOperationalContextRepository(inner: inner, store: store);

      final online = await repo.load('u1');
      expect(online.profile.id, 'u1');
      expect(
        await store.read(CachingOperationalContextRepository.keyFor('u1')),
        isNotNull,
      );

      inner.result = const OperationFailure(
        OperationFailureKind.offline,
        'No connection.',
      );
      final offline = await repo.load('u1');
      expect(offline.selectedMembership.farm.name, 'Al Wahat');
    });

    test('never masks a blocked verdict with a cached context', () async {
      final store = InMemoryCacheStore();
      final inner = _FakeInner()..result = _context();
      final repo =
          CachingOperationalContextRepository(inner: inner, store: store);
      await repo.load('u1'); // seed cache

      inner.result = const BootstrapBlockedException(
        BootstrapBlockReason.profileInactive,
      );
      expect(
        () => repo.load('u1'),
        throwsA(isA<BootstrapBlockedException>()),
      );
    });

    test('rethrows when the network fails and nothing is cached', () async {
      final inner = _FakeInner()
        ..result = const OperationFailure(
          OperationFailureKind.offline,
          'No connection.',
        );
      final repo = CachingOperationalContextRepository(
        inner: inner,
        store: InMemoryCacheStore(),
      );

      expect(() => repo.load('u1'), throwsA(isA<OperationFailure>()));
    });
  });
}
