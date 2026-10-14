import 'package:al_wahat_farm_flutter/app/theme/app_visuals.dart';
import 'package:al_wahat_farm_flutter/core/l10n/domain_labels.dart';
import 'package:al_wahat_farm_flutter/core/l10n/l10n.dart';
import 'package:al_wahat_farm_flutter/core/widgets/option_visuals.dart';
import 'package:al_wahat_farm_flutter/core/widgets/paper_background.dart';
import 'package:al_wahat_farm_flutter/core/widgets/wahat_card.dart';
import 'package:al_wahat_farm_flutter/features/issues/domain/tree_issue.dart';
import 'package:al_wahat_farm_flutter/features/issues/domain/tree_issue_draft.dart';
import 'package:al_wahat_farm_flutter/features/reviews/domain/engineer_review.dart';
import 'package:al_wahat_farm_flutter/features/schedules/domain/schedule_models.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/farm_task.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/task_draft.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Every option set with its fixed picture, colour and word, for training
/// workers and for checking the palette on a real phone.
class IconsGuideScreen extends StatelessWidget {
  const IconsGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sections = <(String, List<(OptionVisual, String)>)>[
      (
        l10n.taskTypeField,
        [for (final v in TaskType.values) (v.visual, v.localizedLabel(l10n))],
      ),
      (
        l10n.issueTypeLabel,
        [
          for (final v in TreeIssueType.values)
            (v.visual, v.localizedLabel(l10n)),
        ],
      ),
      (
        l10n.iconsGuideSeverity,
        [
          for (final v in IssueSeverity.values)
            (v.visual, v.localizedLabel(l10n)),
        ],
      ),
      (
        l10n.iconsGuideTaskStatus,
        [for (final v in TaskStatus.values) (v.visual, v.localizedLabel(l10n))],
      ),
      (
        l10n.iconsGuideIssueStatus,
        [
          for (final v in TreeIssueStatus.values)
            (v.visual, v.localizedLabel(l10n)),
        ],
      ),
      (
        l10n.iconsGuideInventory,
        [
          for (final code in inventoryCategoryCodes)
            (
              inventoryCategoryVisual(code),
              inventoryCategoryCodeLabel(l10n, code)!,
            ),
        ],
      ),
      (
        l10n.iconsGuideReviewDecision,
        [
          for (final v in EngineerReviewDecision.values)
            (v.visual, v.localizedLabel(l10n)),
        ],
      ),
      (
        l10n.iconsGuidePlanStatus,
        [
          for (final v in OperationPlanStatus.values)
            (v.visual, v.localizedLabel(l10n)),
        ],
      ),
    ];
    return Scaffold(
      body: PaperBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final gutter = constraints.maxWidth > 752
                  ? (constraints.maxWidth - 720) / 2
                  : 16.0;
              return ListView(
                key: const Key('icons-guide-list'),
                padding: EdgeInsets.fromLTRB(gutter, 16, gutter, 110),
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      WahatBackButton(
                        key: const Key('icons-guide-back'),
                        tooltip: l10n.commonBack,
                        onPressed: () => context.pop(),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Eyebrow(l10n.iconsGuideEyebrow),
                            Text(
                              l10n.iconsGuideTitle,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(l10n.iconsGuideIntro),
                  const SizedBox(height: 12),
                  for (final (title, options) in sections) ...<Widget>[
                    _GuideSection(title: title, options: options),
                    const SizedBox(height: 12),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _GuideSection extends StatelessWidget {
  const _GuideSection({required this.title, required this.options});

  final String title;
  final List<(OptionVisual, String)> options;

  @override
  Widget build(BuildContext context) => WahatCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Semantics(
              header: true,
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 520 ? 3 : 2;
                const gap = 10.0;
                final width =
                    (constraints.maxWidth - gap * (columns - 1)) / columns;
                return Wrap(
                  spacing: gap,
                  runSpacing: 12,
                  children: <Widget>[
                    for (final (visual, label) in options)
                      SizedBox(
                        width: width,
                        child: OptionLabel(
                          visual,
                          label,
                          size: 40,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.25,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      );
}
