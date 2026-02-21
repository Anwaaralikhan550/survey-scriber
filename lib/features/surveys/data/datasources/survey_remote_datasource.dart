
import '../../../../core/network/api_client.dart';
import '../../../../shared/domain/entities/survey.dart';
import '../../../../shared/domain/entities/survey_answer.dart';
import '../../../../shared/domain/entities/survey_section.dart';

class SurveyRemoteDataSource {
  const SurveyRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<void> createSurvey({
    required Survey survey,
    required List<SurveySection> sections,
    required List<SurveyAnswer> answers,
  }) async {
    final data = _mapToDto(survey, sections, answers);
    await _apiClient.post<dynamic>(
      'surveys',
      data: data,
    );
  }

  Future<void> updateSurvey({
    required Survey survey,
    required List<SurveySection> sections,
    required List<SurveyAnswer> answers,
  }) async {
    final data = _mapToDto(survey, sections, answers);
    await _apiClient.put<dynamic>(
      'surveys/${survey.id}',
      data: data,
    );
  }

  Map<String, dynamic> _mapToDto(
    Survey survey,
    List<SurveySection> sections,
    List<SurveyAnswer> answers,
  ) {
    // Group answers by section
    final answersBySection = <String, List<SurveyAnswer>>{};
    for (final answer in answers) {
      if (!answersBySection.containsKey(answer.sectionId)) {
        answersBySection[answer.sectionId] = [];
      }
      answersBySection[answer.sectionId]!.add(answer);
    }

    return {
      'id': survey.id,
      'title': survey.title,
      'propertyAddress': survey.address,
      'status': survey.status.name.toUpperCase(),
      'type': survey.type.name.toUpperCase(),
      if (survey.jobRef != null) 'jobRef': survey.jobRef,
      if (survey.clientName != null) 'clientName': survey.clientName,
      if (survey.parentSurveyId != null) 'parentSurveyId': survey.parentSurveyId,
      'sections': sections.map((section) {
        final sectionAnswers = answersBySection[section.id] ?? [];
        return {
          'title': section.title,
          'order': section.order,
          'answers': sectionAnswers.map((a) => {
            'questionKey': a.fieldKey,
            'value': a.value,
          },).toList(),
        };
      }).toList(),
    };
  }
}
