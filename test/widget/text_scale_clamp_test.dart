import 'package:al_wahat_farm_flutter/app/app.dart';
import 'package:al_wahat_farm_flutter/core/config/app_config.dart';
import 'package:al_wahat_farm_flutter/features/auth/presentation/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'system text scale is clamped so huge vendor defaults cannot '
      'break the layout', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      const AlWahatApp(config: AppConfig(supabaseUrl: '', anonKey: '')),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(LoginScreen));
    expect(
      MediaQuery.of(context).textScaleFactor,
      AlWahatApp.maxTextScale,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('normal text scale passes through unchanged', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.1;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      const AlWahatApp(config: AppConfig(supabaseUrl: '', anonKey: '')),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(LoginScreen));
    expect(MediaQuery.of(context).textScaleFactor, closeTo(1.1, 0.001));
  });
}
