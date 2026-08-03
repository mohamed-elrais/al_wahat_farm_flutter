import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  AuthRepository(this._client, {this.onSignOut});

  final SupabaseClient _client;
  final Future<void> Function()? onSignOut;

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) =>
      _client.auth.signInWithPassword(email: email, password: password);

  Future<void> signOut() async {
    await _client.auth.signOut();
    await onSignOut?.call();
  }
}
