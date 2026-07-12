import 'package:al_wahat_farm_flutter/features/auth/data/operational_context_repository.dart';
import 'package:al_wahat_farm_flutter/features/auth/domain/operational_context.dart';
import 'package:al_wahat_farm_flutter/shared/models/farm_role.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DefaultOperationalContextRepository', () {
    test('returns every active operational membership without impersonation',
        () async {
      final repository = DefaultOperationalContextRepository(
        _FakeDataSource(
          profile: _profile(),
          memberships: <Map<String, Object?>>[
            _membership('owner', farmId: 'farm-a'),
            _membership('worker', farmId: 'farm-b'),
            _membership('accountant', farmId: 'farm-c'),
            _membership('worker', farmId: 'farm-d', active: false),
          ],
        ),
      );

      final context = await repository.load('user');

      expect(context.profile.fullName, 'Field User');
      expect(context.memberships, hasLength(2));
      expect(context.memberships.map((item) => item.role), <FarmRole>[
        FarmRole.owner,
        FarmRole.worker,
      ]);
      expect(context.membershipForFarm('farm-b')?.role, FarmRole.worker);
      expect(context.membershipForFarm('unknown'), isNull);
    });

    test('blocks inactive profile before loading memberships', () async {
      final source = _FakeDataSource(profile: _profile(active: false));
      final repository = DefaultOperationalContextRepository(source);

      await expectLater(
        repository.load('user'),
        throwsA(
          isA<BootstrapBlockedException>().having(
            (error) => error.reason,
            'reason',
            BootstrapBlockReason.profileInactive,
          ),
        ),
      );
      expect(source.membershipFetches, 0);
    });

    test('blocks users without an active operational membership', () async {
      final repository = DefaultOperationalContextRepository(
        _FakeDataSource(
          profile: _profile(),
          memberships: <Map<String, Object?>>[
            _membership('accountant', farmId: 'farm-a'),
          ],
        ),
      );

      await expectLater(
        repository.load('user'),
        throwsA(
          isA<BootstrapBlockedException>().having(
            (error) => error.reason,
            'reason',
            BootstrapBlockReason.noActiveOperationalMembership,
          ),
        ),
      );
    });
  });
}

class _FakeDataSource implements AuthBootstrapDataSource {
  _FakeDataSource(
      {this.profile, this.memberships = const <Map<String, Object?>>[]});

  final Map<String, Object?>? profile;
  final List<Map<String, Object?>> memberships;
  int membershipFetches = 0;

  @override
  Future<Map<String, Object?>?> fetchProfile(String userId) async => profile;

  @override
  Future<List<Map<String, Object?>>> fetchMemberships(String userId) async {
    membershipFetches++;
    return memberships;
  }
}

Map<String, Object?> _profile({bool active = true}) => <String, Object?>{
      'id': 'user',
      'full_name': 'Field User',
      'phone_number': null,
      'avatar_url': null,
      'is_active': active,
    };

Map<String, Object?> _membership(
  String role, {
  required String farmId,
  bool active = true,
}) =>
    <String, Object?>{
      'id': '$farmId-$role',
      'profile_id': 'user',
      'role': role,
      'is_active': active,
      'farms': <String, Object?>{
        'id': farmId,
        'name': 'Al Wahat $farmId',
        'code': farmId.toUpperCase(),
        'total_area_m2': 252000,
        'timezone': 'Africa/Cairo',
      },
    };
