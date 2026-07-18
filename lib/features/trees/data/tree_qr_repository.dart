import 'package:al_wahat_farm_flutter/core/errors/operation_failure.dart';
import 'package:al_wahat_farm_flutter/features/trees/domain/scanned_tree.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class TreeQrRepository {
  Future<ScannedTree?> scan(String qrToken);
}

class SupabaseTreeQrRepository implements TreeQrRepository {
  const SupabaseTreeQrRepository(this._client);

  static const scanRpc = 'scan_tree_by_qr';
  static const tokenParameter = 'p_qr_token';

  final SupabaseClient _client;

  @override
  Future<ScannedTree?> scan(String qrToken) async {
    if (qrToken.trim().isEmpty) {
      throw const OperationFailure(
        OperationFailureKind.invalidInput,
        'The QR label is empty.',
      );
    }
    final token = resolveTreeQrToken(qrToken);
    if (token == null) {
      throw const OperationFailure(
        OperationFailureKind.invalidInput,
        'This is not a valid Al Wahat tree QR label.',
      );
    }

    try {
      final Object? result = await _client.rpc(
        scanRpc,
        params: <String, Object?>{tokenParameter: token},
      );
      if (result is! List<Object?> || result.isEmpty) return null;
      final Object? first = result.first;
      if (first is! Map) {
        throw const FormatException('Tree scan RPC returned an invalid row');
      }
      return ScannedTree.fromJson(Map<String, Object?>.from(first));
    } on PostgrestException catch (error) {
      throw _translatePostgrest(error);
    }
  }
}

final RegExp _uuidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
  r'[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

/// Extracts the tree QR UUID token from a raw scan. Accepts a bare UUID or an
/// Al Wahat deep link such as `https://alwahat.farm/scan-tree?token=<uuid>`
/// (token as a query parameter or as a path segment). Returns null when the
/// scan carries no recognizable UUID token.
@visibleForTesting
String? resolveTreeQrToken(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  if (_uuidPattern.hasMatch(trimmed)) return trimmed.toLowerCase();

  final uri = Uri.tryParse(trimmed);
  if (uri == null) return null;

  final queryToken = uri.queryParameters['token']?.trim();
  if (queryToken != null && _uuidPattern.hasMatch(queryToken)) {
    return queryToken.toLowerCase();
  }
  for (final segment in uri.pathSegments.reversed) {
    if (_uuidPattern.hasMatch(segment)) return segment.toLowerCase();
  }
  return null;
}

OperationFailure _translatePostgrest(PostgrestException error) =>
    switch (error.code) {
      '22P02' => OperationFailure(
          OperationFailureKind.invalidInput,
          'This is not a valid Al Wahat tree QR label.',
          cause: error,
        ),
      '42501' => OperationFailure(
          OperationFailureKind.authorization,
          'Your account is not authorized to scan this farm.',
          cause: error,
        ),
      _ => OperationFailure(
          OperationFailureKind.unexpected,
          'The farm could not verify this QR label.',
          cause: error,
        ),
    };
