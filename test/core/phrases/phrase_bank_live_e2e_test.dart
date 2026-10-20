// Real end-to-end check of live phrase updates against a running backend.
// Skipped unless PHRASE_E2E_URL (e.g. http://localhost:3099/api/v1) and
// PHRASE_E2E_ADMIN_TOKEN are set:
//   PHRASE_E2E_URL=... PHRASE_E2E_ADMIN_TOKEN=... flutter test test/core/phrases/phrase_bank_live_e2e_test.dart
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/core/network/api_client.dart';
import 'package:survey_scriber/core/phrases/phrase_bank_sync.dart';

void main() {
  final url = Platform.environment['PHRASE_E2E_URL'];
  final token = Platform.environment['PHRASE_E2E_ADMIN_TOKEN'];
  final skip = (url == null || token == null)
      ? 'set PHRASE_E2E_URL and PHRASE_E2E_ADMIN_TOKEN to run'
      : null;

  PhraseBankSync make(Directory dir, {String? bearer}) {
    final dio = Dio(
      BaseOptions(
        baseUrl: url!,
        headers: {if (bearer != null) 'Authorization': 'Bearer $bearer'},
      ),
    );
    return PhraseBankSync(apiClient: ApiClient(dio), docsDir: () async => dir);
  }

  test('admin edit -> server -> a different phone gets it', () async {
    final tmp = await Directory.systemTemp.createTemp('phrase_e2e_');
    addTearDown(() => tmp.delete(recursive: true));
    final admin = make(await Directory('${tmp.path}/admin').create(),
        bearer: token);
    final phone = make(await Directory('${tmp.path}/phone').create());

    final bundled = jsonDecode(
      await File('assets/property_inspection/phrase_texts.json').readAsString(),
    ) as Map<String, dynamic>;
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final edited = Map<String, dynamic>.from(bundled);
    const key = '{PARTY_DISCLOSURES_NONE}';
    edited[key] = '${bundled[key]} LIVE-$stamp';

    final result = await admin.publish(PhraseBank.inspection, edited);
    expect(result.checksum, isNotEmpty);

    expect(await phone.refresh(PhraseBank.inspection), isTrue);
    final got = jsonDecode((await phone.readCached(PhraseBank.inspection))!)
        as Map<String, dynamic>;
    expect(got.length, bundled.length);
    expect(got[key], edited[key]);
    expect(got, edited);

    // Second check: nothing new -> no re-download.
    expect(await phone.refresh(PhraseBank.inspection), isFalse);
  }, skip: skip);

  test('a non-admin phone cannot publish', () async {
    final tmp = await Directory.systemTemp.createTemp('phrase_e2e_');
    addTearDown(() => tmp.delete(recursive: true));
    final nobody = make(tmp); // no token
    expect(
      () => nobody.publish(PhraseBank.inspection, {'a': 'b'}),
      throwsA(anything),
    );
  }, skip: skip);
}
