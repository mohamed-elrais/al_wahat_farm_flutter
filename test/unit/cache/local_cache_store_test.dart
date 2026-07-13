import 'package:al_wahat_farm_flutter/core/cache/local_cache_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InMemoryCacheStore', () {
    test('writes, reads, and removes a single key', () async {
      final store = InMemoryCacheStore();
      await store.write('k', 'v');
      expect(await store.read('k'), 'v');
      await store.remove('k');
      expect(await store.read('k'), isNull);
    });

    test('removeWithPrefix clears only the private namespace', () async {
      final store = InMemoryCacheStore();
      await store.write('${privateCachePrefix}hierarchy:farm', 'a');
      await store.write('${privateCachePrefix}tasks:farm', 'b');
      await store.write('public_theme', 'dark');

      await store.removeWithPrefix(privateCachePrefix);

      expect(await store.read('${privateCachePrefix}hierarchy:farm'), isNull);
      expect(await store.read('${privateCachePrefix}tasks:farm'), isNull);
      expect(await store.read('public_theme'), 'dark');
    });
  });
}
