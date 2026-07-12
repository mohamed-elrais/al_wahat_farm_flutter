import 'package:al_wahat_farm_flutter/app/theme/app_theme.dart';
import 'package:al_wahat_farm_flutter/core/config/app_config.dart';
import 'package:al_wahat_farm_flutter/core/widgets/app_shell.dart';
import 'package:al_wahat_farm_flutter/core/widgets/paper_background.dart';
import 'package:al_wahat_farm_flutter/core/widgets/wahat_card.dart';
import 'package:al_wahat_farm_flutter/features/auth/presentation/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await (FontLoader(
      'Inter',
    )..addFont(rootBundle.load('assets/fonts/Inter-Variable.ttf')))
        .load();
    await (FontLoader('LibreBaskerville')
          ..addFont(
            rootBundle.load('assets/fonts/LibreBaskerville-Variable.ttf'),
          ))
        .load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });

  testWidgets('login visual at 390 by 844', (tester) async {
    _setPhoneSize(tester);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const LoginScreen(
          config: AppConfig(supabaseUrl: '', anonKey: ''),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../goldens/login_390x844.png'),
    );
  });

  testWidgets('phone shell visual at 390 by 844', (tester) async {
    _setPhoneSize(tester);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: Scaffold(
          body: Column(
            children: <Widget>[
              const WahatTopBar(),
              Expanded(
                child: PaperBackground(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: WahatCard(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const Eyebrow('Today at Al Wahat'),
                            const SizedBox(height: 8),
                            Text(
                              'Your farm.\nTree by tree.',
                              textAlign: TextAlign.center,
                              style: AppTheme.light.textTheme.headlineLarge,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: WahatNavigation(index: 0, onSelected: (_) {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Al Wahat'), findsOneWidget);
    final topBar = tester.getRect(find.byType(WahatTopBar));
    final brand = tester.getRect(find.text('Al Wahat'));
    expect(topBar.width, 390);
    expect(brand.center.dx, inInclusiveRange(50, 180));
    expect(brand.center.dy, lessThan(60));

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../goldens/shell_390x844.png'),
    );
  });

  testWidgets('branded top bar visual at 390 by 120', (tester) async {
    _setSize(tester, const Size(390, 120));
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const Scaffold(
          body: Align(alignment: Alignment.topCenter, child: WahatTopBar()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../goldens/top_bar_390x120.png'),
    );
  });
}

void _setPhoneSize(WidgetTester tester) {
  _setSize(tester, const Size(390, 844));
}

void _setSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
