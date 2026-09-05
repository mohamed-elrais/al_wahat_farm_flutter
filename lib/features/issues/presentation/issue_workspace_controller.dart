import 'package:al_wahat_farm_flutter/features/issues/data/issue_workspace_repository.dart';
import 'package:al_wahat_farm_flutter/features/issues/domain/issue_workspace.dart';
import 'package:al_wahat_farm_flutter/features/issues/domain/issue_photo.dart';
import 'package:al_wahat_farm_flutter/features/issues/domain/tree_issue_draft.dart';
import 'package:al_wahat_farm_flutter/features/issues/domain/tree_issue.dart';
import 'package:al_wahat_farm_flutter/features/sync/domain/sync_engine.dart';
import 'package:flutter/widgets.dart';

enum IssueWorkspaceStatus { idle, loading, ready, failure }

class IssueWorkspaceController extends ChangeNotifier {
  IssueWorkspaceController({
    required String farmId,
    required IssueWorkspaceRepository repository,
    this.isManager = false,
    DateTime Function()? now,
  })  : _farmId = farmId,
        _repository = repository,
        _now = now ?? DateTime.now;

  final String _farmId;
  final IssueWorkspaceRepository _repository;
  final DateTime Function() _now;
  final bool isManager;

  IssueWorkspaceStatus status = IssueWorkspaceStatus.idle;
  List<TreeIssueSummary> issues = const <TreeIssueSummary>[];
  List<TreeIssueSummary> allIssues = const <TreeIssueSummary>[];
  TreeIssueType? typeFilter;
  IssueSeverity? severityFilter;
  TreeIssueStatus? issueStatusFilter;
  String? sectionFilter;
  IssueAgeFilter ageFilter = IssueAgeFilter.any;
  IssueAssignmentFilter assignmentFilter = IssueAssignmentFilter.all;
  IssueSource? sourceFilter;
  IssueWorkspaceView view = IssueWorkspaceView.active;
  bool onlyUnclaimed = false;
  Object? error;
  String? busyIssueId;

  int get activeCount => allIssues.where((issue) => issue.isActive).length;
  int get historyCount => allIssues.where((issue) => !issue.isActive).length;

  Future<void> load() async {
    status = IssueWorkspaceStatus.loading;
    error = null;
    notifyListeners();
    try {
      allIssues = isManager
          ? await _repository.listManagerIssues(_farmId)
          : await _repository.listSummaries(_farmId);
      _applyFilters();
      status = IssueWorkspaceStatus.ready;
    } catch (caught) {
      error = caught;
      status = IssueWorkspaceStatus.failure;
    }
    notifyListeners();
  }

  Future<void> setType(TreeIssueType? value) async {
    typeFilter = value;
    _applyFilters();
    notifyListeners();
  }

  Future<void> setSeverity(IssueSeverity? value) async {
    severityFilter = value;
    _applyFilters();
    notifyListeners();
  }

  void setView(IssueWorkspaceView value) {
    view = value;
    issueStatusFilter = null;
    _applyFilters();
    notifyListeners();
  }

  void setStatus(TreeIssueStatus? value) {
    issueStatusFilter = value;
    _applyFilters();
    notifyListeners();
  }

  void setSection(String? value) {
    sectionFilter = value;
    _applyFilters();
    notifyListeners();
  }

  void setAge(IssueAgeFilter value) {
    ageFilter = value;
    _applyFilters();
    notifyListeners();
  }

  void setAssignment(IssueAssignmentFilter value) {
    assignmentFilter = value;
    _applyFilters();
    notifyListeners();
  }

  void setSource(IssueSource? value) {
    sourceFilter = value;
    _applyFilters();
    notifyListeners();
  }

  void resetManagerFilters() {
    typeFilter = null;
    severityFilter = null;
    issueStatusFilter = null;
    sectionFilter = null;
    ageFilter = IssueAgeFilter.any;
    assignmentFilter = IssueAssignmentFilter.all;
    sourceFilter = null;
    _applyFilters();
    notifyListeners();
  }

  Future<void> setOnlyUnclaimed(bool value) async {
    onlyUnclaimed = value;
    _applyFilters();
    notifyListeners();
  }

  Future<String?> claim(TreeIssueSummary issue) async {
    busyIssueId = issue.id;
    error = null;
    notifyListeners();
    try {
      final taskId = await _repository.claim(issue.id);
      await load();
      return taskId;
    } catch (caught) {
      error = caught;
      notifyListeners();
      return null;
    } finally {
      busyIssueId = null;
      notifyListeners();
    }
  }

  Future<String?> assign(
    TreeIssueSummary issue, {
    required String assigneeProfileId,
    required bool requiresEngineerReview,
  }) async {
    busyIssueId = issue.id;
    error = null;
    notifyListeners();
    try {
      final taskId = await _repository.assign(
        issueId: issue.id,
        assigneeProfileId: assigneeProfileId,
        requiresEngineerReview: requiresEngineerReview,
      );
      await load();
      return taskId;
    } catch (caught) {
      error = caught;
      notifyListeners();
      return null;
    } finally {
      busyIssueId = null;
      notifyListeners();
    }
  }

  Future<List<TaskTreeIssueWork>> listTaskWork(String taskId) =>
      _repository.listTaskWork(taskId);

  Future<TreeIssueDetails> loadDetails(String issueId) =>
      _repository.loadDetails(issueId);

  Future<List<TreeIssueOccurrence>> listTreeHistory(String treeId) =>
      _repository.listTreeHistory(treeId);

  Future<void> changeSeverity(
    String issueId,
    IssueSeverity severity, {
    String? notes,
  }) async {
    await _repository.changeSeverity(issueId, severity, notes: notes);
    await load();
  }

  Future<void> dismiss(String issueId, String notes) async {
    await _repository.dismiss(issueId, notes);
    await load();
  }

  Future<void> resolve({
    required String taskId,
    required String issueId,
    String? notes,
    String? photoStoragePath,
    PreparedIssuePhoto? preparedPhoto,
    String? userId,
    String? farmId,
  }) =>
      _repository.resolve(
        taskId: taskId,
        issueId: issueId,
        notes: notes,
        photoStoragePath: photoStoragePath,
        preparedPhoto: preparedPhoto,
        userId: userId,
        farmId: farmId,
      );

  Future<void> unableToFix({
    required String taskId,
    required String issueId,
    required TreeIssueUnableReason reason,
    String? notes,
    PreparedIssuePhoto? preparedPhoto,
    String? userId,
    String? farmId,
  }) =>
      _repository.unableToFix(
        taskId: taskId,
        issueId: issueId,
        reason: reason,
        notes: notes,
        preparedPhoto: preparedPhoto,
        userId: userId,
        farmId: farmId,
      );

  void _applyFilters() {
    final cutoffDays = ageFilter.minimumDays;
    final now = _now();
    issues = allIssues
        .where((item) =>
            (!isManager ||
                (view == IssueWorkspaceView.active
                    ? item.isActive
                    : !item.isActive)) &&
            (typeFilter == null || item.type == typeFilter) &&
            (severityFilter == null || item.severity == severityFilter) &&
            (issueStatusFilter == null || item.status == issueStatusFilter) &&
            (sectionFilter == null || item.sectionId == sectionFilter) &&
            (cutoffDays == null ||
                now.difference(item.reportedAt).inDays >= cutoffDays) &&
            (assignmentFilter == IssueAssignmentFilter.all ||
                (assignmentFilter == IssueAssignmentFilter.assigned
                    ? item.hasAssignment
                    : !item.hasAssignment)) &&
            (sourceFilter == null || item.source == sourceFilter) &&
            (!onlyUnclaimed || !item.isClaimed))
        .toList(growable: false);
  }
}

class IssueWorkspaceScope extends InheritedNotifier<IssueWorkspaceController> {
  const IssueWorkspaceScope({
    required IssueWorkspaceController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static IssueWorkspaceController? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<IssueWorkspaceScope>()
      ?.notifier;
}

class IssueWorkspaceProvider extends StatefulWidget {
  const IssueWorkspaceProvider({
    required this.farmId,
    required this.repository,
    required this.child,
    this.isManager = false,
    this.syncEngine,
    super.key,
  });

  final String farmId;
  final IssueWorkspaceRepository repository;
  final Widget child;
  final bool isManager;
  final SyncEngine? syncEngine;

  @override
  State<IssueWorkspaceProvider> createState() => _IssueWorkspaceProviderState();
}

class _IssueWorkspaceProviderState extends State<IssueWorkspaceProvider> {
  late IssueWorkspaceController _controller;
  int? _lastSyncMillis;

  @override
  void initState() {
    super.initState();
    _controller = IssueWorkspaceController(
      farmId: widget.farmId,
      repository: widget.repository,
      isManager: widget.isManager,
    )..load();
    _listenToSync();
  }

  @override
  void didUpdateWidget(IssueWorkspaceProvider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.syncEngine != widget.syncEngine) {
      oldWidget.syncEngine?.removeListener(_handleSync);
      _listenToSync();
    }
    if (oldWidget.farmId != widget.farmId ||
        oldWidget.isManager != widget.isManager ||
        oldWidget.repository != widget.repository) {
      _controller.dispose();
      _controller = IssueWorkspaceController(
        farmId: widget.farmId,
        repository: widget.repository,
        isManager: widget.isManager,
      )..load();
    }
  }

  @override
  void dispose() {
    widget.syncEngine?.removeListener(_handleSync);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IssueWorkspaceScope(
        controller: _controller,
        child: widget.child,
      );

  void _listenToSync() {
    _lastSyncMillis = widget.syncEngine?.lastSyncedAtMillis;
    widget.syncEngine?.addListener(_handleSync);
  }

  void _handleSync() {
    final engine = widget.syncEngine;
    final completedAt = engine?.lastSyncedAtMillis;
    if (engine == null ||
        engine.isSyncing ||
        completedAt == null ||
        completedAt == _lastSyncMillis) {
      return;
    }
    _lastSyncMillis = completedAt;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.load();
    });
  }
}
