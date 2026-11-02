// Client report 2 Nov 2026: "Create Inspection ... user is logged out of the App and
// the form is not created". A refused request after a good token refresh was treated
// as a failed refresh, which cleared the tokens and logged the user out.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:survey_scriber/core/network/api_interceptors.dart';
import 'package:survey_scriber/core/storage/storage_service.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.respond);
  final (int, Map<String, dynamic>) Function(RequestOptions) respond;
  final calls = <String>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? _, Future<void>? __) async {
    calls.add(options.path);
    final (status, body) = respond(options);
    return ResponseBody.fromString(jsonEncode(body), status, headers: {
      Headers.contentTypeHeader: ['application/json'],
    });
  }

  @override
  void close({bool force = false}) {}
}

const _goodRefresh = (200, <String, dynamic>{'accessToken': 'new-a', 'refreshToken': 'new-r'});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    Hive.init(Directory.systemTemp.createTempSync('token_refresh_').path);
    await StorageService.init();
    await StorageService.setAuthToken('old-a');
    await StorageService.setRefreshToken('old-r');
  });

  (Dio, void Function()) build(_FakeAdapter api, _FakeAdapter refresh, void Function() onFailed) {
    final dio = Dio(BaseOptions(baseUrl: 'http://test/api/v1/'))..httpClientAdapter = api;
    dio.interceptors.add(TokenRefreshInterceptor(
      dio: dio,
      onTokenRefreshFailed: onFailed,
      refreshAdapter: refresh,
    ));
    return (dio, onFailed);
  }

  test('refresh OK, retried request refused: stays logged in and the caller gets the refusal', () async {
    var loggedOut = false;
    var call = 0;
    final api = _FakeAdapter((_) => ++call == 1
        ? (401, <String, dynamic>{'message': 'expired'})
        : (400, <String, dynamic>{'message': 'Cannot create booking for past dates'}));
    final (dio, _) = build(api, _FakeAdapter((_) => _goodRefresh), () => loggedOut = true);

    final error = await dio.post<dynamic>('scheduling/bookings').then<DioException?>((_) => null,
        onError: (Object e) => e as DioException);

    expect(error?.response?.statusCode, 400);
    expect(error?.response?.data['message'], 'Cannot create booking for past dates');
    expect(loggedOut, isFalse);
    expect(StorageService.authToken, 'new-a');
    expect(StorageService.refreshToken, 'new-r');
  });

  test('refresh OK, retried request succeeds: caller gets the response', () async {
    var loggedOut = false;
    var call = 0;
    final api = _FakeAdapter((_) => ++call == 1
        ? (401, <String, dynamic>{})
        : (201, <String, dynamic>{'id': 'b1'}));
    final (dio, _) = build(api, _FakeAdapter((_) => _goodRefresh), () => loggedOut = true);

    final res = await dio.post<dynamic>('scheduling/bookings');

    expect(res.statusCode, 201);
    expect(loggedOut, isFalse);
  });

  test('refresh itself refused: logs out', () async {
    var loggedOut = false;
    final api = _FakeAdapter((_) => (401, <String, dynamic>{}));
    final (dio, _) = build(api, _FakeAdapter((_) => (401, <String, dynamic>{})), () => loggedOut = true);

    await expectLater(dio.post<dynamic>('scheduling/bookings'), throwsA(isA<DioException>()));

    expect(loggedOut, isTrue);
    expect(StorageService.authToken, isNull);
  });

  test('new token rejected as well: logs out, no endless refresh loop', () async {
    var loggedOut = false;
    final api = _FakeAdapter((_) => (401, <String, dynamic>{}));
    final refresh = _FakeAdapter((_) => _goodRefresh);
    final (dio, _) = build(api, refresh, () => loggedOut = true);

    await expectLater(dio.post<dynamic>('scheduling/bookings'), throwsA(isA<DioException>()));

    expect(refresh.calls, hasLength(1));
    expect(api.calls, hasLength(2));
    expect(loggedOut, isTrue);
  });
}
