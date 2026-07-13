import 'package:flutter/foundation.dart';

/// Privacy-safe diagnostics. Every message routed through [SafeLog] is scrubbed
/// of tokens, emails, scoped storage paths, and precise coordinates before it
/// reaches any sink, so error-reporting hooks can never leak PII or secrets.
class SafeLog {
  const SafeLog._();

  // JWT / bearer-style tokens: three dot-separated base64url segments.
  static final RegExp _token =
      RegExp(r'[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}');
  static final RegExp _email =
      RegExp(r'[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}');
  // Scoped evidence paths: {uuid}/{uuid}/{uuid}/filename.
  static final RegExp _storagePath =
      RegExp(r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
          r'[0-9a-fA-F]{12}(?:/[^\s]+)+');
  // Precise decimal coordinates (4+ fraction digits) that could locate a person.
  static final RegExp _coordinate = RegExp(r'-?\d{1,3}\.\d{4,}');

  /// Returns [input] with any detected secret or PII replaced by `[redacted]`.
  static String redact(String input) => input
      .replaceAll(_token, '[redacted-token]')
      .replaceAll(_storagePath, '[redacted-path]')
      .replaceAll(_email, '[redacted-email]')
      .replaceAll(_coordinate, '[redacted-coord]');

  /// Emits a redacted diagnostic event. [data] values are redacted individually.
  static void event(String message, {Map<String, Object?>? data}) {
    final buffer = StringBuffer('[awf] ${redact(message)}');
    if (data != null && data.isNotEmpty) {
      final pairs = data.entries
          .map((entry) => '${entry.key}=${redact('${entry.value}')}')
          .join(', ');
      buffer.write(' {$pairs}');
    }
    debugPrint(buffer.toString());
  }
}
