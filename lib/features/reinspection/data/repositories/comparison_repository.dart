import '../../../../core/database/daos/media_dao.dart';
import '../../../../core/database/daos/signature_dao.dart';
import '../../../../core/database/daos/survey_answers_dao.dart';
import '../../../../core/database/daos/survey_sections_dao.dart';
import '../../../../core/database/daos/surveys_dao.dart';
import '../../../../shared/domain/entities/survey.dart';
import '../../../media/domain/entities/media_item.dart';
import '../../../signature/domain/entities/signature_item.dart';
import '../../domain/entities/comparison_result.dart';
import '../../domain/services/survey_comparison_service.dart';

/// Repository for fetching and comparing survey data
class ComparisonRepository {
  const ComparisonRepository({
    required this.surveysDao,
    required this.sectionsDao,
    required this.answersDao,
    required this.mediaDao,
    required this.signatureDao,
    SurveyComparisonService? comparisonService,
  }) : _comparisonService = comparisonService ?? const SurveyComparisonService();

  final SurveysDao surveysDao;
  final SurveySectionsDao sectionsDao;
  final SurveyAnswersDao answersDao;
  final MediaDao mediaDao;
  final SignatureDao signatureDao;
  final SurveyComparisonService _comparisonService;

  /// Compare two surveys by their IDs
  Future<ComparisonResult?> compareSurveys({
    required String previousSurveyId,
    required String currentSurveyId,
  }) async {
    // Fetch both surveys
    final previousSurvey = await surveysDao.getSurveyById(previousSurveyId);
    final currentSurvey = await surveysDao.getSurveyById(currentSurveyId);

    if (previousSurvey == null || currentSurvey == null) {
      return null;
    }

    // Fetch sections for both surveys
    final previousSections = await sectionsDao.getSectionsForSurvey(previousSurveyId);
    final currentSections = await sectionsDao.getSectionsForSurvey(currentSurveyId);

    // Fetch answers for both surveys (grouped by section)
    final previousAnswers = await _getAnswersBySections(previousSections);
    final currentAnswers = await _getAnswersBySections(currentSections);

    // Fetch media for both surveys (grouped by section)
    final previousMedia = await _getMediaBySections(previousSections);
    final currentMedia = await _getMediaBySections(currentSections);

    // Fetch signatures for both surveys
    final previousSignatures = await _getSignatures(previousSurveyId);
    final currentSignatures = await _getSignatures(currentSurveyId);

    // Perform comparison
    return _comparisonService.compareSurveys(
      previousSurvey: previousSurvey,
      currentSurvey: currentSurvey,
      previousSections: previousSections,
      currentSections: currentSections,
      previousAnswers: previousAnswers,
      currentAnswers: currentAnswers,
      previousMedia: previousMedia,
      currentMedia: currentMedia,
      previousSignatures: previousSignatures,
      currentSignatures: currentSignatures,
    );
  }

  /// Get the parent survey for a re-inspection
  Future<Survey?> getParentSurvey(String surveyId) async {
    final survey = await surveysDao.getSurveyById(surveyId);
    if (survey?.parentSurveyId == null) return null;
    return surveysDao.getSurveyById(survey!.parentSurveyId!);
  }

  /// Get all re-inspections for a survey
  Future<List<Survey>> getReinspections(String surveyId) async => surveysDao.getReinspections(surveyId);

  /// Check if a survey has a parent (is a re-inspection)
  Future<bool> isReinspection(String surveyId) async {
    final survey = await surveysDao.getSurveyById(surveyId);
    return survey?.parentSurveyId != null;
  }

  /// Check if a survey has any re-inspections
  Future<bool> hasReinspections(String surveyId) async => surveysDao.hasReinspections(surveyId);

  /// Get the full inspection history (original + all re-inspections)
  Future<List<Survey>> getInspectionHistory(String surveyId) async {
    final survey = await surveysDao.getSurveyById(surveyId);
    if (survey == null) return [];

    // Find the root survey
    var rootId = surveyId;
    if (survey.parentSurveyId != null) {
      rootId = survey.parentSurveyId!;
    }

    // Get the root survey
    final rootSurvey = await surveysDao.getSurveyById(rootId);
    if (rootSurvey == null) return [];

    // Get all re-inspections
    final reinspections = await surveysDao.getReinspections(rootId);

    return [rootSurvey, ...reinspections];
  }

  /// Get the latest completed re-inspection for comparison
  Future<Survey?> getLatestCompletedReinspection(String parentSurveyId) async {
    final reinspections = await surveysDao.getReinspections(parentSurveyId);

    // Find the latest completed one
    for (final reinspection in reinspections.reversed) {
      if (reinspection.isCompleted) {
        return reinspection;
      }
    }

    return null;
  }

  /// Fetch answers grouped by section ID
  Future<Map<String, Map<String, String>>> _getAnswersBySections(
    List<dynamic> sections,
  ) async {
    final result = <String, Map<String, String>>{};

    for (final section in sections) {
      final answers = await answersDao.getSectionAnswersMap(section.id);
      if (answers.isNotEmpty) {
        result[section.id] = answers;
      }
    }

    return result;
  }

  /// Fetch media items grouped by section ID
  Future<Map<String, List<MediaItem>>> _getMediaBySections(
    List<dynamic> sections,
  ) async {
    final result = <String, List<MediaItem>>{};

    for (final section in sections) {
      final mediaItems = await mediaDao.getPhotosBySection(section.id);
      final photos = mediaItems.map(mediaDao.toPhotoItem).toList();
      if (photos.isNotEmpty) {
        result[section.id] = photos;
      }
    }

    return result;
  }

  /// Fetch signatures for a survey
  Future<List<SignatureItem>> _getSignatures(String surveyId) async {
    final signatureData = await signatureDao.getSignaturesBySurvey(surveyId);
    return signatureData.map(signatureDao.toSignatureItem).toList();
  }
}
