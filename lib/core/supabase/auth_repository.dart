import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  const AuthRepository(this._client, {Future<void> Function()? onSignOut})
      : _onSignOut = onSignOut;

  final SupabaseClient _client;
  final Future<void> Function()? _onSignOut;

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) =>
      _client.auth.signInWithPassword(email: email, password: password);

  /// Clears private local cache before ending the Supabase session so no
  /// session-derived farm data survives the sign-out. The Supabase session
  /// itself is owned and cleared by `supabase_flutter`.
  Future<void> signOut() async {
    try {
      await _onSignOut?.call();
    } catch (_) {
      // Never block sign-out on a cache-clear failure; still end the session.
    }
    await _client.auth.signOut();
  }
}
