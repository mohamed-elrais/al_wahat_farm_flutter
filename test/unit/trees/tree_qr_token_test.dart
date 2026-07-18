import 'package:al_wahat_farm_flutter/features/trees/data/tree_qr_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const uuid = 'd195fa5b-f0e0-4482-9b9e-510c1b207957';

  group('resolveTreeQrToken', () {
    test('extracts the token query parameter from an Al Wahat deep link', () {
      expect(
        resolveTreeQrToken('https://alwahat.farm/scan-tree?token=$uuid'),
        uuid,
      );
    });

    test('accepts a bare UUID', () {
      expect(resolveTreeQrToken(uuid), uuid);
    });

    test('trims surrounding whitespace and lowercases', () {
      expect(resolveTreeQrToken('  ${uuid.toUpperCase()}  '), uuid);
    });

    test('extracts a UUID carried as the last path segment', () {
      expect(
        resolveTreeQrToken('https://alwahat.farm/scan-tree/$uuid'),
        uuid,
      );
    });

    test('ignores extra query parameters around the token', () {
      expect(
        resolveTreeQrToken(
          'https://alwahat.farm/scan-tree?farm=al-wahat&token=$uuid&v=2',
        ),
        uuid,
      );
    });

    test('returns null for a link without a UUID token', () {
      expect(
        resolveTreeQrToken('https://alwahat.farm/scan-tree?token=not-a-uuid'),
        isNull,
      );
      expect(resolveTreeQrToken('just some text'), isNull);
      expect(resolveTreeQrToken('   '), isNull);
    });
  });
}
