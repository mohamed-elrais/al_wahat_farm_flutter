import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Al Wahat Farm Operations';

  @override
  String get brandName => 'Al Wahat';

  @override
  String get navHome => 'Home';

  @override
  String get navMap => 'Map';

  @override
  String get navScan => 'Scan';

  @override
  String get navTasks => 'Tasks';

  @override
  String get navMore => 'More';

  @override
  String get notifications => 'Notifications';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonClose => 'Close';

  @override
  String get commonBack => 'Back';

  @override
  String get commonLoading => 'Loading…';

  @override
  String routeUnavailable(String path) {
    return 'Route unavailable: $path';
  }

  @override
  String get commonCamera => 'Camera';

  @override
  String get commonGallery => 'Gallery';

  @override
  String get commonRemove => 'Remove';

  @override
  String get offlineBanner => 'Offline · showing cached farm and task data';

  @override
  String get offlineBannerSemantics =>
      'You are offline. Showing cached farm and task data.';

  @override
  String get languageLabel => 'Language';

  @override
  String get languageSystem => 'System default';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get loginWelcomeTitle => 'Welcome to\nAl Wahat.';

  @override
  String get loginEyebrow => 'Farm operations';

  @override
  String get loginSignInTitle => 'Sign in';

  @override
  String get loginSignInSubtitle => 'Use your farm operations account.';

  @override
  String get loginEmailLabel => 'Email';

  @override
  String get loginPasswordLabel => 'Password';

  @override
  String get loginSignInButton => 'Sign in';

  @override
  String get loginNotConfigured =>
      'Supabase is not configured. Run with --dart-define-from-file=config.json.';

  @override
  String get loginInvalidEmail => 'Enter a valid email address';

  @override
  String get loginInvalidPassword => 'Password is required';

  @override
  String get loginFailed => 'Unable to sign in. Check your connection.';

  @override
  String get homeDateEyebrow => 'Sunday · 12 July';

  @override
  String get homeHeroTitle => 'Your farm.\nTree by tree.';

  @override
  String get homeHeroLede =>
      'Field operations grounded in every mapped tree and irrigation zone.';

  @override
  String get homeScanTreeQr => 'Scan Tree QR';

  @override
  String get homeLiveMapData => 'Live map data';

  @override
  String get homeFarmOverview => 'Al Wahat farm overview';

  @override
  String get homeMappedTrees => 'Mapped trees';

  @override
  String get homeSections => 'Sections';

  @override
  String get homeIrrigationZones => 'Irrigation zones';

  @override
  String get homeOpenMap => 'Open coordinate map';

  @override
  String get homeTodaysTasks => 'Today’s tasks';

  @override
  String get homeNoTasksToday => 'No tasks are scheduled for today.';

  @override
  String get homeViewAllTasks => 'View all tasks';

  @override
  String get homeWorkspaceUnavailable => 'Task workspace is unavailable.';

  @override
  String get moreEyebrow => 'Account and sync';

  @override
  String get moreTitle => 'More';

  @override
  String get moreFarmMember => 'Farm member';

  @override
  String get moreRoleResolves => 'Role resolves from active farm membership';

  @override
  String moreSignedInAs(String name) {
    return 'Signed in as $name';
  }

  @override
  String get syncOnline => 'Online';

  @override
  String get syncOffline => 'Offline';

  @override
  String get syncOnlineSubtitle =>
      'Online · operational reads refresh from Supabase';

  @override
  String get syncOfflineSubtitle =>
      'Offline · showing cached farm and task data';

  @override
  String get syncStatusOnlineSemantics => 'Sync status online';

  @override
  String get syncStatusOfflineSemantics => 'Sync status offline';

  @override
  String get syncDefaultSubtitle => 'Operational reads refresh from Supabase';

  @override
  String get logout => 'Log out';

  @override
  String get syncTitle => 'Sync';

  @override
  String get syncStatusAllSynced => 'All changes are synced';

  @override
  String syncStatusPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes waiting to sync',
      one: '1 change waiting to sync',
    );
    return '$_temp0';
  }

  @override
  String syncStatusFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes failed to sync',
      one: '1 change failed to sync',
    );
    return '$_temp0';
  }

  @override
  String get syncSyncing => 'Syncing…';

  @override
  String get syncNow => 'Sync now';

  @override
  String get syncRetryFailed => 'Retry failed changes';

  @override
  String get syncPendingBadge => 'Pending sync';

  @override
  String get gateAccessUnavailableTitle => 'Farm access unavailable';

  @override
  String get gateProfileMissing =>
      'Your account profile has not been provisioned.';

  @override
  String get gateProfileInactive => 'Your account is inactive.';

  @override
  String get gateNoMembership =>
      'No active operational farm membership is assigned.';

  @override
  String get gateLoadFailedTitle => 'Unable to load farm access';

  @override
  String get gateLoadFailedMessage => 'Check your connection and try again.';

  @override
  String get hierarchyFailedTitle => 'Unable to load farm data';

  @override
  String get hierarchyFailedMessage =>
      'Check your connection and farm access, then try again.';

  @override
  String get roleOwner => 'Owner';

  @override
  String get roleAgriculturalEngineer => 'Agricultural engineer';

  @override
  String get roleWorker => 'Worker';

  @override
  String get roleAccountant => 'Accountant';

  @override
  String get taskStatusDraft => 'Draft';

  @override
  String get taskStatusAssigned => 'Assigned';

  @override
  String get taskStatusInProgress => 'In progress';

  @override
  String get taskStatusCompleted => 'Completed';

  @override
  String get taskStatusNeedsReview => 'Needs review';

  @override
  String get taskStatusApproved => 'Approved';

  @override
  String get taskStatusReturned => 'Returned';

  @override
  String get taskStatusCancelled => 'Cancelled';

  @override
  String get taskTypeIrrigation => 'Irrigation';

  @override
  String get taskTypeFertilization => 'Fertilization';

  @override
  String get taskTypeHarmfulWeedControl => 'Harmful weed control';

  @override
  String get taskTypeDripperMaintenance => 'Dripper maintenance';

  @override
  String get taskTypeTreeInspection => 'Tree inspection';

  @override
  String get taskTypeEngineerReview => 'Engineer review';

  @override
  String get taskTypeGeneral => 'General field work';

  @override
  String get priorityLow => 'Low';

  @override
  String get priorityMedium => 'Medium';

  @override
  String get priorityHigh => 'High';

  @override
  String get priorityUrgent => 'Urgent';

  @override
  String get activityCreated => 'Task created';

  @override
  String get activityAssigned => 'Assignments updated';

  @override
  String get activityUnassigned => 'Assignments cleared';

  @override
  String get activityStarted => 'Work started';

  @override
  String get activityCompleted => 'Work completed';

  @override
  String get activityFlaggedForReview => 'Sent for engineer review';

  @override
  String get activityReviewedApproved => 'Work approved';

  @override
  String get activityReviewedReturned => 'Returned for correction';

  @override
  String get activityCommented => 'Comment added';

  @override
  String get activityCancelled => 'Task cancelled';

  @override
  String get activityPhotoAdded => 'Evidence added';

  @override
  String get photoTypeBefore => 'Before work';

  @override
  String get photoTypeAfter => 'After work';

  @override
  String get photoTypeEvidence => 'Evidence';

  @override
  String get photoTypeIssue => 'Issue';

  @override
  String get photoTypeReview => 'Review';

  @override
  String get issueTypeInsufficientIrrigation => 'Insufficient irrigation';

  @override
  String get issueTypeCloggedDripper => 'Clogged dripper';

  @override
  String get issueTypeLeakOrDripperDamage => 'Leak or dripper damage';

  @override
  String get issueTypeHarmfulWeed => 'Harmful weed';

  @override
  String get issueTypePestOrDisease => 'Pest or disease';

  @override
  String get issueTypeTreeDamage => 'Tree damage';

  @override
  String get issueTypeOther => 'Other';

  @override
  String get reviewDecisionApproved => 'Approved';

  @override
  String get reviewDecisionReturned => 'Returned for correction';

  @override
  String get reviewDecisionFollowUp => 'Follow-up required';

  @override
  String get reviewActionApprove => 'Approve';

  @override
  String get reviewActionReturn => 'Return for correction';

  @override
  String get reviewActionFollowUp => 'Request follow-up';

  @override
  String get tasksEyebrow => 'Field operations';

  @override
  String get tasksTitle => 'Farm tasks';

  @override
  String get tasksCreate => 'Create';

  @override
  String get tasksFilterToday => 'Today';

  @override
  String tasksFilterAll(int count) {
    return 'All ($count)';
  }

  @override
  String get tasksLoadingTitle => 'Loading farm tasks';

  @override
  String get tasksLoadingMessage => 'Checking your role-filtered task queue…';

  @override
  String get tasksLoadFailedTitle => 'Tasks could not be loaded';

  @override
  String get tasksFailureDefault =>
      'Unable to load farm tasks. Check your connection and try again.';

  @override
  String get tasksEmptyTodayTitle => 'No tasks scheduled today';

  @override
  String get tasksEmptyAllTitle => 'No visible tasks';

  @override
  String get tasksEmptyManager =>
      'Create a task or switch the date and assignment in Supabase.';

  @override
  String get tasksEmptyWorker =>
      'Only active tasks assigned to you appear here.';

  @override
  String get reviewQueueEntryTitle => 'Review queue';

  @override
  String get reviewQueueEntryNone => 'No tasks awaiting review';

  @override
  String reviewQueueEntryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tasks awaiting review',
      one: '1 task awaiting review',
    );
    return '$_temp0';
  }

  @override
  String targetTree(String code) {
    return 'Tree $code';
  }

  @override
  String get targetTreeGeneric => 'Tree';

  @override
  String targetZone(String code) {
    return 'Zone $code';
  }

  @override
  String get targetZoneGeneric => 'Irrigation zone';

  @override
  String targetSection(String code) {
    return 'Section $code';
  }

  @override
  String get targetSectionGeneric => 'Farm section';

  @override
  String get targetWholeFarm => 'Whole farm';

  @override
  String get scheduleNotScheduled => 'Not scheduled';

  @override
  String scheduleDue(String value) {
    return 'Due $value';
  }

  @override
  String get taskDetailEyebrow => 'Task detail';

  @override
  String get backToTasks => 'Back to tasks';

  @override
  String get detailType => 'Type';

  @override
  String get detailTarget => 'Target';

  @override
  String get detailSchedule => 'Schedule';

  @override
  String get detailPriority => 'Priority';

  @override
  String get detailPlannedDuration => 'Planned duration';

  @override
  String durationMinutes(int minutes) {
    return '$minutes minutes';
  }

  @override
  String get detailDescription => 'Description';

  @override
  String get detailInstructions => 'Instructions';

  @override
  String get assignmentsTitle => 'Assignments';

  @override
  String get editAction => 'Edit';

  @override
  String get noActiveAssignees => 'No active assignees.';

  @override
  String assignedAt(String value) {
    return 'Assigned $value';
  }

  @override
  String get assignedFarmMember => 'Assigned farm member';

  @override
  String get actionsTitle => 'Actions';

  @override
  String get startTask => 'Start task';

  @override
  String get completeAction => 'Complete';

  @override
  String get addEvidence => 'Add evidence';

  @override
  String evidenceCount(int count) {
    return 'Evidence ($count)';
  }

  @override
  String get noEvidence => 'No task evidence has been registered.';

  @override
  String get activityTitle => 'Activity';

  @override
  String get noActivity => 'No task activity is visible.';

  @override
  String get editAssignments => 'Edit assignments';

  @override
  String get noOperationalMembers =>
      'No active operational members are available.';

  @override
  String get saveAssignments => 'Save assignments';

  @override
  String get completeTaskTitle => 'Complete task';

  @override
  String get completionNote => 'Completion note';

  @override
  String get sendForReview => 'Send for engineer review';

  @override
  String get optionalCompletionEvidence => 'Optional completion evidence';

  @override
  String selectedFile(String file) {
    return 'Selected: $file';
  }

  @override
  String get evidenceTypeLabel => 'Evidence type';

  @override
  String get evidenceCaptionLabel => 'Evidence caption';

  @override
  String get confirmCompletion => 'Confirm completion';

  @override
  String get addTaskEvidenceTitle => 'Add task evidence';

  @override
  String get choosePhotoToContinue => 'Choose a photo to continue.';

  @override
  String get captionLabel => 'Caption';

  @override
  String get saveEvidence => 'Save evidence';

  @override
  String get unableToLoadTask => 'Unable to load this task.';

  @override
  String get taskWorkspaceUnavailable => 'Task workspace is unavailable.';

  @override
  String get stageReady => 'Ready';

  @override
  String get stageStarting => 'Starting task…';

  @override
  String get stageAssigning => 'Saving assignments…';

  @override
  String get stagePickingEvidence => 'Preparing evidence…';

  @override
  String get stageUploadingEvidence => 'Uploading private evidence…';

  @override
  String get stageRegisteringEvidence => 'Registering evidence…';

  @override
  String get stageCompleting => 'Completing task…';

  @override
  String get msgTaskStarted => 'Task started.';

  @override
  String get msgAssignmentsUpdated => 'Assignments updated.';

  @override
  String get msgTaskEvidenceSaved => 'Task evidence saved.';

  @override
  String get msgTaskCompleted => 'Task completed.';

  @override
  String get msgTaskCompletedReview =>
      'Task completed and sent for engineer review.';

  @override
  String get errTaskStart => 'The task could not be started.';

  @override
  String get errAssignmentsUpdate => 'Assignments could not be updated.';

  @override
  String get errEvidencePrepare => 'Unable to prepare that evidence photo.';

  @override
  String get errEvidenceRegister =>
      'Evidence registration was not confirmed. You can safely retry.';

  @override
  String get errTaskComplete => 'The task could not be completed.';

  @override
  String get errCompletionUnconfirmed =>
      'Evidence is saved, but task completion was not confirmed. Retry completion without uploading again.';

  @override
  String get createEyebrow => 'Plan field work';

  @override
  String get createTitle => 'Create task';

  @override
  String get taskTitleField => 'Task title *';

  @override
  String get enterTaskTitle => 'Enter a task title';

  @override
  String get taskTypeField => 'Task type';

  @override
  String get descriptionField => 'Description';

  @override
  String get workerInstructionsField => 'Worker instructions';

  @override
  String get targetTitle => 'Target';

  @override
  String get scopeField => 'Scope';

  @override
  String get scopeWholeFarm => 'Whole farm';

  @override
  String get scopeSection => 'Section';

  @override
  String get scopeZone => 'Irrigation zone';

  @override
  String get scopeTree => 'Tree';

  @override
  String get scheduleTitle => 'Schedule';

  @override
  String get scheduledDate => 'Scheduled date';

  @override
  String get startTimeLabel => 'Start time';

  @override
  String get dueDateLabel => 'Due date';

  @override
  String get dueTimeLabel => 'Due time';

  @override
  String get plannedDurationField => 'Planned duration (minutes)';

  @override
  String get enterPositiveMinutes => 'Enter a positive number of minutes';

  @override
  String get priorityField => 'Priority';

  @override
  String get requireEngineerReview => 'Require engineer review';

  @override
  String get membersLoadFailed => 'Assignable farm members could not load.';

  @override
  String get creatingTask => 'Creating…';

  @override
  String get createTaskButton => 'Create task';

  @override
  String get chooseTargetSnack => 'Choose a target for this task.';

  @override
  String get chooseTargetValidator => 'Choose a target';

  @override
  String get createUnavailableRole =>
      'Your farm role cannot create or assign tasks.';

  @override
  String get createUnavailableWorkspace =>
      'The farm task workspace is not ready.';

  @override
  String get msgTaskCreated => 'Task created and assigned.';

  @override
  String get errTaskCreate => 'The task could not be created.';

  @override
  String get reviewTaskEyebrow => 'Review task';

  @override
  String get reviewQueueEyebrow => 'Engineer review';

  @override
  String get reviewQueueTitle => 'Review queue';

  @override
  String reviewQueuePending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tasks awaiting a decision.',
      one: '1 task awaiting a decision.',
    );
    return '$_temp0';
  }

  @override
  String get reviewQueueLoadingTitle => 'Loading review queue';

  @override
  String get reviewQueueLoadingMessage =>
      'Checking tasks flagged for engineer review…';

  @override
  String get reviewQueueFailedTitle => 'Queue could not be loaded';

  @override
  String get reviewQueueEmptyTitle => 'No tasks are waiting';

  @override
  String get reviewQueueEmptyMessage =>
      'Completed work sent for review will appear here.';

  @override
  String get reviewQueueUnavailableTitle => 'Review workspace is unavailable';

  @override
  String get reviewQueueUnavailableMessage =>
      'Reopen the app to restore your farm review queue.';

  @override
  String get reviewDeniedTitle => 'Reviews are restricted';

  @override
  String get reviewDeniedMessage =>
      'Only the owner or agricultural engineer can review completed work.';

  @override
  String get backToReviewQueue => 'Back to review queue';

  @override
  String get reviewLinkedIssue => 'Linked to a reported tree issue.';

  @override
  String get reviewCompleted => 'Completed';

  @override
  String get decisionTitle => 'Decision';

  @override
  String get decisionNotAwaiting =>
      'This task is not awaiting a review decision.';

  @override
  String get decisionPrompt =>
      'Record the engineer review outcome for this work.';

  @override
  String get reviewNotesLabel => 'Review notes';

  @override
  String get reviewNotesHint => 'Explain the decision for the assignee.';

  @override
  String get optionalReviewPhoto => 'Optional review photo';

  @override
  String reviewHistory(int count) {
    return 'Review history ($count)';
  }

  @override
  String get noReviews => 'No review decisions have been recorded yet.';

  @override
  String get reviewWorkspaceUnavailable => 'Review workspace is unavailable.';

  @override
  String get unableToLoadReview => 'Unable to load this review.';

  @override
  String confirmDecision(String action) {
    return 'Confirm $action';
  }

  @override
  String get reviewStagePickingPhoto => 'Preparing photo…';

  @override
  String get reviewStageUploadingPhoto => 'Uploading private photo…';

  @override
  String get reviewStageSubmitting => 'Recording decision…';

  @override
  String msgReviewRecorded(String decision) {
    return 'Review recorded: $decision.';
  }

  @override
  String get errReviewPhotoUnconfirmed =>
      'The review photo is uploaded, but the decision was not confirmed. Retry without uploading again.';

  @override
  String get errReviewRecord => 'The review decision could not be recorded.';

  @override
  String get errReviewPhotoPrepare => 'Unable to prepare that review photo.';

  @override
  String get reportIssueTitle => 'Report tree issue';

  @override
  String issueSectionRow(String section, String row, String tree) {
    return 'Section $section · Row $row / Tree $tree';
  }

  @override
  String get issueTypeLabel => 'Issue type';

  @override
  String get issueSeverityLabel => 'Severity';

  @override
  String get issueObservationLabel => 'Observation (optional)';

  @override
  String issueKibPrepared(int kib) {
    return '$kib KiB prepared';
  }

  @override
  String get issueRemovePhoto => 'Remove photo';

  @override
  String get reportIssueButton => 'Report issue';

  @override
  String get issueReportedButton => 'Issue reported';

  @override
  String get issueRetryPhoto => 'Retry photo';

  @override
  String get issueUnavailable =>
      'This tree is not available for issue reporting.';

  @override
  String get issueStagePreparingPhoto => 'Preparing photo…';

  @override
  String get issueStageReporting => 'Creating issue and review task…';

  @override
  String get issueStageUploadingPhoto => 'Uploading private evidence…';

  @override
  String get issueStageRegisteringPhoto => 'Registering evidence…';

  @override
  String get issueErrPhotoPrepare => 'Unable to prepare that photo.';

  @override
  String get issueMsgReported =>
      'Issue reported and engineer review task created.';

  @override
  String get issueErrReport =>
      'The issue could not be reported. Check your connection.';

  @override
  String get issueMsgReportedWithPhoto =>
      'Issue, review task, and photo evidence saved.';

  @override
  String get issueErrPartialPrefix =>
      'The issue and review task were saved, but photo registration was not confirmed. ';

  @override
  String get issueMsgRetryPhoto => 'You can safely retry the photo.';

  @override
  String get selectedTree => 'Selected tree';

  @override
  String get attachTask => 'Attach a task';

  @override
  String get reportAnIssue => 'Report an issue';

  @override
  String get treeUnavailableActions =>
      'This geometry point is not available in live farm data, so operational actions are disabled.';

  @override
  String get treeDetailSection => 'Section';

  @override
  String get treeDetailRowTree => 'Row / tree';

  @override
  String get treeDetailHealth => 'Health';

  @override
  String get treeDetailZone => 'Zone';

  @override
  String get treeZoneUnassigned => 'Unassigned';

  @override
  String get treeUnavailableTitle => 'Tree unavailable';

  @override
  String get treeUnavailableMessage =>
      'This tree is inactive or no longer visible to your farm.';

  @override
  String get goBack => 'Go back';

  @override
  String get scanQrInactive =>
      'This QR code is not active or visible to your farm.';

  @override
  String get scanOffline =>
      'Unable to scan while offline. Try again when connected.';

  @override
  String get scanLookingUp => 'Looking up tree…';

  @override
  String get scanPointCamera => 'Point the camera at a tree QR label.';

  @override
  String get scanCameraOff =>
      'Camera access is off. Enable it in Settings to scan tree labels.';

  @override
  String get scanCameraUnavailable =>
      'The camera is unavailable. You can try again after checking permissions.';

  @override
  String get mapEyebrow => 'Coordinate-accurate 2D map';

  @override
  String get mapZoomIn => 'Zoom in';

  @override
  String get mapZoomOut => 'Zoom out';

  @override
  String get mapReset => 'Reset map';

  @override
  String get mapLayers => 'Map layers';

  @override
  String get mapLayerTrees => 'Trees';

  @override
  String get mapLayerIrrigation => 'Irrigation network';

  @override
  String get mapLayerUtilities => 'Buildings & utilities';

  @override
  String get mapAllSections => 'All 12 sections';

  @override
  String get mapSectionEmpty => 'Empty';

  @override
  String get mapSectionUnplanted => 'Unplanted';

  @override
  String get mapSelectAnyTree => 'Select any tree';

  @override
  String mapTreePointsAvailable(int count) {
    return '$count tree points are available.';
  }

  @override
  String mapGeometryFailed(String error) {
    return 'The bundled farm geometry could not be loaded.\n$error';
  }

  @override
  String get mapDiscrepancySemantics => 'Farm data discrepancy warning';

  @override
  String mapDiscrepancy(int count, String summary) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Farm data check · $count differences',
      one: 'Farm data check · 1 difference',
    );
    return '$_temp0\n$summary';
  }
}
