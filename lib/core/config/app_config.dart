class AppConfig {
  const AppConfig({required this.supabaseUrl, required this.anonKey});

  static const supabaseUrlEnvironmentKey = 'SUPABASE_URL';
  static const supabaseAnonKeyEnvironmentKey = 'SUPABASE_ANON_KEY';

  const AppConfig.fromEnvironment()
      : supabaseUrl = const String.fromEnvironment(supabaseUrlEnvironmentKey),
        anonKey = const String.fromEnvironment(supabaseAnonKeyEnvironmentKey);

  final String supabaseUrl;
  final String anonKey;

  bool get isConfigured => supabaseUrl.isNotEmpty && anonKey.isNotEmpty;
}
