import 'package:al_wahat_farm_flutter/core/cache/local_cache_store.dart';
import 'package:al_wahat_farm_flutter/core/l10n/locale_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocaleController', () {
    test('defaults to system (null) and loads a persisted choice', () async {
      final store = InMemoryCacheStore();
      await store.write(LocaleController.storageKey, 'ar');
      final controller = LocaleController(store);
      addTearDown(controller.dispose);

      expect(controller.locale, isNull);
      await controller.load();
      expect(controller.locale?.languageCode, 'ar');
    });

    test('setLocale persists and clearing returns to system default', () async {
      final store = InMemoryCacheStore();
      final controller = LocaleController(store);
      addTearDown(controller.dispose);
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.setLocale(const Locale('ar'));
      expect(controller.locale?.languageCode, 'ar');
      expect(await store.read(LocaleController.storageKey), 'ar');

      await controller.setLocale(null);
      expect(controller.locale, isNull);
      expect(await store.read(LocaleController.storageKey), isNull);
      expect(notifications, 2);
    });

    test('language preference is stored outside the private cache namespace',
        () {
      expect(
        LocaleController.storageKey.startsWith(privateCachePrefix),
        isFalse,
      );
    });

    test('ignores an unsupported persisted language code', () async {
      final store = InMemoryCacheStore();
      await store.write(LocaleController.storageKey, 'fr');
      final controller = LocaleController(store);
      addTearDown(controller.dispose);

      await controller.load();
      expect(controller.locale, isNull);
    });
  });
}
