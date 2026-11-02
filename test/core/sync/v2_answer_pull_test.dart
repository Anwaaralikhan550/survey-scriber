// Client report 2 Nov 2026: "Party Disclosure: South-east". Party Disclosure and
// Property Facing share a field id, so on the backend's single row per
// (section, questionKey) one overwrote the other and the pull wrote it back.
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/core/database/app_database.dart';
import 'package:survey_scriber/core/sync/v2_answer_pull.dart';
import 'package:survey_scriber/core/sync/v2_sync_helper.dart';

void main() {
  const field = 'android_material_design_spinner';
  const disclosure = 'activity_party_disclosure';
  const facing = 'activity_property_facing';

  late AppDatabase db;
  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> pull(String questionKey, String value) async {
    final keyed = V2SyncHelper.parseAnswerQuestionKey(questionKey);
    await writePulledV2Answer(
      db,
      surveyId: 's',
      screenId: keyed?.screenId ?? disclosure,
      fieldKey: keyed?.fieldKey ?? questionKey,
      value: value,
      isValuation: false,
      createdAt: null,
      updatedAt: null,
      overwriteLocal: keyed != null,
    );
  }

  Future<Map<String, String?>> answers() async => {
        for (final a in await db.select(db.inspectionV2Answers).get()) a.screenId: a.value,
      };

  test('each screen keeps its own answer after a sync round trip', () async {
    final a = V2SyncHelper.answerQuestionKey(disclosure, field);
    final b = V2SyncHelper.answerQuestionKey(facing, field);
    expect(a, isNot(b));

    await pull(a, 'None');
    await pull(b, 'South-east');

    expect(await answers(), {disclosure: 'None', facing: 'South-east'});
  });

  test('an old plain-key row cannot replace what the screen already holds', () async {
    await pull(V2SyncHelper.answerQuestionKey(disclosure, field), 'None');
    await pull(field, 'South-east');
    expect((await answers())[disclosure], 'None');
  });

  test('an old plain-key row still fills an empty answer', () async {
    await pull(field, 'None');
    expect((await answers())[disclosure], 'None');
  });

  test('newer keyed answer replaces an older one', () async {
    final key = V2SyncHelper.answerQuestionKey(disclosure, field);
    await pull(key, 'None');
    await pull(key, 'Conflict');
    expect((await answers())[disclosure], 'Conflict');
  });

  test('plain field ids are not read as keyed answers', () {
    expect(V2SyncHelper.parseAnswerQuestionKey(field), isNull);
    expect(V2SyncHelper.parseAnswerQuestionKey('mw_sbbw_condition'), isNull);
    expect(V2SyncHelper.parseAnswerQuestionKey('::x'), isNull);
    expect(V2SyncHelper.parseAnswerQuestionKey('x::'), isNull);
    final parsed = V2SyncHelper.parseAnswerQuestionKey('$disclosure::$field');
    expect(parsed?.screenId, disclosure);
    expect(parsed?.fieldKey, field);
  });
}
