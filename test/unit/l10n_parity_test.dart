import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards against a translation drifting: every message key defined in English
/// must have an Arabic counterpart and vice versa.
void main() {
  test('English and Arabic ARB files define the same message keys', () {
    final en = _messageKeys('lib/l10n/arb/app_en.arb');
    final ar = _messageKeys('lib/l10n/arb/app_ar.arb');

    expect(en.difference(ar), isEmpty,
        reason: 'Arabic (app_ar.arb) is missing these keys');
    expect(ar.difference(en), isEmpty,
        reason: 'Arabic (app_ar.arb) has keys English does not');
  });

  test('no message value is empty in either locale', () {
    for (final path in <String>[
      'lib/l10n/arb/app_en.arb',
      'lib/l10n/arb/app_ar.arb',
    ]) {
      final arb = _load(path);
      for (final key in arb.keys.where((key) => !key.startsWith('@'))) {
        expect((arb[key]! as String).trim(), isNotEmpty,
            reason: '$key is empty in $path');
      }
    }
  });

  test('placeholders match between locales', () {
    final en = _load('lib/l10n/arb/app_en.arb');
    final ar = _load('lib/l10n/arb/app_ar.arb');
    final pattern = RegExp(r'\{(\w+)[,}]');
    final shared = _messageKeys('lib/l10n/arb/app_en.arb')
        .intersection(_messageKeys('lib/l10n/arb/app_ar.arb'));
    for (final key in shared) {
      final enPlaceholders = pattern
          .allMatches(en[key]! as String)
          .map((match) => match.group(1))
          .toSet();
      final arPlaceholders = pattern
          .allMatches(ar[key]! as String)
          .map((match) => match.group(1))
          .toSet();
      expect(arPlaceholders, enPlaceholders,
          reason: 'placeholder mismatch in "$key"');
    }
  });
}

Map<String, Object?> _load(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, Object?>;

Set<String> _messageKeys(String path) =>
    _load(path).keys.where((key) => !key.startsWith('@')).toSet();
