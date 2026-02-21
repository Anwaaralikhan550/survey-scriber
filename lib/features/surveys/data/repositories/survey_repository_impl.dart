import '../../../../core/database/daos/survey_answers_dao.dart';
import '../../../../core/database/daos/survey_sections_dao.dart';
import '../../../../core/database/daos/surveys_dao.dart';
import '../../../../shared/domain/entities/survey.dart';
import '../../../../shared/domain/entities/survey_answer.dart';
import '../../../../shared/domain/entities/survey_section.dart';
import '../../domain/repositories/survey_repository.dart';

/// Callback for survey changes (create/update/status change).
/// Used to queue sync operations.
typedef OnSurveyChanged = Future<void> Function(String surveyId);

class SurveyRepositoryImpl implements SurveyRepository {
  SurveyRepositoryImpl({
    required SurveysDao surveysDao,
    required SurveySectionsDao sectionsDao,
    required SurveyAnswersDao answersDao,
    this.onSurveyChanged,
  })  : _surveysDao = surveysDao,
        _sectionsDao = sectionsDao,
        _answersDao = answersDao;

  final SurveysDao _surveysDao;
  final SurveySectionsDao _sectionsDao;
  final SurveyAnswersDao _answersDao;

  /// Callback to notify when a survey is modified (for sync).
  final OnSurveyChanged? onSurveyChanged;

  // Survey CRUD
  @override
  Future<List<Survey>> getAllSurveys() => _surveysDao.getAllSurveys();

  @override
  Future<Survey?> getSurveyById(String id) => _surveysDao.getSurveyById(id);

  @override
  Future<List<Survey>> getRecentSurveys({int limit = 5}) =>
      _surveysDao.getRecentSurveys(limit: limit);

  @override
  Future<List<Survey>> getSurveysByStatus(SurveyStatus status) =>
      _surveysDao.getSurveysByStatus(status);

  @override
  Future<List<Survey>> getInProgressSurveys() =>
      _surveysDao.getInProgressSurveys();

  @override
  Future<List<Survey>> getCompletedSurveys() =>
      _surveysDao.getCompletedSurveys();

  @override
  Future<void> createSurvey(Survey survey) async {
    await _surveysDao.insertSurvey(survey);
    _notifyChange(survey.id);
  }

  @override
  Future<void> updateSurvey(Survey survey) async {
    await _surveysDao.updateSurvey(survey);
    _notifyChange(survey.id);
  }

  @override
  Future<void> deleteSurvey(String id) async {
    await _answersDao.deleteAnswersForSurvey(id);
    await _sectionsDao.deleteSectionsForSurvey(id);
    await _surveysDao.deleteSurvey(id);
    // Note: Deletion sync is complex (soft delete vs hard delete).
    // For now, we focus on create/update sync.
  }

  @override
  Future<void> updateSurveyStatus(String surveyId, SurveyStatus status) async {
    await _surveysDao.updateSurveyStatus(surveyId, status);
    _notifyChange(surveyId);
  }

  // Statistics
  @override
  Future<int> getTotalSurveyCount() => _surveysDao.getTotalSurveyCount();

  @override
  Future<int> getInProgressCount() => _surveysDao.getInProgressCount();

  @override
  Future<int> getCompletedCount() => _surveysDao.getCompletedCount();

  // Sections
  @override
  Future<List<SurveySection>> getSectionsForSurvey(String surveyId) async {
    final sections = await _sectionsDao.getSectionsForSurvey(surveyId);
    final hydratedSections = <SurveySection>[];
    for (final section in sections) {
      final answers = await _answersDao.getAnswersForSection(section.id);
      hydratedSections.add(section.copyWith(answers: answers));
    }
    return hydratedSections;
  }

  @override
  Future<SurveySection?> getSectionById(String id) =>
      _sectionsDao.getSectionById(id);

  @override
  Future<void> createSections(List<SurveySection> sections) async {
    await _sectionsDao.insertSections(sections);
    if (sections.isNotEmpty) {
      _notifyChange(sections.first.surveyId);
    }
  }

  @override
  Future<void> updateSection(SurveySection section) async {
    await _sectionsDao.updateSection(section);
    _notifyChange(section.surveyId);
  }

  @override
  Future<void> markSectionCompleted(String sectionId, {required bool isCompleted}) async {
    await _sectionsDao.markSectionCompleted(sectionId, isCompleted: isCompleted);
    final section = await _sectionsDao.getSectionById(sectionId);
    if (section != null) {
      _notifyChange(section.surveyId);
    }
  }

  // Answers
  @override
  Future<List<SurveyAnswer>> getAnswersForSection(String sectionId) =>
      _answersDao.getAnswersForSection(sectionId);

  @override
  Future<Map<String, String>> getSectionAnswersMap(String sectionId) =>
      _answersDao.getSectionAnswersMap(sectionId);

  @override
  Future<void> saveAnswer(SurveyAnswer answer) async {
    await _answersDao.saveAnswer(answer);
    final section = await _sectionsDao.getSectionById(answer.sectionId);
    if (section != null) {
      _notifyChange(section.surveyId);
    }
  }

  @override
  Future<void> saveAnswers(List<SurveyAnswer> answers) async {
    await _answersDao.saveAnswers(answers);
    if (answers.isNotEmpty) {
      final section = await _sectionsDao.getSectionById(answers.first.sectionId);
      if (section != null) {
        _notifyChange(section.surveyId);
      }
    }
  }

  // Progress
  @override
  Future<void> recalculateSurveyProgress(String surveyId) async {
    final completedCount = await _sectionsDao.getCompletedSectionsCount(surveyId);
    final totalCount = await _sectionsDao.getTotalSectionsCount(surveyId);
    await _surveysDao.updateSurveyProgress(surveyId, completedCount, totalCount);

    if (totalCount > 0 && completedCount == totalCount) {
      final survey = await _surveysDao.getSurveyById(surveyId);
      if (survey != null &&
          (survey.status == SurveyStatus.inProgress ||
           survey.status == SurveyStatus.draft)) {
        await _surveysDao.updateSurveyStatus(surveyId, SurveyStatus.completed);
      }
    }
    
    _notifyChange(surveyId);
  }

  void _notifyChange(String surveyId) {
    // Fire and forget, don't await
    onSurveyChanged?.call(surveyId).ignore();
  }
}

extension FutureIgnore on Future {
  void ignore() {}
}
