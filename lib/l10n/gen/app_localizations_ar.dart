import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'عمليات مزرعة الواحة';

  @override
  String get brandName => 'الواحة';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navMap => 'الخريطة';

  @override
  String get navScan => 'مسح';

  @override
  String get navTasks => 'المهام';

  @override
  String get navMore => 'المزيد';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get commonRetry => 'إعادة المحاولة';

  @override
  String get commonCancel => 'إلغاء';

  @override
  String get commonSave => 'حفظ';

  @override
  String get commonClose => 'إغلاق';

  @override
  String get commonBack => 'رجوع';

  @override
  String get commonLoading => 'جارٍ التحميل…';

  @override
  String routeUnavailable(String path) {
    return 'المسار غير متاح: $path';
  }

  @override
  String get commonCamera => 'الكاميرا';

  @override
  String get commonGallery => 'المعرض';

  @override
  String get commonRemove => 'إزالة';

  @override
  String get offlineBanner => 'غير متصل · عرض بيانات المزرعة والمهام المخزّنة';

  @override
  String get offlineBannerSemantics => 'أنت غير متصل. يتم عرض بيانات المزرعة والمهام المخزّنة.';

  @override
  String get languageLabel => 'اللغة';

  @override
  String get languageSystem => 'الإعداد الافتراضي للنظام';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get loginWelcomeTitle => 'مرحبًا بك في\nالواحة.';

  @override
  String get loginEyebrow => 'عمليات المزرعة';

  @override
  String get loginSignInTitle => 'تسجيل الدخول';

  @override
  String get loginSignInSubtitle => 'استخدم حساب عمليات المزرعة الخاص بك.';

  @override
  String get loginEmailLabel => 'البريد الإلكتروني';

  @override
  String get loginPasswordLabel => 'كلمة المرور';

  @override
  String get loginSignInButton => 'تسجيل الدخول';

  @override
  String get loginNotConfigured => 'لم يتم إعداد Supabase. شغّل التطبيق باستخدام --dart-define-from-file=config.json.';

  @override
  String get loginInvalidEmail => 'أدخل عنوان بريد إلكتروني صالحًا';

  @override
  String get loginInvalidPassword => 'كلمة المرور مطلوبة';

  @override
  String get loginFailed => 'تعذّر تسجيل الدخول. تحقق من اتصالك.';

  @override
  String get homeDateEyebrow => 'الأحد · 12 يوليو';

  @override
  String get homeHeroTitle => 'مزرعتك.\nشجرةً شجرة.';

  @override
  String get homeHeroLede => 'عمليات ميدانية قائمة على كل شجرة ومنطقة ري مُدرجة على الخريطة.';

  @override
  String get homeScanTreeQr => 'مسح رمز QR للشجرة';

  @override
  String get homeLiveMapData => 'بيانات الخريطة المباشرة';

  @override
  String get homeFarmOverview => 'نظرة عامة على مزرعة الواحة';

  @override
  String get homeMappedTrees => 'الأشجار المُدرجة على الخريطة';

  @override
  String get homeSections => 'الأقسام';

  @override
  String get homeIrrigationZones => 'مناطق الري';

  @override
  String get homePlantingPits => 'حفر الزراعة';

  @override
  String get homeOpenMap => 'فتح خريطة الإحداثيات';

  @override
  String get homeTodaysTasks => 'مهام اليوم';

  @override
  String get homeNoTasksToday => 'لا توجد مهام مجدولة لهذا اليوم.';

  @override
  String get homeViewAllTasks => 'عرض جميع المهام';

  @override
  String get homeWorkspaceUnavailable => 'مساحة عمل المهام غير متاحة.';

  @override
  String get moreEyebrow => 'الحساب والمزامنة';

  @override
  String get moreTitle => 'المزيد';

  @override
  String get moreFarmMember => 'عضو المزرعة';

  @override
  String get moreRoleResolves => 'يُحدَّد الدور من عضوية المزرعة النشطة';

  @override
  String moreSignedInAs(String name) {
    return 'تم تسجيل الدخول باسم $name';
  }

  @override
  String get syncOnline => 'متصل';

  @override
  String get syncOffline => 'غير متصل';

  @override
  String get syncOnlineSubtitle => 'متصل · يتم تحديث بيانات العمليات من Supabase';

  @override
  String get syncOfflineSubtitle => 'غير متصل · عرض بيانات المزرعة والمهام المخزّنة';

  @override
  String get syncStatusOnlineSemantics => 'حالة المزامنة: متصل';

  @override
  String get syncStatusOfflineSemantics => 'حالة المزامنة: غير متصل';

  @override
  String get syncDefaultSubtitle => 'يتم تحديث بيانات العمليات من Supabase';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get syncTitle => 'المزامنة';

  @override
  String get syncStatusAllSynced => 'تمت مزامنة جميع التغييرات';

  @override
  String syncStatusPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تغييرات بانتظار المزامنة',
      one: 'تغيير واحد بانتظار المزامنة',
    );
    return '$_temp0';
  }

  @override
  String syncStatusFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'فشلت مزامنة $count تغييرات',
      one: 'فشلت مزامنة تغيير واحد',
    );
    return '$_temp0';
  }

  @override
  String get syncSyncing => 'جارٍ المزامنة…';

  @override
  String get syncNow => 'المزامنة الآن';

  @override
  String get syncRetryFailed => 'إعادة محاولة التغييرات الفاشلة';

  @override
  String get syncPendingBadge => 'بانتظار المزامنة';

  @override
  String get syncReviewFailed => 'مراجعة التغييرات الفاشلة';

  @override
  String get failedOpsEyebrow => 'المزامنة';

  @override
  String get failedOpsTitle => 'التغييرات الفاشلة';

  @override
  String get failedOpsIntro => 'تعذّرت مزامنة هذه التغييرات مع المزرعة. أعد المحاولة، أو تجاهل ما لم تعد بحاجة إليه.';

  @override
  String get failedOpsUnavailable => 'المزامنة غير متاحة حالياً.';

  @override
  String get failedOpsEmptyTitle => 'لا توجد تغييرات فاشلة';

  @override
  String get failedOpsEmptyMessage => 'تمت مزامنة كل شيء أو أنه لا يزال بانتظار المزامنة.';

  @override
  String get failedOpsRetryAll => 'إعادة محاولة الكل';

  @override
  String get failedOpsRetry => 'إعادة المحاولة';

  @override
  String get failedOpsDiscard => 'تجاهل';

  @override
  String get failedOpsDiscardConfirmTitle => 'تجاهل هذا التغيير؟';

  @override
  String get failedOpsDiscardConfirmMessage => 'سيُحذف هذا التغيير ولن يُرسل إلى المزرعة. لا يمكن التراجع عن ذلك.';

  @override
  String get failedOpsKindStartTask => 'بدء المهمة';

  @override
  String get failedOpsKindCompleteTask => 'إكمال المهمة';

  @override
  String get failedOpsKindSetAssignments => 'تحديث الإسنادات';

  @override
  String get failedOpsKindAddTaskPhoto => 'صورة إثبات المهمة';

  @override
  String get failedOpsKindCreateTask => 'إنشاء مهمة';

  @override
  String get failedOpsKindReportIssue => 'الإبلاغ عن مشكلة شجرة';

  @override
  String get failedOpsKindReviewTask => 'قرار المراجعة';

  @override
  String get gateAccessUnavailableTitle => 'الوصول إلى المزرعة غير متاح';

  @override
  String get gateProfileMissing => 'لم يتم إعداد ملف حسابك الشخصي.';

  @override
  String get gateProfileInactive => 'حسابك غير نشط.';

  @override
  String get gateNoMembership => 'لم يتم تعيين عضوية تشغيلية نشطة في المزرعة.';

  @override
  String get gateLoadFailedTitle => 'تعذّر تحميل صلاحية الوصول إلى المزرعة';

  @override
  String get gateLoadFailedMessage => 'تحقق من اتصالك وحاول مرة أخرى.';

  @override
  String get hierarchyFailedTitle => 'تعذّر تحميل بيانات المزرعة';

  @override
  String get hierarchyFailedMessage => 'تحقق من اتصالك ومن صلاحية وصولك إلى المزرعة، ثم حاول مرة أخرى.';

  @override
  String get roleOwner => 'المالك';

  @override
  String get roleAgriculturalEngineer => 'مهندس زراعي';

  @override
  String get roleWorker => 'عامل';

  @override
  String get roleAccountant => 'محاسب';

  @override
  String get taskStatusDraft => 'مسودة';

  @override
  String get taskStatusAssigned => 'مُسندة';

  @override
  String get taskStatusInProgress => 'قيد التنفيذ';

  @override
  String get taskStatusCompleted => 'مكتملة';

  @override
  String get taskStatusNeedsReview => 'بحاجة إلى مراجعة';

  @override
  String get taskStatusApproved => 'معتمدة';

  @override
  String get taskStatusReturned => 'مُعادة';

  @override
  String get taskStatusCancelled => 'ملغاة';

  @override
  String get taskTypeIrrigation => 'الري';

  @override
  String get taskTypeFertilization => 'التسميد';

  @override
  String get taskTypeHarmfulWeedControl => 'مكافحة الأعشاب الضارة';

  @override
  String get taskTypePestControl => 'مكافحة الحشرات';

  @override
  String get taskTypeDiseaseControl => 'مكافحة الأمراض الفطرية';

  @override
  String get taskTypeDripperMaintenance => 'صيانة النقّاطات';

  @override
  String get taskTypeTreeInspection => 'فحص الأشجار';

  @override
  String get taskTypeEngineerReview => 'مراجعة المهندس الزراعي';

  @override
  String get taskTypeGeneral => 'عمل ميداني عام';

  @override
  String get priorityLow => 'منخفضة';

  @override
  String get priorityMedium => 'متوسطة';

  @override
  String get priorityHigh => 'عالية';

  @override
  String get priorityUrgent => 'عاجلة';

  @override
  String get activityCreated => 'تم إنشاء المهمة';

  @override
  String get activityAssigned => 'تم تحديث الإسنادات';

  @override
  String get activityUnassigned => 'تم مسح الإسنادات';

  @override
  String get activityStarted => 'بدأ العمل';

  @override
  String get activityCompleted => 'اكتمل العمل';

  @override
  String get activityFlaggedForReview => 'أُرسلت لمراجعة المهندس الزراعي';

  @override
  String get activityReviewedApproved => 'تم اعتماد العمل';

  @override
  String get activityReviewedReturned => 'أُعيدت للتصحيح';

  @override
  String get activityCommented => 'تمت إضافة تعليق';

  @override
  String get activityCancelled => 'تم إلغاء المهمة';

  @override
  String get activityPhotoAdded => 'تمت إضافة دليل';

  @override
  String get photoTypeBefore => 'قبل العمل';

  @override
  String get photoTypeAfter => 'بعد العمل';

  @override
  String get photoTypeEvidence => 'دليل';

  @override
  String get photoTypeIssue => 'مشكلة';

  @override
  String get photoTypeReview => 'مراجعة';

  @override
  String get issueTypeInsufficientIrrigation => 'ري غير كافٍ';

  @override
  String get issueTypeCloggedDripper => 'نقّاط مسدود';

  @override
  String get issueTypeLeakOrDripperDamage => 'تسرّب أو تلف في النقّاط';

  @override
  String get issueTypeHarmfulWeed => 'أعشاب ضارة';

  @override
  String get issueTypePestOrDisease => 'آفة أو مرض';

  @override
  String get issueTypeTreeDamage => 'تلف في الشجرة';

  @override
  String get issueTypeOther => 'أخرى';

  @override
  String get reviewDecisionApproved => 'معتمدة';

  @override
  String get reviewDecisionReturned => 'أُعيدت للتصحيح';

  @override
  String get reviewDecisionFollowUp => 'تتطلب متابعة';

  @override
  String get reviewActionApprove => 'اعتماد';

  @override
  String get reviewActionReturn => 'إعادة للتصحيح';

  @override
  String get reviewActionFollowUp => 'طلب متابعة';

  @override
  String get tasksEyebrow => 'عمليات المزرعة';

  @override
  String get tasksTitle => 'مهام المزرعة';

  @override
  String get tasksCreate => 'إنشاء';

  @override
  String get tasksFilterToday => 'اليوم';

  @override
  String tasksFilterAll(int count) {
    return 'الكل ($count)';
  }

  @override
  String get tasksViewList => 'القائمة';

  @override
  String get tasksViewCalendar => 'التقويم';

  @override
  String get tasksCalendarPreviousMonth => 'الشهر السابق';

  @override
  String get tasksCalendarNextMonth => 'الشهر التالي';

  @override
  String get tasksCalendarToday => 'اليوم';

  @override
  String tasksCalendarTasksForDate(String date) {
    return 'مهام $date';
  }

  @override
  String tasksCalendarTaskCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مهمة',
      many: '$count مهمة',
      few: '$count مهام',
      two: 'مهمتان',
      one: 'مهمة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get tasksCalendarNoTasksTitle => 'لا توجد مهام في هذا التاريخ';

  @override
  String get tasksCalendarNoTasksManager => 'اختر تاريخًا آخر أو أنشئ مهمة جديدة.';

  @override
  String get tasksCalendarNoTasksWorker => 'اختر تاريخًا آخر لعرض المهام المسندة إليك.';

  @override
  String get tasksLoadingTitle => 'جارٍ تحميل مهام المزرعة';

  @override
  String get tasksLoadingMessage => 'جارٍ التحقق من قائمة مهامك المصفّاة حسب دورك…';

  @override
  String get tasksLoadFailedTitle => 'تعذّر تحميل المهام';

  @override
  String get tasksFailureDefault => 'تعذّر تحميل مهام المزرعة. تحقق من اتصالك وحاول مرة أخرى.';

  @override
  String get tasksEmptyTodayTitle => 'لا توجد مهام مجدولة اليوم';

  @override
  String get tasksEmptyAllTitle => 'لا توجد مهام مرئية';

  @override
  String get tasksEmptyManager => 'أنشئ مهمة أو غيّر التاريخ والإسناد في Supabase.';

  @override
  String get tasksEmptyWorker => 'تظهر هنا فقط المهام النشطة المُسندة إليك.';

  @override
  String get reviewQueueEntryTitle => 'قائمة انتظار المراجعة';

  @override
  String get reviewQueueEntryNone => 'لا توجد مهام بانتظار المراجعة';

  @override
  String reviewQueueEntryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مهام بانتظار المراجعة',
      one: 'مهمة واحدة بانتظار المراجعة',
    );
    return '$_temp0';
  }

  @override
  String targetTree(String code) {
    return 'الشجرة $code';
  }

  @override
  String get targetTreeGeneric => 'شجرة';

  @override
  String targetZone(String code) {
    return 'المنطقة $code';
  }

  @override
  String get targetZoneGeneric => 'منطقة ري';

  @override
  String targetSection(String code) {
    return 'القسم $code';
  }

  @override
  String get targetSectionGeneric => 'قسم من المزرعة';

  @override
  String get targetWholeFarm => 'المزرعة بأكملها';

  @override
  String get scheduleNotScheduled => 'غير مجدولة';

  @override
  String scheduleDue(String value) {
    return 'الاستحقاق $value';
  }

  @override
  String get taskDetailEyebrow => 'تفاصيل المهمة';

  @override
  String get backToTasks => 'العودة إلى المهام';

  @override
  String get detailType => 'النوع';

  @override
  String get detailTarget => 'الهدف';

  @override
  String get detailSchedule => 'الجدولة';

  @override
  String get detailPriority => 'الأولوية';

  @override
  String get detailPlannedDuration => 'المدة المخطط لها';

  @override
  String durationMinutes(int minutes) {
    return '$minutes دقيقة';
  }

  @override
  String get detailDescription => 'الوصف';

  @override
  String get detailInstructions => 'التعليمات';

  @override
  String get assignmentsTitle => 'الإسنادات';

  @override
  String get editAction => 'تعديل';

  @override
  String get noActiveAssignees => 'لا يوجد مكلّفون نشطون.';

  @override
  String assignedAt(String value) {
    return 'تم الإسناد $value';
  }

  @override
  String get assignedFarmMember => 'عضو المزرعة المُكلّف';

  @override
  String get actionsTitle => 'الإجراءات';

  @override
  String get startTask => 'بدء المهمة';

  @override
  String get completeAction => 'إكمال';

  @override
  String get addEvidence => 'إضافة دليل';

  @override
  String evidenceCount(int count) {
    return 'الأدلة ($count)';
  }

  @override
  String get noEvidence => 'لم يتم تسجيل أي دليل للمهمة.';

  @override
  String get activityTitle => 'النشاط';

  @override
  String get noActivity => 'لا يوجد نشاط مرئي للمهمة.';

  @override
  String get editAssignments => 'تعديل الإسنادات';

  @override
  String get noOperationalMembers => 'لا يوجد أعضاء تشغيليون نشطون متاحون.';

  @override
  String get saveAssignments => 'حفظ الإسنادات';

  @override
  String get completeTaskTitle => 'إكمال المهمة';

  @override
  String get completionNote => 'ملاحظة الإكمال';

  @override
  String get sendForReview => 'إرسال لمراجعة المهندس الزراعي';

  @override
  String get optionalCompletionEvidence => 'دليل إكمال اختياري';

  @override
  String selectedFile(String file) {
    return 'المحدد: $file';
  }

  @override
  String get evidenceTypeLabel => 'نوع الدليل';

  @override
  String get evidenceCaptionLabel => 'تعليق الدليل';

  @override
  String get confirmCompletion => 'تأكيد الإكمال';

  @override
  String get addTaskEvidenceTitle => 'إضافة دليل للمهمة';

  @override
  String get choosePhotoToContinue => 'اختر صورة للمتابعة.';

  @override
  String get captionLabel => 'التعليق';

  @override
  String get saveEvidence => 'حفظ الدليل';

  @override
  String get unableToLoadTask => 'تعذّر تحميل هذه المهمة.';

  @override
  String get taskWorkspaceUnavailable => 'مساحة عمل المهام غير متاحة.';

  @override
  String get stageReady => 'جاهز';

  @override
  String get stageStarting => 'جارٍ بدء المهمة…';

  @override
  String get stageAssigning => 'جارٍ حفظ الإسنادات…';

  @override
  String get stagePickingEvidence => 'جارٍ تجهيز الدليل…';

  @override
  String get stageUploadingEvidence => 'جارٍ رفع الدليل الخاص…';

  @override
  String get stageRegisteringEvidence => 'جارٍ تسجيل الدليل…';

  @override
  String get stageCompleting => 'جارٍ إكمال المهمة…';

  @override
  String get msgTaskStarted => 'بدأت المهمة.';

  @override
  String get msgAssignmentsUpdated => 'تم تحديث الإسنادات.';

  @override
  String get msgTaskEvidenceSaved => 'تم حفظ دليل المهمة.';

  @override
  String get msgEvidenceQueuedOffline => 'تم حفظ الدليل دون اتصال. سيُرفع عند عودة الاتصال بالإنترنت.';

  @override
  String get msgTaskCompleted => 'اكتملت المهمة.';

  @override
  String get msgTaskCompletedReview => 'اكتملت المهمة وأُرسلت لمراجعة المهندس الزراعي.';

  @override
  String get errTaskStart => 'تعذّر بدء المهمة.';

  @override
  String get errAssignmentsUpdate => 'تعذّر تحديث الإسنادات.';

  @override
  String get errEvidencePrepare => 'تعذّر تجهيز صورة الدليل تلك.';

  @override
  String get errEvidenceRegister => 'لم يتم تأكيد تسجيل الدليل. يمكنك إعادة المحاولة بأمان.';

  @override
  String get errTaskComplete => 'تعذّر إكمال المهمة.';

  @override
  String get errCompletionUnconfirmed => 'تم حفظ الدليل، لكن لم يتم تأكيد إكمال المهمة. أعد محاولة الإكمال دون الرفع مرة أخرى.';

  @override
  String get createEyebrow => 'التخطيط للعمل الميداني';

  @override
  String get createTitle => 'إنشاء مهمة';

  @override
  String get taskTitleField => 'عنوان المهمة *';

  @override
  String get enterTaskTitle => 'أدخل عنوانًا للمهمة';

  @override
  String get taskTypeField => 'نوع المهمة';

  @override
  String get descriptionField => 'الوصف';

  @override
  String get workerInstructionsField => 'تعليمات العامل';

  @override
  String get targetTitle => 'الهدف';

  @override
  String get scopeField => 'النطاق';

  @override
  String get scopeWholeFarm => 'المزرعة بأكملها';

  @override
  String get scopeSection => 'قسم';

  @override
  String get scopeZone => 'منطقة ري';

  @override
  String get scopeTree => 'شجرة';

  @override
  String get scheduleTitle => 'الجدولة';

  @override
  String get scheduledDate => 'التاريخ المجدول';

  @override
  String get startTimeLabel => 'وقت البدء';

  @override
  String get dueDateLabel => 'تاريخ الاستحقاق';

  @override
  String get dueTimeLabel => 'وقت الاستحقاق';

  @override
  String get plannedDurationField => 'المدة المخطط لها (بالدقائق)';

  @override
  String get enterPositiveMinutes => 'أدخل عددًا موجبًا من الدقائق';

  @override
  String get priorityField => 'الأولوية';

  @override
  String get requireEngineerReview => 'طلب مراجعة المهندس الزراعي';

  @override
  String get membersLoadFailed => 'تعذّر تحميل أعضاء المزرعة القابلين للإسناد.';

  @override
  String get creatingTask => 'جارٍ الإنشاء…';

  @override
  String get createTaskButton => 'إنشاء مهمة';

  @override
  String get chooseTargetSnack => 'اختر هدفًا لهذه المهمة.';

  @override
  String get chooseTargetValidator => 'اختر هدفًا';

  @override
  String get addAnotherTarget => 'أضف هدفًا آخر';

  @override
  String get createUnavailableRole => 'لا يسمح دورك في المزرعة بإنشاء المهام أو إسنادها.';

  @override
  String get createUnavailableWorkspace => 'مساحة عمل مهام المزرعة غير جاهزة.';

  @override
  String get msgTaskCreated => 'تم إنشاء المهمة وإسنادها.';

  @override
  String get msgTaskCreatedOffline => 'تم حفظ المهمة دون اتصال. سيتم إنشاؤها في المزرعة عند عودة الاتصال بالإنترنت.';

  @override
  String get errTaskCreate => 'تعذّر إنشاء المهمة.';

  @override
  String get taskPendingSyncBadge => 'بانتظار المزامنة';

  @override
  String get taskPendingSyncOpen => 'تُفتح هذه المهمة بعد مزامنتها مع المزرعة.';

  @override
  String get reviewTaskEyebrow => 'مراجعة المهمة';

  @override
  String get reviewQueueEyebrow => 'مراجعة المهندس الزراعي';

  @override
  String get reviewQueueTitle => 'قائمة انتظار المراجعة';

  @override
  String reviewQueuePending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مهام بانتظار القرار.',
      one: 'مهمة واحدة بانتظار القرار.',
    );
    return '$_temp0';
  }

  @override
  String get reviewQueueLoadingTitle => 'جارٍ تحميل قائمة انتظار المراجعة';

  @override
  String get reviewQueueLoadingMessage => 'جارٍ التحقق من المهام المحوّلة لمراجعة المهندس الزراعي…';

  @override
  String get reviewQueueFailedTitle => 'تعذّر تحميل قائمة الانتظار';

  @override
  String get reviewQueueEmptyTitle => 'لا توجد مهام قيد الانتظار';

  @override
  String get reviewQueueEmptyMessage => 'سيظهر هنا العمل المكتمل المُرسل للمراجعة.';

  @override
  String get reviewQueueUnavailableTitle => 'مساحة عمل المراجعة غير متاحة';

  @override
  String get reviewQueueUnavailableMessage => 'أعد فتح التطبيق لاستعادة قائمة انتظار مراجعة المزرعة.';

  @override
  String get reviewDeniedTitle => 'المراجعات مقيّدة';

  @override
  String get reviewDeniedMessage => 'يمكن للمالك أو المهندس الزراعي فقط مراجعة العمل المكتمل.';

  @override
  String get backToReviewQueue => 'العودة إلى قائمة انتظار المراجعة';

  @override
  String get reviewLinkedIssue => 'مرتبطة ببلاغ عن مشكلة في شجرة.';

  @override
  String get reviewCompleted => 'مكتملة';

  @override
  String get decisionTitle => 'القرار';

  @override
  String get decisionNotAwaiting => 'هذه المهمة ليست بانتظار قرار مراجعة.';

  @override
  String get decisionPrompt => 'سجّل نتيجة مراجعة المهندس الزراعي لهذا العمل.';

  @override
  String get reviewNotesLabel => 'ملاحظات المراجعة';

  @override
  String get reviewNotesHint => 'اشرح القرار للمكلّف.';

  @override
  String get optionalReviewPhoto => 'صورة مراجعة اختيارية';

  @override
  String reviewHistory(int count) {
    return 'سجل المراجعات ($count)';
  }

  @override
  String get noReviews => 'لم يتم تسجيل أي قرارات مراجعة بعد.';

  @override
  String get reviewWorkspaceUnavailable => 'مساحة عمل المراجعة غير متاحة.';

  @override
  String get unableToLoadReview => 'تعذّر تحميل هذه المراجعة.';

  @override
  String confirmDecision(String action) {
    return 'تأكيد $action';
  }

  @override
  String get reviewStagePickingPhoto => 'جارٍ تجهيز الصورة…';

  @override
  String get reviewStageUploadingPhoto => 'جارٍ رفع الصورة الخاصة…';

  @override
  String get reviewStageSubmitting => 'جارٍ تسجيل القرار…';

  @override
  String msgReviewRecorded(String decision) {
    return 'تم تسجيل المراجعة: $decision.';
  }

  @override
  String get msgReviewRecordedOffline => 'تم حفظ المراجعة دون اتصال. سيتم تسجيلها في المزرعة عند عودة الاتصال بالإنترنت.';

  @override
  String get errReviewPhotoUnconfirmed => 'تم رفع صورة المراجعة، لكن لم يتم تأكيد القرار. أعد المحاولة دون الرفع مرة أخرى.';

  @override
  String get errReviewRecord => 'تعذّر تسجيل قرار المراجعة.';

  @override
  String get errReviewPhotoPrepare => 'تعذّر تجهيز صورة المراجعة تلك.';

  @override
  String get reportIssueTitle => 'الإبلاغ عن مشكلة في شجرة';

  @override
  String issueSectionRow(String section, String row, String tree) {
    return 'القسم $section · الصف $row / الشجرة $tree';
  }

  @override
  String get issueTypeLabel => 'نوع المشكلة';

  @override
  String get issueSeverityLabel => 'الخطورة';

  @override
  String get issueObservationLabel => 'ملاحظة (اختياري)';

  @override
  String issueKibPrepared(int kib) {
    return 'تم تجهيز $kib ك.ب';
  }

  @override
  String get issueRemovePhoto => 'إزالة الصورة';

  @override
  String get reportIssueButton => 'الإبلاغ عن مشكلة';

  @override
  String get issueReportedButton => 'تم الإبلاغ عن المشكلة';

  @override
  String get issueRetryPhoto => 'إعادة محاولة الصورة';

  @override
  String get issueUnavailable => 'هذه الشجرة غير متاحة للإبلاغ عن مشكلة.';

  @override
  String get issueStagePreparingPhoto => 'جارٍ تجهيز الصورة…';

  @override
  String get issueStageReporting => 'جارٍ إنشاء المشكلة ومهمة المراجعة…';

  @override
  String get issueStageUploadingPhoto => 'جارٍ رفع الدليل الخاص…';

  @override
  String get issueStageRegisteringPhoto => 'جارٍ تسجيل الدليل…';

  @override
  String get issueErrPhotoPrepare => 'تعذّر تجهيز تلك الصورة.';

  @override
  String get issueMsgReported => 'تم الإبلاغ عن المشكلة وإنشاء مهمة مراجعة للمهندس الزراعي.';

  @override
  String get issueMsgReportedOffline => 'تم حفظ المشكلة دون اتصال. سيتم الإبلاغ عنها إلى المزرعة عند عودة الاتصال بالإنترنت.';

  @override
  String get issueErrReport => 'تعذّر الإبلاغ عن المشكلة. تحقق من اتصالك.';

  @override
  String get issueMsgReportedWithPhoto => 'تم حفظ المشكلة ومهمة المراجعة ودليل الصورة.';

  @override
  String get issueErrPartialPrefix => 'تم حفظ المشكلة ومهمة المراجعة، لكن لم يتم تأكيد تسجيل الصورة. ';

  @override
  String get issueMsgRetryPhoto => 'يمكنك إعادة محاولة رفع الصورة بأمان.';

  @override
  String get selectedTree => 'الشجرة المحددة';

  @override
  String get scheduleEndsOnRequired => 'ينتهي في (مطلوب)';

  @override
  String get scheduleEndRequiredMessage => 'اختر تاريخ النهاية — الجداول تحتاج إليه';

  @override
  String get scheduleDateWithinMonth => 'يبدأ الجدول اليوم أو لاحقاً ويستمر لمدة شهر كحد أقصى.';

  @override
  String scheduleRepetitions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ينفذ $count مرة',
      few: 'ينفذ $count مرات',
      two: 'ينفذ مرتين',
      one: 'ينفذ مرة واحدة',
      zero: 'لا تنفيذات ضمن التواريخ المحددة',
    );
    return '$_temp0';
  }

  @override
  String scheduleTotalRequired(String quantity, String unit) {
    return 'الإجمالي للجدول كاملاً: $quantity $unit';
  }

  @override
  String scheduleAvailableStock(String quantity, String unit) {
    return 'المتوفر الآن: $quantity $unit';
  }

  @override
  String scheduleRemainingAfter(String quantity, String unit) {
    return 'المتبقي بعد الجدول: $quantity $unit';
  }

  @override
  String scheduleShortage(String quantity, String unit) {
    return 'العجز: $quantity $unit';
  }

  @override
  String get scheduleGroupingTitle => 'طريقة إنشاء المهام';

  @override
  String get scheduleGroupingSeparate => 'مهام منفصلة';

  @override
  String get scheduleGroupingSeparateHint => 'مهمة لكل هدف في كل تاريخ تنفيذ.';

  @override
  String get scheduleGroupingCombined => 'مهمة واحدة مجمعة';

  @override
  String get scheduleGroupingCombinedHint => 'مهمة واحدة تضم كل الأهداف المحددة في كل تاريخ تنفيذ.';

  @override
  String get scheduleReviewTitle => 'مراجعة قبل الإنشاء';

  @override
  String scheduleReviewTargets(int count, String labels) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count هدفاً',
      few: '$count أهداف',
      two: 'هدفان',
      one: 'هدف واحد',
    );
    return '$_temp0: $labels';
  }

  @override
  String scheduleTasksTotal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ستُنشأ $count مهمة إجمالاً',
      few: 'ستُنشأ $count مهام إجمالاً',
      two: 'ستُنشأ مهمتان إجمالاً',
      one: 'ستُنشأ مهمة واحدة إجمالاً',
    );
    return '$_temp0';
  }

  @override
  String get scheduleExecutionDates => 'تواريخ التنفيذ';

  @override
  String scheduleMoreDates(int count) {
    return '+$count أخرى';
  }

  @override
  String get scheduleReviewNoProduct => 'بدون منتج';

  @override
  String get commonNotSet => 'غير محدد';

  @override
  String get photoLoadFailed => 'تعذر تحميل هذه الصورة. تحقق من الاتصال وحاول مرة أخرى.';

  @override
  String get mapFullScreen => 'ملء الشاشة';

  @override
  String get mapExitFullScreen => 'الخروج من ملء الشاشة';

  @override
  String mapCreateTaskForSection(String code) {
    return 'إنشاء مهمة للقسم $code';
  }

  @override
  String get attachTask => 'إرفاق مهمة';

  @override
  String get reportAnIssue => 'الإبلاغ عن مشكلة';

  @override
  String get treeUnavailableActions => 'نقطة الإحداثيات هذه غير متوفرة في بيانات المزرعة المباشرة، لذا فإن الإجراءات التشغيلية معطّلة.';

  @override
  String get treeDetailSection => 'القسم';

  @override
  String get treeDetailRowTree => 'الصف / الشجرة';

  @override
  String get treeDetailHealth => 'الحالة الصحية';

  @override
  String get treeDetailZone => 'المنطقة';

  @override
  String get treeZoneUnassigned => 'غير مُعيّنة';

  @override
  String get treeUnavailableTitle => 'الشجرة غير متاحة';

  @override
  String get treeUnavailableMessage => 'هذه الشجرة غير نشطة أو لم تعد مرئية لمزرعتك.';

  @override
  String get goBack => 'العودة';

  @override
  String get scanQrInactive => 'رمز QR هذا غير نشط أو غير مرئي لمزرعتك.';

  @override
  String get scanOffline => 'تعذّر المسح أثناء عدم الاتصال. حاول مرة أخرى عند الاتصال.';

  @override
  String get scanLookingUp => 'جارٍ البحث عن الشجرة…';

  @override
  String get scanPointCamera => 'وجّه الكاميرا نحو ملصق QR الخاص بالشجرة.';

  @override
  String get scanCameraOff => 'الوصول إلى الكاميرا معطّل. فعّله في الإعدادات لمسح ملصقات الأشجار.';

  @override
  String get scanCameraUnavailable => 'الكاميرا غير متاحة. يمكنك المحاولة مرة أخرى بعد التحقق من الأذونات.';

  @override
  String get mapEyebrow => 'خريطة ثنائية الأبعاد دقيقة الإحداثيات';

  @override
  String get mapZoomIn => 'تكبير';

  @override
  String get mapZoomOut => 'تصغير';

  @override
  String get mapReset => 'إعادة تعيين الخريطة';

  @override
  String get mapLayers => 'طبقات الخريطة';

  @override
  String get mapLayerTrees => 'الأشجار';

  @override
  String get mapLayerPlantingPits => 'حفر الزراعة';

  @override
  String get mapLayerIrrigation => 'شبكة الري';

  @override
  String get mapLayerUtilities => 'المباني والمرافق';

  @override
  String get mapLayerValves => 'محابس المناطق';

  @override
  String get mapLayerFlushValves => 'محابس الغسيل';

  @override
  String get mapLayerWaterSupply => 'إمداد المياه';

  @override
  String mapSectionName(String id) {
    return 'القسم $id';
  }

  @override
  String mapValveNameZone(String section, String submain, String number) {
    return 'القسم $section — الخط الفرعي $submain — محبس المنطقة $number';
  }

  @override
  String mapValveNameIsolation(String number) {
    return 'محبس عزل الخط الرئيسي $number';
  }

  @override
  String get mapIsolationSheetTitle => 'محبس الخط الرئيسي';

  @override
  String mapValveTreeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count شجرة تُغذّى عبر هذا المحبس',
      one: 'شجرة واحدة تُغذّى عبر هذا المحبس',
      zero: 'لا توجد أشجار مزروعة تعتمد على هذا المحبس',
    );
    return '$_temp0';
  }

  @override
  String mapValveDownstream(String list) {
    return 'يغذي الخطوط الفرعية: $list';
  }

  @override
  String get mapValveHighlightHint => 'الخط اللاحق ومناطقه مميزة على الخريطة. اضغط على مساحة فارغة من الخريطة للإزالة.';

  @override
  String get mapZoneSheetTitle => 'منطقة الري';

  @override
  String mapZoneTreeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count أشجار تُروى من هذا المحبس',
      one: 'شجرة واحدة تُروى من هذا المحبس',
      zero: 'لا توجد أشجار مرتبطة بهذه المنطقة',
    );
    return '$_temp0';
  }

  @override
  String mapZoneTreesPlanned(int count) {
    return 'السعة المخططة: $count شجرة';
  }

  @override
  String get mapZoneHighlightHint => 'خطوط المنطقة وأشجارها مميزة على الخريطة. اضغط على مساحة فارغة من الخريطة للإزالة.';

  @override
  String get mapAllSections => 'جميع الأقسام الـ 12';

  @override
  String get mapSectionEmpty => 'فارغ';

  @override
  String get mapSectionUnplanted => 'غير مزروع';

  @override
  String mapSectionPitCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count حفرة',
      few: '$count حفر',
      two: 'حفرتان',
      one: 'حفرة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get plantingPitEyebrow => 'حفرة زراعة';

  @override
  String plantingPitSection(String section) {
    return 'القسم $section';
  }

  @override
  String plantingPitPosition(String row, String pit) {
    return 'الصف $row · الحفرة $pit';
  }

  @override
  String plantingPitCoordinates(String latitude, String longitude) {
    return '$latitude، $longitude';
  }

  @override
  String plantingPitPlannedFor(String date) {
    return 'مخطط لها في $date';
  }

  @override
  String get plantingPitStatusPlanned => 'مخططة';

  @override
  String get plantingPitStatusMarked => 'معلّمة';

  @override
  String get plantingPitStatusDug => 'محفورة';

  @override
  String get plantingPitStatusPrepared => 'مجهّزة';

  @override
  String get plantingPitStatusCompleted => 'مكتملة';

  @override
  String get plantingPitStatusCancelled => 'ملغاة';

  @override
  String plantingPitAdvanceTo(String status) {
    return 'النقل إلى $status';
  }

  @override
  String get plantingPitCancel => 'إلغاء الحفرة';

  @override
  String get plantingPitUpdating => 'جارٍ التحديث…';

  @override
  String get plantingPitUpdated => 'تم تحديث حفرة الزراعة.';

  @override
  String get plantingPitUpdateFailed => 'تعذّر تحديث حفرة الزراعة.';

  @override
  String plantingPitAddForSection(String section) {
    return 'إضافة حفرة إلى القسم $section';
  }

  @override
  String get plantingPitCreateTitle => 'إضافة حفرة زراعة';

  @override
  String get plantingPitCodeField => 'رمز الحفرة';

  @override
  String get plantingPitRowField => 'رقم الصف';

  @override
  String get plantingPitNumberField => 'رقم الحفرة';

  @override
  String get plantingPitLatitudeField => 'خط العرض';

  @override
  String get plantingPitLongitudeField => 'خط الطول';

  @override
  String get plantingPitPlannedDateField => 'التاريخ المخطط (اختياري)';

  @override
  String get plantingPitNotesField => 'ملاحظات (اختياري)';

  @override
  String get plantingPitSave => 'إضافة الحفرة';

  @override
  String get plantingPitSaving => 'جارٍ الإضافة…';

  @override
  String get plantingPitCreated => 'تمت إضافة حفرة الزراعة.';

  @override
  String get plantingPitCreateFailed => 'تعذّرت إضافة حفرة الزراعة.';

  @override
  String get plantingPitRequiredField => 'هذا الحقل مطلوب';

  @override
  String get plantingPitInvalidCoordinate => 'أدخل إحداثياً صحيحاً';

  @override
  String get plantingPitGridPairRequired => 'أدخل رقم الصف ورقم الحفرة معاً أو اتركهما فارغين';

  @override
  String get mapSelectAnyTree => 'اختر أي شجرة';

  @override
  String mapTreePointsAvailable(int count) {
    return 'تتوفر $count نقطة شجرة.';
  }

  @override
  String mapGeometryFailed(String error) {
    return 'تعذّر تحميل هندسة المزرعة المُضمّنة.\n$error';
  }

  @override
  String get mapDiscrepancySemantics => 'تحذير من تعارض في بيانات المزرعة';

  @override
  String mapDiscrepancy(int count, String summary) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'فحص بيانات المزرعة · $count فروقات',
      one: 'فحص بيانات المزرعة · فرق واحد',
    );
    return '$_temp0\n$summary';
  }

  @override
  String get inventoryTitle => 'المخزون';

  @override
  String get inventoryEyebrow => 'مستلزمات المزرعة';

  @override
  String get inventorySearchHint => 'ابحث في الأصناف';

  @override
  String get inventoryAllCategories => 'الكل';

  @override
  String get inventoryEmptyTitle => 'لا توجد أصناف في المخزون';

  @override
  String get inventoryEmptyManager => 'أضف أول صنف بالزر أدناه.';

  @override
  String get inventoryEmptyWorker => 'لم تتم إضافة أصناف بعد.';

  @override
  String get inventoryLowStock => 'مخزون منخفض';

  @override
  String inventoryLowStockCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count أصناف دون الحد الأدنى للمخزون',
      one: 'صنف واحد دون الحد الأدنى للمخزون',
    );
    return '$_temp0';
  }

  @override
  String get inventoryQuantityLabel => 'المتوفر';

  @override
  String get inventoryMinimumLabel => 'الحد الأدنى';

  @override
  String get inventoryAddItem => 'إضافة صنف';

  @override
  String get inventoryEditItem => 'تعديل الصنف';

  @override
  String get inventoryItemName => 'اسم الصنف';

  @override
  String get inventoryItemNameRequired => 'أدخل اسم الصنف';

  @override
  String get inventoryCategoryField => 'الفئة';

  @override
  String get inventoryUnitField => 'الوحدة';

  @override
  String get inventoryDescriptionField => 'الوصف';

  @override
  String get inventoryMinimumStockField => 'الحد الأدنى للمخزون (تنبيه)';

  @override
  String get inventoryInitialQuantityField => 'الكمية الابتدائية';

  @override
  String get inventoryInvalidNumber => 'أدخل رقماً صحيحاً';

  @override
  String get inventoryAttributesTitle => 'المواصفات';

  @override
  String get inventoryAttributeName => 'الاسم';

  @override
  String get inventoryAttributeValue => 'القيمة';

  @override
  String get inventoryAddAttribute => 'إضافة مواصفة';

  @override
  String get inventorySaveItem => 'حفظ الصنف';

  @override
  String get inventorySaving => 'جارٍ الحفظ…';

  @override
  String get inventoryAddStock => 'إضافة مخزون';

  @override
  String get inventoryAdjust => 'تسوية';

  @override
  String get inventoryAdjustHint => 'قيمة موجبة تضيف وسالبة تخصم';

  @override
  String get inventoryQuantityField => 'الكمية';

  @override
  String get inventoryNoteField => 'ملاحظة';

  @override
  String get inventoryRecord => 'تسجيل';

  @override
  String get inventoryHistoryTitle => 'سجل الحركات';

  @override
  String get inventoryHistoryEmpty => 'لا توجد حركات بعد.';

  @override
  String get inventoryDeactivate => 'إلغاء تفعيل الصنف';

  @override
  String get inventoryDeactivateConfirmTitle => 'إلغاء تفعيل هذا الصنف؟';

  @override
  String get inventoryDeactivateConfirmMessage => 'سيُخفى الصنف من المخزون مع الاحتفاظ بسجله.';

  @override
  String get inventoryOffline => 'تعديلات المخزون تتطلب اتصالاً بالإنترنت. تُعرض البيانات المحفوظة.';

  @override
  String get inventoryMsgItemCreated => 'تمت إضافة الصنف إلى المخزون.';

  @override
  String get inventoryMsgItemUpdated => 'تم تحديث الصنف.';

  @override
  String get inventoryMsgStockRecorded => 'تم تسجيل حركة المخزون.';

  @override
  String get inventoryErrGeneric => 'تعذر حفظ إجراء المخزون.';

  @override
  String get inventoryLoadFailed => 'تعذر تحميل المخزون.';

  @override
  String get unitGram => 'جرام';

  @override
  String get unitKilogram => 'كيلوجرام';

  @override
  String get unitLiter => 'لتر';

  @override
  String get unitMilliliter => 'مليلتر';

  @override
  String get unitPiece => 'قطعة';

  @override
  String get unitMeter => 'متر';

  @override
  String get txnAddition => 'إضافة مخزون';

  @override
  String get txnConsumption => 'استهلاك بواسطة مهمة';

  @override
  String get txnAdjustment => 'تسوية';

  @override
  String get txnReversal => 'استرجاع استهلاك';

  @override
  String get categoryPipe => 'مواسير';

  @override
  String get categoryPipeJoint => 'وصلات مواسير';

  @override
  String get categoryFertilizer => 'أسمدة';

  @override
  String get categoryDripper => 'نقاطات';

  @override
  String get categoryInsecticide => 'مبيدات حشرية';

  @override
  String get categoryHerbicide => 'مبيدات أعشاب';

  @override
  String get categoryFungicide => 'مبيدات فطرية';

  @override
  String get categoryTool => 'أدوات زراعية';

  @override
  String get categoryOther => 'أخرى';

  @override
  String get schedulesTitle => 'الجداول';

  @override
  String get schedulesEyebrow => 'عمليات متكررة';

  @override
  String get scheduleNew => 'جدول جديد';

  @override
  String get schedulesEmptyTitle => 'لا توجد جداول بعد';

  @override
  String get schedulesEmptyMessage => 'أنشئ خطة متكررة للري أو التسميد أو الرش.';

  @override
  String get schedulesLoadFailed => 'تعذر تحميل الجداول.';

  @override
  String get planStatusDraft => 'مسودة';

  @override
  String get planStatusActive => 'نشط';

  @override
  String get planStatusPaused => 'متوقف مؤقتاً';

  @override
  String get planStatusCompleted => 'مكتمل';

  @override
  String get planStatusArchived => 'مؤرشف';

  @override
  String get scheduleOnce => 'مرة واحدة';

  @override
  String get scheduleDaily => 'يومياً';

  @override
  String get scheduleWeekly => 'أسبوعياً';

  @override
  String get basisPerFeddan => 'لكل فدان';

  @override
  String get basisPerTree => 'لكل شجرة';

  @override
  String get basisAbsolute => 'كمية ثابتة';

  @override
  String get methodFertigation => 'تسميد مع الري';

  @override
  String get methodSoilApplication => 'إضافة أرضية';

  @override
  String get methodFoliarSpray => 'رش ورقي';

  @override
  String get methodManualApplication => 'إضافة يدوية';

  @override
  String get scheduleTypeField => 'العملية';

  @override
  String get scheduleTitleField => 'عنوان الجدول';

  @override
  String get scheduleTitleRequired => 'أدخل عنوان الجدول';

  @override
  String get scheduleRecurrenceField => 'التكرار';

  @override
  String get scheduleWeekdaysField => 'في أيام';

  @override
  String get scheduleWeekdaysRequired => 'اختر يوماً واحداً على الأقل';

  @override
  String get scheduleStartsOn => 'يبدأ في';

  @override
  String get scheduleEndsOn => 'ينتهي في (اختياري)';

  @override
  String get scheduleTimeField => 'وقت التنفيذ';

  @override
  String get scheduleDurationField => 'المدة (دقائق)';

  @override
  String get scheduleTargetsTitle => 'الأهداف';

  @override
  String get scheduleTargetFarm => 'المزرعة كاملة';

  @override
  String get scheduleTargetSections => 'الأقسام';

  @override
  String get scheduleTargetZones => 'مناطق الري';

  @override
  String get scheduleProductTitle => 'المنتج والجرعة';

  @override
  String get scheduleProductField => 'منتج من المخزون';

  @override
  String get scheduleRateField => 'معدل الإضافة';

  @override
  String get scheduleBasisField => 'أساس المعدل';

  @override
  String get scheduleMethodField => 'طريقة الإضافة';

  @override
  String schedulePerOccurrence(String quantity, String unit) {
    return 'المطلوب لكل تنفيذ: $quantity $unit';
  }

  @override
  String scheduleCoverage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'المخزون الحالي يغطي $count تنفيذات',
      one: 'المخزون الحالي يغطي تنفيذاً واحداً',
      zero: 'المخزون الحالي لا يغطي أي تنفيذ',
    );
    return '$_temp0';
  }

  @override
  String get scheduleInsufficient => 'المخزون غير كافٍ — لن تُنشأ المهام حتى تعيد التخزين.';

  @override
  String get scheduleAssigneesTitle => 'العمال المكلفون';

  @override
  String get scheduleCreate => 'إنشاء الجدول';

  @override
  String get scheduleSaving => 'جارٍ الحفظ…';

  @override
  String get scheduleMsgCreated => 'تم إنشاء الجدول.';

  @override
  String get scheduleMsgUpdated => 'تم تحديث الجدول.';

  @override
  String get scheduleErrGeneric => 'تعذر حفظ الجدول.';

  @override
  String get scheduleNextOccurrences => 'المواعيد القادمة';

  @override
  String get scheduleGenerateNow => 'إنشاء مهام اليوم';

  @override
  String scheduleGenerated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تم إنشاء $count مهام',
      one: 'تم إنشاء مهمة واحدة',
      zero: 'لا توجد مهام جديدة للإنشاء',
    );
    return '$_temp0';
  }

  @override
  String get schedulePause => 'إيقاف مؤقت';

  @override
  String get scheduleActivate => 'تفعيل';

  @override
  String get scheduleArchive => 'أرشفة';

  @override
  String scheduleTargetCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count أهداف',
      one: 'هدف واحد',
    );
    return '$_temp0';
  }

  @override
  String get taskProductTitle => 'المنتج المطلوب';

  @override
  String taskProductQuantity(String quantity, String unit) {
    return '$quantity $unit';
  }
}
