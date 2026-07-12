import 'package:al_wahat_farm_flutter/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppConfig', () {
    test('uses the documented dart-define keys', () {
      expect(AppConfig.supabaseUrlEnvironmentKey, 'SUPABASE_URL');
      expect(AppConfig.supabaseAnonKeyEnvironmentKey, 'SUPABASE_ANON_KEY');
    });

    test('requires both values to be configured', () {
      expect(
        const AppConfig(supabaseUrl: 'https://example.supabase.co', anonKey: '')
            .isConfigured,
        isFalse,
      );
      expect(
        const AppConfig(
          supabaseUrl: 'https://example.supabase.co',
          anonKey: 'public-key',
        ).isConfigured,
        isTrue,
      );
    });

    test('loads values supplied through dart defines', () {
      const config = AppConfig.fromEnvironment();
      const hasSupabaseUrl =
          bool.hasEnvironment(AppConfig.supabaseUrlEnvironmentKey);
      const hasSupabaseAnonKey =
          bool.hasEnvironment(AppConfig.supabaseAnonKeyEnvironmentKey);

      expect(config.isConfigured, hasSupabaseUrl && hasSupabaseAnonKey);
    });
  });
}
