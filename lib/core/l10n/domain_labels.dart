import 'package:al_wahat_farm_flutter/l10n/gen/app_localizations.dart';
import 'package:al_wahat_farm_flutter/features/inventory/domain/inventory_models.dart';
import 'package:al_wahat_farm_flutter/features/issues/domain/tree_issue_draft.dart';
import 'package:al_wahat_farm_flutter/features/reviews/domain/engineer_review.dart';
import 'package:al_wahat_farm_flutter/features/schedules/domain/schedule_models.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/farm_task.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/task_draft.dart';
import 'package:al_wahat_farm_flutter/shared/models/farm_role.dart';

/// Localized display labels for domain enums. Kept out of the domain models so
/// those stay pure; the model `.label` getters remain the English/debug source.

extension FarmRoleL10n on FarmRole {
  String localizedLabel(AppLocalizations l10n) => switch (this) {
        FarmRole.owner => l10n.roleOwner,
        FarmRole.agriculturalEngineer => l10n.roleAgriculturalEngineer,
        FarmRole.worker => l10n.roleWorker,
        FarmRole.accountant => l10n.roleAccountant,
      };
}

extension TaskStatusL10n on TaskStatus {
  String localizedLabel(AppLocalizations l10n) => switch (this) {
        TaskStatus.draft => l10n.taskStatusDraft,
        TaskStatus.assigned => l10n.taskStatusAssigned,
        TaskStatus.inProgress => l10n.taskStatusInProgress,
        TaskStatus.completed => l10n.taskStatusCompleted,
        TaskStatus.needsEngineerReview => l10n.taskStatusNeedsReview,
        TaskStatus.approved => l10n.taskStatusApproved,
        TaskStatus.returned => l10n.taskStatusReturned,
        TaskStatus.cancelled => l10n.taskStatusCancelled,
      };
}

extension TaskTypeL10n on TaskType {
  String localizedLabel(AppLocalizations l10n) => switch (this) {
        TaskType.irrigation => l10n.taskTypeIrrigation,
        TaskType.fertilization => l10n.taskTypeFertilization,
        TaskType.harmfulWeedControl => l10n.taskTypeHarmfulWeedControl,
        TaskType.pestControl => l10n.taskTypePestControl,
        TaskType.diseaseControl => l10n.taskTypeDiseaseControl,
        TaskType.dripperMaintenance => l10n.taskTypeDripperMaintenance,
        TaskType.treeInspection => l10n.taskTypeTreeInspection,
        TaskType.engineerReview => l10n.taskTypeEngineerReview,
        TaskType.general => l10n.taskTypeGeneral,
      };
}

extension TaskPriorityL10n on TaskPriority {
  String localizedLabel(AppLocalizations l10n) => switch (this) {
        TaskPriority.low => l10n.priorityLow,
        TaskPriority.medium => l10n.priorityMedium,
        TaskPriority.high => l10n.priorityHigh,
        TaskPriority.urgent => l10n.priorityUrgent,
      };
}

extension TaskActivityActionL10n on TaskActivityAction {
  String localizedLabel(AppLocalizations l10n) => switch (this) {
        TaskActivityAction.created => l10n.activityCreated,
        TaskActivityAction.assigned => l10n.activityAssigned,
        TaskActivityAction.unassigned => l10n.activityUnassigned,
        TaskActivityAction.started => l10n.activityStarted,
        TaskActivityAction.completed => l10n.activityCompleted,
        TaskActivityAction.flaggedForReview => l10n.activityFlaggedForReview,
        TaskActivityAction.reviewedApproved => l10n.activityReviewedApproved,
        TaskActivityAction.reviewedReturned => l10n.activityReviewedReturned,
        TaskActivityAction.commented => l10n.activityCommented,
        TaskActivityAction.cancelled => l10n.activityCancelled,
        TaskActivityAction.photoAdded => l10n.activityPhotoAdded,
      };
}

extension TaskPhotoTypeL10n on TaskPhotoType {
  String localizedLabel(AppLocalizations l10n) => switch (this) {
        TaskPhotoType.before => l10n.photoTypeBefore,
        TaskPhotoType.after => l10n.photoTypeAfter,
        TaskPhotoType.evidence => l10n.photoTypeEvidence,
        TaskPhotoType.issue => l10n.photoTypeIssue,
        TaskPhotoType.review => l10n.photoTypeReview,
      };
}

extension TreeIssueTypeL10n on TreeIssueType {
  String localizedLabel(AppLocalizations l10n) => switch (this) {
        TreeIssueType.insufficientIrrigation =>
          l10n.issueTypeInsufficientIrrigation,
        TreeIssueType.cloggedDripper => l10n.issueTypeCloggedDripper,
        TreeIssueType.leakOrDripperDamage => l10n.issueTypeLeakOrDripperDamage,
        TreeIssueType.harmfulWeed => l10n.issueTypeHarmfulWeed,
        TreeIssueType.pestOrDisease => l10n.issueTypePestOrDisease,
        TreeIssueType.treeDamage => l10n.issueTypeTreeDamage,
        TreeIssueType.other => l10n.issueTypeOther,
      };
}

extension IssueSeverityL10n on IssueSeverity {
  String localizedLabel(AppLocalizations l10n) => switch (this) {
        IssueSeverity.low => l10n.priorityLow,
        IssueSeverity.medium => l10n.priorityMedium,
        IssueSeverity.high => l10n.priorityHigh,
        IssueSeverity.urgent => l10n.priorityUrgent,
      };
}

extension EngineerReviewDecisionL10n on EngineerReviewDecision {
  String localizedLabel(AppLocalizations l10n) => switch (this) {
        EngineerReviewDecision.approved => l10n.reviewDecisionApproved,
        EngineerReviewDecision.returnedForCorrection =>
          l10n.reviewDecisionReturned,
        EngineerReviewDecision.followUpRequired => l10n.reviewDecisionFollowUp,
      };

  String localizedActionLabel(AppLocalizations l10n) => switch (this) {
        EngineerReviewDecision.approved => l10n.reviewActionApprove,
        EngineerReviewDecision.returnedForCorrection => l10n.reviewActionReturn,
        EngineerReviewDecision.followUpRequired => l10n.reviewActionFollowUp,
      };
}

extension InventoryUnitL10n on InventoryUnit {
  String localizedLabel(AppLocalizations l10n) => switch (this) {
        InventoryUnit.gram => l10n.unitGram,
        InventoryUnit.kilogram => l10n.unitKilogram,
        InventoryUnit.liter => l10n.unitLiter,
        InventoryUnit.milliliter => l10n.unitMilliliter,
        InventoryUnit.piece => l10n.unitPiece,
        InventoryUnit.meter => l10n.unitMeter,
      };
}

extension InventoryTransactionTypeL10n on InventoryTransactionType {
  String localizedLabel(AppLocalizations l10n) => switch (this) {
        InventoryTransactionType.addition => l10n.txnAddition,
        InventoryTransactionType.consumption => l10n.txnConsumption,
        InventoryTransactionType.adjustment => l10n.txnAdjustment,
        InventoryTransactionType.reversal => l10n.txnReversal,
      };
}

extension InventoryCategoryL10n on InventoryCategory {
  /// Localized label for the seeded default categories; custom categories
  /// created by managers show their stored name as-is.
  String localizedLabel(AppLocalizations l10n) => switch (code) {
        'pipe' => l10n.categoryPipe,
        'pipe_joint' => l10n.categoryPipeJoint,
        'fertilizer' => l10n.categoryFertilizer,
        'dripper' => l10n.categoryDripper,
        'insecticide' => l10n.categoryInsecticide,
        'herbicide' => l10n.categoryHerbicide,
        'fungicide' => l10n.categoryFungicide,
        'tool' => l10n.categoryTool,
        'other' => l10n.categoryOther,
        _ => name,
      };
}

extension OperationPlanTypeL10n on OperationPlanType {
  String localizedLabel(AppLocalizations l10n) => switch (this) {
        OperationPlanType.irrigation => l10n.taskTypeIrrigation,
        OperationPlanType.fertilization => l10n.taskTypeFertilization,
        OperationPlanType.harmfulWeedControl => l10n.taskTypeHarmfulWeedControl,
        OperationPlanType.pestControl => l10n.taskTypePestControl,
        OperationPlanType.diseaseControl => l10n.taskTypeDiseaseControl,
      };
}

extension OperationPlanStatusL10n on OperationPlanStatus {
  String localizedLabel(AppLocalizations l10n) => switch (this) {
        OperationPlanStatus.draft => l10n.planStatusDraft,
        OperationPlanStatus.active => l10n.planStatusActive,
        OperationPlanStatus.paused => l10n.planStatusPaused,
        OperationPlanStatus.completed => l10n.planStatusCompleted,
        OperationPlanStatus.archived => l10n.planStatusArchived,
      };
}

extension PlanScheduleTypeL10n on PlanScheduleType {
  String localizedLabel(AppLocalizations l10n) => switch (this) {
        PlanScheduleType.once => l10n.scheduleOnce,
        PlanScheduleType.daily => l10n.scheduleDaily,
        PlanScheduleType.weekly => l10n.scheduleWeekly,
      };
}

extension RateBasisL10n on RateBasis {
  String localizedLabel(AppLocalizations l10n) => switch (this) {
        RateBasis.perFeddan => l10n.basisPerFeddan,
        RateBasis.perTree => l10n.basisPerTree,
        RateBasis.absolute => l10n.basisAbsolute,
      };
}

extension ApplicationMethodL10n on ApplicationMethod {
  String localizedLabel(AppLocalizations l10n) => switch (this) {
        ApplicationMethod.fertigation => l10n.methodFertigation,
        ApplicationMethod.soilApplication => l10n.methodSoilApplication,
        ApplicationMethod.foliarSpray => l10n.methodFoliarSpray,
        ApplicationMethod.manualApplication => l10n.methodManualApplication,
      };
}
