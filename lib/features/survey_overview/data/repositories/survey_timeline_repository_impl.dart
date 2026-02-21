import '../../../../shared/domain/entities/timeline_event.dart';
import '../../../../shared/domain/services/timeline_event_service.dart';
import '../../../surveys/domain/repositories/survey_repository.dart';
import '../../domain/repositories/survey_timeline_repository.dart';

/// Implementation of [SurveyTimelineRepository] that aggregates
/// timeline events from survey and section data.
///
/// This is a READ-ONLY repository - it does not modify any data.
class SurveyTimelineRepositoryImpl implements SurveyTimelineRepository {
  SurveyTimelineRepositoryImpl({
    required SurveyRepository surveyRepository,
    TimelineEventService? timelineService,
  })  : _surveyRepository = surveyRepository,
        _timelineService = timelineService ?? TimelineEventService.instance;

  final SurveyRepository _surveyRepository;
  final TimelineEventService _timelineService;

  @override
  Future<List<TimelineEvent>> getTimelineEvents(String surveyId) async {
    try {
      // Fetch survey and sections from existing repository
      final survey = await _surveyRepository.getSurveyById(surveyId);
      if (survey == null) {
        return [];
      }

      final sections = await _surveyRepository.getSectionsForSurvey(surveyId);

      // Generate timeline events using the service
      return _timelineService.generateTimelineEvents(
        survey: survey,
        sections: sections,
      );
    } catch (e) {
      // Gracefully handle errors - return empty list
      return [];
    }
  }
}
