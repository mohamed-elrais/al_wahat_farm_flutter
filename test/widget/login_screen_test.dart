import 'package:al_wahat_farm_flutter/app/theme/app_theme.dart';
import 'package:al_wahat_farm_flutter/core/config/app_config.dart';
import 'package:al_wahat_farm_flutter/features/auth/presentation/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('login communicates missing configuration intentionally', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const LoginScreen(
          config: AppConfig(supabaseUrl: '', anonKey: ''),
        ),
      ),
    );
    expect(find.text('Welcome to\nAl Wahat.'), findsOneWidget);
    expect(find.byKey(const Key('login-submit')), findsOneWidget);
    expect(find.textContaining('Supabase is not configured'), findsOneWidget);
  });

  testWidgets('login validates malformed credentials', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const LoginScreen(
          config: AppConfig(
            supabaseUrl: 'https://example.supabase.co',
            anonKey: 'key',
          ),
        ),
      ),
    );
    await tester.enterText(find.byKey(const Key('login-email')), 'not-email');
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pump();
    expect(find.text('Enter a valid email address'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
  });
}
