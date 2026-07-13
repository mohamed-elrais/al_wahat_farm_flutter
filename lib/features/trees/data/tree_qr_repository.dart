import 'package:al_wahat_farm_flutter/core/errors/operation_failure.dart';
import 'package:al_wahat_farm_flutter/features/trees/domain/scanned_tree.dart';
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
    final token = qrToken.trim();
    if (token.isEmpty) {
      throw const OperationFailure(
        OperationFailureKind.invalidInput,
        'The QR label is empty.',
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
