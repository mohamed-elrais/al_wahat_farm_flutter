import 'package:al_wahat_farm_flutter/app/app.dart';
import 'package:al_wahat_farm_flutter/app/theme/app_theme.dart';
import 'package:al_wahat_farm_flutter/core/config/app_config.dart';
import 'package:al_wahat_farm_flutter/core/widgets/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('missing configuration restores to the intentional login state', (
    tester,
  ) async {
    await tester.pumpWidget(
      const AlWahatApp(
        config: AppConfig(supabaseUrl: '', anonKey: ''),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome to\nAl Wahat.'), findsOneWidget);
    expect(find.textContaining('Supabase is not configured'), findsOneWidget);
  });

  testWidgets('five-item navigation exposes labels and selects Map', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var selectedIndex = -1;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          bottomNavigationBar: WahatNavigation(
            index: 0,
            onSelected: (index) => selectedIndex = index,
          ),
        ),
      ),
    );

    for (final label in <String>['Home', 'Map', 'Scan', 'Tasks', 'More']) {
      final destination = find.byKey(Key('nav-${label.toLowerCase()}'));
      expect(destination, findsOneWidget);
      expect(tester.getSemantics(destination).label, label);
    }

    await tester.tap(find.byKey(const Key('nav-map')));
    await tester.pump();

    expect(selectedIndex, 1);
    semantics.dispose();
  });
}
