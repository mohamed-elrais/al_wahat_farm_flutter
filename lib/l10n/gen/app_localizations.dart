import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Al Wahat Farm Operations'**
  String get appTitle;

  /// No description provided for @brandName.
  ///
  /// In en, this message translates to:
  /// **'Al Wahat'**
  String get brandName;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get navMap;

  /// No description provided for @navScan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get navScan;

  /// No description provided for @navTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get navTasks;

  /// No description provided for @navMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get navMore;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get commonLoading;

  /// No description provided for @routeUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Route unavailable: {path}'**
  String routeUnavailable(String path);

  /// No description provided for @commonCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get commonCamera;

  /// No description provided for @commonGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get commonGallery;

  /// No description provided for @commonRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get commonRemove;

  /// No description provided for @offlineBanner.
  ///
  /// In en, this message translates to:
  /// **'Offline · showing cached farm and task data'**
  String get offlineBanner;

  /// No description provided for @offlineBannerSemantics.
  ///
  /// In en, this message translates to:
  /// **'You are offline. Showing cached farm and task data.'**
  String get offlineBannerSemantics;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageArabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get languageArabic;

  /// No description provided for @loginWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to\nAl Wahat.'**
  String get loginWelcomeTitle;

  /// No description provided for @loginEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Farm operations'**
  String get loginEyebrow;

  /// No description provided for @loginSignInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginSignInTitle;

  /// No description provided for @loginSignInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use your farm operations account.'**
  String get loginSignInSubtitle;

  /// No description provided for @loginEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get loginEmailLabel;

  /// No description provided for @loginPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPasswordLabel;

  /// No description provided for @loginSignInButton.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginSignInButton;

  /// No description provided for @loginNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Supabase is not configured. Run with --dart-define-from-file=config.json.'**
  String get loginNotConfigured;

  /// No description provided for @loginInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get loginInvalidEmail;

  /// No description provided for @loginInvalidPassword.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get loginInvalidPassword;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to sign in. Check your connection.'**
  String get loginFailed;

  /// No description provided for @homeDateEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Sunday · 12 July'**
  String get homeDateEyebrow;

  /// No description provided for @homeHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Your farm.\nTree by tree.'**
  String get homeHeroTitle;

  /// No description provided for @homeHeroLede.
  ///
  /// In en, this message translates to:
  /// **'Field operations grounded in every mapped tree and irrigation zone.'**
  String get homeHeroLede;

  /// No description provided for @homeScanTreeQr.
  ///
  /// In en, this message translates to:
  /// **'Scan Tree QR'**
  String get homeScanTreeQr;

  /// No description provided for @homeLiveMapData.
  ///
  /// In en, this message translates to:
  /// **'Live map data'**
  String get homeLiveMapData;

  /// No description provided for @homeFarmOverview.
  ///
  /// In en, this message translates to:
  /// **'Al Wahat farm overview'**
  String get homeFarmOverview;

  /// No description provided for @homeMappedTrees.
  ///
  /// In en, this message translates to:
  /// **'Mapped trees'**
  String get homeMappedTrees;

  /// No description provided for @homeSections.
  ///
  /// In en, this message translates to:
  /// **'Sections'**
  String get homeSections;

  /// No description provided for @homeIrrigationZones.
  ///
  /// In en, this message translates to:
  /// **'Irrigation zones'**
  String get homeIrrigationZones;

  /// No description provided for @homeOpenMap.
  ///
  /// In en, this message translates to:
  /// **'Open coordinate map'**
  String get homeOpenMap;

  /// No description provided for @homeTodaysTasks.
  ///
  /// In en, this message translates to:
  /// **'Today’s tasks'**
  String get homeTodaysTasks;

  /// No description provided for @homeNoTasksToday.
  ///
  /// In en, this message translates to:
  /// **'No tasks are scheduled for today.'**
  String get homeNoTasksToday;

  /// No description provided for @homeViewAllTasks.
  ///
  /// In en, this message translates to:
  /// **'View all tasks'**
  String get homeViewAllTasks;

  /// No description provided for @homeWorkspaceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Task workspace is unavailable.'**
  String get homeWorkspaceUnavailable;

  /// No description provided for @moreEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Account and sync'**
  String get moreEyebrow;

  /// No description provided for @moreTitle.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get moreTitle;

  /// No description provided for @moreFarmMember.
  ///
  /// In en, this message translates to:
  /// **'Farm member'**
  String get moreFarmMember;

  /// No description provided for @moreRoleResolves.
  ///
  /// In en, this message translates to:
  /// **'Role resolves from active farm membership'**
  String get moreRoleResolves;

  /// No description provided for @moreSignedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {name}'**
  String moreSignedInAs(String name);

  /// No description provided for @syncOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get syncOnline;

  /// No description provided for @syncOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get syncOffline;

  /// No description provided for @syncOnlineSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Online · operational reads refresh from Supabase'**
  String get syncOnlineSubtitle;

  /// No description provided for @syncOfflineSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Offline · showing cached farm and task data'**
  String get syncOfflineSubtitle;

  /// No description provided for @syncStatusOnlineSemantics.
  ///
  /// In en, this message translates to:
  /// **'Sync status online'**
  String get syncStatusOnlineSemantics;

  /// No description provided for @syncStatusOfflineSemantics.
  ///
  /// In en, this message translates to:
  /// **'Sync status offline'**
  String get syncStatusOfflineSemantics;

  /// No description provided for @syncDefaultSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Operational reads refresh from Supabase'**
  String get syncDefaultSubtitle;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @syncTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get syncTitle;

  /// No description provided for @syncStatusAllSynced.
  ///
  /// In en, this message translates to:
  /// **'All changes are synced'**
  String get syncStatusAllSynced;

  /// No description provided for @syncStatusPending.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 change waiting to sync} other{{count} changes waiting to sync}}'**
  String syncStatusPending(int count);

  /// No description provided for @syncStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 change failed to sync} other{{count} changes failed to sync}}'**
  String syncStatusFailed(int count);

  /// No description provided for @syncSyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing…'**
  String get syncSyncing;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get syncNow;

  /// No description provided for @syncRetryFailed.
  ///
  /// In en, this message translates to:
  /// **'Retry failed changes'**
  String get syncRetryFailed;

  /// No description provided for @syncPendingBadge.
  ///
  /// In en, this message translates to:
  /// **'Pending sync'**
  String get syncPendingBadge;

  /// No description provided for @syncReviewFailed.
  ///
  /// In en, this message translates to:
  /// **'Review failed changes'**
  String get syncReviewFailed;

  /// No description provided for @failedOpsEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get failedOpsEyebrow;

  /// No description provided for @failedOpsTitle.
  ///
  /// In en, this message translates to:
  /// **'Failed changes'**
  String get failedOpsTitle;

  /// No description provided for @failedOpsIntro.
  ///
  /// In en, this message translates to:
  /// **'These changes could not be synced to the farm. Retry them, or discard the ones you no longer need.'**
  String get failedOpsIntro;

  /// No description provided for @failedOpsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Sync is not available right now.'**
  String get failedOpsUnavailable;

  /// No description provided for @failedOpsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No failed changes'**
  String get failedOpsEmptyTitle;

  /// No description provided for @failedOpsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Everything has synced or is still waiting to sync.'**
  String get failedOpsEmptyMessage;

  /// No description provided for @failedOpsRetryAll.
  ///
  /// In en, this message translates to:
  /// **'Retry all'**
  String get failedOpsRetryAll;

  /// No description provided for @failedOpsRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get failedOpsRetry;

  /// No description provided for @failedOpsDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get failedOpsDiscard;

  /// No description provided for @failedOpsDiscardConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard this change?'**
  String get failedOpsDiscardConfirmTitle;

  /// No description provided for @failedOpsDiscardConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This change will be removed and will not be sent to the farm. This cannot be undone.'**
  String get failedOpsDiscardConfirmMessage;

  /// No description provided for @failedOpsKindStartTask.
  ///
  /// In en, this message translates to:
  /// **'Start task'**
  String get failedOpsKindStartTask;

  /// No description provided for @failedOpsKindCompleteTask.
  ///
  /// In en, this message translates to:
  /// **'Complete task'**
  String get failedOpsKindCompleteTask;

  /// No description provided for @failedOpsKindSetAssignments.
  ///
  /// In en, this message translates to:
  /// **'Update assignments'**
  String get failedOpsKindSetAssignments;

  /// No description provided for @failedOpsKindAddTaskPhoto.
  ///
  /// In en, this message translates to:
  /// **'Task evidence photo'**
  String get failedOpsKindAddTaskPhoto;

  /// No description provided for @failedOpsKindCreateTask.
  ///
  /// In en, this message translates to:
  /// **'Create task'**
  String get failedOpsKindCreateTask;

  /// No description provided for @failedOpsKindReportIssue.
  ///
  /// In en, this message translates to:
  /// **'Report tree issue'**
  String get failedOpsKindReportIssue;

  /// No description provided for @failedOpsKindReviewTask.
  ///
  /// In en, this message translates to:
  /// **'Review decision'**
  String get failedOpsKindReviewTask;

  /// No description provided for @gateAccessUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Farm access unavailable'**
  String get gateAccessUnavailableTitle;

  /// No description provided for @gateProfileMissing.
  ///
  /// In en, this message translates to:
  /// **'Your account profile has not been provisioned.'**
  String get gateProfileMissing;

  /// No description provided for @gateProfileInactive.
  ///
  /// In en, this message translates to:
  /// **'Your account is inactive.'**
  String get gateProfileInactive;

  /// No description provided for @gateNoMembership.
  ///
  /// In en, this message translates to:
  /// **'No active operational farm membership is assigned.'**
  String get gateNoMembership;

  /// No description provided for @gateLoadFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Unable to load farm access'**
  String get gateLoadFailedTitle;

  /// No description provided for @gateLoadFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get gateLoadFailedMessage;

  /// No description provided for @hierarchyFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Unable to load farm data'**
  String get hierarchyFailedTitle;

  /// No description provided for @hierarchyFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and farm access, then try again.'**
  String get hierarchyFailedMessage;

  /// No description provided for @roleOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get roleOwner;

  /// No description provided for @roleAgriculturalEngineer.
  ///
  /// In en, this message translates to:
  /// **'Agricultural engineer'**
  String get roleAgriculturalEngineer;

  /// No description provided for @roleWorker.
  ///
  /// In en, this message translates to:
  /// **'Worker'**
  String get roleWorker;

  /// No description provided for @roleAccountant.
  ///
  /// In en, this message translates to:
  /// **'Accountant'**
  String get roleAccountant;

  /// No description provided for @taskStatusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get taskStatusDraft;

  /// No description provided for @taskStatusAssigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get taskStatusAssigned;

  /// No description provided for @taskStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get taskStatusInProgress;

  /// No description provided for @taskStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get taskStatusCompleted;

  /// No description provided for @taskStatusNeedsReview.
  ///
  /// In en, this message translates to:
  /// **'Needs review'**
  String get taskStatusNeedsReview;

  /// No description provided for @taskStatusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get taskStatusApproved;

  /// No description provided for @taskStatusReturned.
  ///
  /// In en, this message translates to:
  /// **'Returned'**
  String get taskStatusReturned;

  /// No description provided for @taskStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get taskStatusCancelled;

  /// No description provided for @taskTypeIrrigation.
  ///
  /// In en, this message translates to:
  /// **'Irrigation'**
  String get taskTypeIrrigation;

  /// No description provided for @taskTypeFertilization.
  ///
  /// In en, this message translates to:
  /// **'Fertilization'**
  String get taskTypeFertilization;

  /// No description provided for @taskTypeHarmfulWeedControl.
  ///
  /// In en, this message translates to:
  /// **'Harmful weed control'**
  String get taskTypeHarmfulWeedControl;

  /// No description provided for @taskTypePestControl.
  ///
  /// In en, this message translates to:
  /// **'Pest control'**
  String get taskTypePestControl;

  /// No description provided for @taskTypeDiseaseControl.
  ///
  /// In en, this message translates to:
  /// **'Disease control'**
  String get taskTypeDiseaseControl;

  /// No description provided for @taskTypeDripperMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Dripper maintenance'**
  String get taskTypeDripperMaintenance;

  /// No description provided for @taskTypeTreeInspection.
  ///
  /// In en, this message translates to:
  /// **'Tree inspection'**
  String get taskTypeTreeInspection;

  /// No description provided for @taskTypeEngineerReview.
  ///
  /// In en, this message translates to:
  /// **'Engineer review'**
  String get taskTypeEngineerReview;

  /// No description provided for @taskTypeGeneral.
  ///
  /// In en, this message translates to:
  /// **'General field work'**
  String get taskTypeGeneral;

  /// No description provided for @priorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get priorityLow;

  /// No description provided for @priorityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get priorityMedium;

  /// No description provided for @priorityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get priorityHigh;

  /// No description provided for @priorityUrgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get priorityUrgent;

  /// No description provided for @activityCreated.
  ///
  /// In en, this message translates to:
  /// **'Task created'**
  String get activityCreated;

  /// No description provided for @activityAssigned.
  ///
  /// In en, this message translates to:
  /// **'Assignments updated'**
  String get activityAssigned;

  /// No description provided for @activityUnassigned.
  ///
  /// In en, this message translates to:
  /// **'Assignments cleared'**
  String get activityUnassigned;

  /// No description provided for @activityStarted.
  ///
  /// In en, this message translates to:
  /// **'Work started'**
  String get activityStarted;

  /// No description provided for @activityCompleted.
  ///
  /// In en, this message translates to:
  /// **'Work completed'**
  String get activityCompleted;

  /// No description provided for @activityFlaggedForReview.
  ///
  /// In en, this message translates to:
  /// **'Sent for engineer review'**
  String get activityFlaggedForReview;

  /// No description provided for @activityReviewedApproved.
  ///
  /// In en, this message translates to:
  /// **'Work approved'**
  String get activityReviewedApproved;

  /// No description provided for @activityReviewedReturned.
  ///
  /// In en, this message translates to:
  /// **'Returned for correction'**
  String get activityReviewedReturned;

  /// No description provided for @activityCommented.
  ///
  /// In en, this message translates to:
  /// **'Comment added'**
  String get activityCommented;

  /// No description provided for @activityCancelled.
  ///
  /// In en, this message translates to:
  /// **'Task cancelled'**
  String get activityCancelled;

  /// No description provided for @activityPhotoAdded.
  ///
  /// In en, this message translates to:
  /// **'Evidence added'**
  String get activityPhotoAdded;

  /// No description provided for @photoTypeBefore.
  ///
  /// In en, this message translates to:
  /// **'Before work'**
  String get photoTypeBefore;

  /// No description provided for @photoTypeAfter.
  ///
  /// In en, this message translates to:
  /// **'After work'**
  String get photoTypeAfter;

  /// No description provided for @photoTypeEvidence.
  ///
  /// In en, this message translates to:
  /// **'Evidence'**
  String get photoTypeEvidence;

  /// No description provided for @photoTypeIssue.
  ///
  /// In en, this message translates to:
  /// **'Issue'**
  String get photoTypeIssue;

  /// No description provided for @photoTypeReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get photoTypeReview;

  /// No description provided for @issueTypeInsufficientIrrigation.
  ///
  /// In en, this message translates to:
  /// **'Insufficient irrigation'**
  String get issueTypeInsufficientIrrigation;

  /// No description provided for @issueTypeCloggedDripper.
  ///
  /// In en, this message translates to:
  /// **'Clogged dripper'**
  String get issueTypeCloggedDripper;

  /// No description provided for @issueTypeLeakOrDripperDamage.
  ///
  /// In en, this message translates to:
  /// **'Leak or dripper damage'**
  String get issueTypeLeakOrDripperDamage;

  /// No description provided for @issueTypeHarmfulWeed.
  ///
  /// In en, this message translates to:
  /// **'Harmful weed'**
  String get issueTypeHarmfulWeed;

  /// No description provided for @issueTypePestOrDisease.
  ///
  /// In en, this message translates to:
  /// **'Pest or disease'**
  String get issueTypePestOrDisease;

  /// No description provided for @issueTypeTreeDamage.
  ///
  /// In en, this message translates to:
  /// **'Tree damage'**
  String get issueTypeTreeDamage;

  /// No description provided for @issueTypeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get issueTypeOther;

  /// No description provided for @reviewDecisionApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get reviewDecisionApproved;

  /// No description provided for @reviewDecisionReturned.
  ///
  /// In en, this message translates to:
  /// **'Returned for correction'**
  String get reviewDecisionReturned;

  /// No description provided for @reviewDecisionFollowUp.
  ///
  /// In en, this message translates to:
  /// **'Follow-up required'**
  String get reviewDecisionFollowUp;

  /// No description provided for @reviewActionApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get reviewActionApprove;

  /// No description provided for @reviewActionReturn.
  ///
  /// In en, this message translates to:
  /// **'Return for correction'**
  String get reviewActionReturn;

  /// No description provided for @reviewActionFollowUp.
  ///
  /// In en, this message translates to:
  /// **'Request follow-up'**
  String get reviewActionFollowUp;

  /// No description provided for @tasksEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Field operations'**
  String get tasksEyebrow;

  /// No description provided for @tasksTitle.
  ///
  /// In en, this message translates to:
  /// **'Farm tasks'**
  String get tasksTitle;

  /// No description provided for @tasksCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get tasksCreate;

  /// No description provided for @tasksFilterToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get tasksFilterToday;

  /// No description provided for @tasksFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All ({count})'**
  String tasksFilterAll(int count);

  /// No description provided for @tasksLoadingTitle.
  ///
  /// In en, this message translates to:
  /// **'Loading farm tasks'**
  String get tasksLoadingTitle;

  /// No description provided for @tasksLoadingMessage.
  ///
  /// In en, this message translates to:
  /// **'Checking your role-filtered task queue…'**
  String get tasksLoadingMessage;

  /// No description provided for @tasksLoadFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Tasks could not be loaded'**
  String get tasksLoadFailedTitle;

  /// No description provided for @tasksFailureDefault.
  ///
  /// In en, this message translates to:
  /// **'Unable to load farm tasks. Check your connection and try again.'**
  String get tasksFailureDefault;

  /// No description provided for @tasksEmptyTodayTitle.
  ///
  /// In en, this message translates to:
  /// **'No tasks scheduled today'**
  String get tasksEmptyTodayTitle;

  /// No description provided for @tasksEmptyAllTitle.
  ///
  /// In en, this message translates to:
  /// **'No visible tasks'**
  String get tasksEmptyAllTitle;

  /// No description provided for @tasksEmptyManager.
  ///
  /// In en, this message translates to:
  /// **'Create a task or switch the date and assignment in Supabase.'**
  String get tasksEmptyManager;

  /// No description provided for @tasksEmptyWorker.
  ///
  /// In en, this message translates to:
  /// **'Only active tasks assigned to you appear here.'**
  String get tasksEmptyWorker;

  /// No description provided for @reviewQueueEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Review queue'**
  String get reviewQueueEntryTitle;

  /// No description provided for @reviewQueueEntryNone.
  ///
  /// In en, this message translates to:
  /// **'No tasks awaiting review'**
  String get reviewQueueEntryNone;

  /// No description provided for @reviewQueueEntryCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 task awaiting review} other{{count} tasks awaiting review}}'**
  String reviewQueueEntryCount(int count);

  /// No description provided for @targetTree.
  ///
  /// In en, this message translates to:
  /// **'Tree {code}'**
  String targetTree(String code);

  /// No description provided for @targetTreeGeneric.
  ///
  /// In en, this message translates to:
  /// **'Tree'**
  String get targetTreeGeneric;

  /// No description provided for @targetZone.
  ///
  /// In en, this message translates to:
  /// **'Zone {code}'**
  String targetZone(String code);

  /// No description provided for @targetZoneGeneric.
  ///
  /// In en, this message translates to:
  /// **'Irrigation zone'**
  String get targetZoneGeneric;

  /// No description provided for @targetSection.
  ///
  /// In en, this message translates to:
  /// **'Section {code}'**
  String targetSection(String code);

  /// No description provided for @targetSectionGeneric.
  ///
  /// In en, this message translates to:
  /// **'Farm section'**
  String get targetSectionGeneric;

  /// No description provided for @targetWholeFarm.
  ///
  /// In en, this message translates to:
  /// **'Whole farm'**
  String get targetWholeFarm;

  /// No description provided for @scheduleNotScheduled.
  ///
  /// In en, this message translates to:
  /// **'Not scheduled'**
  String get scheduleNotScheduled;

  /// No description provided for @scheduleDue.
  ///
  /// In en, this message translates to:
  /// **'Due {value}'**
  String scheduleDue(String value);

  /// No description provided for @taskDetailEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Task detail'**
  String get taskDetailEyebrow;

  /// No description provided for @backToTasks.
  ///
  /// In en, this message translates to:
  /// **'Back to tasks'**
  String get backToTasks;

  /// No description provided for @detailType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get detailType;

  /// No description provided for @detailTarget.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get detailTarget;

  /// No description provided for @detailSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get detailSchedule;

  /// No description provided for @detailPriority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get detailPriority;

  /// No description provided for @detailPlannedDuration.
  ///
  /// In en, this message translates to:
  /// **'Planned duration'**
  String get detailPlannedDuration;

  /// No description provided for @durationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes'**
  String durationMinutes(int minutes);

  /// No description provided for @detailDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get detailDescription;

  /// No description provided for @detailInstructions.
  ///
  /// In en, this message translates to:
  /// **'Instructions'**
  String get detailInstructions;

  /// No description provided for @assignmentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Assignments'**
  String get assignmentsTitle;

  /// No description provided for @editAction.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editAction;

  /// No description provided for @noActiveAssignees.
  ///
  /// In en, this message translates to:
  /// **'No active assignees.'**
  String get noActiveAssignees;

  /// No description provided for @assignedAt.
  ///
  /// In en, this message translates to:
  /// **'Assigned {value}'**
  String assignedAt(String value);

  /// No description provided for @assignedFarmMember.
  ///
  /// In en, this message translates to:
  /// **'Assigned farm member'**
  String get assignedFarmMember;

  /// No description provided for @actionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actionsTitle;

  /// No description provided for @startTask.
  ///
  /// In en, this message translates to:
  /// **'Start task'**
  String get startTask;

  /// No description provided for @completeAction.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get completeAction;

  /// No description provided for @addEvidence.
  ///
  /// In en, this message translates to:
  /// **'Add evidence'**
  String get addEvidence;

  /// No description provided for @evidenceCount.
  ///
  /// In en, this message translates to:
  /// **'Evidence ({count})'**
  String evidenceCount(int count);

  /// No description provided for @noEvidence.
  ///
  /// In en, this message translates to:
  /// **'No task evidence has been registered.'**
  String get noEvidence;

  /// No description provided for @activityTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activityTitle;

  /// No description provided for @noActivity.
  ///
  /// In en, this message translates to:
  /// **'No task activity is visible.'**
  String get noActivity;

  /// No description provided for @editAssignments.
  ///
  /// In en, this message translates to:
  /// **'Edit assignments'**
  String get editAssignments;

  /// No description provided for @noOperationalMembers.
  ///
  /// In en, this message translates to:
  /// **'No active operational members are available.'**
  String get noOperationalMembers;

  /// No description provided for @saveAssignments.
  ///
  /// In en, this message translates to:
  /// **'Save assignments'**
  String get saveAssignments;

  /// No description provided for @completeTaskTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete task'**
  String get completeTaskTitle;

  /// No description provided for @completionNote.
  ///
  /// In en, this message translates to:
  /// **'Completion note'**
  String get completionNote;

  /// No description provided for @sendForReview.
  ///
  /// In en, this message translates to:
  /// **'Send for engineer review'**
  String get sendForReview;

  /// No description provided for @optionalCompletionEvidence.
  ///
  /// In en, this message translates to:
  /// **'Optional completion evidence'**
  String get optionalCompletionEvidence;

  /// No description provided for @selectedFile.
  ///
  /// In en, this message translates to:
  /// **'Selected: {file}'**
  String selectedFile(String file);

  /// No description provided for @evidenceTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Evidence type'**
  String get evidenceTypeLabel;

  /// No description provided for @evidenceCaptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Evidence caption'**
  String get evidenceCaptionLabel;

  /// No description provided for @confirmCompletion.
  ///
  /// In en, this message translates to:
  /// **'Confirm completion'**
  String get confirmCompletion;

  /// No description provided for @addTaskEvidenceTitle.
  ///
  /// In en, this message translates to:
  /// **'Add task evidence'**
  String get addTaskEvidenceTitle;

  /// No description provided for @choosePhotoToContinue.
  ///
  /// In en, this message translates to:
  /// **'Choose a photo to continue.'**
  String get choosePhotoToContinue;

  /// No description provided for @captionLabel.
  ///
  /// In en, this message translates to:
  /// **'Caption'**
  String get captionLabel;

  /// No description provided for @saveEvidence.
  ///
  /// In en, this message translates to:
  /// **'Save evidence'**
  String get saveEvidence;

  /// No description provided for @unableToLoadTask.
  ///
  /// In en, this message translates to:
  /// **'Unable to load this task.'**
  String get unableToLoadTask;

  /// No description provided for @taskWorkspaceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Task workspace is unavailable.'**
  String get taskWorkspaceUnavailable;

  /// No description provided for @stageReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get stageReady;

  /// No description provided for @stageStarting.
  ///
  /// In en, this message translates to:
  /// **'Starting task…'**
  String get stageStarting;

  /// No description provided for @stageAssigning.
  ///
  /// In en, this message translates to:
  /// **'Saving assignments…'**
  String get stageAssigning;

  /// No description provided for @stagePickingEvidence.
  ///
  /// In en, this message translates to:
  /// **'Preparing evidence…'**
  String get stagePickingEvidence;

  /// No description provided for @stageUploadingEvidence.
  ///
  /// In en, this message translates to:
  /// **'Uploading private evidence…'**
  String get stageUploadingEvidence;

  /// No description provided for @stageRegisteringEvidence.
  ///
  /// In en, this message translates to:
  /// **'Registering evidence…'**
  String get stageRegisteringEvidence;

  /// No description provided for @stageCompleting.
  ///
  /// In en, this message translates to:
  /// **'Completing task…'**
  String get stageCompleting;

  /// No description provided for @msgTaskStarted.
  ///
  /// In en, this message translates to:
  /// **'Task started.'**
  String get msgTaskStarted;

  /// No description provided for @msgAssignmentsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Assignments updated.'**
  String get msgAssignmentsUpdated;

  /// No description provided for @msgTaskEvidenceSaved.
  ///
  /// In en, this message translates to:
  /// **'Task evidence saved.'**
  String get msgTaskEvidenceSaved;

  /// No description provided for @msgEvidenceQueuedOffline.
  ///
  /// In en, this message translates to:
  /// **'Evidence saved offline. It will upload when you\'re back online.'**
  String get msgEvidenceQueuedOffline;

  /// No description provided for @msgTaskCompleted.
  ///
  /// In en, this message translates to:
  /// **'Task completed.'**
  String get msgTaskCompleted;

  /// No description provided for @msgTaskCompletedReview.
  ///
  /// In en, this message translates to:
  /// **'Task completed and sent for engineer review.'**
  String get msgTaskCompletedReview;

  /// No description provided for @errTaskStart.
  ///
  /// In en, this message translates to:
  /// **'The task could not be started.'**
  String get errTaskStart;

  /// No description provided for @errAssignmentsUpdate.
  ///
  /// In en, this message translates to:
  /// **'Assignments could not be updated.'**
  String get errAssignmentsUpdate;

  /// No description provided for @errEvidencePrepare.
  ///
  /// In en, this message translates to:
  /// **'Unable to prepare that evidence photo.'**
  String get errEvidencePrepare;

  /// No description provided for @errEvidenceRegister.
  ///
  /// In en, this message translates to:
  /// **'Evidence registration was not confirmed. You can safely retry.'**
  String get errEvidenceRegister;

  /// No description provided for @errTaskComplete.
  ///
  /// In en, this message translates to:
  /// **'The task could not be completed.'**
  String get errTaskComplete;

  /// No description provided for @errCompletionUnconfirmed.
  ///
  /// In en, this message translates to:
  /// **'Evidence is saved, but task completion was not confirmed. Retry completion without uploading again.'**
  String get errCompletionUnconfirmed;

  /// No description provided for @createEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Plan field work'**
  String get createEyebrow;

  /// No description provided for @createTitle.
  ///
  /// In en, this message translates to:
  /// **'Create task'**
  String get createTitle;

  /// No description provided for @taskTitleField.
  ///
  /// In en, this message translates to:
  /// **'Task title *'**
  String get taskTitleField;

  /// No description provided for @enterTaskTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter a task title'**
  String get enterTaskTitle;

  /// No description provided for @taskTypeField.
  ///
  /// In en, this message translates to:
  /// **'Task type'**
  String get taskTypeField;

  /// No description provided for @descriptionField.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionField;

  /// No description provided for @workerInstructionsField.
  ///
  /// In en, this message translates to:
  /// **'Worker instructions'**
  String get workerInstructionsField;

  /// No description provided for @targetTitle.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get targetTitle;

  /// No description provided for @scopeField.
  ///
  /// In en, this message translates to:
  /// **'Scope'**
  String get scopeField;

  /// No description provided for @scopeWholeFarm.
  ///
  /// In en, this message translates to:
  /// **'Whole farm'**
  String get scopeWholeFarm;

  /// No description provided for @scopeSection.
  ///
  /// In en, this message translates to:
  /// **'Section'**
  String get scopeSection;

  /// No description provided for @scopeZone.
  ///
  /// In en, this message translates to:
  /// **'Irrigation zone'**
  String get scopeZone;

  /// No description provided for @scopeTree.
  ///
  /// In en, this message translates to:
  /// **'Tree'**
  String get scopeTree;

  /// No description provided for @scheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get scheduleTitle;

  /// No description provided for @scheduledDate.
  ///
  /// In en, this message translates to:
  /// **'Scheduled date'**
  String get scheduledDate;

  /// No description provided for @startTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Start time'**
  String get startTimeLabel;

  /// No description provided for @dueDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get dueDateLabel;

  /// No description provided for @dueTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Due time'**
  String get dueTimeLabel;

  /// No description provided for @plannedDurationField.
  ///
  /// In en, this message translates to:
  /// **'Planned duration (minutes)'**
  String get plannedDurationField;

  /// No description provided for @enterPositiveMinutes.
  ///
  /// In en, this message translates to:
  /// **'Enter a positive number of minutes'**
  String get enterPositiveMinutes;

  /// No description provided for @priorityField.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priorityField;

  /// No description provided for @requireEngineerReview.
  ///
  /// In en, this message translates to:
  /// **'Require engineer review'**
  String get requireEngineerReview;

  /// No description provided for @membersLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Assignable farm members could not load.'**
  String get membersLoadFailed;

  /// No description provided for @creatingTask.
  ///
  /// In en, this message translates to:
  /// **'Creating…'**
  String get creatingTask;

  /// No description provided for @createTaskButton.
  ///
  /// In en, this message translates to:
  /// **'Create task'**
  String get createTaskButton;

  /// No description provided for @chooseTargetSnack.
  ///
  /// In en, this message translates to:
  /// **'Choose a target for this task.'**
  String get chooseTargetSnack;

  /// No description provided for @chooseTargetValidator.
  ///
  /// In en, this message translates to:
  /// **'Choose a target'**
  String get chooseTargetValidator;

  /// No description provided for @createUnavailableRole.
  ///
  /// In en, this message translates to:
  /// **'Your farm role cannot create or assign tasks.'**
  String get createUnavailableRole;

  /// No description provided for @createUnavailableWorkspace.
  ///
  /// In en, this message translates to:
  /// **'The farm task workspace is not ready.'**
  String get createUnavailableWorkspace;

  /// No description provided for @msgTaskCreated.
  ///
  /// In en, this message translates to:
  /// **'Task created and assigned.'**
  String get msgTaskCreated;

  /// No description provided for @msgTaskCreatedOffline.
  ///
  /// In en, this message translates to:
  /// **'Task saved offline. It will be created on the farm when you\'re back online.'**
  String get msgTaskCreatedOffline;

  /// No description provided for @errTaskCreate.
  ///
  /// In en, this message translates to:
  /// **'The task could not be created.'**
  String get errTaskCreate;

  /// No description provided for @taskPendingSyncBadge.
  ///
  /// In en, this message translates to:
  /// **'Pending sync'**
  String get taskPendingSyncBadge;

  /// No description provided for @taskPendingSyncOpen.
  ///
  /// In en, this message translates to:
  /// **'This task opens once it syncs to the farm.'**
  String get taskPendingSyncOpen;

  /// No description provided for @reviewTaskEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Review task'**
  String get reviewTaskEyebrow;

  /// No description provided for @reviewQueueEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Engineer review'**
  String get reviewQueueEyebrow;

  /// No description provided for @reviewQueueTitle.
  ///
  /// In en, this message translates to:
  /// **'Review queue'**
  String get reviewQueueTitle;

  /// No description provided for @reviewQueuePending.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 task awaiting a decision.} other{{count} tasks awaiting a decision.}}'**
  String reviewQueuePending(int count);

  /// No description provided for @reviewQueueLoadingTitle.
  ///
  /// In en, this message translates to:
  /// **'Loading review queue'**
  String get reviewQueueLoadingTitle;

  /// No description provided for @reviewQueueLoadingMessage.
  ///
  /// In en, this message translates to:
  /// **'Checking tasks flagged for engineer review…'**
  String get reviewQueueLoadingMessage;

  /// No description provided for @reviewQueueFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Queue could not be loaded'**
  String get reviewQueueFailedTitle;

  /// No description provided for @reviewQueueEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No tasks are waiting'**
  String get reviewQueueEmptyTitle;

  /// No description provided for @reviewQueueEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Completed work sent for review will appear here.'**
  String get reviewQueueEmptyMessage;

  /// No description provided for @reviewQueueUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Review workspace is unavailable'**
  String get reviewQueueUnavailableTitle;

  /// No description provided for @reviewQueueUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'Reopen the app to restore your farm review queue.'**
  String get reviewQueueUnavailableMessage;

  /// No description provided for @reviewDeniedTitle.
  ///
  /// In en, this message translates to:
  /// **'Reviews are restricted'**
  String get reviewDeniedTitle;

  /// No description provided for @reviewDeniedMessage.
  ///
  /// In en, this message translates to:
  /// **'Only the owner or agricultural engineer can review completed work.'**
  String get reviewDeniedMessage;

  /// No description provided for @backToReviewQueue.
  ///
  /// In en, this message translates to:
  /// **'Back to review queue'**
  String get backToReviewQueue;

  /// No description provided for @reviewLinkedIssue.
  ///
  /// In en, this message translates to:
  /// **'Linked to a reported tree issue.'**
  String get reviewLinkedIssue;

  /// No description provided for @reviewCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get reviewCompleted;

  /// No description provided for @decisionTitle.
  ///
  /// In en, this message translates to:
  /// **'Decision'**
  String get decisionTitle;

  /// No description provided for @decisionNotAwaiting.
  ///
  /// In en, this message translates to:
  /// **'This task is not awaiting a review decision.'**
  String get decisionNotAwaiting;

  /// No description provided for @decisionPrompt.
  ///
  /// In en, this message translates to:
  /// **'Record the engineer review outcome for this work.'**
  String get decisionPrompt;

  /// No description provided for @reviewNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Review notes'**
  String get reviewNotesLabel;

  /// No description provided for @reviewNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Explain the decision for the assignee.'**
  String get reviewNotesHint;

  /// No description provided for @optionalReviewPhoto.
  ///
  /// In en, this message translates to:
  /// **'Optional review photo'**
  String get optionalReviewPhoto;

  /// No description provided for @reviewHistory.
  ///
  /// In en, this message translates to:
  /// **'Review history ({count})'**
  String reviewHistory(int count);

  /// No description provided for @noReviews.
  ///
  /// In en, this message translates to:
  /// **'No review decisions have been recorded yet.'**
  String get noReviews;

  /// No description provided for @reviewWorkspaceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Review workspace is unavailable.'**
  String get reviewWorkspaceUnavailable;

  /// No description provided for @unableToLoadReview.
  ///
  /// In en, this message translates to:
  /// **'Unable to load this review.'**
  String get unableToLoadReview;

  /// No description provided for @confirmDecision.
  ///
  /// In en, this message translates to:
  /// **'Confirm {action}'**
  String confirmDecision(String action);

  /// No description provided for @reviewStagePickingPhoto.
  ///
  /// In en, this message translates to:
  /// **'Preparing photo…'**
  String get reviewStagePickingPhoto;

  /// No description provided for @reviewStageUploadingPhoto.
  ///
  /// In en, this message translates to:
  /// **'Uploading private photo…'**
  String get reviewStageUploadingPhoto;

  /// No description provided for @reviewStageSubmitting.
  ///
  /// In en, this message translates to:
  /// **'Recording decision…'**
  String get reviewStageSubmitting;

  /// No description provided for @msgReviewRecorded.
  ///
  /// In en, this message translates to:
  /// **'Review recorded: {decision}.'**
  String msgReviewRecorded(String decision);

  /// No description provided for @msgReviewRecordedOffline.
  ///
  /// In en, this message translates to:
  /// **'Review saved offline. It will be recorded on the farm when you\'re back online.'**
  String get msgReviewRecordedOffline;

  /// No description provided for @errReviewPhotoUnconfirmed.
  ///
  /// In en, this message translates to:
  /// **'The review photo is uploaded, but the decision was not confirmed. Retry without uploading again.'**
  String get errReviewPhotoUnconfirmed;

  /// No description provided for @errReviewRecord.
  ///
  /// In en, this message translates to:
  /// **'The review decision could not be recorded.'**
  String get errReviewRecord;

  /// No description provided for @errReviewPhotoPrepare.
  ///
  /// In en, this message translates to:
  /// **'Unable to prepare that review photo.'**
  String get errReviewPhotoPrepare;

  /// No description provided for @reportIssueTitle.
  ///
  /// In en, this message translates to:
  /// **'Report tree issue'**
  String get reportIssueTitle;

  /// No description provided for @issueSectionRow.
  ///
  /// In en, this message translates to:
  /// **'Section {section} · Row {row} / Tree {tree}'**
  String issueSectionRow(String section, String row, String tree);

  /// No description provided for @issueTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Issue type'**
  String get issueTypeLabel;

  /// No description provided for @issueSeverityLabel.
  ///
  /// In en, this message translates to:
  /// **'Severity'**
  String get issueSeverityLabel;

  /// No description provided for @issueObservationLabel.
  ///
  /// In en, this message translates to:
  /// **'Observation (optional)'**
  String get issueObservationLabel;

  /// No description provided for @issueKibPrepared.
  ///
  /// In en, this message translates to:
  /// **'{kib} KiB prepared'**
  String issueKibPrepared(int kib);

  /// No description provided for @issueRemovePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get issueRemovePhoto;

  /// No description provided for @reportIssueButton.
  ///
  /// In en, this message translates to:
  /// **'Report issue'**
  String get reportIssueButton;

  /// No description provided for @issueReportedButton.
  ///
  /// In en, this message translates to:
  /// **'Issue reported'**
  String get issueReportedButton;

  /// No description provided for @issueRetryPhoto.
  ///
  /// In en, this message translates to:
  /// **'Retry photo'**
  String get issueRetryPhoto;

  /// No description provided for @issueUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This tree is not available for issue reporting.'**
  String get issueUnavailable;

  /// No description provided for @issueStagePreparingPhoto.
  ///
  /// In en, this message translates to:
  /// **'Preparing photo…'**
  String get issueStagePreparingPhoto;

  /// No description provided for @issueStageReporting.
  ///
  /// In en, this message translates to:
  /// **'Creating issue and review task…'**
  String get issueStageReporting;

  /// No description provided for @issueStageUploadingPhoto.
  ///
  /// In en, this message translates to:
  /// **'Uploading private evidence…'**
  String get issueStageUploadingPhoto;

  /// No description provided for @issueStageRegisteringPhoto.
  ///
  /// In en, this message translates to:
  /// **'Registering evidence…'**
  String get issueStageRegisteringPhoto;

  /// No description provided for @issueErrPhotoPrepare.
  ///
  /// In en, this message translates to:
  /// **'Unable to prepare that photo.'**
  String get issueErrPhotoPrepare;

  /// No description provided for @issueMsgReported.
  ///
  /// In en, this message translates to:
  /// **'Issue reported and engineer review task created.'**
  String get issueMsgReported;

  /// No description provided for @issueMsgReportedOffline.
  ///
  /// In en, this message translates to:
  /// **'Issue saved offline. It will be reported to the farm when you\'re back online.'**
  String get issueMsgReportedOffline;

  /// No description provided for @issueErrReport.
  ///
  /// In en, this message translates to:
  /// **'The issue could not be reported. Check your connection.'**
  String get issueErrReport;

  /// No description provided for @issueMsgReportedWithPhoto.
  ///
  /// In en, this message translates to:
  /// **'Issue, review task, and photo evidence saved.'**
  String get issueMsgReportedWithPhoto;

  /// No description provided for @issueErrPartialPrefix.
  ///
  /// In en, this message translates to:
  /// **'The issue and review task were saved, but photo registration was not confirmed. '**
  String get issueErrPartialPrefix;

  /// No description provided for @issueMsgRetryPhoto.
  ///
  /// In en, this message translates to:
  /// **'You can safely retry the photo.'**
  String get issueMsgRetryPhoto;

  /// No description provided for @selectedTree.
  ///
  /// In en, this message translates to:
  /// **'Selected tree'**
  String get selectedTree;

  /// No description provided for @attachTask.
  ///
  /// In en, this message translates to:
  /// **'Attach a task'**
  String get attachTask;

  /// No description provided for @reportAnIssue.
  ///
  /// In en, this message translates to:
  /// **'Report an issue'**
  String get reportAnIssue;

  /// No description provided for @treeUnavailableActions.
  ///
  /// In en, this message translates to:
  /// **'This geometry point is not available in live farm data, so operational actions are disabled.'**
  String get treeUnavailableActions;

  /// No description provided for @treeDetailSection.
  ///
  /// In en, this message translates to:
  /// **'Section'**
  String get treeDetailSection;

  /// No description provided for @treeDetailRowTree.
  ///
  /// In en, this message translates to:
  /// **'Row / tree'**
  String get treeDetailRowTree;

  /// No description provided for @treeDetailHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get treeDetailHealth;

  /// No description provided for @treeDetailZone.
  ///
  /// In en, this message translates to:
  /// **'Zone'**
  String get treeDetailZone;

  /// No description provided for @treeZoneUnassigned.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get treeZoneUnassigned;

  /// No description provided for @treeUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Tree unavailable'**
  String get treeUnavailableTitle;

  /// No description provided for @treeUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'This tree is inactive or no longer visible to your farm.'**
  String get treeUnavailableMessage;

  /// No description provided for @goBack.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get goBack;

  /// No description provided for @scanQrInactive.
  ///
  /// In en, this message translates to:
  /// **'This QR code is not active or visible to your farm.'**
  String get scanQrInactive;

  /// No description provided for @scanOffline.
  ///
  /// In en, this message translates to:
  /// **'Unable to scan while offline. Try again when connected.'**
  String get scanOffline;

  /// No description provided for @scanLookingUp.
  ///
  /// In en, this message translates to:
  /// **'Looking up tree…'**
  String get scanLookingUp;

  /// No description provided for @scanPointCamera.
  ///
  /// In en, this message translates to:
  /// **'Point the camera at a tree QR label.'**
  String get scanPointCamera;

  /// No description provided for @scanCameraOff.
  ///
  /// In en, this message translates to:
  /// **'Camera access is off. Enable it in Settings to scan tree labels.'**
  String get scanCameraOff;

  /// No description provided for @scanCameraUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The camera is unavailable. You can try again after checking permissions.'**
  String get scanCameraUnavailable;

  /// No description provided for @mapEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Coordinate-accurate 2D map'**
  String get mapEyebrow;

  /// No description provided for @mapZoomIn.
  ///
  /// In en, this message translates to:
  /// **'Zoom in'**
  String get mapZoomIn;

  /// No description provided for @mapZoomOut.
  ///
  /// In en, this message translates to:
  /// **'Zoom out'**
  String get mapZoomOut;

  /// No description provided for @mapReset.
  ///
  /// In en, this message translates to:
  /// **'Reset map'**
  String get mapReset;

  /// No description provided for @mapLayers.
  ///
  /// In en, this message translates to:
  /// **'Map layers'**
  String get mapLayers;

  /// No description provided for @mapLayerTrees.
  ///
  /// In en, this message translates to:
  /// **'Trees'**
  String get mapLayerTrees;

  /// No description provided for @mapLayerIrrigation.
  ///
  /// In en, this message translates to:
  /// **'Irrigation network'**
  String get mapLayerIrrigation;

  /// No description provided for @mapLayerUtilities.
  ///
  /// In en, this message translates to:
  /// **'Buildings & utilities'**
  String get mapLayerUtilities;

  /// No description provided for @mapLayerValves.
  ///
  /// In en, this message translates to:
  /// **'Zone valves'**
  String get mapLayerValves;

  /// No description provided for @mapLayerFlushValves.
  ///
  /// In en, this message translates to:
  /// **'Flush valves'**
  String get mapLayerFlushValves;

  /// No description provided for @mapLayerWaterSupply.
  ///
  /// In en, this message translates to:
  /// **'Water supply'**
  String get mapLayerWaterSupply;

  /// No description provided for @mapSectionName.
  ///
  /// In en, this message translates to:
  /// **'Section {id}'**
  String mapSectionName(String id);

  /// No description provided for @mapValveNameZone.
  ///
  /// In en, this message translates to:
  /// **'Section {section} — Submain {submain} — Zone Control Valve {number}'**
  String mapValveNameZone(String section, String submain, String number);

  /// No description provided for @mapValveNameIsolation.
  ///
  /// In en, this message translates to:
  /// **'Mainline Isolation Valve {number}'**
  String mapValveNameIsolation(String number);

  /// No description provided for @mapIsolationSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Mainline valve'**
  String get mapIsolationSheetTitle;

  /// No description provided for @mapValveTreeCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No planted trees depend on this valve} =1{1 tree is fed through this valve} other{{count} trees are fed through this valve}}'**
  String mapValveTreeCount(int count);

  /// No description provided for @mapValveDownstream.
  ///
  /// In en, this message translates to:
  /// **'Feeds submains: {list}'**
  String mapValveDownstream(String list);

  /// No description provided for @mapValveHighlightHint.
  ///
  /// In en, this message translates to:
  /// **'The downstream line and its zones are highlighted on the map. Tap empty map space to clear.'**
  String get mapValveHighlightHint;

  /// No description provided for @mapZoneSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Irrigation zone'**
  String get mapZoneSheetTitle;

  /// No description provided for @mapZoneTreeCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No trees mapped to this zone} =1{1 tree irrigated by this valve} other{{count} trees irrigated by this valve}}'**
  String mapZoneTreeCount(int count);

  /// No description provided for @mapZoneTreesPlanned.
  ///
  /// In en, this message translates to:
  /// **'Planned capacity: {count} trees'**
  String mapZoneTreesPlanned(int count);

  /// No description provided for @mapZoneHighlightHint.
  ///
  /// In en, this message translates to:
  /// **'The zone\'s lines and trees are highlighted on the map. Tap empty map space to clear.'**
  String get mapZoneHighlightHint;

  /// No description provided for @mapAllSections.
  ///
  /// In en, this message translates to:
  /// **'All 12 sections'**
  String get mapAllSections;

  /// No description provided for @mapSectionEmpty.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get mapSectionEmpty;

  /// No description provided for @mapSectionUnplanted.
  ///
  /// In en, this message translates to:
  /// **'Unplanted'**
  String get mapSectionUnplanted;

  /// No description provided for @mapSelectAnyTree.
  ///
  /// In en, this message translates to:
  /// **'Select any tree'**
  String get mapSelectAnyTree;

  /// No description provided for @mapTreePointsAvailable.
  ///
  /// In en, this message translates to:
  /// **'{count} tree points are available.'**
  String mapTreePointsAvailable(int count);

  /// No description provided for @mapGeometryFailed.
  ///
  /// In en, this message translates to:
  /// **'The bundled farm geometry could not be loaded.\n{error}'**
  String mapGeometryFailed(String error);

  /// No description provided for @mapDiscrepancySemantics.
  ///
  /// In en, this message translates to:
  /// **'Farm data discrepancy warning'**
  String get mapDiscrepancySemantics;

  /// No description provided for @mapDiscrepancy.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Farm data check · 1 difference} other{Farm data check · {count} differences}}\n{summary}'**
  String mapDiscrepancy(int count, String summary);

  /// No description provided for @inventoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get inventoryTitle;

  /// No description provided for @inventoryEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Farm supplies'**
  String get inventoryEyebrow;

  /// No description provided for @inventorySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search items'**
  String get inventorySearchHint;

  /// No description provided for @inventoryAllCategories.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get inventoryAllCategories;

  /// No description provided for @inventoryEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No inventory items'**
  String get inventoryEmptyTitle;

  /// No description provided for @inventoryEmptyManager.
  ///
  /// In en, this message translates to:
  /// **'Add your first item with the button below.'**
  String get inventoryEmptyManager;

  /// No description provided for @inventoryEmptyWorker.
  ///
  /// In en, this message translates to:
  /// **'No items have been added yet.'**
  String get inventoryEmptyWorker;

  /// No description provided for @inventoryLowStock.
  ///
  /// In en, this message translates to:
  /// **'Low stock'**
  String get inventoryLowStock;

  /// No description provided for @inventoryLowStockCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item below minimum stock} other{{count} items below minimum stock}}'**
  String inventoryLowStockCount(int count);

  /// No description provided for @inventoryQuantityLabel.
  ///
  /// In en, this message translates to:
  /// **'In stock'**
  String get inventoryQuantityLabel;

  /// No description provided for @inventoryMinimumLabel.
  ///
  /// In en, this message translates to:
  /// **'Minimum'**
  String get inventoryMinimumLabel;

  /// No description provided for @inventoryAddItem.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get inventoryAddItem;

  /// No description provided for @inventoryEditItem.
  ///
  /// In en, this message translates to:
  /// **'Edit item'**
  String get inventoryEditItem;

  /// No description provided for @inventoryItemName.
  ///
  /// In en, this message translates to:
  /// **'Item name'**
  String get inventoryItemName;

  /// No description provided for @inventoryItemNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter an item name'**
  String get inventoryItemNameRequired;

  /// No description provided for @inventoryCategoryField.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get inventoryCategoryField;

  /// No description provided for @inventoryUnitField.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get inventoryUnitField;

  /// No description provided for @inventoryDescriptionField.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get inventoryDescriptionField;

  /// No description provided for @inventoryMinimumStockField.
  ///
  /// In en, this message translates to:
  /// **'Minimum stock (alert threshold)'**
  String get inventoryMinimumStockField;

  /// No description provided for @inventoryInitialQuantityField.
  ///
  /// In en, this message translates to:
  /// **'Initial quantity'**
  String get inventoryInitialQuantityField;

  /// No description provided for @inventoryInvalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number'**
  String get inventoryInvalidNumber;

  /// No description provided for @inventoryAttributesTitle.
  ///
  /// In en, this message translates to:
  /// **'Specifications'**
  String get inventoryAttributesTitle;

  /// No description provided for @inventoryAttributeName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get inventoryAttributeName;

  /// No description provided for @inventoryAttributeValue.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get inventoryAttributeValue;

  /// No description provided for @inventoryAddAttribute.
  ///
  /// In en, this message translates to:
  /// **'Add specification'**
  String get inventoryAddAttribute;

  /// No description provided for @inventorySaveItem.
  ///
  /// In en, this message translates to:
  /// **'Save item'**
  String get inventorySaveItem;

  /// No description provided for @inventorySaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get inventorySaving;

  /// No description provided for @inventoryAddStock.
  ///
  /// In en, this message translates to:
  /// **'Add stock'**
  String get inventoryAddStock;

  /// No description provided for @inventoryAdjust.
  ///
  /// In en, this message translates to:
  /// **'Adjust'**
  String get inventoryAdjust;

  /// No description provided for @inventoryAdjustHint.
  ///
  /// In en, this message translates to:
  /// **'Positive adds, negative removes'**
  String get inventoryAdjustHint;

  /// No description provided for @inventoryQuantityField.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get inventoryQuantityField;

  /// No description provided for @inventoryNoteField.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get inventoryNoteField;

  /// No description provided for @inventoryRecord.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get inventoryRecord;

  /// No description provided for @inventoryHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Transaction history'**
  String get inventoryHistoryTitle;

  /// No description provided for @inventoryHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet.'**
  String get inventoryHistoryEmpty;

  /// No description provided for @inventoryDeactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivate item'**
  String get inventoryDeactivate;

  /// No description provided for @inventoryDeactivateConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Deactivate this item?'**
  String get inventoryDeactivateConfirmTitle;

  /// No description provided for @inventoryDeactivateConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'The item is hidden from the inventory but its history is kept.'**
  String get inventoryDeactivateConfirmMessage;

  /// No description provided for @inventoryOffline.
  ///
  /// In en, this message translates to:
  /// **'Inventory changes need a connection. Showing saved data.'**
  String get inventoryOffline;

  /// No description provided for @inventoryMsgItemCreated.
  ///
  /// In en, this message translates to:
  /// **'Item added to the inventory.'**
  String get inventoryMsgItemCreated;

  /// No description provided for @inventoryMsgItemUpdated.
  ///
  /// In en, this message translates to:
  /// **'Item updated.'**
  String get inventoryMsgItemUpdated;

  /// No description provided for @inventoryMsgStockRecorded.
  ///
  /// In en, this message translates to:
  /// **'Stock movement recorded.'**
  String get inventoryMsgStockRecorded;

  /// No description provided for @inventoryErrGeneric.
  ///
  /// In en, this message translates to:
  /// **'The inventory action could not be saved.'**
  String get inventoryErrGeneric;

  /// No description provided for @inventoryLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'The inventory could not be loaded.'**
  String get inventoryLoadFailed;

  /// No description provided for @unitGram.
  ///
  /// In en, this message translates to:
  /// **'Grams'**
  String get unitGram;

  /// No description provided for @unitKilogram.
  ///
  /// In en, this message translates to:
  /// **'Kilograms'**
  String get unitKilogram;

  /// No description provided for @unitLiter.
  ///
  /// In en, this message translates to:
  /// **'Liters'**
  String get unitLiter;

  /// No description provided for @unitMilliliter.
  ///
  /// In en, this message translates to:
  /// **'Milliliters'**
  String get unitMilliliter;

  /// No description provided for @unitPiece.
  ///
  /// In en, this message translates to:
  /// **'Pieces'**
  String get unitPiece;

  /// No description provided for @unitMeter.
  ///
  /// In en, this message translates to:
  /// **'Meters'**
  String get unitMeter;

  /// No description provided for @txnAddition.
  ///
  /// In en, this message translates to:
  /// **'Stock added'**
  String get txnAddition;

  /// No description provided for @txnConsumption.
  ///
  /// In en, this message translates to:
  /// **'Consumed by task'**
  String get txnConsumption;

  /// No description provided for @txnAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Adjustment'**
  String get txnAdjustment;

  /// No description provided for @txnReversal.
  ///
  /// In en, this message translates to:
  /// **'Consumption reversed'**
  String get txnReversal;

  /// No description provided for @categoryPipe.
  ///
  /// In en, this message translates to:
  /// **'Pipes'**
  String get categoryPipe;

  /// No description provided for @categoryPipeJoint.
  ///
  /// In en, this message translates to:
  /// **'Pipe joints'**
  String get categoryPipeJoint;

  /// No description provided for @categoryFertilizer.
  ///
  /// In en, this message translates to:
  /// **'Fertilizers'**
  String get categoryFertilizer;

  /// No description provided for @categoryDripper.
  ///
  /// In en, this message translates to:
  /// **'Drippers'**
  String get categoryDripper;

  /// No description provided for @categoryInsecticide.
  ///
  /// In en, this message translates to:
  /// **'Insecticides'**
  String get categoryInsecticide;

  /// No description provided for @categoryHerbicide.
  ///
  /// In en, this message translates to:
  /// **'Herbicides'**
  String get categoryHerbicide;

  /// No description provided for @categoryFungicide.
  ///
  /// In en, this message translates to:
  /// **'Fungicides'**
  String get categoryFungicide;

  /// No description provided for @categoryTool.
  ///
  /// In en, this message translates to:
  /// **'Farm tools'**
  String get categoryTool;

  /// No description provided for @categoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryOther;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
