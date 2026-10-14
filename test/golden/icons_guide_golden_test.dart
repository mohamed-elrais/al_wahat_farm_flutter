import 'package:al_wahat_farm_flutter/app/theme/app_theme.dart';
import 'package:al_wahat_farm_flutter/core/l10n/l10n.dart';
import 'package:al_wahat_farm_flutter/features/profile/presentation/icons_guide_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// The icons guide shows every option set's picture and colour; these
/// goldens are the palette review (ICONS_AND_COLORS_PLAN.md, V0).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    for (final (family, asset) in <(String, String)>[
      ('Inter', 'assets/fonts/Inter-Variable.ttf'),
      ('LibreBaskerville', 'assets/fonts/LibreBaskerville-Variable.ttf'),
      ('NotoSansArabic', 'assets/fonts/NotoSansArabic-Variable.ttf'),
      ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
    ]) {
      await (FontLoader(family)..addFont(rootBundle.load(asset))).load();
    }
  });

  for (final language in <String>['en', 'ar']) {
    testWidgets('icons guide in $language at 390 wide', (tester) async {
      tester.view.physicalSize = const Size(390, 2150);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          locale: Locale(language),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const IconsGuideScreen(),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('../goldens/icons_guide_${language}_390.png'),
      );
    });
  }
}
