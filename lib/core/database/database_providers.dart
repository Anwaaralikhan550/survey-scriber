import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';
import 'daos/generated_reports_dao.dart';
import 'daos/media_dao.dart';
import 'daos/signature_dao.dart';
import 'daos/survey_answers_dao.dart';
import 'daos/survey_quality_scores_dao.dart';
import 'daos/survey_recommendations_dao.dart';
import 'daos/survey_sections_dao.dart';
import 'daos/surveys_dao.dart';
import 'daos/sync_queue_dao.dart';

/// Provider for the main database instance
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Provider for SurveysDao
final surveysDaoProvider = Provider<SurveysDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return SurveysDao(db);
});

/// Provider for SurveySectionsDao
final surveySectionsDaoProvider = Provider<SurveySectionsDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return SurveySectionsDao(db);
});

/// Provider for SurveyAnswersDao
final surveyAnswersDaoProvider = Provider<SurveyAnswersDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return SurveyAnswersDao(db);
});

/// Provider for SyncQueueDao
final syncQueueDaoProvider = Provider<SyncQueueDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.syncQueueDao;
});

/// Provider for MediaDao
final mediaDaoProvider = Provider<MediaDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.mediaDao;
});

/// Provider for SignatureDao
final signatureDaoProvider = Provider<SignatureDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.signatureDao;
});

/// Provider for GeneratedReportsDao
final generatedReportsDaoProvider = Provider<GeneratedReportsDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.generatedReportsDao;
});

/// Provider for SurveyRecommendationsDao
final surveyRecommendationsDaoProvider =
    Provider<SurveyRecommendationsDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.surveyRecommendationsDao;
});

/// Provider for SurveyQualityScoresDao
final surveyQualityScoresDaoProvider =
    Provider<SurveyQualityScoresDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.surveyQualityScoresDao;
});
