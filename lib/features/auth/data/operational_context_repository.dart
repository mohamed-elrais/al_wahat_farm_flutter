import 'dart:convert';

import 'package:al_wahat_farm_flutter/core/cache/local_cache_store.dart';
import 'package:al_wahat_farm_flutter/core/logging/safe_log.dart';
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

/// Wraps an [OperationalContextRepository] so the resolved context is cached and
/// the app can bootstrap offline. On a successful online load it writes through
/// to the cache; when the network load fails it serves the cached context so a
/// returning user opens straight into the app. A [BootstrapBlockedException]
/// (profile missing/inactive, no membership) is an authoritative backend
/// verdict and is never masked by the cache.
class CachingOperationalContextRepository
    implements OperationalContextRepository {
  const CachingOperationalContextRepository({
    required OperationalContextRepository inner,
    required LocalCacheStore store,
  })  : _inner = inner,
        _store = store;

  static const keyPrefix = '${privateCachePrefix}operational_context:';

  final OperationalContextRepository _inner;
  final LocalCacheStore _store;

  static String keyFor(String userId) => '$keyPrefix$userId';

  @override
  Future<OperationalContext> load(String userId) async {
    try {
      final context = await _inner.load(userId);
      await _store.write(keyFor(userId), jsonEncode(context.toCacheJson()));
      return context;
    } on BootstrapBlockedException {
      // Authoritative "blocked" state — do not fall back to a stale cache.
      rethrow;
    } catch (error) {
      final cached = await _readCache(userId);
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<OperationalContext?> _readCache(String userId) async {
    final raw = await _store.read(keyFor(userId));
    if (raw == null) return null;
    try {
      return OperationalContext.fromCacheJson(
        Map<String, Object?>.from(jsonDecode(raw) as Map),
      );
    } catch (error) {
      SafeLog.event(
        'operational_context_cache_dropped',
        data: <String, Object?>{'error': error.runtimeType},
      );
      await _store.remove(keyFor(userId));
      return null;
    }
  }
}
