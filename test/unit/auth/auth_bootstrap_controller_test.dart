import 'package:al_wahat_farm_flutter/features/auth/data/operational_context_repository.dart';
import 'package:al_wahat_farm_flutter/features/auth/domain/operational_context.dart';
import 'package:al_wahat_farm_flutter/features/auth/presentation/auth_bootstrap_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('controller publishes loading then ready', () async {
    final context = OperationalContext(
      profile: const UserProfile(id: 'user', fullName: 'User', isActive: true),
      memberships: const <FarmMembership>[],
    );
    final controller =
        AuthBootstrapController(_FakeRepository(context: context));
    final states = <Type>[];
    controller.addListener(() => states.add(controller.state.runtimeType));

    await controller.load('user');

    expect(states, <Type>[AuthBootstrapLoading, AuthBootstrapReady]);
    expect((controller.state as AuthBootstrapReady).context, same(context));
  });

  test('controller distinguishes blocked state from unexpected failure',
      () async {
    final blocked = AuthBootstrapController(
      const _FakeRepository(
        error: BootstrapBlockedException(
          BootstrapBlockReason.profileInactive,
        ),
      ),
    );
    await blocked.load('user');
    expect(blocked.state, isA<AuthBootstrapBlocked>());
    expect(
      (blocked.state as AuthBootstrapBlocked).reason,
      BootstrapBlockReason.profileInactive,
    );

    final failed = AuthBootstrapController(
      _FakeRepository(error: StateError('network')),
    );
    await failed.load('user');
    expect(failed.state, isA<AuthBootstrapFailure>());
  });
}

class _FakeRepository implements OperationalContextRepository {
  const _FakeRepository({this.context, this.error});

  final OperationalContext? context;
  final Object? error;

  @override
  Future<OperationalContext> load(String userId) async {
    if (error != null) throw error!;
    return context!;
  }
}
