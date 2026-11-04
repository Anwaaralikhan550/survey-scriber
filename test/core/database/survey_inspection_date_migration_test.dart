// A phone on schema 21 updates to 22: surveys keep everything and gain the visit date.
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/core/database/app_database.dart' hide Survey;
import 'package:survey_scriber/core/database/daos/surveys_dao.dart';
import 'package:survey_scriber/shared/domain/entities/survey.dart';

void main() {
  late Directory dir;
  late File file;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('drift_22_');
    file = File('${dir.path}/app.db');
  });

  tearDown(() => dir.deleteSync(recursive: true));

  Future<void> makeSchema21WithOneSurvey() async {
    final db = AppDatabase.forTesting(NativeDatabase(file));
    await SurveysDao(db).upsertSurvey(Survey(
      id: 's1',
      title: 'Inspection - OLD',
      type: SurveyType.inspection,
      status: SurveyStatus.inProgress,
      createdAt: DateTime(2026, 1, 2),
      jobRef: 'OLD',
      clientName: 'Ann',
      address: '1 High St',
      progress: 0.5,
      totalSections: 10,
      completedSections: 5,
    ));
    await db.customStatement('ALTER TABLE surveys DROP COLUMN inspection_date');
    await db.customStatement('PRAGMA user_version = 21');
    await db.close();
  }

  test('an old survey comes through whole, with no visit date', () async {
    await makeSchema21WithOneSurvey();

    final db = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(db.close);
    final survey = await SurveysDao(db).getSurveyById('s1');

    expect(survey, isNotNull);
    expect(survey!.title, 'Inspection - OLD');
    expect(survey.status, SurveyStatus.inProgress);
    expect(survey.jobRef, 'OLD');
    expect(survey.clientName, 'Ann');
    expect(survey.address, '1 High St');
    expect(survey.progress, 0.5);
    expect(survey.totalSections, 10);
    expect(survey.completedSections, 5);
    expect(survey.createdAt, DateTime(2026, 1, 2));
    expect(survey.inspectionDate, isNull);
  });

  test('the new column works after the update', () async {
    await makeSchema21WithOneSurvey();

    final db = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(db.close);
    final dao = SurveysDao(db);
    final survey = await dao.getSurveyById('s1');
    await dao.upsertSurvey(survey!.copyWith(inspectionDate: DateTime(2026, 12, 1)));

    expect((await dao.getSurveyById('s1'))!.inspectionDate, DateTime(2026, 12, 1));
    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.read<int>('user_version'), db.schemaVersion);
    expect(db.schemaVersion, 22);
  });

  test('a database that already has the column opens without trouble', () async {
    final first = AppDatabase.forTesting(NativeDatabase(file));
    await SurveysDao(first).upsertSurvey(Survey(
      id: 's1',
      title: 'New',
      type: SurveyType.inspection,
      status: SurveyStatus.draft,
      createdAt: DateTime(2026, 11, 1),
      inspectionDate: DateTime(2026, 12, 1),
    ));
    await first.close();

    final second = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(second.close);
    expect((await SurveysDao(second).getSurveyById('s1'))!.inspectionDate, DateTime(2026, 12, 1));
  });
}
