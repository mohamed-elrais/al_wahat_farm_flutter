import 'dart:async';

import 'package:al_wahat_farm_flutter/core/widgets/app_update_banner.dart';
import 'package:al_wahat_farm_flutter/l10n/gen/app_localizations_en.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final en = AppLocalizationsEn();

  Widget host(AppUpdateBanner banner) => MaterialApp(home: banner);

  testWidgets('does nothing when disabled (native)', (tester) async {
    var checks = 0;
    await tester.pumpWidget(host(AppUpdateBanner(
      enabled: false,
      checkForUpdate: () async {
        checks++;
        return true;
      },
      initialDelay: Duration.zero,
      foreground: const Stream<void>.empty(),
      child: const Text('app'),
    )));
    await tester.pump(const Duration(seconds: 1));

    expect(checks, 0);
    expect(find.byKey(const Key('app-update-banner')), findsNothing);
  });

  testWidgets('shows the banner when a newer build is deployed and reloads',
      (tester) async {
    var reloads = 0;
    await tester.pumpWidget(host(AppUpdateBanner(
      enabled: true,
      checkForUpdate: () async => true,
      reload: () => reloads++,
      initialDelay: Duration.zero,
      foreground: const Stream<void>.empty(),
      child: const Text('app'),
    )));
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();

    expect(find.byKey(const Key('app-update-banner')), findsOneWidget);
    expect(find.text(en.appUpdateAvailable), findsOneWidget);
    expect(find.text('app'), findsOneWidget);

    await tester.tap(find.byKey(const Key('app-update-reload')));
    expect(reloads, 1);
  });

  testWidgets('checks again when the app returns to the foreground',
      (tester) async {
    final foreground = StreamController<void>();
    var deployed = false;
    await tester.pumpWidget(host(AppUpdateBanner(
      enabled: true,
      checkForUpdate: () async => deployed,
      initialDelay: Duration.zero,
      foreground: foreground.stream,
      child: const Text('app'),
    )));
    await tester.pump();
    expect(find.byKey(const Key('app-update-banner')), findsNothing);

    deployed = true;
    foreground.add(null);
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('app-update-banner')), findsOneWidget);
    await foreground.close();
  });
}
