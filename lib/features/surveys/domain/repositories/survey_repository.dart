import '../../../../shared/domain/entities/survey.dart';
import '../../../../shared/domain/entities/survey_answer.dart';
import '../../../../shared/domain/entities/survey_section.dart';

/// Repository interface for survey operations
abstract class SurveyRepository {
  // Survey CRUD
  Future<List<Survey>> getAllSurveys();
  Future<Survey?> getSurveyById(String id);
  Future<List<Survey>> getRecentSurveys({int limit = 5});
  Future<List<Survey>> getSurveysByStatus(SurveyStatus status);
  Future<List<Survey>> getInProgressSurveys();
  Future<List<Survey>> getCompletedSurveys();
  Future<void> createSurvey(Survey survey);
  Future<void> updateSurvey(Survey survey);
  Future<void> deleteSurvey(String id);
  Future<void> updateSurveyStatus(String surveyId, SurveyStatus status);

  // Statistics
  Future<int> getTotalSurveyCount();
  Future<int> getInProgressCount();
  Future<int> getCompletedCount();

  // Sections
  Future<List<SurveySection>> getSectionsForSurvey(String surveyId);
  Future<SurveySection?> getSectionById(String id);
  Future<void> createSections(List<SurveySection> sections);
  Future<void> updateSection(SurveySection section);
  Future<void> markSectionCompleted(String sectionId, {required bool isCompleted});

  // Answers
  Future<List<SurveyAnswer>> getAnswersForSection(String sectionId);
  Future<Map<String, String>> getSectionAnswersMap(String sectionId);
  Future<void> saveAnswer(SurveyAnswer answer);
  Future<void> saveAnswers(List<SurveyAnswer> answers);

  // Progress
  Future<void> recalculateSurveyProgress(String surveyId);
}
