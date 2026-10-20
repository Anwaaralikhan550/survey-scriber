import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/core/network/api_client.dart';
import 'package:survey_scriber/core/phrases/phrase_bank_sync.dart';

/// Minimal fake server: remembers the last published bank per type.
class _FakeServer implements HttpClientAdapter {
  final Map<String, Map<String, dynamic>> banks = {};
  final Map<String, int> versions = {};
  int getCalls = 0;
  bool offline = false;

  @override
  void close({bool force = false}) {}

  ResponseBody _json(int code, Object body) => ResponseBody.fromString(
        jsonEncode(body),
        code,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (offline) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }
    if (options.method == 'POST') {
      final body = options.data as Map<String, dynamic>;
      final type = body['bankType'] as String;
      final same = jsonEncode(banks[type]) == jsonEncode(body['bank']);
      if (!same) {
        banks[type] = body['bank'] as Map<String, dynamic>;
        versions[type] = (versions[type] ?? 0) + 1;
      }
      return _json(201, {
        'version': versions[type],
        'checksum': 'sum-${versions[type]}',
        'unchanged': same,
      });
    }
    getCalls++;
    final type = options.path.split('/').last;
    if (!banks.containsKey(type)) return _json(404, {'message': 'none'});
    final checksum = 'sum-${versions[type]}';
    final known = options.queryParameters['known'];
    return _json(200, {
      'version': versions[type],
      'checksum': checksum,
      'unchanged': known == checksum,
      if (known != checksum) 'bank': banks[type],
    });
  }
}

void main() {
  late Directory tmp;
  late _FakeServer server;
  late PhraseBankSync admin;
  late PhraseBankSync phone;

  PhraseBankSync make(Directory dir) {
    final dio = Dio(BaseOptions(baseUrl: 'http://fake/api/v1'))
      ..httpClientAdapter = server;
    return PhraseBankSync(apiClient: ApiClient(dio), docsDir: () async => dir);
  }

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('phrase_sync_');
    server = _FakeServer();
    admin = make(await Directory('${tmp.path}/admin').create());
    phone = make(await Directory('${tmp.path}/phone').create());
  });

  tearDown(() async => tmp.delete(recursive: true));

  test('nothing published: refresh is a quiet no-op, no cache', () async {
    expect(await phone.refresh(PhraseBank.inspection), isFalse);
    expect(await phone.readCached(PhraseBank.inspection), isNull);
  });

  test('admin publishes -> another phone receives the new wording', () async {
    final result =
        await admin.publish(PhraseBank.inspection, {'{A}': 'Old {X}.'});
    expect(result.version, 1);

    expect(await phone.refresh(PhraseBank.inspection), isTrue);
    final cached = await phone.readCached(PhraseBank.inspection);
    expect(jsonDecode(cached!), {'{A}': 'Old {X}.'});

    await admin.publish(PhraseBank.inspection, {'{A}': 'New {X}.'});
    expect(await phone.refresh(PhraseBank.inspection), isTrue);
    expect(
      jsonDecode((await phone.readCached(PhraseBank.inspection))!),
      {'{A}': 'New {X}.'},
    );
  });

  test('phone already up to date: server says unchanged, cache kept', () async {
    await admin.publish(PhraseBank.inspection, {'{A}': 'One.'});
    expect(await phone.refresh(PhraseBank.inspection), isTrue);
    expect(await phone.refresh(PhraseBank.inspection), isFalse);
    expect(await phone.readCached(PhraseBank.inspection), isNotNull);
  });

  test('offline: refresh returns false and keeps the old cache', () async {
    await admin.publish(PhraseBank.valuation, {
      'meta': <String, dynamic>{},
      'templates': {
        'T1': {'screenId': '*', 'text': 'Text.'},
      },
    });
    expect(await phone.refresh(PhraseBank.valuation), isTrue);
    server.offline = true;
    expect(await phone.refresh(PhraseBank.valuation), isFalse);
    expect(await phone.readCached(PhraseBank.valuation), isNotNull);
  });

  test('banks are cached separately per type', () async {
    await admin.publish(PhraseBank.inspection, {'{A}': 'Insp.'});
    await phone.refresh(PhraseBank.inspection);
    expect(await phone.readCached(PhraseBank.valuation), isNull);
  });

  test('publishing the same content twice is reported as unchanged', () async {
    await admin.publish(PhraseBank.inspection, {'{A}': 'Same.'});
    final again = await admin.publish(PhraseBank.inspection, {'{A}': 'Same.'});
    expect(again.unchanged, isTrue);
    expect(again.version, 1);
  });

  test('publish without API client throws (edit stays pending)', () async {
    final offlineSync = PhraseBankSync(docsDir: () async => tmp);
    expect(
      () => offlineSync.publish(PhraseBank.inspection, {'a': 'b'}),
      throwsStateError,
    );
  });
}
