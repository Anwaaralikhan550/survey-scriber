import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_providers.dart';
import '../../../../core/sync/sync_manager.dart';
import '../../../../core/sync/sync_state.dart';
import '../../../../core/utils/logger.dart';
import '../../../../shared/domain/entities/survey.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import 'survey_invalidation.dart';

/// Which Survey Folder a job sits in follows what the surveyor does with it:
/// a booking's inspection starts in Live, the first answer moves it to In
/// Progress, the first report moves it to Completed. A completed survey stays
/// open for editing and further reports, and stays in Completed.
class SurveyLifecycle {
  SurveyLifecycle(this._ref);

  final Ref _ref;

  // These write through the DAO, not the survey repository. The repository's
  // change hook sends the whole survey with its legacy section list, which a
  // tree-based survey does not use, and the server would replace its sections.
  Future<void> _moveTo(String surveyId, SurveyStatus status) async {
    await _ref.read(surveysDaoProvider).updateSurveyStatus(surveyId, status);
    await _ref.read(syncStateProvider.notifier).queueSync(
      entityType: SyncEntityType.survey,
      entityId: surveyId,
      action: SyncAction.update,
      payload: {'status': status.toBackendString()},
    );
    _ref.invalidate(dashboardProvider);
    _ref.invalidate(jobsListProvider);
  }

  /// The surveyor saved an answer.
  Future<void> markStarted(String surveyId) async {
    try {
      final survey = await _ref.read(surveysDaoProvider).getSurveyById(surveyId);
      if (survey?.status == SurveyStatus.draft) {
        await _moveTo(surveyId, SurveyStatus.inProgress);
      }
    } catch (e) {
      // Never let the folder move get in the way of saving the survey.
      AppLogger.w('SurveyLifecycle', 'markStarted failed: $e');
    }
  }

  /// A report was generated.
  Future<void> markReportGenerated(String surveyId) async {
    try {
      final survey = await _ref.read(surveysDaoProvider).getSurveyById(surveyId);
      if (survey == null) return;
      if (survey.status == SurveyStatus.draft ||
          survey.status == SurveyStatus.inProgress ||
          survey.status == SurveyStatus.paused) {
        await _moveTo(surveyId, SurveyStatus.completed);
      } else {
        _ref.invalidate(jobsListProvider);
      }
    } catch (e) {
      AppLogger.w('SurveyLifecycle', 'markReportGenerated failed: $e');
    }
  }

  /// The newest report on this phone, PDF first. Null when there is none.
  Future<GeneratedReportData?> latestReport(String surveyId) async {
    final reports = await _ref
        .read(generatedReportsDaoProvider)
        .getReportsForSurvey(surveyId);
    if (reports.isEmpty) return null;
    final byNewest = [...reports]
      ..sort((a, b) => b.generatedAt.compareTo(a.generatedAt));
    return byNewest.firstWhere(
      (r) => r.format == 'pdf',
      orElse: () => byNewest.first,
    );
  }

  /// Removes the survey and its reports from this phone and from the server.
  /// A booking keeps going and can start a new inspection.
  Future<void> delete(String surveyId) async {
    final reports = _ref.read(generatedReportsDaoProvider);
    if (!kIsWeb) {
      for (final report in await reports.getReportsForSurvey(surveyId)) {
        try {
          final file = File(report.filePath);
          if (await file.exists()) await file.delete();
        } catch (e) {
          AppLogger.w('SurveyLifecycle', 'Report file not deleted: $e');
        }
      }
    }
    await reports.deleteReportsForSurvey(surveyId);
    await _ref.read(surveyAnswersDaoProvider).deleteAnswersForSurvey(surveyId);
    await _ref.read(surveySectionsDaoProvider).deleteSectionsForSurvey(surveyId);
    await _ref.read(surveysDaoProvider).deleteSurvey(surveyId);
    await _ref.read(syncStateProvider.notifier).queueSync(
      entityType: SyncEntityType.survey,
      entityId: surveyId,
      action: SyncAction.delete,
      payload: const {},
    );
    SurveyInvalidation.afterBulkMutation(_ref);
  }
}

final surveyLifecycleProvider = Provider<SurveyLifecycle>(SurveyLifecycle.new);
