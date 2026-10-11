import 'package:al_wahat_farm_flutter/core/web/second_tab_app.dart';
import 'package:al_wahat_farm_flutter/l10n/gen/app_localizations_en.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('explains the other tab and hands over on "Use here"',
      (tester) async {
    final en = AppLocalizationsEn();
    var usedHere = 0;
    await tester.pumpWidget(SecondTabApp(onUseHere: () => usedHere++));
    await tester.pumpAndSettle();

    expect(find.text(en.secondTabTitle), findsOneWidget);
    expect(find.text(en.secondTabBody), findsOneWidget);

    await tester.tap(find.byKey(const Key('second-tab-use-here')));
    expect(usedHere, 1);
  });
}
