import 'package:al_wahat_farm_flutter/app/theme/app_theme.dart';
import 'package:al_wahat_farm_flutter/core/l10n/l10n.dart';
import 'package:al_wahat_farm_flutter/features/issues/presentation/issue_report_controller.dart';
import 'package:al_wahat_farm_flutter/features/issues/presentation/issue_report_screen.dart';
import 'package:al_wahat_farm_flutter/features/trees/domain/tree_identity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/phase4_fakes.dart';

const _tree = TreeIdentity(
  id: 'tree-id',
  farmId: 'farm-id',
  code: 'TREE-B-120',
  sectionCode: 'B',
  rowNumber: 4,
  treeNumber: 120,
  healthStatus: 'healthy',
  type: 'date_palm',
);

/// The worker's issue form picks type and severity with picture tiles
/// (ICONS_AND_COLORS_PLAN.md, V4), in both languages.
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
    testWidgets('report issue tiles in $language at 390 wide', (tester) async {
      tester.view.physicalSize = const Size(390, 1250);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = IssueReportController(
        repository: FakeTreeIssueRepository(),
        photoPicker: FakeIssuePhotoPicker(),
        photoStorage: FakeIssuePhotoStorage(),
        userId: 'user-id',
        farmId: 'farm-id',
        treeId: 'tree-id',
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          locale: Locale(language),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: IssueReportScreen(
            treeId: _tree.id,
            tree: _tree,
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('issue-type-pest_or_disease')));
      await tester.tap(find.byKey(const Key('issue-severity-high')));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('../goldens/issue_report_tiles_${language}_390.png'),
      );
    });
  }
}
