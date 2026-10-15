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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
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

  /// No description provided for @commonAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get commonAll;

  /// No description provided for @commonClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get commonClear;

  /// No description provided for @commonApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get commonApply;

  /// No description provided for @routeUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Route unavailable: {path}'**
  String routeUnavailable(String path);

  /// No description provided for @routeUnavailableHome.
  ///
  /// In en, this message translates to:
  /// **'Go to Home'**
  String get routeUnavailableHome;

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

  /// Today's date above the home title, for example Sunday · 12 July.
  ///
  /// In en, this message translates to:
  /// **'{weekday} · {date}'**
  String homeDateEyebrow(String weekday, String date);

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

  /// No description provided for @homePlantingPits.
  ///
  /// In en, this message translates to:
  /// **'Planting pits'**
  String get homePlantingPits;

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
  /// **'Online · farm data is kept up to date'**
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
  /// **'Farm data refreshes whenever you are online'**
  String get syncDefaultSubtitle;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @logoutUnsentTitle.
  ///
  /// In en, this message translates to:
  /// **'Changes not uploaded yet'**
  String get logoutUnsentTitle;

  /// No description provided for @logoutUnsentBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 change on this device has not been uploaded.} other{{count} changes on this device have not been uploaded.}} Logging out deletes them. Connect to the internet and wait for them to sync first.'**
  String logoutUnsentBody(int count);

  /// No description provided for @logoutAnyway.
  ///
  /// In en, this message translates to:
  /// **'Log out anyway'**
  String get logoutAnyway;

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

  /// No description provided for @issueTypeExcessIrrigation.
  ///
  /// In en, this message translates to:
  /// **'Too much water'**
  String get issueTypeExcessIrrigation;

  /// No description provided for @issueTypeDripperProblem.
  ///
  /// In en, this message translates to:
  /// **'Dripper problem'**
  String get issueTypeDripperProblem;

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

  /// No description provided for @tasksViewList.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get tasksViewList;

  /// No description provided for @tasksViewCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get tasksViewCalendar;

  /// No description provided for @tasksCalendarPreviousMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get tasksCalendarPreviousMonth;

  /// No description provided for @tasksCalendarNextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get tasksCalendarNextMonth;

  /// No description provided for @tasksCalendarToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get tasksCalendarToday;

  /// Heading above tasks for the selected calendar date.
  ///
  /// In en, this message translates to:
  /// **'Tasks for {date}'**
  String tasksCalendarTasksForDate(String date);

  /// Accessible task count announced for a calendar date.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 task} other{{count} tasks}}'**
  String tasksCalendarTaskCount(int count);

  /// No description provided for @tasksCalendarNoTasksTitle.
  ///
  /// In en, this message translates to:
  /// **'No tasks on this date'**
  String get tasksCalendarNoTasksTitle;

  /// No description provided for @tasksCalendarNoTasksManager.
  ///
  /// In en, this message translates to:
  /// **'Choose another date or create a new task.'**
  String get tasksCalendarNoTasksManager;

  /// No description provided for @tasksCalendarNoTasksWorker.
  ///
  /// In en, this message translates to:
  /// **'Choose another date to view tasks assigned to you.'**
  String get tasksCalendarNoTasksWorker;

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
  /// **'Create a task, or choose another day or filter.'**
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

  /// No description provided for @addAnotherTarget.
  ///
  /// In en, this message translates to:
  /// **'Add another target'**
  String get addAnotherTarget;

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

  /// No description provided for @issueMsgConfirmedExisting.
  ///
  /// In en, this message translates to:
  /// **'The existing active issue was confirmed. Its severity was not changed.'**
  String get issueMsgConfirmedExisting;

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

  /// No description provided for @issueMsgConfirmedExistingWithPhoto.
  ///
  /// In en, this message translates to:
  /// **'The existing active issue was confirmed with photo evidence. Its severity was not changed.'**
  String get issueMsgConfirmedExistingWithPhoto;

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

  /// No description provided for @scheduleEndsOnRequired.
  ///
  /// In en, this message translates to:
  /// **'Ends on (required)'**
  String get scheduleEndsOnRequired;

  /// No description provided for @scheduleEndRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Choose an end date — schedules need one'**
  String get scheduleEndRequiredMessage;

  /// No description provided for @scheduleRepetitions.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No runs in the selected dates} =1{Runs once} other{Runs {count} times}}'**
  String scheduleRepetitions(int count);

  /// No description provided for @scheduleTotalRequired.
  ///
  /// In en, this message translates to:
  /// **'Total for the whole schedule: {quantity} {unit}'**
  String scheduleTotalRequired(String quantity, String unit);

  /// No description provided for @scheduleAvailableStock.
  ///
  /// In en, this message translates to:
  /// **'Available now: {quantity} {unit}'**
  String scheduleAvailableStock(String quantity, String unit);

  /// No description provided for @scheduleRemainingAfter.
  ///
  /// In en, this message translates to:
  /// **'Left after the schedule: {quantity} {unit}'**
  String scheduleRemainingAfter(String quantity, String unit);

  /// No description provided for @scheduleShortage.
  ///
  /// In en, this message translates to:
  /// **'Shortage: {quantity} {unit}'**
  String scheduleShortage(String quantity, String unit);

  /// No description provided for @scheduleGroupingTitle.
  ///
  /// In en, this message translates to:
  /// **'Task creation'**
  String get scheduleGroupingTitle;

  /// No description provided for @scheduleGroupingSeparate.
  ///
  /// In en, this message translates to:
  /// **'Separate tasks'**
  String get scheduleGroupingSeparate;

  /// No description provided for @scheduleGroupingSeparateHint.
  ///
  /// In en, this message translates to:
  /// **'One task per target on every run date.'**
  String get scheduleGroupingSeparateHint;

  /// No description provided for @scheduleGroupingCombined.
  ///
  /// In en, this message translates to:
  /// **'One combined task'**
  String get scheduleGroupingCombined;

  /// No description provided for @scheduleGroupingCombinedHint.
  ///
  /// In en, this message translates to:
  /// **'A single task carrying all selected targets on every run date.'**
  String get scheduleGroupingCombinedHint;

  /// No description provided for @scheduleReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review before creating'**
  String get scheduleReviewTitle;

  /// No description provided for @scheduleReviewTargets.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 target} other{{count} targets}}: {labels}'**
  String scheduleReviewTargets(int count, String labels);

  /// No description provided for @scheduleTasksTotal.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 task will be created in total} other{{count} tasks will be created in total}}'**
  String scheduleTasksTotal(int count);

  /// No description provided for @scheduleExecutionDates.
  ///
  /// In en, this message translates to:
  /// **'Run dates'**
  String get scheduleExecutionDates;

  /// No description provided for @scheduleMoreDates.
  ///
  /// In en, this message translates to:
  /// **'+{count} more'**
  String scheduleMoreDates(int count);

  /// No description provided for @scheduleReviewNoProduct.
  ///
  /// In en, this message translates to:
  /// **'No product'**
  String get scheduleReviewNoProduct;

  /// No description provided for @commonNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get commonNotSet;

  /// No description provided for @photoLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'This photo could not be loaded. Check your connection and try again.'**
  String get photoLoadFailed;

  /// No description provided for @mapFullScreen.
  ///
  /// In en, this message translates to:
  /// **'Full screen'**
  String get mapFullScreen;

  /// No description provided for @mapExitFullScreen.
  ///
  /// In en, this message translates to:
  /// **'Exit full screen'**
  String get mapExitFullScreen;

  /// No description provided for @mapCreateTaskForSection.
  ///
  /// In en, this message translates to:
  /// **'Create task for Section {code}'**
  String mapCreateTaskForSection(String code);

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

  /// No description provided for @mapLayerPlantingPits.
  ///
  /// In en, this message translates to:
  /// **'Planting pits'**
  String get mapLayerPlantingPits;

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

  /// No description provided for @mapSectionPitCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 pit} other{{count} pits}}'**
  String mapSectionPitCount(int count);

  /// No description provided for @plantingPitEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Planting pit'**
  String get plantingPitEyebrow;

  /// No description provided for @plantingPitSection.
  ///
  /// In en, this message translates to:
  /// **'Section {section}'**
  String plantingPitSection(String section);

  /// No description provided for @plantingPitPosition.
  ///
  /// In en, this message translates to:
  /// **'Row {row} · Pit {pit}'**
  String plantingPitPosition(String row, String pit);

  /// No description provided for @plantingPitCoordinates.
  ///
  /// In en, this message translates to:
  /// **'{latitude}, {longitude}'**
  String plantingPitCoordinates(String latitude, String longitude);

  /// No description provided for @plantingPitPlannedFor.
  ///
  /// In en, this message translates to:
  /// **'Planned for {date}'**
  String plantingPitPlannedFor(String date);

  /// No description provided for @plantingPitStatusPlanned.
  ///
  /// In en, this message translates to:
  /// **'Planned'**
  String get plantingPitStatusPlanned;

  /// No description provided for @plantingPitStatusMarked.
  ///
  /// In en, this message translates to:
  /// **'Marked'**
  String get plantingPitStatusMarked;

  /// No description provided for @plantingPitStatusDug.
  ///
  /// In en, this message translates to:
  /// **'Dug'**
  String get plantingPitStatusDug;

  /// No description provided for @plantingPitStatusPrepared.
  ///
  /// In en, this message translates to:
  /// **'Prepared'**
  String get plantingPitStatusPrepared;

  /// No description provided for @plantingPitStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get plantingPitStatusCompleted;

  /// No description provided for @plantingPitStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get plantingPitStatusCancelled;

  /// No description provided for @plantingPitAdvanceTo.
  ///
  /// In en, this message translates to:
  /// **'Move to {status}'**
  String plantingPitAdvanceTo(String status);

  /// No description provided for @plantingPitCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel pit'**
  String get plantingPitCancel;

  /// No description provided for @plantingPitUpdating.
  ///
  /// In en, this message translates to:
  /// **'Updating…'**
  String get plantingPitUpdating;

  /// No description provided for @plantingPitUpdated.
  ///
  /// In en, this message translates to:
  /// **'Planting pit updated.'**
  String get plantingPitUpdated;

  /// No description provided for @plantingPitUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'The planting pit could not be updated.'**
  String get plantingPitUpdateFailed;

  /// No description provided for @plantingPitAddForSection.
  ///
  /// In en, this message translates to:
  /// **'Add pit to Section {section}'**
  String plantingPitAddForSection(String section);

  /// No description provided for @plantingPitCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Add planting pit'**
  String get plantingPitCreateTitle;

  /// No description provided for @plantingPitCodeField.
  ///
  /// In en, this message translates to:
  /// **'Pit code'**
  String get plantingPitCodeField;

  /// No description provided for @plantingPitRowField.
  ///
  /// In en, this message translates to:
  /// **'Row number'**
  String get plantingPitRowField;

  /// No description provided for @plantingPitNumberField.
  ///
  /// In en, this message translates to:
  /// **'Pit number'**
  String get plantingPitNumberField;

  /// No description provided for @plantingPitLatitudeField.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get plantingPitLatitudeField;

  /// No description provided for @plantingPitLongitudeField.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get plantingPitLongitudeField;

  /// No description provided for @plantingPitPlannedDateField.
  ///
  /// In en, this message translates to:
  /// **'Planned date (optional)'**
  String get plantingPitPlannedDateField;

  /// No description provided for @plantingPitNotesField.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get plantingPitNotesField;

  /// No description provided for @plantingPitSave.
  ///
  /// In en, this message translates to:
  /// **'Add pit'**
  String get plantingPitSave;

  /// No description provided for @plantingPitSaving.
  ///
  /// In en, this message translates to:
  /// **'Adding…'**
  String get plantingPitSaving;

  /// No description provided for @plantingPitCreated.
  ///
  /// In en, this message translates to:
  /// **'Planting pit added.'**
  String get plantingPitCreated;

  /// No description provided for @plantingPitCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'The planting pit could not be added.'**
  String get plantingPitCreateFailed;

  /// No description provided for @plantingPitRequiredField.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get plantingPitRequiredField;

  /// No description provided for @plantingPitInvalidCoordinate.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid coordinate'**
  String get plantingPitInvalidCoordinate;

  /// No description provided for @plantingPitGridPairRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter both row and pit numbers, or leave both empty'**
  String get plantingPitGridPairRequired;

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

  /// No description provided for @schedulesTitle.
  ///
  /// In en, this message translates to:
  /// **'Schedules'**
  String get schedulesTitle;

  /// No description provided for @schedulesEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Recurring operations'**
  String get schedulesEyebrow;

  /// No description provided for @scheduleNew.
  ///
  /// In en, this message translates to:
  /// **'New schedule'**
  String get scheduleNew;

  /// No description provided for @schedulesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No schedules yet'**
  String get schedulesEmptyTitle;

  /// No description provided for @schedulesEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Create a recurring irrigation, fertilization, or spraying plan.'**
  String get schedulesEmptyMessage;

  /// No description provided for @schedulesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Schedules could not be loaded.'**
  String get schedulesLoadFailed;

  /// No description provided for @planStatusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get planStatusDraft;

  /// No description provided for @planStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get planStatusActive;

  /// No description provided for @planStatusPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get planStatusPaused;

  /// No description provided for @planStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get planStatusCompleted;

  /// No description provided for @planStatusArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get planStatusArchived;

  /// No description provided for @scheduleOnce.
  ///
  /// In en, this message translates to:
  /// **'Once'**
  String get scheduleOnce;

  /// No description provided for @scheduleDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get scheduleDaily;

  /// No description provided for @scheduleWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get scheduleWeekly;

  /// No description provided for @basisPerFeddan.
  ///
  /// In en, this message translates to:
  /// **'Per feddan'**
  String get basisPerFeddan;

  /// No description provided for @basisPerTree.
  ///
  /// In en, this message translates to:
  /// **'Per tree'**
  String get basisPerTree;

  /// No description provided for @basisAbsolute.
  ///
  /// In en, this message translates to:
  /// **'Fixed amount'**
  String get basisAbsolute;

  /// No description provided for @methodFertigation.
  ///
  /// In en, this message translates to:
  /// **'Fertigation'**
  String get methodFertigation;

  /// No description provided for @methodSoilApplication.
  ///
  /// In en, this message translates to:
  /// **'Soil application'**
  String get methodSoilApplication;

  /// No description provided for @methodFoliarSpray.
  ///
  /// In en, this message translates to:
  /// **'Foliar spray'**
  String get methodFoliarSpray;

  /// No description provided for @methodManualApplication.
  ///
  /// In en, this message translates to:
  /// **'Manual application'**
  String get methodManualApplication;

  /// No description provided for @scheduleTypeField.
  ///
  /// In en, this message translates to:
  /// **'Operation'**
  String get scheduleTypeField;

  /// No description provided for @scheduleTitleField.
  ///
  /// In en, this message translates to:
  /// **'Schedule title'**
  String get scheduleTitleField;

  /// No description provided for @scheduleTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a schedule title'**
  String get scheduleTitleRequired;

  /// No description provided for @scheduleRecurrenceField.
  ///
  /// In en, this message translates to:
  /// **'Repeats'**
  String get scheduleRecurrenceField;

  /// No description provided for @scheduleWeekdaysField.
  ///
  /// In en, this message translates to:
  /// **'On days'**
  String get scheduleWeekdaysField;

  /// No description provided for @scheduleWeekdaysRequired.
  ///
  /// In en, this message translates to:
  /// **'Pick at least one weekday'**
  String get scheduleWeekdaysRequired;

  /// No description provided for @scheduleStartsOn.
  ///
  /// In en, this message translates to:
  /// **'Starts on'**
  String get scheduleStartsOn;

  /// No description provided for @scheduleEndsOn.
  ///
  /// In en, this message translates to:
  /// **'Ends on'**
  String get scheduleEndsOn;

  /// No description provided for @scheduleTimeField.
  ///
  /// In en, this message translates to:
  /// **'Execution time'**
  String get scheduleTimeField;

  /// No description provided for @scheduleDurationField.
  ///
  /// In en, this message translates to:
  /// **'Duration (minutes)'**
  String get scheduleDurationField;

  /// No description provided for @scheduleTargetsTitle.
  ///
  /// In en, this message translates to:
  /// **'Targets'**
  String get scheduleTargetsTitle;

  /// No description provided for @scheduleTargetFarm.
  ///
  /// In en, this message translates to:
  /// **'Whole farm'**
  String get scheduleTargetFarm;

  /// No description provided for @scheduleTargetSections.
  ///
  /// In en, this message translates to:
  /// **'Sections'**
  String get scheduleTargetSections;

  /// No description provided for @scheduleTargetZones.
  ///
  /// In en, this message translates to:
  /// **'Irrigation zones'**
  String get scheduleTargetZones;

  /// No description provided for @scheduleProductTitle.
  ///
  /// In en, this message translates to:
  /// **'Product & dose'**
  String get scheduleProductTitle;

  /// No description provided for @scheduleProductField.
  ///
  /// In en, this message translates to:
  /// **'Product from inventory'**
  String get scheduleProductField;

  /// No description provided for @scheduleRateField.
  ///
  /// In en, this message translates to:
  /// **'Application rate'**
  String get scheduleRateField;

  /// No description provided for @scheduleBasisField.
  ///
  /// In en, this message translates to:
  /// **'Rate basis'**
  String get scheduleBasisField;

  /// No description provided for @scheduleMethodField.
  ///
  /// In en, this message translates to:
  /// **'Application method'**
  String get scheduleMethodField;

  /// No description provided for @schedulePerOccurrence.
  ///
  /// In en, this message translates to:
  /// **'Needed per run: {quantity} {unit}'**
  String schedulePerOccurrence(String quantity, String unit);

  /// No description provided for @scheduleCoverage.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Current stock covers no applications} =1{Current stock covers 1 application} other{Current stock covers {count} applications}}'**
  String scheduleCoverage(int count);

  /// No description provided for @scheduleInsufficient.
  ///
  /// In en, this message translates to:
  /// **'Not enough stock — tasks will not be generated until you restock.'**
  String get scheduleInsufficient;

  /// No description provided for @scheduleAssigneesTitle.
  ///
  /// In en, this message translates to:
  /// **'Assigned workers'**
  String get scheduleAssigneesTitle;

  /// No description provided for @scheduleCreate.
  ///
  /// In en, this message translates to:
  /// **'Create schedule'**
  String get scheduleCreate;

  /// No description provided for @scheduleSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get scheduleSaving;

  /// No description provided for @scheduleMsgCreated.
  ///
  /// In en, this message translates to:
  /// **'Schedule created.'**
  String get scheduleMsgCreated;

  /// No description provided for @scheduleMsgUpdated.
  ///
  /// In en, this message translates to:
  /// **'Schedule updated.'**
  String get scheduleMsgUpdated;

  /// No description provided for @scheduleErrGeneric.
  ///
  /// In en, this message translates to:
  /// **'The schedule could not be saved.'**
  String get scheduleErrGeneric;

  /// No description provided for @scheduleNextOccurrences.
  ///
  /// In en, this message translates to:
  /// **'Next dates'**
  String get scheduleNextOccurrences;

  /// No description provided for @scheduleGenerateNow.
  ///
  /// In en, this message translates to:
  /// **'Create today\'s tasks for all schedules'**
  String get scheduleGenerateNow;

  /// No description provided for @scheduleGenerated.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No new tasks to generate} =1{1 task generated} other{{count} tasks generated}}'**
  String scheduleGenerated(int count);

  /// No description provided for @schedulePause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get schedulePause;

  /// No description provided for @scheduleActivate.
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get scheduleActivate;

  /// No description provided for @scheduleArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get scheduleArchive;

  /// No description provided for @scheduleTargetCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 target} other{{count} targets}}'**
  String scheduleTargetCount(int count);

  /// No description provided for @taskProductTitle.
  ///
  /// In en, this message translates to:
  /// **'Product to apply'**
  String get taskProductTitle;

  /// No description provided for @taskProductQuantity.
  ///
  /// In en, this message translates to:
  /// **'{quantity} {unit}'**
  String taskProductQuantity(String quantity, String unit);

  /// No description provided for @issuesEyebrow.
  ///
  /// In en, this message translates to:
  /// **'FIELD HEALTH'**
  String get issuesEyebrow;

  /// No description provided for @issuesTitle.
  ///
  /// In en, this message translates to:
  /// **'Active tree issues'**
  String get issuesTitle;

  /// No description provided for @issuesUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The issue workspace is unavailable.'**
  String get issuesUnavailable;

  /// No description provided for @issuesFilters.
  ///
  /// In en, this message translates to:
  /// **'Filter issues'**
  String get issuesFilters;

  /// No description provided for @issuesAllTypes.
  ///
  /// In en, this message translates to:
  /// **'All issue types'**
  String get issuesAllTypes;

  /// No description provided for @issuesAllSeverities.
  ///
  /// In en, this message translates to:
  /// **'All severities'**
  String get issuesAllSeverities;

  /// No description provided for @issuesOnlyUnclaimed.
  ///
  /// In en, this message translates to:
  /// **'Only issues available to claim'**
  String get issuesOnlyUnclaimed;

  /// No description provided for @issuesTreeLocation.
  ///
  /// In en, this message translates to:
  /// **'Section {section} · {tree}'**
  String issuesTreeLocation(String section, String tree);

  /// No description provided for @issuesOpenTree.
  ///
  /// In en, this message translates to:
  /// **'Open tree'**
  String get issuesOpenTree;

  /// No description provided for @issuesClaim.
  ///
  /// In en, this message translates to:
  /// **'Claim issue'**
  String get issuesClaim;

  /// No description provided for @issuesClaimOnlineOnly.
  ///
  /// In en, this message translates to:
  /// **'Connect to the internet to claim this issue'**
  String get issuesClaimOnlineOnly;

  /// No description provided for @issuesClaimed.
  ///
  /// In en, this message translates to:
  /// **'Claimed'**
  String get issuesClaimed;

  /// No description provided for @issuesClaimedByYou.
  ///
  /// In en, this message translates to:
  /// **'Assigned to you'**
  String get issuesClaimedByYou;

  /// No description provided for @issuesDetailsAvailable.
  ///
  /// In en, this message translates to:
  /// **'Full details available'**
  String get issuesDetailsAvailable;

  /// No description provided for @issuesSummaryOnly.
  ///
  /// In en, this message translates to:
  /// **'Safe summary'**
  String get issuesSummaryOnly;

  /// No description provided for @issuesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'The active issues could not be loaded.'**
  String get issuesLoadFailed;

  /// No description provided for @issuesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No active issues match these filters.'**
  String get issuesEmpty;

  /// No description provided for @issueDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Issue details'**
  String get issueDetailTitle;

  /// No description provided for @issueDetailHistory.
  ///
  /// In en, this message translates to:
  /// **'Issue history'**
  String get issueDetailHistory;

  /// No description provided for @issueDetailDescription.
  ///
  /// In en, this message translates to:
  /// **'Field observation'**
  String get issueDetailDescription;

  /// No description provided for @issueDetailNoDescription.
  ///
  /// In en, this message translates to:
  /// **'No observation notes were recorded.'**
  String get issueDetailNoDescription;

  /// No description provided for @issueDetailViewHistory.
  ///
  /// In en, this message translates to:
  /// **'View details and history'**
  String get issueDetailViewHistory;

  /// No description provided for @issueDetailChangeSeverity.
  ///
  /// In en, this message translates to:
  /// **'Change severity'**
  String get issueDetailChangeSeverity;

  /// No description provided for @issueDetailDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss issue'**
  String get issueDetailDismiss;

  /// No description provided for @issueDetailDismissPrompt.
  ///
  /// In en, this message translates to:
  /// **'Why should this issue be dismissed?'**
  String get issueDetailDismissPrompt;

  /// No description provided for @issueDetailDismissRequired.
  ///
  /// In en, this message translates to:
  /// **'A dismissal reason is required.'**
  String get issueDetailDismissRequired;

  /// No description provided for @issueDetailActionSaved.
  ///
  /// In en, this message translates to:
  /// **'The issue action was saved or queued for sync.'**
  String get issueDetailActionSaved;

  /// No description provided for @issueDetailOpenTask.
  ///
  /// In en, this message translates to:
  /// **'Open related task'**
  String get issueDetailOpenTask;

  /// No description provided for @issueDetailNoHistory.
  ///
  /// In en, this message translates to:
  /// **'No issue events are available.'**
  String get issueDetailNoHistory;

  /// No description provided for @issueDetailLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'The authorized issue details could not be loaded.'**
  String get issueDetailLoadFailed;

  /// No description provided for @issueDetailObservations.
  ///
  /// In en, this message translates to:
  /// **'Inspection observations'**
  String get issueDetailObservations;

  /// No description provided for @issueDetailNoObservations.
  ///
  /// In en, this message translates to:
  /// **'No inspection observations are linked to this issue.'**
  String get issueDetailNoObservations;

  /// No description provided for @issueDetailLinkedTasks.
  ///
  /// In en, this message translates to:
  /// **'Linked tasks'**
  String get issueDetailLinkedTasks;

  /// No description provided for @issueDetailNoLinkedTasks.
  ///
  /// In en, this message translates to:
  /// **'No tasks are linked to this issue.'**
  String get issueDetailNoLinkedTasks;

  /// No description provided for @issueDetailTaskRestricted.
  ///
  /// In en, this message translates to:
  /// **'Task details are restricted to its assignees and farm managers.'**
  String get issueDetailTaskRestricted;

  /// No description provided for @issueDetailEvidence.
  ///
  /// In en, this message translates to:
  /// **'Issue evidence ({count})'**
  String issueDetailEvidence(int count);

  /// No description provided for @issueObservationDetected.
  ///
  /// In en, this message translates to:
  /// **'Detected during inspection'**
  String get issueObservationDetected;

  /// No description provided for @issueObservationConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed during inspection'**
  String get issueObservationConfirmed;

  /// No description provided for @issueObservationNotObserved.
  ///
  /// In en, this message translates to:
  /// **'Not observed during inspection'**
  String get issueObservationNotObserved;

  /// No description provided for @issueObservationSeverityChanged.
  ///
  /// In en, this message translates to:
  /// **'Severity explicitly changed'**
  String get issueObservationSeverityChanged;

  /// No description provided for @issueStatusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get issueStatusOpen;

  /// No description provided for @issueStatusInReview.
  ///
  /// In en, this message translates to:
  /// **'In review'**
  String get issueStatusInReview;

  /// No description provided for @issueStatusResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get issueStatusResolved;

  /// No description provided for @issueStatusDismissed.
  ///
  /// In en, this message translates to:
  /// **'Dismissed'**
  String get issueStatusDismissed;

  /// No description provided for @issueEventDetected.
  ///
  /// In en, this message translates to:
  /// **'Issue detected'**
  String get issueEventDetected;

  /// No description provided for @issueEventConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Issue confirmed'**
  String get issueEventConfirmed;

  /// No description provided for @issueEventNotObserved.
  ///
  /// In en, this message translates to:
  /// **'Not observed during inspection'**
  String get issueEventNotObserved;

  /// No description provided for @issueEventSeverityChanged.
  ///
  /// In en, this message translates to:
  /// **'Severity changed'**
  String get issueEventSeverityChanged;

  /// No description provided for @issueEventResolutionSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Resolution submitted for review'**
  String get issueEventResolutionSubmitted;

  /// No description provided for @issueEventResolved.
  ///
  /// In en, this message translates to:
  /// **'Issue resolved'**
  String get issueEventResolved;

  /// No description provided for @issueEventUnableToFix.
  ///
  /// In en, this message translates to:
  /// **'Unable to fix recorded'**
  String get issueEventUnableToFix;

  /// No description provided for @issueEventDismissed.
  ///
  /// In en, this message translates to:
  /// **'Issue dismissed'**
  String get issueEventDismissed;

  /// No description provided for @issueEventReviewReturned.
  ///
  /// In en, this message translates to:
  /// **'Review returned'**
  String get issueEventReviewReturned;

  /// No description provided for @homeActiveIssues.
  ///
  /// In en, this message translates to:
  /// **'Active issues ({count})'**
  String homeActiveIssues(int count);

  /// No description provided for @failedOpsKindIssueWorkflow.
  ///
  /// In en, this message translates to:
  /// **'Tree issue action'**
  String get failedOpsKindIssueWorkflow;

  /// No description provided for @failedOpsKindInspection.
  ///
  /// In en, this message translates to:
  /// **'Tree inspection action'**
  String get failedOpsKindInspection;

  /// No description provided for @inspectionCreateUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Only farm managers can create inspections.'**
  String get inspectionCreateUnavailable;

  /// No description provided for @inspectionCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create tree inspection'**
  String get inspectionCreateTitle;

  /// No description provided for @inspectionCreateForSection.
  ///
  /// In en, this message translates to:
  /// **'Inspect section {section}'**
  String inspectionCreateForSection(String section);

  /// No description provided for @inspectionStandardTaskHint.
  ///
  /// In en, this message translates to:
  /// **'This creates a standard task. For a guided tree-by-tree route, use guided inspection setup.'**
  String get inspectionStandardTaskHint;

  /// No description provided for @inspectionGuidedCreateAction.
  ///
  /// In en, this message translates to:
  /// **'Create guided inspection'**
  String get inspectionGuidedCreateAction;

  /// No description provided for @inspectionGuidedSessionMissing.
  ///
  /// In en, this message translates to:
  /// **'This is a standard task and has no guided inspection route.'**
  String get inspectionGuidedSessionMissing;

  /// No description provided for @inspectionBackToTask.
  ///
  /// In en, this message translates to:
  /// **'Back to task'**
  String get inspectionBackToTask;

  /// No description provided for @inspectionTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Inspection title'**
  String get inspectionTitleLabel;

  /// No description provided for @inspectionSectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Section'**
  String get inspectionSectionLabel;

  /// No description provided for @inspectionInspectorLabel.
  ///
  /// In en, this message translates to:
  /// **'Assigned inspector'**
  String get inspectionInspectorLabel;

  /// No description provided for @inspectionChooseSchedule.
  ///
  /// In en, this message translates to:
  /// **'Choose scheduled date'**
  String get inspectionChooseSchedule;

  /// No description provided for @inspectionScheduleRequired.
  ///
  /// In en, this message translates to:
  /// **'A scheduled date is required.'**
  String get inspectionScheduleRequired;

  /// No description provided for @inspectionDefaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Tree inspection · {section}'**
  String inspectionDefaultTitle(String section);

  /// No description provided for @inspectionRequiresReview.
  ///
  /// In en, this message translates to:
  /// **'Require engineer review'**
  String get inspectionRequiresReview;

  /// No description provided for @inspectionRequiresPhoto.
  ///
  /// In en, this message translates to:
  /// **'Require a photo for every selected issue'**
  String get inspectionRequiresPhoto;

  /// No description provided for @inspectionPhotoRequirementHint.
  ///
  /// In en, this message translates to:
  /// **'Photos stay optional when this is off.'**
  String get inspectionPhotoRequirementHint;

  /// No description provided for @inspectionBuildRoute.
  ///
  /// In en, this message translates to:
  /// **'Build and preview walking route'**
  String get inspectionBuildRoute;

  /// No description provided for @inspectionSectionHasNoTrees.
  ///
  /// In en, this message translates to:
  /// **'This section has no active trees to inspect.'**
  String get inspectionSectionHasNoTrees;

  /// No description provided for @inspectionCreateAction.
  ///
  /// In en, this message translates to:
  /// **'Create inspection'**
  String get inspectionCreateAction;

  /// No description provided for @inspectionTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter an inspection title.'**
  String get inspectionTitleRequired;

  /// No description provided for @inspectionQueuedOffline.
  ///
  /// In en, this message translates to:
  /// **'Inspection saved offline and queued for sync.'**
  String get inspectionQueuedOffline;

  /// No description provided for @inspectionRoutePreview.
  ///
  /// In en, this message translates to:
  /// **'Walking route preview'**
  String get inspectionRoutePreview;

  /// No description provided for @inspectionRouteCounts.
  ///
  /// In en, this message translates to:
  /// **'{trees} trees · {stations} stations'**
  String inspectionRouteCounts(int trees, int stations);

  /// No description provided for @inspectionStartsAt.
  ///
  /// In en, this message translates to:
  /// **'Starts at {tree}'**
  String inspectionStartsAt(String tree);

  /// No description provided for @inspectionRoutePreviewSemantics.
  ///
  /// In en, this message translates to:
  /// **'Walking route starts at {tree} and covers {trees} trees across {stations} stations. Green lines are tree rows and orange arrows are walking corridors.'**
  String inspectionRoutePreviewSemantics(String tree, int trees, int stations);

  /// No description provided for @inspectionRouteRowsLegend.
  ///
  /// In en, this message translates to:
  /// **'Tree rows'**
  String get inspectionRouteRowsLegend;

  /// No description provided for @inspectionRoutePathLegend.
  ///
  /// In en, this message translates to:
  /// **'Walking direction'**
  String get inspectionRoutePathLegend;

  /// No description provided for @inspectionPhysicalSidesHint.
  ///
  /// In en, this message translates to:
  /// **'Left and right are physical sides while walking and do not change in Arabic.'**
  String get inspectionPhysicalSidesHint;

  /// No description provided for @inspectionOpenRunner.
  ///
  /// In en, this message translates to:
  /// **'Open inspection'**
  String get inspectionOpenRunner;

  /// No description provided for @inspectionRunnerEyebrow.
  ///
  /// In en, this message translates to:
  /// **'SECTION WALK'**
  String get inspectionRunnerEyebrow;

  /// No description provided for @inspectionRunnerTitle.
  ///
  /// In en, this message translates to:
  /// **'Tree inspection'**
  String get inspectionRunnerTitle;

  /// No description provided for @inspectionProgress.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} trees inspected'**
  String inspectionProgress(int done, int total);

  /// No description provided for @inspectionStart.
  ///
  /// In en, this message translates to:
  /// **'Start inspection'**
  String get inspectionStart;

  /// No description provided for @inspectionResume.
  ///
  /// In en, this message translates to:
  /// **'Resume inspection'**
  String get inspectionResume;

  /// No description provided for @inspectionPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get inspectionPause;

  /// No description provided for @inspectionAssignedToAnotherInspector.
  ///
  /// In en, this message translates to:
  /// **'Assigned to another inspector'**
  String get inspectionAssignedToAnotherInspector;

  /// No description provided for @inspectionTakeoverHint.
  ///
  /// In en, this message translates to:
  /// **'Taking over is online-only, replaces the assigned inspector, and is recorded in task history.'**
  String get inspectionTakeoverHint;

  /// No description provided for @inspectionTakeover.
  ///
  /// In en, this message translates to:
  /// **'Take over inspection'**
  String get inspectionTakeover;

  /// No description provided for @inspectionPreviousStation.
  ///
  /// In en, this message translates to:
  /// **'Previous station'**
  String get inspectionPreviousStation;

  /// No description provided for @inspectionSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit inspection'**
  String get inspectionSubmit;

  /// No description provided for @inspectionSubmitted.
  ///
  /// In en, this message translates to:
  /// **'This inspection was submitted.'**
  String get inspectionSubmitted;

  /// No description provided for @inspectionFinalReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review before submission'**
  String get inspectionFinalReviewTitle;

  /// No description provided for @inspectionFinalReviewMessage.
  ///
  /// In en, this message translates to:
  /// **'All {trees} trees across {stations} stations are saved. Review the previous station or submit the inspection.'**
  String inspectionFinalReviewMessage(int trees, int stations);

  /// No description provided for @inspectionStation.
  ///
  /// In en, this message translates to:
  /// **'Station {current} of {total}'**
  String inspectionStation(int current, int total);

  /// No description provided for @inspectionPhysicalLeft.
  ///
  /// In en, this message translates to:
  /// **'Physical left'**
  String get inspectionPhysicalLeft;

  /// No description provided for @inspectionPhysicalRight.
  ///
  /// In en, this message translates to:
  /// **'Physical right'**
  String get inspectionPhysicalRight;

  /// No description provided for @inspectionSingleSide.
  ///
  /// In en, this message translates to:
  /// **'Single side'**
  String get inspectionSingleSide;

  /// No description provided for @inspectionTreePosition.
  ///
  /// In en, this message translates to:
  /// **'Source row {row} · tree {tree}'**
  String inspectionTreePosition(String row, String tree);

  /// No description provided for @inspectionCoordinates.
  ///
  /// In en, this message translates to:
  /// **'{latitude}, {longitude}'**
  String inspectionCoordinates(String latitude, String longitude);

  /// No description provided for @inspectionExistingIssues.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 existing issue} other{{count} existing issues}}'**
  String inspectionExistingIssues(int count);

  /// No description provided for @inspectionTreeCardSemantics.
  ///
  /// In en, this message translates to:
  /// **'Tree {tree}, {side}, {issues, plural, =0{no existing issues} =1{1 existing issue} other{{issues} existing issues}}'**
  String inspectionTreeCardSemantics(String tree, String side, int issues);

  /// No description provided for @inspectionSelectSeverity.
  ///
  /// In en, this message translates to:
  /// **'Select severity'**
  String get inspectionSelectSeverity;

  /// No description provided for @inspectionNoNewIssue.
  ///
  /// In en, this message translates to:
  /// **'No new issue found. Existing deselected issues remain active.'**
  String get inspectionNoNewIssue;

  /// No description provided for @inspectionSaveNext.
  ///
  /// In en, this message translates to:
  /// **'Save station and continue'**
  String get inspectionSaveNext;

  /// No description provided for @inspectionPhotoRequiredError.
  ///
  /// In en, this message translates to:
  /// **'This inspection requires a photo for every selected issue.'**
  String get inspectionPhotoRequiredError;

  /// No description provided for @inspectionAddIssuePhoto.
  ///
  /// In en, this message translates to:
  /// **'Add issue photo (optional)'**
  String get inspectionAddIssuePhoto;

  /// No description provided for @inspectionAddRequiredIssuePhoto.
  ///
  /// In en, this message translates to:
  /// **'Add required issue photo'**
  String get inspectionAddRequiredIssuePhoto;

  /// No description provided for @inspectionIssuePhotoReady.
  ///
  /// In en, this message translates to:
  /// **'Issue photo prepared'**
  String get inspectionIssuePhotoReady;

  /// No description provided for @inspectionLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'The inspection could not be loaded.'**
  String get inspectionLoadFailed;

  /// No description provided for @issueWorkTitle.
  ///
  /// In en, this message translates to:
  /// **'Issues in this task'**
  String get issueWorkTitle;

  /// No description provided for @issueWorkIndividualHint.
  ///
  /// In en, this message translates to:
  /// **'Review and record an outcome for each issue separately.'**
  String get issueWorkIndividualHint;

  /// No description provided for @issueWorkPhotoRequired.
  ///
  /// In en, this message translates to:
  /// **'A resolution photo is required before Resolve.'**
  String get issueWorkPhotoRequired;

  /// No description provided for @issueWorkAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add outcome photo (optional)'**
  String get issueWorkAddPhoto;

  /// No description provided for @issueWorkPhotoReady.
  ///
  /// In en, this message translates to:
  /// **'Outcome photo prepared'**
  String get issueWorkPhotoReady;

  /// No description provided for @issueWorkResolve.
  ///
  /// In en, this message translates to:
  /// **'Resolve'**
  String get issueWorkResolve;

  /// No description provided for @issueWorkUnable.
  ///
  /// In en, this message translates to:
  /// **'Unable to fix'**
  String get issueWorkUnable;

  /// No description provided for @issueWorkUnableReason.
  ///
  /// In en, this message translates to:
  /// **'Why could this not be fixed?'**
  String get issueWorkUnableReason;

  /// No description provided for @issueWorkNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get issueWorkNotes;

  /// No description provided for @issueWorkPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get issueWorkPending;

  /// No description provided for @issueWorkSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted for review'**
  String get issueWorkSubmitted;

  /// No description provided for @issueWorkResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get issueWorkResolved;

  /// No description provided for @issueWorkUnableState.
  ///
  /// In en, this message translates to:
  /// **'Unable to fix'**
  String get issueWorkUnableState;

  /// No description provided for @issueWorkReturned.
  ///
  /// In en, this message translates to:
  /// **'Returned'**
  String get issueWorkReturned;

  /// No description provided for @reviewIssueScopeHint.
  ///
  /// In en, this message translates to:
  /// **'Approval affects only the issues explicitly listed in this task. Other issues on the same trees remain unchanged.'**
  String get reviewIssueScopeHint;

  /// No description provided for @unableReasonReplacementPart.
  ///
  /// In en, this message translates to:
  /// **'Replacement part required'**
  String get unableReasonReplacementPart;

  /// No description provided for @unableReasonSpecialist.
  ///
  /// In en, this message translates to:
  /// **'Specialist required'**
  String get unableReasonSpecialist;

  /// No description provided for @unableReasonAdditionalWorker.
  ///
  /// In en, this message translates to:
  /// **'Additional worker required'**
  String get unableReasonAdditionalWorker;

  /// No description provided for @unableReasonEquipment.
  ///
  /// In en, this message translates to:
  /// **'Equipment unavailable'**
  String get unableReasonEquipment;

  /// No description provided for @unableReasonInaccessible.
  ///
  /// In en, this message translates to:
  /// **'Tree inaccessible'**
  String get unableReasonInaccessible;

  /// No description provided for @unableReasonIncorrectIssue.
  ///
  /// In en, this message translates to:
  /// **'Suspected incorrect issue'**
  String get unableReasonIncorrectIssue;

  /// No description provided for @mapActiveIssueFilter.
  ///
  /// In en, this message translates to:
  /// **'Active issues ({count})'**
  String mapActiveIssueFilter(int count);

  /// No description provided for @mapShowIssueMatchesOnly.
  ///
  /// In en, this message translates to:
  /// **'Show matching trees only'**
  String get mapShowIssueMatchesOnly;

  /// No description provided for @mapIssueFilters.
  ///
  /// In en, this message translates to:
  /// **'Filters ({count})'**
  String mapIssueFilters(int count);

  /// No description provided for @mapIssueTreeSemantics.
  ///
  /// In en, this message translates to:
  /// **'Tree {tree}, {count, plural, =1{1 active issue} other{{count} active issues}}, highest severity {severity}'**
  String mapIssueTreeSemantics(String tree, int count, String severity);

  /// No description provided for @mapIssueFiltersTitle.
  ///
  /// In en, this message translates to:
  /// **'Map issue filters'**
  String get mapIssueFiltersTitle;

  /// No description provided for @mapIssueStatusFilter.
  ///
  /// In en, this message translates to:
  /// **'Issue status'**
  String get mapIssueStatusFilter;

  /// No description provided for @mapIssueLayerSemantics.
  ///
  /// In en, this message translates to:
  /// **'Issue layer: {trees} matching trees with {issues} active issues'**
  String mapIssueLayerSemantics(int trees, int issues);

  /// No description provided for @treeActiveIssues.
  ///
  /// In en, this message translates to:
  /// **'Active issues ({count})'**
  String treeActiveIssues(int count);

  /// No description provided for @treeActiveIssuesSemantics.
  ///
  /// In en, this message translates to:
  /// **'This tree has {count} active issues'**
  String treeActiveIssuesSemantics(int count);

  /// No description provided for @treeIssueHistory.
  ///
  /// In en, this message translates to:
  /// **'Past issue occurrences'**
  String get treeIssueHistory;

  /// No description provided for @treeIssueHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No past occurrences are available.'**
  String get treeIssueHistoryEmpty;

  /// No description provided for @treeIssueHistoryLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load history. Retry'**
  String get treeIssueHistoryLoadFailed;

  /// No description provided for @treeIssueReportedDate.
  ///
  /// In en, this message translates to:
  /// **'Reported {date}'**
  String treeIssueReportedDate(String date);

  /// No description provided for @treeIssueOccurrenceDates.
  ///
  /// In en, this message translates to:
  /// **'Reported {reported} · Closed {closed}'**
  String treeIssueOccurrenceDates(String reported, String closed);

  /// No description provided for @treeIssueHistorySemantics.
  ///
  /// In en, this message translates to:
  /// **'{count} past issue occurrences'**
  String treeIssueHistorySemantics(int count);

  /// No description provided for @treeIssueOccurrenceSemantics.
  ///
  /// In en, this message translates to:
  /// **'{type}, {severity}, {status}, {dates}'**
  String treeIssueOccurrenceSemantics(String type, String severity, String status, String dates);

  /// No description provided for @issuesActiveTab.
  ///
  /// In en, this message translates to:
  /// **'Active ({count})'**
  String issuesActiveTab(int count);

  /// No description provided for @issuesHistoryTab.
  ///
  /// In en, this message translates to:
  /// **'History ({count})'**
  String issuesHistoryTab(int count);

  /// No description provided for @issuesHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No historical issue occurrences match these filters.'**
  String get issuesHistoryEmpty;

  /// No description provided for @issuesStatusFilter.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get issuesStatusFilter;

  /// No description provided for @issuesAllStatuses.
  ///
  /// In en, this message translates to:
  /// **'All statuses'**
  String get issuesAllStatuses;

  /// No description provided for @issuesSectionFilter.
  ///
  /// In en, this message translates to:
  /// **'Section'**
  String get issuesSectionFilter;

  /// No description provided for @issuesAllSections.
  ///
  /// In en, this message translates to:
  /// **'All sections'**
  String get issuesAllSections;

  /// No description provided for @issuesAgeFilter.
  ///
  /// In en, this message translates to:
  /// **'Issue age'**
  String get issuesAgeFilter;

  /// No description provided for @issuesAnyAge.
  ///
  /// In en, this message translates to:
  /// **'Any age'**
  String get issuesAnyAge;

  /// No description provided for @issuesAgeSevenDays.
  ///
  /// In en, this message translates to:
  /// **'7 days or older'**
  String get issuesAgeSevenDays;

  /// No description provided for @issuesAgeThirtyDays.
  ///
  /// In en, this message translates to:
  /// **'30 days or older'**
  String get issuesAgeThirtyDays;

  /// No description provided for @issuesAgeNinetyDays.
  ///
  /// In en, this message translates to:
  /// **'90 days or older'**
  String get issuesAgeNinetyDays;

  /// No description provided for @issuesAssignmentFilter.
  ///
  /// In en, this message translates to:
  /// **'Assignment'**
  String get issuesAssignmentFilter;

  /// No description provided for @issuesAllAssignments.
  ///
  /// In en, this message translates to:
  /// **'All assignments'**
  String get issuesAllAssignments;

  /// No description provided for @issuesAssigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get issuesAssigned;

  /// No description provided for @issuesUnassigned.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get issuesUnassigned;

  /// No description provided for @issuesSourceFilter.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get issuesSourceFilter;

  /// No description provided for @issuesAllSources.
  ///
  /// In en, this message translates to:
  /// **'All sources'**
  String get issuesAllSources;

  /// No description provided for @issueSourceInspection.
  ///
  /// In en, this message translates to:
  /// **'Inspection'**
  String get issueSourceInspection;

  /// No description provided for @issueSourceQuickReport.
  ///
  /// In en, this message translates to:
  /// **'Quick report'**
  String get issueSourceQuickReport;

  /// No description provided for @issuesResetFilters.
  ///
  /// In en, this message translates to:
  /// **'Reset filters'**
  String get issuesResetFilters;

  /// No description provided for @issuesAssign.
  ///
  /// In en, this message translates to:
  /// **'Assign'**
  String get issuesAssign;

  /// No description provided for @issuesAssignTitle.
  ///
  /// In en, this message translates to:
  /// **'Assign issue work'**
  String get issuesAssignTitle;

  /// No description provided for @issuesAssignTo.
  ///
  /// In en, this message translates to:
  /// **'Assign to'**
  String get issuesAssignTo;

  /// No description provided for @issuesRequireEngineerReview.
  ///
  /// In en, this message translates to:
  /// **'Require engineer review before closing'**
  String get issuesRequireEngineerReview;

  /// No description provided for @issuesAssignmentOnlineOnly.
  ///
  /// In en, this message translates to:
  /// **'Connect to the internet to assign this issue'**
  String get issuesAssignmentOnlineOnly;

  /// No description provided for @issuesNoAssignableMembers.
  ///
  /// In en, this message translates to:
  /// **'No active operational farm members are available.'**
  String get issuesNoAssignableMembers;

  /// No description provided for @issuesAssignedTo.
  ///
  /// In en, this message translates to:
  /// **'Assigned to {name}'**
  String issuesAssignedTo(String name);

  /// No description provided for @issuesReportedOn.
  ///
  /// In en, this message translates to:
  /// **'Reported {date}'**
  String issuesReportedOn(String date);

  /// No description provided for @issuesClosedOn.
  ///
  /// In en, this message translates to:
  /// **'Closed {date}'**
  String issuesClosedOn(String date);

  /// No description provided for @storageUnavailableWarning.
  ///
  /// In en, this message translates to:
  /// **'Offline storage is unavailable on this device. Work you queue offline will be lost if you close the app.'**
  String get storageUnavailableWarning;

  /// No description provided for @storageTitle.
  ///
  /// In en, this message translates to:
  /// **'Offline storage'**
  String get storageTitle;

  /// No description provided for @storagePersistent.
  ///
  /// In en, this message translates to:
  /// **'Kept by the browser'**
  String get storagePersistent;

  /// No description provided for @storageBestEffort.
  ///
  /// In en, this message translates to:
  /// **'The browser may clear it when space is low. Install the app to keep it.'**
  String get storageBestEffort;

  /// No description provided for @storageUsage.
  ///
  /// In en, this message translates to:
  /// **'{used} of {quota} used'**
  String storageUsage(String used, String quota);

  /// No description provided for @secondTabTitle.
  ///
  /// In en, this message translates to:
  /// **'Al Wahat is open in another tab'**
  String get secondTabTitle;

  /// No description provided for @secondTabBody.
  ///
  /// In en, this message translates to:
  /// **'To keep offline work safe, the app runs in one tab or window at a time.'**
  String get secondTabBody;

  /// No description provided for @secondTabUseHere.
  ///
  /// In en, this message translates to:
  /// **'Use here'**
  String get secondTabUseHere;

  /// No description provided for @scanCameraInsecure.
  ///
  /// In en, this message translates to:
  /// **'The camera needs a secure (https) connection. Open the app from its https address.'**
  String get scanCameraInsecure;

  /// No description provided for @appUpdateAvailable.
  ///
  /// In en, this message translates to:
  /// **'A new version of the app is available.'**
  String get appUpdateAvailable;

  /// No description provided for @appUpdateReload.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get appUpdateReload;

  /// No description provided for @installAppTitle.
  ///
  /// In en, this message translates to:
  /// **'Install app'**
  String get installAppTitle;

  /// No description provided for @installAppSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Opens full screen and keeps your offline work safe.'**
  String get installAppSubtitle;

  /// No description provided for @installIosTitle.
  ///
  /// In en, this message translates to:
  /// **'Install on iPhone or iPad'**
  String get installIosTitle;

  /// No description provided for @installIosStep1.
  ///
  /// In en, this message translates to:
  /// **'In Safari, tap the Share button.'**
  String get installIosStep1;

  /// No description provided for @installIosStep2.
  ///
  /// In en, this message translates to:
  /// **'Choose “Add to Home Screen”.'**
  String get installIosStep2;

  /// No description provided for @installIosStep3.
  ///
  /// In en, this message translates to:
  /// **'Tap “Add”, then open Al Wahat from your home screen.'**
  String get installIosStep3;

  /// No description provided for @installIosDone.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get installIosDone;

  /// No description provided for @inspectionAislePosition.
  ///
  /// In en, this message translates to:
  /// **'Aisle {aisle} of {aisles} · station {station} of {stations} in this aisle'**
  String inspectionAislePosition(int aisle, int aisles, int station, int stations);

  /// No description provided for @inspectionRowTree.
  ///
  /// In en, this message translates to:
  /// **'Row {row} · tree {tree}'**
  String inspectionRowTree(String row, String tree);

  /// No description provided for @inspectionHealthy.
  ///
  /// In en, this message translates to:
  /// **'Healthy'**
  String get inspectionHealthy;

  /// No description provided for @inspectionIssueCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 issue} other{{count} issues}}'**
  String inspectionIssueCount(int count);

  /// No description provided for @inspectionReportIssue.
  ///
  /// In en, this message translates to:
  /// **'Report issue'**
  String get inspectionReportIssue;

  /// No description provided for @inspectionEditIssues.
  ///
  /// In en, this message translates to:
  /// **'Edit issues'**
  String get inspectionEditIssues;

  /// No description provided for @inspectionIssuesDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get inspectionIssuesDone;

  /// No description provided for @inspectionAllHealthyNext.
  ///
  /// In en, this message translates to:
  /// **'All healthy · next'**
  String get inspectionAllHealthyNext;

  /// No description provided for @inspectionNextTrees.
  ///
  /// In en, this message translates to:
  /// **'Next: {trees}'**
  String inspectionNextTrees(String trees);

  /// No description provided for @inspectionAisleStart.
  ///
  /// In en, this message translates to:
  /// **'New aisle: turn around and walk the other way, between rows {left} and {right}.'**
  String inspectionAisleStart(int left, int right);

  /// No description provided for @inspectionAisleStartSingle.
  ///
  /// In en, this message translates to:
  /// **'New aisle: turn around and walk the other way, along row {row}.'**
  String inspectionAisleStartSingle(int row);

  /// No description provided for @inspectionAisleEnd.
  ///
  /// In en, this message translates to:
  /// **'Last station in this aisle. Then turn into aisle {aisle}.'**
  String inspectionAisleEnd(int aisle);

  /// No description provided for @inspectionExistingIssueHint.
  ///
  /// In en, this message translates to:
  /// **'Unticking an existing issue does not close it.'**
  String get inspectionExistingIssueHint;

  /// No description provided for @inspectionOpenMap.
  ///
  /// In en, this message translates to:
  /// **'Open full map'**
  String get inspectionOpenMap;

  /// No description provided for @inspectionMapTitle.
  ///
  /// In en, this message translates to:
  /// **'Inspection map'**
  String get inspectionMapTitle;

  /// No description provided for @inspectionMapSemantics.
  ///
  /// In en, this message translates to:
  /// **'Section map. Station {station} of {stations}. Green trees are done, red trees have issues, the orange trees are the current station.'**
  String inspectionMapSemantics(int station, int stations);

  /// No description provided for @inspectionMapLegendDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get inspectionMapLegendDone;

  /// No description provided for @inspectionMapLegendIssue.
  ///
  /// In en, this message translates to:
  /// **'Issue found'**
  String get inspectionMapLegendIssue;

  /// No description provided for @inspectionMapLegendCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current station'**
  String get inspectionMapLegendCurrent;

  /// No description provided for @inspectionMapLegendPending.
  ///
  /// In en, this message translates to:
  /// **'Not yet'**
  String get inspectionMapLegendPending;

  /// No description provided for @inspectionMapLegendYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get inspectionMapLegendYou;

  /// No description provided for @inspectionMapLegendLine.
  ///
  /// In en, this message translates to:
  /// **'Irrigation line'**
  String get inspectionMapLegendLine;

  /// No description provided for @inspectionMapLegendValve.
  ///
  /// In en, this message translates to:
  /// **'Valve'**
  String get inspectionMapLegendValve;

  /// No description provided for @inspectionMapLegendFlush.
  ///
  /// In en, this message translates to:
  /// **'Flush valve'**
  String get inspectionMapLegendFlush;

  /// No description provided for @inspectionMapTapHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a tree you already inspected to go back to its station.'**
  String get inspectionMapTapHint;

  /// No description provided for @inspectionJumpBlocked.
  ///
  /// In en, this message translates to:
  /// **'Finish station {station} first. Stations are saved in walking order.'**
  String inspectionJumpBlocked(int station);

  /// No description provided for @inspectionLocationHere.
  ///
  /// In en, this message translates to:
  /// **'You are at this station (GPS ±{accuracy} m).'**
  String inspectionLocationHere(int accuracy);

  /// No description provided for @inspectionLocationAway.
  ///
  /// In en, this message translates to:
  /// **'This station is about {meters} m from you (GPS ±{accuracy} m).'**
  String inspectionLocationAway(int meters, int accuracy);

  /// No description provided for @inspectionLocationAhead.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{You seem to be 1 station past this one.} other{You seem to be {count} stations past this one.}}'**
  String inspectionLocationAhead(int count);

  /// No description provided for @inspectionLocationBehind.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{You seem to be 1 station before this one.} other{You seem to be {count} stations before this one.}}'**
  String inspectionLocationBehind(int count);

  /// No description provided for @inspectionLocationOtherAisle.
  ///
  /// In en, this message translates to:
  /// **'You seem to be in aisle {aisle}; this station is in aisle {current}.'**
  String inspectionLocationOtherAisle(int aisle, int current);

  /// No description provided for @inspectionLocationOutside.
  ///
  /// In en, this message translates to:
  /// **'You are about {meters} m from this section.'**
  String inspectionLocationOutside(int meters);

  /// No description provided for @locationShow.
  ///
  /// In en, this message translates to:
  /// **'Show my location'**
  String get locationShow;

  /// No description provided for @locationHide.
  ///
  /// In en, this message translates to:
  /// **'Hide my location'**
  String get locationHide;

  /// No description provided for @locationFinding.
  ///
  /// In en, this message translates to:
  /// **'Finding your location…'**
  String get locationFinding;

  /// No description provided for @locationWeak.
  ///
  /// In en, this message translates to:
  /// **'Weak GPS signal (±{accuracy} m). Use the rows and tree labels to find your place.'**
  String locationWeak(int accuracy);

  /// No description provided for @locationDenied.
  ///
  /// In en, this message translates to:
  /// **'Location is blocked. Allow it for this app in the phone settings.'**
  String get locationDenied;

  /// No description provided for @locationServiceOff.
  ///
  /// In en, this message translates to:
  /// **'Turn on location (GPS) on the phone.'**
  String get locationServiceOff;

  /// No description provided for @locationFailed.
  ///
  /// In en, this message translates to:
  /// **'Your location is not available right now.'**
  String get locationFailed;

  /// No description provided for @mapLocationOutside.
  ///
  /// In en, this message translates to:
  /// **'You are about {meters} m outside the farm map.'**
  String mapLocationOutside(int meters);

  /// No description provided for @iconsGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'Icons guide'**
  String get iconsGuideTitle;

  /// No description provided for @iconsGuideEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Learn the pictures'**
  String get iconsGuideEyebrow;

  /// No description provided for @iconsGuideIntro.
  ///
  /// In en, this message translates to:
  /// **'Each kind of work, problem and status always has the same picture and colour everywhere in the app.'**
  String get iconsGuideIntro;

  /// No description provided for @iconsGuideSeverity.
  ///
  /// In en, this message translates to:
  /// **'Severity and priority'**
  String get iconsGuideSeverity;

  /// No description provided for @iconsGuideTaskStatus.
  ///
  /// In en, this message translates to:
  /// **'Task status'**
  String get iconsGuideTaskStatus;

  /// No description provided for @iconsGuideIssueStatus.
  ///
  /// In en, this message translates to:
  /// **'Issue status'**
  String get iconsGuideIssueStatus;

  /// No description provided for @iconsGuideInventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory categories'**
  String get iconsGuideInventory;

  /// No description provided for @iconsGuidePlanStatus.
  ///
  /// In en, this message translates to:
  /// **'Schedule status'**
  String get iconsGuidePlanStatus;

  /// No description provided for @iconsGuideReviewDecision.
  ///
  /// In en, this message translates to:
  /// **'Engineer review'**
  String get iconsGuideReviewDecision;

  /// No description provided for @scheduleRepeatField.
  ///
  /// In en, this message translates to:
  /// **'How often'**
  String get scheduleRepeatField;

  /// No description provided for @scheduleEveryDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Every day} other{Every {count} days}}'**
  String scheduleEveryDays(int count);

  /// No description provided for @scheduleEveryWeeks.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Every week} other{Every {count} weeks}}'**
  String scheduleEveryWeeks(int count);

  /// No description provided for @scheduleDateWithinYear.
  ///
  /// In en, this message translates to:
  /// **'A schedule starts today or later and can run for up to one year.'**
  String get scheduleDateWithinYear;

  /// No description provided for @scheduleAllWorkers.
  ///
  /// In en, this message translates to:
  /// **'All workers'**
  String get scheduleAllWorkers;

  /// No description provided for @scheduleAllWorkersHint.
  ///
  /// In en, this message translates to:
  /// **'Choose nobody to give the tasks to every worker.'**
  String get scheduleAllWorkersHint;

  /// No description provided for @scheduleErrRepeat.
  ///
  /// In en, this message translates to:
  /// **'A schedule repeats every 1 to 12 days or weeks.'**
  String get scheduleErrRepeat;

  /// No description provided for @scheduleErrStartPast.
  ///
  /// In en, this message translates to:
  /// **'The start date cannot be in the past.'**
  String get scheduleErrStartPast;

  /// No description provided for @scheduleErrEndBeforeStart.
  ///
  /// In en, this message translates to:
  /// **'The end date must be on or after the start date.'**
  String get scheduleErrEndBeforeStart;

  /// No description provided for @scheduleErrEndTooLate.
  ///
  /// In en, this message translates to:
  /// **'The end date can be at most one year after the start date.'**
  String get scheduleErrEndTooLate;

  /// No description provided for @scheduleErrRate.
  ///
  /// In en, this message translates to:
  /// **'Enter a dose above zero.'**
  String get scheduleErrRate;

  /// No description provided for @scheduleErrRateDetails.
  ///
  /// In en, this message translates to:
  /// **'Choose how the dose is measured.'**
  String get scheduleErrRateDetails;

  /// No description provided for @scheduleErrIrrigationProduct.
  ///
  /// In en, this message translates to:
  /// **'Irrigation schedules cannot use a product.'**
  String get scheduleErrIrrigationProduct;

  /// No description provided for @scheduleErrTargets.
  ///
  /// In en, this message translates to:
  /// **'Choose at least one place.'**
  String get scheduleErrTargets;

  /// No description provided for @scheduleErrCombinedTargets.
  ///
  /// In en, this message translates to:
  /// **'One combined task needs specific sections or zones, not the whole farm.'**
  String get scheduleErrCombinedTargets;

  /// No description provided for @scheduleErrCombinedKind.
  ///
  /// In en, this message translates to:
  /// **'One combined task can only group places of the same kind.'**
  String get scheduleErrCombinedKind;

  /// No description provided for @scheduleEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get scheduleEdit;

  /// No description provided for @scheduleEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit schedule'**
  String get scheduleEditTitle;

  /// No description provided for @scheduleSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get scheduleSaveChanges;

  /// No description provided for @scheduleCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get scheduleCopy;

  /// No description provided for @scheduleCopyTitle.
  ///
  /// In en, this message translates to:
  /// **'Copy schedule'**
  String get scheduleCopyTitle;

  /// No description provided for @scheduleHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Past runs'**
  String get scheduleHistoryTitle;

  /// No description provided for @scheduleHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No tasks yet. Each run\'s tasks are created the day before.'**
  String get scheduleHistoryEmpty;

  /// No description provided for @scheduleSkippedStock.
  ///
  /// In en, this message translates to:
  /// **'Skipped: not enough stock'**
  String get scheduleSkippedStock;

  /// No description provided for @scheduleArchiveConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Archive this schedule?'**
  String get scheduleArchiveConfirmTitle;

  /// No description provided for @scheduleArchiveConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'It stops creating tasks and leaves the list. Tasks it already created stay.'**
  String get scheduleArchiveConfirmBody;

  /// No description provided for @scheduleDose.
  ///
  /// In en, this message translates to:
  /// **'{amount} {unit} · {basis}'**
  String scheduleDose(String amount, String unit, String basis);

  /// No description provided for @scheduleShowArchived.
  ///
  /// In en, this message translates to:
  /// **'Show archived'**
  String get scheduleShowArchived;

  /// No description provided for @scheduleRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get scheduleRestore;

  /// No description provided for @scheduleSkippedWarning.
  ///
  /// In en, this message translates to:
  /// **'Runs skipped: not enough stock. Add stock to continue.'**
  String get scheduleSkippedWarning;

  /// No description provided for @scheduleZonesAll.
  ///
  /// In en, this message translates to:
  /// **'All zones'**
  String get scheduleZonesAll;

  /// No description provided for @scheduleZonesClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get scheduleZonesClear;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar': return AppLocalizationsAr();
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
