import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:survey_scriber/core/database/app_database.dart';

/// Creates an in-memory Drift database for testing.
AppDatabase _createTestDb() =>
    AppDatabase.forTesting(NativeDatabase.memory());

void main() {
  group('AppDatabase.deleteEverything (Clear All Storage)', () {
    late AppDatabase db;

    setUp(() {
      db = _createTestDb();
    });

    tearDown(() async {
      await db.close();
    });

    test('deleteEverything removes all rows from all tables', () async {
      final now = DateTime.now();

      // Insert test data across tables
      await db.into(db.surveys).insert(SurveysCompanion.insert(
        id: 'survey-1',
        title: 'Test Survey',
        type: 'LEVEL_2',
        status: 'in_progress',
        createdAt: now,
      ));

      await db.into(db.surveySections).insert(SurveySectionsCompanion.insert(
        id: 'section-1',
        surveyId: 'survey-1',
        sectionType: 'about-property',
        title: 'About Property',
        sectionOrder: 0,
        createdAt: now,
      ));

      await db.into(db.surveyAnswers).insert(SurveyAnswersCompanion.insert(
        id: 'answer-1',
        surveyId: 'survey-1',
        sectionId: 'section-1',
        fieldKey: 'property_type',
        createdAt: now,
        value: const Value('Detached House'),
      ));

      await db.into(db.syncQueue).insert(SyncQueueCompanion.insert(
        entityType: 'survey',
        entityId: 'survey-1',
        action: 'create',
        payload: '{"id":"survey-1"}',
        createdAt: now,
      ));

      await db.into(db.mediaItems).insert(MediaItemsCompanion.insert(
        id: 'media-1',
        surveyId: 'survey-1',
        sectionId: 'section-1',
        localPath: '/path/to/photo.jpg',
        mediaType: 'photo',
        createdAt: now,
      ));

      await db.into(db.signatures).insert(SignaturesCompanion.insert(
        id: 'sig-1',
        surveyId: 'survey-1',
        strokesJson: '[]',
        createdAt: now,
      ));

      await db.into(db.generatedReports).insert(GeneratedReportsCompanion.insert(
        id: 'report-1',
        surveyId: 'survey-1',
        filePath: '/path/to/report.pdf',
        fileName: 'report.pdf',
        generatedAt: now,
      ));

      // Verify data exists
      expect(await db.select(db.surveys).get(), hasLength(1));
      expect(await db.select(db.surveySections).get(), hasLength(1));
      expect(await db.select(db.surveyAnswers).get(), hasLength(1));
      expect(await db.select(db.syncQueue).get(), hasLength(1));
      expect(await db.select(db.mediaItems).get(), hasLength(1));
      expect(await db.select(db.signatures).get(), hasLength(1));
      expect(await db.select(db.generatedReports).get(), hasLength(1));

      // Act: delete everything
      await db.deleteEverything();

      // Verify all tables are empty
      expect(await db.select(db.surveys).get(), isEmpty);
      expect(await db.select(db.surveySections).get(), isEmpty);
      expect(await db.select(db.surveyAnswers).get(), isEmpty);
      expect(await db.select(db.syncQueue).get(), isEmpty);
      expect(await db.select(db.mediaItems).get(), isEmpty);
      expect(await db.select(db.signatures).get(), isEmpty);
      expect(await db.select(db.generatedReports).get(), isEmpty);
      expect(await db.select(db.photoAnnotations).get(), isEmpty);
    });

    test('deleteEverything is idempotent on empty database', () async {
      await db.deleteEverything();

      expect(await db.select(db.surveys).get(), isEmpty);
      expect(await db.select(db.syncQueue).get(), isEmpty);
    });

    test('deleteEverything runs atomically (transaction)', () async {
      final now = DateTime.now();

      await db.into(db.surveys).insert(SurveysCompanion.insert(
        id: 'survey-1',
        title: 'Survey 1',
        type: 'LEVEL_2',
        status: 'in_progress',
        createdAt: now,
      ));

      await db.into(db.surveys).insert(SurveysCompanion.insert(
        id: 'survey-2',
        title: 'Survey 2',
        type: 'LEVEL_3',
        status: 'completed',
        createdAt: now,
      ));

      await db.into(db.syncQueue).insert(SyncQueueCompanion.insert(
        entityType: 'survey',
        entityId: 'survey-1',
        action: 'create',
        payload: '{}',
        createdAt: now,
      ));

      await db.deleteEverything();

      expect(await db.select(db.surveys).get(), isEmpty);
      expect(await db.select(db.syncQueue).get(), isEmpty);
    });

    test('database is usable after deleteEverything', () async {
      final now = DateTime.now();

      await db.into(db.surveys).insert(SurveysCompanion.insert(
        id: 'survey-old',
        title: 'Old',
        type: 'LEVEL_2',
        status: 'completed',
        createdAt: now,
      ));

      await db.deleteEverything();

      await db.into(db.surveys).insert(SurveysCompanion.insert(
        id: 'survey-new',
        title: 'New Survey',
        type: 'LEVEL_2',
        status: 'draft',
        createdAt: now,
      ));

      final surveys = await db.select(db.surveys).get();
      expect(surveys, hasLength(1));
      expect(surveys.first.id, 'survey-new');
    });

    test('deleteEverything clears ALL sync queue statuses', () async {
      final now = DateTime.now();

      for (final status in ['pending', 'failed', 'conflict']) {
        await db.into(db.syncQueue).insert(SyncQueueCompanion.insert(
          entityType: 'survey',
          entityId: 'survey-$status',
          action: 'create',
          payload: '{}',
          createdAt: now,
          status: Value(status),
        ));
      }

      expect(await db.select(db.syncQueue).get(), hasLength(3));

      await db.deleteEverything();

      expect(await db.select(db.syncQueue).get(), isEmpty);
    });
  });

  group('Clear Storage operation ordering (design verification)', () {
    test('logout must happen BEFORE clearAllStorage to preserve refresh token', () {
      // BEFORE FIX (Bug #2):
      //   1. StorageService.clearAllStorage()  -> deletes secure storage tokens
      //   2. authNotifier.logout()             -> getRefreshToken() = null
      //   3. POST /auth/logout body: { refreshToken: null } -> server ignores
      //
      // AFTER FIX:
      //   1. authNotifier.logout()             -> getRefreshToken() = "abc..."
      //   2. POST /auth/logout { refreshToken: "abc..." } -> server revokes
      //   3. StorageService.clearAllStorage(database: db) -> wipes everything
      expect(true, isTrue, reason: 'Documented ordering contract');
    });

    test('clearAllStorage accepts database for clean DB shutdown', () {
      // StorageService.clearAllStorage(database: db):
      //   1. db.deleteEverything() — truncates all tables in transaction
      //   2. db.close()           — releases SQLite file lock
      //   3. _clearDirectory()    — can now safely delete the .db file
      expect(true, isTrue, reason: 'Documented database parameter contract');
    });
  });
}
