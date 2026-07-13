import 'package:shared_preferences/shared_preferences.dart';

/// Namespace prefix for every locally cached value that is derived from an
/// authenticated session (farm hierarchy, task reads, and similar). Logout
/// removes exactly these keys so no private farm data survives a sign-out,
/// while bundled immutable assets and non-private preferences remain intact.
const String privateCachePrefix = 'awf_private:';

/// A minimal key/value string store used for offline read caching. It is
/// deliberately tiny and synchronous-friendly so it can be faked in tests
/// without pulling in a database dependency.
abstract interface class LocalCacheStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> remove(String key);

  /// Removes every stored key that begins with [prefix]. Used to clear all
  /// private cached data on logout in a single sweep.
  Future<void> removeWithPrefix(String prefix);
}

class SharedPreferencesCacheStore implements LocalCacheStore {
  const SharedPreferencesCacheStore(this._prefs);

  final SharedPreferences _prefs;

  @override
  Future<String?> read(String key) async => _prefs.getString(key);

  @override
  Future<void> write(String key, String value) async {
    await _prefs.setString(key, value);
  }

  @override
  Future<void> remove(String key) async {
    await _prefs.remove(key);
  }

  @override
  Future<void> removeWithPrefix(String prefix) async {
    final keys = _prefs
        .getKeys()
        .where((key) => key.startsWith(prefix))
        .toList(growable: false);
    for (final key in keys) {
      await _prefs.remove(key);
    }
  }
}

/// An in-memory [LocalCacheStore] for tests and for a graceful fallback when
/// persistent storage is unavailable.
class InMemoryCacheStore implements LocalCacheStore {
  final Map<String, String> _entries = <String, String>{};

  @override
  Future<String?> read(String key) async => _entries[key];

  @override
  Future<void> write(String key, String value) async {
    _entries[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    _entries.remove(key);
  }

  @override
  Future<void> removeWithPrefix(String prefix) async {
    _entries.removeWhere((key, _) => key.startsWith(prefix));
  }
}
