import 'package:al_wahat_farm_flutter/core/logging/safe_log.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SafeLog.redact', () {
    test('removes JWT-style access tokens', () {
      const token = 'eyJhbGciOi.eyJzdWIiOiIxMjM0.SflKxwRJSMeKKF2QT4';
      final redacted = SafeLog.redact('bearer $token');
      expect(redacted, contains('[redacted-token]'));
      expect(redacted, isNot(contains(token)));
    });

    test('removes email addresses', () {
      final redacted = SafeLog.redact('login owl@samwa.ai failed');
      expect(redacted, isNot(contains('owl@samwa.ai')));
      expect(redacted, contains('[redacted-email]'));
    });

    test('removes scoped evidence storage paths', () {
      const path = '11111111-2222-3333-4444-555555555555/'
          'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee/'
          '99999999-8888-7777-6666-555555555555/photo.jpg';
      final redacted = SafeLog.redact('upload $path');
      expect(redacted, isNot(contains('photo.jpg')));
      expect(redacted, contains('[redacted-path]'));
    });

    test('removes precise coordinates that could locate a person', () {
      final redacted = SafeLog.redact('tree at 28.2971234, 28.7501234');
      expect(redacted, isNot(contains('28.2971234')));
      expect(redacted, contains('[redacted-coord]'));
    });

    test('leaves safe operational text intact', () {
      expect(SafeLog.redact('discrepancies: 3'), 'discrepancies: 3');
    });
  });
}
