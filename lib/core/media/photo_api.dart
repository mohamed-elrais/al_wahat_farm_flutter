import 'dart:async';
import 'dart:convert';

import 'package:al_wahat_farm_flutter/core/errors/operation_failure.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Client for the photo service on the app's own site (`/api/photos`, a
/// Cloudflare Pages Function that stores photos in R2; R2_PHOTOS_PLAN.md).
///
/// It sends the user's Supabase login token; the service checks with the
/// database what the user may do. No storage key is in the app.
class PhotoApi {
  PhotoApi({
    required Uri base,
    required Future<String?> Function() accessToken,
    http.Client? client,
  })  : _base = base,
        _accessToken = accessToken,
        _client = client ?? http.Client();

  /// Uses the signed-in Supabase session, refreshed first when it expired.
  factory PhotoApi.forSupabase(SupabaseClient supabase, {http.Client? client}) =>
      PhotoApi(
        base: defaultBase(),
        client: client,
        accessToken: () async {
          var session = supabase.auth.currentSession;
          if (session != null && session.isExpired) {
            session = (await supabase.auth.refreshSession()).session;
          }
          return session?.accessToken;
        },
      );

  /// The web app calls its own site (staging calls staging). Native builds
  /// call production unless PHOTO_API_URL is defined.
  static Uri defaultBase() {
    const configured = String.fromEnvironment('PHOTO_API_URL');
    if (configured.isNotEmpty) return Uri.parse('$configured/api/photos/');
    if (kIsWeb) return Uri.base.resolve('/api/photos/');
    return Uri.parse('https://al-wahat-farm.pages.dev/api/photos/');
  }

  final Uri _base;
  final Future<String?> Function() _accessToken;
  final http.Client _client;

  Future<void> upload(String path, Uint8List bytes, String contentType) async {
    final response = await _send(
      () async => http.Request('PUT', _object(path))
        ..headers['Content-Type'] = contentType
        ..bodyBytes = bytes,
    );
    _check(response, 'The photo could not be uploaded.');
  }

  Future<void> delete(String path) async {
    final response =
        await _send(() async => http.Request('DELETE', _object(path)));
    _check(response, 'The photo could not be deleted.');
  }

  /// Short-lived links for the paths the user may view; others are left out.
  Future<Map<String, String>> sign(List<String> paths) async {
    final response = await _send(
      () async => http.Request('POST', _base.resolve('sign'))
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode(<String, Object?>{'paths': paths}),
    );
    _check(response, 'The photo links could not be loaded.');
    final body = jsonDecode(response.body) as Map<String, Object?>;
    final urls = body['urls'] as Map<String, Object?>? ?? const {};
    return urls.map((path, url) => MapEntry(path, url! as String));
  }

  Uri _object(String path) => _base.resolve(
        'object/${path.split('/').map(Uri.encodeComponent).join('/')}',
      );

  Future<http.Response> _send(Future<http.Request> Function() build) async {
    final token = await _accessToken();
    if (token == null) {
      throw const OperationFailure(
        OperationFailureKind.authorization,
        'Sign in again to send photos.',
      );
    }
    final request = await build();
    request.headers['Authorization'] = 'Bearer $token';
    try {
      return await http.Response.fromStream(
        await _client.send(request).timeout(const Duration(seconds: 90)),
      );
    } on TimeoutException catch (error) {
      throw OperationFailure(
        OperationFailureKind.offline,
        'The photo service did not answer.',
        cause: error,
      );
    } on http.ClientException catch (error) {
      throw OperationFailure(
        OperationFailureKind.offline,
        'The photo service could not be reached.',
        cause: error,
      );
    }
  }

  void _check(http.Response response, String message) {
    final status = response.statusCode;
    if (status >= 200 && status < 300) return;
    final kind = switch (status) {
      403 => OperationFailureKind.authorization,
      404 => OperationFailureKind.notFound,
      400 || 413 || 415 => OperationFailureKind.invalidInput,
      // 401: an expired token; a later retry sends a refreshed one.
      _ => OperationFailureKind.unexpected,
    };
    throw OperationFailure(kind, message, cause: 'HTTP $status');
  }
}
