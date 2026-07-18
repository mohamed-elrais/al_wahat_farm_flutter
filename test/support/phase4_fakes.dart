import 'package:al_wahat_farm_flutter/features/issues/data/tree_issue_repository.dart';
import 'package:al_wahat_farm_flutter/features/issues/domain/issue_photo.dart';
import 'package:al_wahat_farm_flutter/features/issues/domain/tree_issue.dart';
import 'package:al_wahat_farm_flutter/features/issues/domain/tree_issue_draft.dart';
import 'package:al_wahat_farm_flutter/features/trees/data/tree_qr_repository.dart';
import 'package:al_wahat_farm_flutter/features/trees/domain/scanned_tree.dart';

class FakeTreeQrRepository implements TreeQrRepository {
  FakeTreeQrRepository({this.result, this.failure});

  ScannedTree? result;
  Object? failure;
  final tokens = <String>[];

  @override
  Future<ScannedTree?> scan(String qrToken) async {
    tokens.add(qrToken);
    if (failure != null) throw failure!;
    return result;
  }
}

class FakeTreeIssueRepository implements TreeIssueRepository {
  FakeTreeIssueRepository({
    this.reportResult = const ReportedTreeIssue(
      issueId: 'issue-id',
      taskId: 'task-id',
    ),
    List<String>? events,
  }) : events = events ?? <String>[];

  final ReportedTreeIssue reportResult;
  final List<String> events;
  TreeIssueDraft? reportedDraft;
  Object? reportFailure;
  Object? addPhotoFailure;
  String? attachedIssueId;
  String? attachedStoragePath;

  @override
  Future<List<TreeIssue>> listForFarm(String farmId) async => const [];

  String? lastReportOpId;

  @override
  Future<ReportedTreeIssue> report(TreeIssueDraft draft, {String? opId}) async {
    events.add('report');
    reportedDraft = draft;
    lastReportOpId = opId;
    if (reportFailure != null) throw reportFailure!;
    return reportResult;
  }

  @override
  Future<String> addPhoto({
    required String issueId,
    required String storagePath,
    String? caption,
  }) async {
    events.add('add-photo');
    attachedIssueId = issueId;
    attachedStoragePath = storagePath;
    if (addPhotoFailure != null) throw addPhotoFailure!;
    return 'photo-id';
  }
}

class FakeIssuePhotoPicker implements IssuePhotoPicker {
  FakeIssuePhotoPicker({this.photo, this.failure, List<String>? events})
      : events = events ?? <String>[];

  PreparedIssuePhoto? photo;
  Object? failure;
  final List<String> events;
  IssuePhotoSource? source;

  @override
  Future<PreparedIssuePhoto?> pick(IssuePhotoSource source) async {
    events.add('pick-photo');
    this.source = source;
    if (failure != null) throw failure!;
    return photo;
  }
}

class FakeIssuePhotoStorage implements IssuePhotoStorage {
  FakeIssuePhotoStorage({List<String>? events}) : events = events ?? <String>[];

  final List<String> events;
  Object? uploadFailure;
  Object? deleteFailure;
  var uploadAttempts = 0;
  String uploadedPath = 'user-id/farm-id/task-id/issue.jpg';
  String? deletedPath;
  String? lastUploadTaskId;

  @override
  Future<String> upload({
    required String userId,
    required String farmId,
    required String taskId,
    required PreparedIssuePhoto photo,
  }) async {
    events.add('upload-photo');
    uploadAttempts++;
    lastUploadTaskId = taskId;
    if (uploadFailure != null) throw uploadFailure!;
    return uploadedPath;
  }

  @override
  Future<void> delete(String storagePath) async {
    events.add('delete-photo');
    deletedPath = storagePath;
    if (deleteFailure != null) throw deleteFailure!;
  }
}
