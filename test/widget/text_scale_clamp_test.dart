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

  testWidgets(
      'vendor display zoom (narrow dp canvas) normalizes the text scale',
      (tester) async {
    // Realme C75 with density override 540: 1080x2400 physical at dpr 3.375
    // gives a 320dp-wide canvas; system font scale 1.15 on top of that made
    // Android text far larger than the iPhone rendering.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.375;
    tester.platformDispatcher.textScaleFactorTestValue = 1.15;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      const AlWahatApp(config: AppConfig(supabaseUrl: '', anonKey: '')),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(LoginScreen));
    // 1.15 * (320 / 360) ≈ 1.02 — visually on par with an iPhone.
    expect(
      MediaQuery.of(context).textScaleFactor,
      closeTo(1.15 * (320 / 360), 0.005),
    );
    expect(tester.takeException(), isNull);
  });
}
