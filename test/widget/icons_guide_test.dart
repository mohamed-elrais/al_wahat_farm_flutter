import 'package:al_wahat_farm_flutter/app/theme/app_theme.dart';
import 'package:al_wahat_farm_flutter/app/theme/app_visuals.dart';
import 'package:al_wahat_farm_flutter/core/l10n/l10n.dart';
import 'package:al_wahat_farm_flutter/core/widgets/option_visuals.dart';
import 'package:al_wahat_farm_flutter/features/issues/domain/tree_issue_draft.dart';
import 'package:al_wahat_farm_flutter/features/profile/presentation/icons_guide_screen.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/task_draft.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget home, {String language = 'en'}) => MaterialApp(
      theme: AppTheme.light,
      locale: Locale(language),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    );

void main() {
  testWidgets('the guide lists every task and issue type with its badge',
      (tester) async {
    await tester.pumpWidget(_app(const IconsGuideScreen()));
    await tester.pumpAndSettle();

    final list = find.byKey(const Key('icons-guide-list'));
    for (final label in <String>[
      'Irrigation',
      'Dripper maintenance',
      'Clogged dripper',
      'Tree damage',
      'Urgent',
      'Needs review',
    ]) {
      await tester.scrollUntilVisible(find.text(label), 200,
          scrollable: find.descendant(
              of: list, matching: find.byType(Scrollable)));
      final row = find.ancestor(
        of: find.text(label).first,
        matching: find.byType(OptionLabel),
      );
      expect(row, findsOneWidget, reason: label);
      expect(
        find.descendant(of: row, matching: find.byType(OptionBadge)),
        findsOneWidget,
      );
    }
  });

  testWidgets('badges stay out of screen readers; the word is read',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_app(
      Scaffold(
        body: OptionLabel(TaskType.irrigation.visual, 'Irrigation'),
      ),
    ));
    expect(find.bySemanticsLabel('Irrigation'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(OptionBadge),
        matching: find.byType(ExcludeSemantics),
      ),
      findsWidgets,
    );
    semantics.dispose();
  });

  testWidgets('a selected chip fills with the option colour', (tester) async {
    var selected = false;
    await tester.pumpWidget(_app(
      Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => OptionChip(
            visual: TreeIssueType.pestOrDisease.visual,
            label: 'Pest or disease',
            selected: selected,
            onSelected: (value) => setState(() => selected = value),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Pest or disease'));
    await tester.pumpAndSettle();

    final chip = tester.widget<FilterChip>(find.byType(FilterChip));
    expect(chip.selected, isTrue);
    expect(chip.selectedColor, OptionColors.pest);
    expect(
      tester.widget<OptionBadge>(find.byType(OptionBadge)).inverted,
      isTrue,
    );
  });

  testWidgets('the Arabic guide is right-to-left', (tester) async {
    await tester.pumpWidget(_app(const IconsGuideScreen(), language: 'ar'));
    await tester.pumpAndSettle();
    expect(find.text('دليل الأيقونات'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text('دليل الأيقونات'))),
      TextDirection.rtl,
    );
  });
}
