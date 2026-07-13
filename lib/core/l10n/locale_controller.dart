import 'package:al_wahat_farm_flutter/core/cache/local_cache_store.dart';
import 'package:flutter/widgets.dart';

/// Holds the user's language choice. A null [locale] means "follow the device
/// language"; an explicit locale overrides it. The choice is persisted under a
/// non-private key so it survives logout (it is a preference, not session data).
class LocaleController extends ChangeNotifier {
  LocaleController(this._store);

  /// Deliberately outside [privateCachePrefix]: language is a device preference,
  /// not private farm data, so logout must not reset it.
  static const storageKey = 'awf_locale';

  static const supportedLanguageCodes = <String>['en', 'ar'];

  final LocalCacheStore _store;
  Locale? _locale;

  Locale? get locale => _locale;

  Future<void> load() async {
    final code = await _store.read(storageKey);
    if (code != null && supportedLanguageCodes.contains(code)) {
      _locale = Locale(code);
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale? locale) async {
    if (_locale?.languageCode == locale?.languageCode) return;
    _locale = locale;
    if (locale == null) {
      await _store.remove(storageKey);
    } else {
      await _store.write(storageKey, locale.languageCode);
    }
    notifyListeners();
  }
}
