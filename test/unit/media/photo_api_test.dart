import 'dart:convert';
import 'dart:typed_data';

import 'package:al_wahat_farm_flutter/core/errors/operation_failure.dart';
import 'package:al_wahat_farm_flutter/core/media/photo_api.dart';
import 'package:al_wahat_farm_flutter/features/issues/data/issue_photo_service.dart';
import 'package:al_wahat_farm_flutter/features/issues/domain/issue_photo.dart';
import 'package:al_wahat_farm_flutter/features/tasks/data/task_evidence_service.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/farm_task.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/task_evidence.dart';
import 'package:al_wahat_farm_flutter/features/tasks/presentation/task_photo_viewer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

final _base = Uri.parse('https://farm.example/api/photos/');

PhotoApi _api(
  Future<http.Response> Function(http.Request request) handler, {
  String? token = 'token',
}) =>
    PhotoApi(
      base: _base,
      accessToken: () async => token,
      client: MockClient(handler),
    );

TaskPhoto _photo(String path) => TaskPhoto.fromJson(<String, Object?>{
      'id': path,
      'task_id': 'task',
      'storage_bucket_id': 'farm-evidence',
      'storage_path': path,
      'photo_type': 'evidence',
      'caption': null,
      'uploaded_by_profile_id': 'user',
      'created_at': '2026-10-15T10:00:00Z',
    });

void main() {
  test('uploads evidence to the same path form as before, with the token',
      () async {
    late http.Request sent;
    final storage = R2TaskEvidenceStorage(
      _api((request) async {
        sent = request;
        return http.Response('{"path":"p"}', 201);
      }),
      timestamp: () => 42,
    );

    final path = await storage.upload(
      userId: 'user',
      farmId: 'farm',
      taskId: 'task',
      evidence: PreparedTaskEvidence(
        bytes: Uint8List.fromList(<int>[0xff, 0xd8, 0xff]),
        filename: 'leaf.jpg',
        contentType: 'image/jpeg',
      ),
    );

    expect(path, 'user/farm/task/42_leaf.jpg');
    expect(sent.method, 'PUT');
    expect(sent.url.toString(),
        'https://farm.example/api/photos/object/user/farm/task/42_leaf.jpg');
    expect(sent.headers['Authorization'], 'Bearer token');
    expect(sent.headers['Content-Type'], 'image/jpeg');
    expect(sent.bodyBytes, <int>[0xff, 0xd8, 0xff]);
  });

  test('issue photos upload and delete through the service', () async {
    final calls = <String>[];
    final storage = R2IssuePhotoStorage(
      _api((request) async {
        calls.add('${request.method} ${request.url.path}');
        return http.Response('{}', 200);
      }),
      timestamp: () => 7,
    );
    final path = await storage.upload(
      userId: 'user',
      farmId: 'farm',
      taskId: 'task',
      photo: PreparedIssuePhoto(
        bytes: Uint8List.fromList(<int>[1]),
        filename: 'tree.jpg',
        contentType: 'image/jpeg',
      ),
    );
    await storage.delete(path);
    expect(calls, <String>[
      'PUT /api/photos/object/user/farm/task/7_tree.jpg',
      'DELETE /api/photos/object/user/farm/task/7_tree.jpg',
    ]);
  });

  group('failures keep the offline queue right', () {
    Future<OperationFailureKind> kindFor(int status) async {
      try {
        await _api((_) async => http.Response('{}', status))
            .upload('user/farm/task/x.jpg', Uint8List(1), 'image/jpeg');
      } on OperationFailure catch (error) {
        return error.kind;
      }
      fail('expected a failure');
    }

    test('refused or bad photos stop retrying', () async {
      expect(await kindFor(403), OperationFailureKind.authorization);
      expect(await kindFor(413), OperationFailureKind.invalidInput);
      expect(await kindFor(415), OperationFailureKind.invalidInput);
    });

    test('an expired login or a server error is retried later', () async {
      expect(await kindFor(401), OperationFailureKind.unexpected);
      expect(await kindFor(502), OperationFailureKind.unexpected);
    });

    test('no network is reported as offline', () async {
      final api = _api((_) async => throw http.ClientException('no network'));
      expect(
        () => api.upload('user/farm/task/x.jpg', Uint8List(1), 'image/jpeg'),
        throwsA(isA<OperationFailure>().having(
            (e) => e.kind, 'kind', OperationFailureKind.offline)),
      );
    });

    test('signed out is not sent at all', () async {
      var sent = false;
      final api = _api((_) async {
        sent = true;
        return http.Response('{}', 200);
      }, token: null);
      await expectLater(
        api.delete('user/farm/task/x.jpg'),
        throwsA(isA<OperationFailure>().having(
            (e) => e.kind, 'kind', OperationFailureKind.authorization)),
      );
      expect(sent, isFalse);
    });
  });

  test('thumbnails asked for together share one link request', () async {
    final requests = <List<Object?>>[];
    final provider = R2PhotoUrlProvider(_api((request) async {
      final paths = (jsonDecode(request.body) as Map)['paths'] as List;
      requests.add(paths);
      return http.Response(
        jsonEncode(<String, Object?>{
          'urls': <String, String>{
            for (final path in paths.cast<String>())
              if (path != 'u/f/t/hidden.jpg') path: 'https://link/$path',
          },
        }),
        200,
      );
    }));

    final a = provider.urlFor(_photo('u/f/t/a.jpg'));
    final b = provider.urlFor(_photo('u/f/t/b.jpg'));
    final again = provider.urlFor(_photo('u/f/t/a.jpg'));
    final hidden = expectLater(
      provider.urlFor(_photo('u/f/t/hidden.jpg')),
      throwsA(isA<OperationFailure>()
          .having((e) => e.kind, 'kind', OperationFailureKind.notFound)),
    );
    expect(await a, 'https://link/u/f/t/a.jpg');
    expect(await b, 'https://link/u/f/t/b.jpg');
    expect(await again, 'https://link/u/f/t/a.jpg');
    await hidden;
    expect(requests, hasLength(1));
    expect(requests.single, hasLength(3));

    // A failed link is not cached: asking again sends a new request.
    await expectLater(
      provider.urlFor(_photo('u/f/t/hidden.jpg')),
      throwsA(isA<OperationFailure>()),
    );
    expect(requests, hasLength(2));
    // A cached link is reused; refresh asks again.
    expect(await provider.urlFor(_photo('u/f/t/a.jpg')),
        'https://link/u/f/t/a.jpg');
    expect(requests, hasLength(2));
    await provider.urlFor(_photo('u/f/t/a.jpg'), refresh: true);
    expect(requests, hasLength(3));
  });
}
