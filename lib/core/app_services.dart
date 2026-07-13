import 'package:al_wahat_farm_flutter/core/cache/local_cache_store.dart';
import 'package:al_wahat_farm_flutter/core/connectivity/connectivity_service.dart';
import 'package:flutter/widgets.dart';

/// Process-wide services that outlive a single authenticated session: the local
/// read cache and observable connectivity. Provided near the app root through
/// [AppServicesScope] so gates and screens can reach them without a DI package.
class AppServices {
  const AppServices({
    required this.cacheStore,
    required this.connectivity,
  });

  final LocalCacheStore cacheStore;
  final ConnectivityController connectivity;

  /// Removes every private cached value derived from the authenticated session.
  /// Bundled immutable assets and the Supabase session (owned by
  /// `supabase_flutter`) are handled separately.
  Future<void> clearPrivateData() =>
      cacheStore.removeWithPrefix(privateCachePrefix);
}

class AppServicesScope extends InheritedWidget {
  const AppServicesScope({
    required this.services,
    required super.child,
    super.key,
  });

  final AppServices services;

  static AppServices? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppServicesScope>()?.services;

  @override
  bool updateShouldNotify(AppServicesScope oldWidget) =>
      oldWidget.services != services;
}
