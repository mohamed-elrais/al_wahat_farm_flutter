import 'package:al_wahat_farm_flutter/core/widgets/install_app_tile.dart';
import 'package:al_wahat_farm_flutter/l10n/gen/app_localizations_en.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _en = AppLocalizationsEn();

Widget _host(InstallAppTile tile) =>
    MaterialApp(home: Scaffold(body: ListView(children: <Widget>[tile])));

InstallAppTile _tile({
  bool enabled = true,
  bool standalone = false,
  bool ios = false,
  bool canPrompt = false,
  Future<bool> Function()? prompt,
}) =>
    InstallAppTile(
      enabled: enabled,
      isStandalone: () => standalone,
      isIos: () => ios,
      canPromptInstall: () => canPrompt,
      promptInstall: prompt ?? () async => false,
      installAvailable: const Stream<void>.empty(),
    );

void main() {
  final tile = find.byKey(const Key('install-app-tile'));

  testWidgets('hidden on native', (tester) async {
    await tester.pumpWidget(_host(_tile(enabled: false, canPrompt: true)));
    expect(tile, findsNothing);
  });

  testWidgets('hidden when already installed', (tester) async {
    await tester.pumpWidget(_host(_tile(standalone: true, canPrompt: true)));
    expect(tile, findsNothing);
  });

  testWidgets('hidden when the browser offers no install path', (tester) async {
    await tester.pumpWidget(_host(_tile()));
    expect(tile, findsNothing);
  });

  testWidgets('Chromium: shows the install dialog and hides once accepted',
      (tester) async {
    var prompts = 0;
    await tester.pumpWidget(_host(_tile(
      canPrompt: true,
      prompt: () async {
        prompts++;
        return true;
      },
    )));
    expect(find.text(_en.installAppTitle), findsOneWidget);

    await tester.tap(tile);
    await tester.pump();

    expect(prompts, 1);
    expect(tile, findsNothing);
  });

  testWidgets('iOS: explains Add to Home Screen', (tester) async {
    await tester.pumpWidget(_host(_tile(ios: true)));
    expect(find.text(_en.installIosTitle), findsOneWidget);

    await tester.tap(tile);
    await tester.pumpAndSettle();

    expect(find.text(_en.installIosStep1), findsOneWidget);
    expect(find.text(_en.installIosStep2), findsOneWidget);
    expect(find.text(_en.installIosStep3), findsOneWidget);
    await tester.tap(find.byKey(const Key('install-ios-done')));
    await tester.pumpAndSettle();
    expect(find.text(_en.installIosStep1), findsNothing);
  });
}
