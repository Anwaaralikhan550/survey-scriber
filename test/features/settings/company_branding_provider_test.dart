import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:survey_scriber/core/network/api_client.dart';
import 'package:survey_scriber/features/settings/presentation/providers/company_branding_provider.dart';

class _Api extends Mock implements ApiClient {}

Response<Map<String, dynamic>> _reply(Map<String, dynamic> data) => Response(
      data: data,
      requestOptions: RequestOptions(path: 'auth/branding'),
    );

void main() {
  late _Api api;
  late SharedPreferences prefs;
  final logo = Uint8List.fromList([1, 2, 3, 4]);

  void serverHas(String? name, Uint8List? image) {
    when(() => api.get<Map<String, dynamic>>('auth/branding')).thenAnswer(
      (_) async => _reply({
        'companyName': name,
        'companyLogo': image == null ? null : base64Encode(image),
      }),
    );
  }

  void serverAcceptsSaves() {
    when(() => api.put<Map<String, dynamic>>('auth/branding', data: any(named: 'data')))
        .thenAnswer((_) async => _reply({}));
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    api = _Api();
  });

  test('a new phone gets the company from the server', () async {
    serverHas('Francis Blackstone', logo);
    final notifier = CompanyBrandingNotifier(prefs, api, 'u1');
    expect(notifier.state.name, '');
    await notifier.sync();
    expect(notifier.state.name, 'Francis Blackstone');
    expect(notifier.state.logo, logo);
    // Kept for making reports offline.
    final offline = CompanyBrandingNotifier(prefs, api, 'u1');
    expect(offline.state.name, 'Francis Blackstone');
    expect(offline.state.logo, logo);
  });

  test('saving sends name and logo to the server', () async {
    serverHas(null, null);
    serverAcceptsSaves();
    final notifier = CompanyBrandingNotifier(prefs, api, 'u1');
    await notifier.sync();
    expect(await notifier.save(name: '  Francis Blackstone ', logo: logo), isTrue);
    expect(notifier.state.name, 'Francis Blackstone');
    verify(() => api.put<Map<String, dynamic>>('auth/branding', data: {
          'companyName': 'Francis Blackstone',
          'companyLogo': base64Encode(logo),
        })).called(1);
  });

  test('offline save stays on the phone and goes up on the next sync', () async {
    serverHas(null, null);
    when(() => api.put<Map<String, dynamic>>('auth/branding', data: any(named: 'data')))
        .thenThrow(Exception('offline'));
    final notifier = CompanyBrandingNotifier(prefs, api, 'u1');
    await notifier.sync();
    expect(await notifier.save(name: 'Francis', logo: null), isFalse);
    expect(notifier.state.name, 'Francis');

    // The old server copy must not overwrite the unsent save.
    serverAcceptsSaves();
    expect(await notifier.sync(), isTrue);
    expect(notifier.state.name, 'Francis');
    verify(() => api.put<Map<String, dynamic>>('auth/branding', data: {
          'companyName': 'Francis',
          'companyLogo': null,
        })).called(2); // the failed try, then the one that went up
  });

  test('a save made while the server copy is on its way wins', () async {
    final answer = Completer<Response<Map<String, dynamic>>>();
    when(() => api.get<Map<String, dynamic>>('auth/branding')).thenAnswer((_) => answer.future);
    when(() => api.put<Map<String, dynamic>>('auth/branding', data: any(named: 'data')))
        .thenThrow(Exception('offline'));
    final notifier = CompanyBrandingNotifier(prefs, api, 'u1');
    await notifier.save(name: 'New name', logo: null);
    answer.complete(_reply({'companyName': 'Old name', 'companyLogo': null}));
    await Future<void>.delayed(Duration.zero);
    expect(notifier.state.name, 'New name');
  });

  test('removing the logo removes it from the phone', () async {
    serverHas('Francis', logo);
    serverAcceptsSaves();
    final notifier = CompanyBrandingNotifier(prefs, api, 'u1');
    await notifier.sync();
    await notifier.save(name: 'Francis', logo: null);
    expect(notifier.state.logo, isNull);
    expect(CompanyBrandingNotifier(prefs, api, 'u1').state.logo, isNull);
  });

  test('each account on a phone has its own company', () async {
    serverHas('Francis', logo);
    await CompanyBrandingNotifier(prefs, api, 'u1').sync();
    when(() => api.get<Map<String, dynamic>>('auth/branding')).thenThrow(Exception('offline'));
    expect(CompanyBrandingNotifier(prefs, api, 'u2').state.name, '');
  });

  test('signed out means no company', () {
    serverHas(null, null);
    expect(CompanyBrandingNotifier(prefs, api, null).state, const CompanyBranding());
  });
}
