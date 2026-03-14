import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'daos/generated_reports_dao.dart';
import 'daos/media_dao.dart';
import 'daos/signature_dao.dart';
import 'daos/survey_quality_scores_dao.dart';
import 'daos/survey_recommendations_dao.dart';
import 'daos/sync_queue_dao.dart';
import 'tables/generated_reports_table.dart';
import 'tables/inspection_v2_answers_table.dart';
import 'tables/inspection_v2_screens_table.dart';
import 'tables/media_items_table.dart';
import 'tables/signatures_table.dart';
import 'tables/survey_answers_table.dart';
import 'tables/survey_sections_table.dart';
import 'tables/survey_quality_scores_table.dart';
import 'tables/survey_recommendations_table.dart';
import 'tables/surveys_table.dart';
import 'tables/sync_queue_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Surveys,
    SurveySections, // Legacy V1 — read-only, kept for historical data
    SurveyAnswers, // Legacy V1 — read-only, kept for historical data
    InspectionV2Screens,
    InspectionV2Answers,
    SyncQueue,
    MediaItems,
    PhotoAnnotations,
    Signatures,
    GeneratedReports,
    SurveyRecommendations,
    SurveyQualityScores,
  ],
  daos: [SyncQueueDao, MediaDao, SignatureDao, GeneratedReportsDao, SurveyRecommendationsDao, SurveyQualityScoresDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'survey_scriber'));

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 21;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          // Migration for sync_queue table
          if (from < 2) {
            await m.createTable(syncQueue);
          }
          // Migration for media tables
          if (from < 3) {
            await m.createTable(mediaItems);
            await m.createTable(photoAnnotations);
          }
          // Migration for signatures table
          if (from < 4) {
            await m.createTable(signatures);
          }
          // Migration for re-inspection fields (idempotent - check if column exists first)
          if (from < 5) {
            await _addColumnIfNotExists(m, 'surveys', 'parent_survey_id', 'TEXT');
            await _addColumnIfNotExists(m, 'surveys', 'reinspection_number', 'INTEGER DEFAULT 0');
          }
          // Migration for sync_queue processedAt column (crash recovery tracking)
          if (from < 6) {
            await _addColumnIfNotExists(m, 'sync_queue', 'processed_at', 'INTEGER');
          }
          // Migration for generated reports table (PDF history)
          if (from < 7) {
            await m.createTable(generatedReports);
          }
          // Migration for AI summary column on surveys
          if (from < 8) {
            await _addColumnIfNotExists(m, 'surveys', 'ai_summary', 'TEXT');
          }
          // Migration for risk summary and repair recommendations columns
          if (from < 9) {
            await _addColumnIfNotExists(m, 'surveys', 'risk_summary', 'TEXT');
            await _addColumnIfNotExists(m, 'surveys', 'repair_recommendations', 'TEXT');
          }
          if (from < 10) {
            await m.createTable(inspectionV2Screens);
            await m.createTable(inspectionV2Answers);
          }
          if (from < 11) {
            await _addColumnIfNotExists(m, 'inspection_v2_screens', 'group_key', 'TEXT');
          }
          if (from < 12) {
            await _addColumnIfNotExists(m, 'inspection_v2_screens', 'node_type', 'TEXT');
            await _addColumnIfNotExists(m, 'inspection_v2_screens', 'parent_id', 'TEXT');
          }
          // V1 deprecation: unify survey type values
          if (from < 13) {
            await m.issueCustomQuery(
              "UPDATE surveys SET type = 'inspection' WHERE type IN ('level2', 'level3', 'inspectionV2')",
            );
            await m.issueCustomQuery(
              "UPDATE surveys SET type = 'valuation' WHERE type = 'valuationV2'",
            );
          }
          // Add enhanced metadata columns to generated_reports
          if (from < 14) {
            await _addColumnIfNotExists(m, 'generated_reports', 'module_type', "TEXT DEFAULT 'inspection'");
            await _addColumnIfNotExists(m, 'generated_reports', 'format', "TEXT DEFAULT 'pdf'");
            await _addColumnIfNotExists(m, 'generated_reports', 'style', "TEXT DEFAULT 'legacy'");
            await _addColumnIfNotExists(m, 'generated_reports', 'remote_url', 'TEXT');
            await _addColumnIfNotExists(m, 'generated_reports', 'checksum', "TEXT DEFAULT ''");
          }
          // Add startedAt timestamp to surveys
          if (from < 15) {
            await _addColumnIfNotExists(m, 'surveys', 'started_at', 'INTEGER');
          }
          // Add survey_recommendations table
          if (from < 16) {
            await m.createTable(surveyRecommendations);
          }
          // v17: Hybrid intelligence — extend recommendations + scoring table
          if (from < 17) {
            await _addColumnIfNotExists(m, 'survey_recommendations', 'source_type', "TEXT DEFAULT 'rule'");
            await _addColumnIfNotExists(m, 'survey_recommendations', 'rule_version', 'TEXT');
            await _addColumnIfNotExists(m, 'survey_recommendations', 'ai_model_version', 'TEXT');
            await _addColumnIfNotExists(m, 'survey_recommendations', 'confidence_score', 'REAL');
            await _addColumnIfNotExists(m, 'survey_recommendations', 'generation_timestamp', 'INTEGER');
            await _addColumnIfNotExists(m, 'survey_recommendations', 'internal_reasoning', 'TEXT');
            await _addColumnIfNotExists(m, 'survey_recommendations', 'audit_hash', 'TEXT');
            await m.createTable(surveyQualityScores);
          }
          // v18: Phrase engine output persistence (Broken Link #3)
          if (from < 18) {
            await _addColumnIfNotExists(m, 'inspection_v2_screens', 'phrase_output', 'TEXT');
          }
          // v19: Surveyor user notes per screen (editable live preview)
          if (from < 19) {
            await _addColumnIfNotExists(m, 'inspection_v2_screens', 'user_note', 'TEXT');
          }
          // v20: Soft delete + unique constraint alignment with backend
          if (from < 20) {
            await _addColumnIfNotExists(m, 'surveys', 'deleted_at', 'INTEGER');
            // Add unique index on inspection_v2_answers(survey_id, screen_id, field_key)
            // Using IF NOT EXISTS to be idempotent.
            await m.issueCustomQuery(
              'CREATE UNIQUE INDEX IF NOT EXISTS idx_v2_answers_unique '
              'ON inspection_v2_answers (survey_id, screen_id, field_key)',
            );
          }
          // v21: Distinguish manual live-preview edits from auto-generated
          // phrase output so stale cached auto phrases do not override fresh
          // preview text on reopen.
          if (from < 21) {
            await _addColumnIfNotExists(
              m,
              'inspection_v2_screens',
              'phrase_edited_manually',
              'INTEGER NOT NULL DEFAULT 0',
            );
          }
        },
        beforeOpen: (details) async {
          // Safety check: ensure required columns exist even if schema version is current
          // This handles cases where migration failed partially or database is corrupted
          if (details.wasCreated == false) {
            await _ensureColumnsExist();
          }
        },
      );

  /// Ensure all required columns exist (repairs corrupted migrations)
  Future<void> _ensureColumnsExist() async {
    // Check surveys table columns
    final surveysResult = await customSelect('PRAGMA table_info(surveys)').get();
    final surveysColumns = surveysResult.map((row) => row.read<String>('name')).toSet();

    if (!surveysColumns.contains('parent_survey_id')) {
      await customStatement('ALTER TABLE surveys ADD COLUMN parent_survey_id TEXT');
    }
    if (!surveysColumns.contains('reinspection_number')) {
      await customStatement('ALTER TABLE surveys ADD COLUMN reinspection_number INTEGER DEFAULT 0');
    }
    if (!surveysColumns.contains('ai_summary')) {
      await customStatement('ALTER TABLE surveys ADD COLUMN ai_summary TEXT');
    }
    if (!surveysColumns.contains('risk_summary')) {
      await customStatement('ALTER TABLE surveys ADD COLUMN risk_summary TEXT');
    }
    if (!surveysColumns.contains('repair_recommendations')) {
      await customStatement('ALTER TABLE surveys ADD COLUMN repair_recommendations TEXT');
    }
    if (!surveysColumns.contains('started_at')) {
      await customStatement('ALTER TABLE surveys ADD COLUMN started_at INTEGER');
    }
    if (!surveysColumns.contains('deleted_at')) {
      await customStatement('ALTER TABLE surveys ADD COLUMN deleted_at INTEGER');
    }

    // Check sync_queue table columns
    final syncQueueResult = await customSelect('PRAGMA table_info(sync_queue)').get();
    final syncQueueColumns = syncQueueResult.map((row) => row.read<String>('name')).toSet();

    if (!syncQueueColumns.contains('processed_at')) {
      await customStatement('ALTER TABLE sync_queue ADD COLUMN processed_at INTEGER');
    }

    final inspectionScreensResult =
        await customSelect('PRAGMA table_info(inspection_v2_screens)').get();
    final inspectionScreensColumns =
        inspectionScreensResult.map((row) => row.read<String>('name')).toSet();

    if (!inspectionScreensColumns.contains('group_key')) {
      await customStatement('ALTER TABLE inspection_v2_screens ADD COLUMN group_key TEXT');
    }
    if (!inspectionScreensColumns.contains('node_type')) {
      await customStatement('ALTER TABLE inspection_v2_screens ADD COLUMN node_type TEXT');
    }
    if (!inspectionScreensColumns.contains('parent_id')) {
      await customStatement('ALTER TABLE inspection_v2_screens ADD COLUMN parent_id TEXT');
    }
    if (!inspectionScreensColumns.contains('phrase_output')) {
      await customStatement('ALTER TABLE inspection_v2_screens ADD COLUMN phrase_output TEXT');
    }
    if (!inspectionScreensColumns.contains('phrase_edited_manually')) {
      await customStatement(
        'ALTER TABLE inspection_v2_screens '
        'ADD COLUMN phrase_edited_manually INTEGER NOT NULL DEFAULT 0',
      );
    }
    if (!inspectionScreensColumns.contains('user_note')) {
      await customStatement('ALTER TABLE inspection_v2_screens ADD COLUMN user_note TEXT');
    }

    // Check survey_recommendations table columns (v17)
    final recsResult = await customSelect('PRAGMA table_info(survey_recommendations)').get();
    final recsColumns = recsResult.map((row) => row.read<String>('name')).toSet();

    if (recsColumns.isNotEmpty) {
      if (!recsColumns.contains('source_type')) {
        await customStatement("ALTER TABLE survey_recommendations ADD COLUMN source_type TEXT DEFAULT 'rule'");
      }
      if (!recsColumns.contains('rule_version')) {
        await customStatement('ALTER TABLE survey_recommendations ADD COLUMN rule_version TEXT');
      }
      if (!recsColumns.contains('ai_model_version')) {
        await customStatement('ALTER TABLE survey_recommendations ADD COLUMN ai_model_version TEXT');
      }
      if (!recsColumns.contains('confidence_score')) {
        await customStatement('ALTER TABLE survey_recommendations ADD COLUMN confidence_score REAL');
      }
      if (!recsColumns.contains('generation_timestamp')) {
        await customStatement('ALTER TABLE survey_recommendations ADD COLUMN generation_timestamp INTEGER');
      }
      if (!recsColumns.contains('internal_reasoning')) {
        await customStatement('ALTER TABLE survey_recommendations ADD COLUMN internal_reasoning TEXT');
      }
      if (!recsColumns.contains('audit_hash')) {
        await customStatement('ALTER TABLE survey_recommendations ADD COLUMN audit_hash TEXT');
      }
    }

    // Check generated_reports table columns
    final reportsResult = await customSelect('PRAGMA table_info(generated_reports)').get();
    final reportsColumns = reportsResult.map((row) => row.read<String>('name')).toSet();

    if (!reportsColumns.contains('module_type')) {
      await customStatement("ALTER TABLE generated_reports ADD COLUMN module_type TEXT DEFAULT 'inspection'");
    }
    if (!reportsColumns.contains('format')) {
      await customStatement("ALTER TABLE generated_reports ADD COLUMN format TEXT DEFAULT 'pdf'");
    }
    if (!reportsColumns.contains('style')) {
      await customStatement("ALTER TABLE generated_reports ADD COLUMN style TEXT DEFAULT 'legacy'");
    }
    if (!reportsColumns.contains('remote_url')) {
      await customStatement('ALTER TABLE generated_reports ADD COLUMN remote_url TEXT');
    }
    if (!reportsColumns.contains('checksum')) {
      await customStatement("ALTER TABLE generated_reports ADD COLUMN checksum TEXT DEFAULT ''");
    }
  }

  /// Delete all rows from every table in a single transaction.
  /// Used by "Clear All Storage" to wipe local data cleanly before
  /// closing the database connection.
  ///
  /// Deletion order respects foreign-key-like dependencies:
  /// child tables first, then parent tables.
  Future<void> deleteEverything() async {
    await transaction(() async {
      // Child tables first
      await delete(photoAnnotations).go();
      await delete(surveyQualityScores).go();
      await delete(surveyRecommendations).go();
      await delete(generatedReports).go();
      await delete(signatures).go();
      await delete(mediaItems).go();
      await delete(inspectionV2Answers).go();
      await delete(inspectionV2Screens).go();
      await delete(surveyAnswers).go();
      await delete(surveySections).go();
      await delete(syncQueue).go();
      // Parent table last
      await delete(surveys).go();
    });
  }

  /// Helper to safely add a column only if it doesn't already exist
  Future<void> _addColumnIfNotExists(
    Migrator m,
    String tableName,
    String columnName,
    String columnType,
  ) async {
    final result = await customSelect(
      'PRAGMA table_info($tableName)',
    ).get();

    final columnExists = result.any(
      (row) => row.read<String>('name') == columnName,
    );

    if (!columnExists) {
      await m.issueCustomQuery('ALTER TABLE $tableName ADD COLUMN $columnName $columnType');
    }
  }
}
