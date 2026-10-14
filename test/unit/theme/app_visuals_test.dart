import 'package:al_wahat_farm_flutter/app/theme/app_tokens.dart';
import 'package:al_wahat_farm_flutter/app/theme/app_visuals.dart';
import 'package:al_wahat_farm_flutter/features/issues/domain/tree_issue.dart';
import 'package:al_wahat_farm_flutter/features/issues/domain/tree_issue_draft.dart';
import 'package:al_wahat_farm_flutter/features/reviews/domain/engineer_review.dart';
import 'package:al_wahat_farm_flutter/features/schedules/domain/schedule_models.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/farm_task.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/task_draft.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final sets = <String, List<OptionVisual>>{
    'task types': [for (final v in TaskType.values) v.visual],
    'plan types': [for (final v in OperationPlanType.values) v.visual],
    'issue types': [for (final v in TreeIssueType.values) v.visual],
    'severity': [for (final v in IssueSeverity.values) v.visual],
    'priority': [for (final v in TaskPriority.values) v.visual],
    'task status': [for (final v in TaskStatus.values) v.visual],
    'issue status': [for (final v in TreeIssueStatus.values) v.visual],
    'plan status': [for (final v in OperationPlanStatus.values) v.visual],
    'review decision': [
      for (final v in EngineerReviewDecision.values) v.visual,
    ],
    'inventory categories': [
      for (final code in inventoryCategoryCodes) inventoryCategoryVisual(code),
    ],
  };

  double contrast(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    return (la > lb ? la + 0.05 : lb + 0.05) / (la > lb ? lb + 0.05 : la + 0.05);
  }

  for (final MapEntry(key: name, value: visuals) in sets.entries) {
    test('$name: every option has its own colour', () {
      final colors = visuals.map((v) => v.color.value).toList();
      expect(colors.toSet(), hasLength(colors.length), reason: '$colors');
    });

    test('$name: every option has its own picture', () {
      final pictures = visuals
          .map((v) => v.bars ?? '${v.icon!.codePoint}:${v.corner?.codePoint}')
          .toList();
      expect(pictures.toSet(), hasLength(pictures.length));
    });

    test('$name: the white glyph is visible on every colour (3:1)', () {
      for (final visual in visuals) {
        expect(
          contrast(visual.color, Colors.white),
          greaterThanOrEqualTo(3),
          reason: visual.color.toString(),
        );
        expect(
          contrast(visual.color, AppColors.card),
          greaterThanOrEqualTo(3),
          reason: visual.color.toString(),
        );
      }
    });
  }

  test('one idea looks the same in every set', () {
    expect(TaskType.pestControl.visual, TreeIssueType.pestOrDisease.visual);
    expect(TaskType.pestControl.visual, inventoryCategoryVisual('insecticide'));
    expect(TaskType.harmfulWeedControl.visual, TreeIssueType.harmfulWeed.visual);
    expect(TaskType.harmfulWeedControl.visual,
        inventoryCategoryVisual('herbicide'));
    expect(TaskType.dripperMaintenance.visual,
        TreeIssueType.dripperProblem.visual);
    expect(TaskType.dripperMaintenance.visual,
        inventoryCategoryVisual('dripper'));
    expect(TaskType.fertilization.visual, inventoryCategoryVisual('fertilizer'));
    expect(TaskType.diseaseControl.visual, inventoryCategoryVisual('fungicide'));
    for (final type in OperationPlanType.values) {
      expect(type.visual, TaskType.values.byName(type.name).visual);
    }
    expect(TaskStatus.completed.visual, TreeIssueStatus.resolved.visual);
    expect(TaskStatus.needsEngineerReview.visual,
        TreeIssueStatus.inReview.visual);
    expect(TaskStatus.approved.visual, EngineerReviewDecision.approved.visual);
    expect(TaskStatus.returned.visual,
        EngineerReviewDecision.returnedForCorrection.visual);
  });

  test('severity and priority share one rising scale', () {
    for (var i = 0; i < 4; i++) {
      expect(IssueSeverity.values[i].visual.bars, i + 1);
      expect(TaskPriority.values[i].visual, IssueSeverity.values[i].visual);
    }
  });

  test('categories a manager adds look like "other"', () {
    expect(inventoryCategoryVisual('seeds'), inventoryCategoryVisual('other'));
    expect(inventoryCategoryVisual(null), inventoryCategoryVisual('other'));
  });
}
