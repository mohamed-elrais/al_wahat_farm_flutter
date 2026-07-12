import 'package:al_wahat_farm_flutter/features/auth/domain/operational_context.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class AuthBootstrapDataSource {
  Future<Map<String, Object?>?> fetchProfile(String userId);
  Future<List<Map<String, Object?>>> fetchMemberships(String userId);
}

class SupabaseAuthBootstrapDataSource implements AuthBootstrapDataSource {
  const SupabaseAuthBootstrapDataSource(this._client);

  final SupabaseClient _client;

  @override
  Future<Map<String, Object?>?> fetchProfile(String userId) async {
    final result = await _client
        .from('profiles')
        .select('id, full_name, phone_number, avatar_url, is_active')
        .eq('id', userId)
        .maybeSingle();
    return result;
  }

  @override
  Future<List<Map<String, Object?>>> fetchMemberships(String userId) async {
    final result = await _client
        .from('farm_memberships')
        .select(
          'id, profile_id, role, is_active, '
          'farms!inner(id, name, code, total_area_m2, timezone)',
        )
        .eq('profile_id', userId)
        .order('created_at');
    return result
        .map<Map<String, Object?>>((row) => Map<String, Object?>.from(row))
        .toList(growable: false);
  }
}

abstract interface class OperationalContextRepository {
  Future<OperationalContext> load(String userId);
}

class DefaultOperationalContextRepository
    implements OperationalContextRepository {
  const DefaultOperationalContextRepository(this._dataSource);

  final AuthBootstrapDataSource _dataSource;

  @override
  Future<OperationalContext> load(String userId) async {
    final profileJson = await _dataSource.fetchProfile(userId);
    if (profileJson == null) {
      throw const BootstrapBlockedException(
        BootstrapBlockReason.profileMissing,
      );
    }
    final profile = UserProfile.fromJson(profileJson);
    if (!profile.isActive) {
      throw const BootstrapBlockedException(
        BootstrapBlockReason.profileInactive,
      );
    }

    final memberships = (await _dataSource.fetchMemberships(userId))
        .map(FarmMembership.fromJson)
        .where((membership) =>
            membership.isActive && membership.role.isOperational)
        .toList(growable: false);
    if (memberships.isEmpty) {
      throw const BootstrapBlockedException(
        BootstrapBlockReason.noActiveOperationalMembership,
      );
    }
    return OperationalContext(profile: profile, memberships: memberships);
  }
}
