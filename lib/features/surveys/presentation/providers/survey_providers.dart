import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_providers.dart';
import '../../../../core/sync/sync_manager.dart';
import '../../../../core/sync/sync_state.dart';
import '../../../../features/config/presentation/helpers/config_aware_fields.dart';
import '../../data/repositories/survey_repository_impl.dart';
import '../../domain/repositories/survey_repository.dart';

/// Provider for SurveyRepository
final localSurveyRepositoryProvider = Provider<SurveyRepository>(
  (ref) => SurveyRepositoryImpl(
    surveysDao: ref.watch(surveysDaoProvider),
    sectionsDao: ref.watch(surveySectionsDaoProvider),
    answersDao: ref.watch(surveyAnswersDaoProvider),
    onSurveyChanged: (surveyId) async {
      // When survey changes locally, we queue a sync operation
      // We use the "Composite Sync" pattern: fetching the full survey data
      // and queuing it as a single update to ensure consistency.
      try {
        final surveyDao = ref.read(surveysDaoProvider);
        final sectionsDao = ref.read(surveySectionsDaoProvider);
        final answersDao = ref.read(surveyAnswersDaoProvider);

        final survey = await surveyDao.getSurveyById(surveyId);
        if (survey == null) return;

        // Fetch all sections and answers to build full payload
        final sections = await sectionsDao.getSectionsForSurvey(surveyId);
        final hydratedSections = <Map<String, dynamic>>[];

        for (final section in sections) {
          final answers = await answersDao.getAnswersForSection(section.id);
          // Filter out answers with empty/null values — backend rejects empty
          // strings with @IsNotEmpty() validation. Empty answers are optional
          // fields that haven't been filled in yet.
          final nonEmptyAnswers = answers
              .where((a) => a.value != null && a.value!.trim().isNotEmpty)
              .toList();
          hydratedSections.add({
            'title': section.title,
            'order': section.order,
            'sectionTypeKey': section.sectionType.apiSectionType,
            if (nonEmptyAnswers.isNotEmpty)
              'answers': nonEmptyAnswers.map((a) => {
                'questionKey': a.fieldKey,
                'value': a.value,
              },).toList(),
          });
        }

        final payload = {
          'title': survey.title,
          'propertyAddress': survey.address ?? '',
          'status': survey.status.toBackendString(),
          'type': survey.type.toBackendString(),
          if (survey.jobRef != null) 'jobRef': survey.jobRef,
          if (survey.clientName != null) 'clientName': survey.clientName,
          if (survey.parentSurveyId != null) 'parentSurveyId': survey.parentSurveyId,
          'sections': hydratedSections,
        };

        // Queue for sync
        await ref.read(syncStateProvider.notifier).queueSync(
              entityType: SyncEntityType.survey,
              entityId: surveyId,
              action: SyncAction.create, // Backend handles upsert
              payload: payload,
            );
      } catch (e) {
        // Log but don't crash - sync will happen on next change or retry
        print('Failed to queue sync for survey $surveyId: $e');
      }
    },
  ),
);
