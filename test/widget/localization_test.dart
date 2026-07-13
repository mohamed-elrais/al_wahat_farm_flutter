import 'package:al_wahat_farm_flutter/core/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget probe() => Builder(
        builder: (context) => Scaffold(
          body: Column(
            children: <Widget>[
              Text(context.l10n.navHome),
              Text(context.l10n.loginSignInButton),
            ],
          ),
        ),
      );

  testWidgets('English locale renders LTR English strings', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: probe(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text('Home'))),
      TextDirection.ltr,
    );
  });

  testWidgets('Arabic locale renders RTL Arabic strings', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: probe(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('الرئيسية'), findsOneWidget);
    expect(find.text('تسجيل الدخول'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text('الرئيسية'))),
      TextDirection.rtl,
    );
  });

  testWidgets('missing delegates fall back to English instead of throwing',
      (tester) async {
    await tester.pumpWidget(MaterialApp(home: probe()));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
  });
}
