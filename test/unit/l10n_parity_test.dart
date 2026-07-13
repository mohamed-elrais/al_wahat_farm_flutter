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
}

Set<String> _messageKeys(String path) {
  final json =
      jsonDecode(File(path).readAsStringSync()) as Map<String, Object?>;
  return json.keys.where((key) => !key.startsWith('@')).toSet();
}
