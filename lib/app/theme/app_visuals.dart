import 'package:al_wahat_farm_flutter/features/issues/domain/tree_issue.dart';
import 'package:al_wahat_farm_flutter/features/issues/domain/tree_issue_draft.dart';
import 'package:al_wahat_farm_flutter/features/reviews/domain/engineer_review.dart';
import 'package:al_wahat_farm_flutter/features/schedules/domain/schedule_models.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/farm_task.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/task_draft.dart';
import 'package:flutter/material.dart';

/// The one fixed icon and colour of every option a user picks or reads, so a
/// worker who can't read the word still recognises it ("blue drop" is always
/// irrigation). Screens never choose their own; see ICONS_AND_COLORS_PLAN.md.
///
/// Rules (tested in test/unit/theme/app_visuals_test.dart):
/// - icon and colour are unique within each set;
/// - the same idea looks the same in every set (pest task = insecticide =
///   pest issue);
/// - every colour is at least 3:1 against white and the card, so the white
///   glyph inside a badge stays visible. Labels stay ink, never these colours.
@immutable
class OptionVisual {
  const OptionVisual(IconData this.icon, this.color, {this.corner})
      : bars = null;

  /// Severity and priority: 1–4 bars drawn by the app instead of an icon.
  const OptionVisual.bars(int this.bars, this.color)
      : icon = null,
        corner = null;

  final IconData? icon;
  final Color color;
  final int? bars;

  /// A small mark on the badge's corner that sets one option apart from
  /// another with the same picture (a damaged tree vs. a tree).
  final IconData? corner;

  @override
  bool operator ==(Object other) =>
      other is OptionVisual &&
      other.icon == icon &&
      other.color == color &&
      other.bars == bars &&
      other.corner == corner;

  @override
  int get hashCode => Object.hash(icon, color, bars, corner);
}

/// Colours by meaning. A family colour is shared across sets on purpose.
abstract final class OptionColors {
  static const water = Color(0xFF2F6E99);
  static const waterLight = Color(0xFF4F7FA0);
  static const leak = Color(0xFF1A7FA6);
  static const dripper = Color(0xFF1F7A74);
  static const fertilizer = Color(0xFF8A5A32);
  static const weed = Color(0xFF5E7A1F);
  static const pest = Color(0xFFB03A2E);
  static const disease = Color(0xFF7B4B94);
  static const tree = Color(0xFF285C36);
  static const treeDamage = Color(0xFFA23B72);
  static const engineer = Color(0xFF3F51A3);
  static const general = Color(0xFF6E7168);
  static const tool = Color(0xFF4A5560);

  // Statuses.
  static const good = Color(0xFF285C36);
  static const approved = Color(0xFF1E6B4A);
  static const working = Color(0xFFC25E2E);
  static const problem = Color(0xFFB03A2E);
  static const waiting = Color(0xFF3F51A3);
  static const draft = Color(0xFF7A7F87);
  static const stopped = Color(0xFF8C8880);
  static const paused = Color(0xFFB07D12);
  static const followUp = Color(0xFFD0612A);

  // Severity and priority, low to urgent.
  static const severity = <Color>[
    Color(0xFF5E7A1F),
    Color(0xFFB07D12),
    Color(0xFFD0612A),
    Color(0xFFA3262A),
  ];
}

abstract final class _Family {
  static const irrigation =
      OptionVisual(Icons.water_drop, OptionColors.water);
  static const fertilizer = OptionVisual(Icons.compost, OptionColors.fertilizer);
  static const weed = OptionVisual(Icons.grass, OptionColors.weed);
  static const pest = OptionVisual(Icons.pest_control, OptionColors.pest);
  static const disease = OptionVisual(Icons.coronavirus, OptionColors.disease);
  static const dripper = OptionVisual(Icons.plumbing, OptionColors.dripper);
  static const general = OptionVisual(Icons.assignment, OptionColors.general);

  static const draft = OptionVisual(Icons.edit_note, OptionColors.draft);
  static const done = OptionVisual(Icons.check_circle, OptionColors.good);
  static const approved = OptionVisual(Icons.verified, OptionColors.approved);
  static const waiting = OptionVisual(Icons.rate_review, OptionColors.waiting);
  static const returned = OptionVisual(Icons.undo, OptionColors.problem);
  static const cancelled = OptionVisual(Icons.cancel, OptionColors.stopped);
}

OptionVisual _severity(int index) =>
    OptionVisual.bars(index + 1, OptionColors.severity[index]);

extension TaskTypeVisual on TaskType {
  OptionVisual get visual => switch (this) {
        TaskType.irrigation => _Family.irrigation,
        TaskType.fertilization => _Family.fertilizer,
        TaskType.harmfulWeedControl => _Family.weed,
        TaskType.pestControl => _Family.pest,
        TaskType.diseaseControl => _Family.disease,
        TaskType.dripperMaintenance => _Family.dripper,
        TaskType.treeInspection =>
          const OptionVisual(Icons.park, OptionColors.tree),
        TaskType.engineerReview =>
          const OptionVisual(Icons.engineering, OptionColors.engineer),
        TaskType.general => _Family.general,
      };
}

extension OperationPlanTypeVisual on OperationPlanType {
  OptionVisual get visual => switch (this) {
        OperationPlanType.irrigation => _Family.irrigation,
        OperationPlanType.fertilization => _Family.fertilizer,
        OperationPlanType.harmfulWeedControl => _Family.weed,
        OperationPlanType.pestControl => _Family.pest,
        OperationPlanType.diseaseControl => _Family.disease,
      };
}

extension TreeIssueTypeVisual on TreeIssueType {
  OptionVisual get visual => switch (this) {
        TreeIssueType.insufficientIrrigation =>
          const OptionVisual(Icons.format_color_reset, OptionColors.water),
        TreeIssueType.cloggedDripper => _Family.dripper,
        TreeIssueType.leakOrDripperDamage =>
          const OptionVisual(Icons.water_damage, OptionColors.leak),
        TreeIssueType.harmfulWeed => _Family.weed,
        TreeIssueType.pestOrDisease => _Family.pest,
        TreeIssueType.treeDamage => const OptionVisual(
            Icons.park,
            OptionColors.treeDamage,
            corner: Icons.close,
          ),
        TreeIssueType.other =>
          const OptionVisual(Icons.help, OptionColors.general),
      };
}

extension IssueSeverityVisual on IssueSeverity {
  OptionVisual get visual => _severity(index);
}

extension TaskPriorityVisual on TaskPriority {
  OptionVisual get visual => _severity(index);
}

extension TaskStatusVisual on TaskStatus {
  OptionVisual get visual => switch (this) {
        TaskStatus.draft => _Family.draft,
        TaskStatus.assigned =>
          const OptionVisual(Icons.assignment_ind, OptionColors.water),
        TaskStatus.inProgress =>
          const OptionVisual(Icons.timelapse, OptionColors.working),
        TaskStatus.completed => _Family.done,
        TaskStatus.needsEngineerReview => _Family.waiting,
        TaskStatus.approved => _Family.approved,
        TaskStatus.returned => _Family.returned,
        TaskStatus.cancelled => _Family.cancelled,
      };
}

extension TreeIssueStatusVisual on TreeIssueStatus {
  OptionVisual get visual => switch (this) {
        TreeIssueStatus.open =>
          const OptionVisual(Icons.report, OptionColors.problem),
        TreeIssueStatus.inReview => _Family.waiting,
        TreeIssueStatus.resolved => _Family.done,
        TreeIssueStatus.dismissed => _Family.cancelled,
      };
}

extension OperationPlanStatusVisual on OperationPlanStatus {
  OptionVisual get visual => switch (this) {
        OperationPlanStatus.draft => _Family.draft,
        OperationPlanStatus.active =>
          const OptionVisual(Icons.play_circle, OptionColors.good),
        OperationPlanStatus.paused =>
          const OptionVisual(Icons.pause_circle, OptionColors.paused),
        OperationPlanStatus.completed =>
          const OptionVisual(Icons.check_circle, OptionColors.water),
        OperationPlanStatus.archived =>
          const OptionVisual(Icons.archive, OptionColors.stopped),
      };
}

extension EngineerReviewDecisionVisual on EngineerReviewDecision {
  OptionVisual get visual => switch (this) {
        EngineerReviewDecision.approved => _Family.approved,
        EngineerReviewDecision.returnedForCorrection => _Family.returned,
        EngineerReviewDecision.followUpRequired =>
          const OptionVisual(Icons.flag, OptionColors.followUp),
      };
}

/// The seeded inventory category codes, in display order.
const inventoryCategoryCodes = <String>[
  'pipe',
  'pipe_joint',
  'dripper',
  'fertilizer',
  'insecticide',
  'herbicide',
  'fungicide',
  'tool',
  'other',
];

/// Seeded categories by code; categories managers add share the "other" look.
OptionVisual inventoryCategoryVisual(String? code) => switch (code) {
      'pipe' => const OptionVisual(Icons.horizontal_rule, OptionColors.water),
      'pipe_joint' =>
        const OptionVisual(Icons.call_split, OptionColors.waterLight),
      'dripper' => _Family.dripper,
      'fertilizer' => _Family.fertilizer,
      'insecticide' => _Family.pest,
      'herbicide' => _Family.weed,
      'fungicide' => _Family.disease,
      'tool' => const OptionVisual(Icons.handyman, OptionColors.tool),
      _ => const OptionVisual(Icons.inventory_2, OptionColors.general),
    };
