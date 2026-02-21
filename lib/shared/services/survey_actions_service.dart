import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/router/routes.dart';
import '../../features/dashboard/presentation/providers/dashboard_provider.dart';
import '../../features/forms/presentation/providers/forms_provider.dart';
import '../../features/surveys/presentation/providers/survey_providers.dart';
import '../domain/entities/survey.dart';

/// Reusable service for survey-related actions (Share, Delete, etc.)
/// Use this service to ensure consistent behavior across the entire app.
class SurveyActionsService {
  SurveyActionsService._();

  static final instance = SurveyActionsService._();

  // ============================================
  // SHARE FUNCTIONALITY
  // ============================================

  /// Share a survey's details using native OS share sheet.
  /// Works on both Android and iOS.
  ///
  /// Parameters:
  /// - [survey]: The survey to share
  /// - [context]: BuildContext for error handling
  Future<void> shareSurvey(Survey survey, BuildContext context) async {
    final statusText = _getStatusText(survey.status);
    final typeText = _getTypeText(survey.type);

    final shareText = StringBuffer()
      ..writeln('Survey Details')
      ..writeln('─────────────────')
      ..writeln('Title: ${survey.title}')
      ..writeln('Type: $typeText')
      ..writeln('Status: $statusText');

    if (survey.address != null && survey.address!.isNotEmpty) {
      shareText.writeln('Address: ${survey.address}');
    }
    if (survey.clientName != null && survey.clientName!.isNotEmpty) {
      shareText.writeln('Client: ${survey.clientName}');
    }
    if (survey.jobRef != null && survey.jobRef!.isNotEmpty) {
      shareText.writeln('Job Ref: ${survey.jobRef}');
    }

    shareText
      ..writeln('─────────────────')
      ..writeln('Survey ID: ${survey.id}');

    try {
      await Share.share(
        shareText.toString(),
        subject: 'Survey: ${survey.title}',
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to share: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Share a photo file using native OS share sheet.
  ///
  /// Parameters:
  /// - [filePath]: Path to the photo file
  /// - [caption]: Optional caption for the photo
  /// - [context]: BuildContext for error handling
  Future<void> sharePhoto({
    required String filePath,
    String? caption,
    required BuildContext context,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo file not found'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      await Share.shareXFiles(
        [XFile(filePath)],
        text: caption,
        subject: 'Photo from Survey',
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to share photo: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Share a media file (photo, audio, video) using native OS share sheet.
  Future<void> shareMedia({
    required String filePath,
    String? text,
    String? subject,
    required BuildContext context,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File not found'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      await Share.shareXFiles(
        [XFile(filePath)],
        text: text,
        subject: subject ?? 'Media from Survey',
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to share: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ============================================
  // DELETE FUNCTIONALITY
  // ============================================

  /// Show delete confirmation dialog and delete survey if confirmed.
  /// Handles navigation after successful deletion.
  ///
  /// Parameters:
  /// - [context]: BuildContext for showing dialog and navigation
  /// - [ref]: WidgetRef for accessing providers
  /// - [surveyId]: The ID of the survey to delete
  /// - [surveyTitle]: The title of the survey (for display)
  /// - [navigateAfterDelete]: Where to navigate after deletion (defaults to forms page)
  Future<bool> confirmAndDeleteSurvey({
    required BuildContext context,
    required WidgetRef ref,
    required String surveyId,
    required String surveyTitle,
    String? navigateAfterDelete,
  }) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.delete_outline_rounded,
                color: colorScheme.error,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Delete Survey?'),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete "$surveyTitle"?',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 20,
                    color: colorScheme.error,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This action cannot be undone. All survey data, sections, and media will be permanently deleted.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return false;

    // Perform delete
    try {
      final repository = ref.read(localSurveyRepositoryProvider);
      await repository.deleteSurvey(surveyId);

      // Invalidate list providers so they refresh without deleted survey
      ref.invalidate(dashboardProvider);
      ref.invalidate(formsProvider);

      if (!context.mounted) return true;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Survey deleted successfully'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );

      // Navigate away
      if (navigateAfterDelete != null) {
        context.go(navigateAfterDelete);
      } else {
        context.go(Routes.forms);
      }

      return true;
    } catch (e) {
      if (!context.mounted) return false;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete survey: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: colorScheme.error,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );

      return false;
    }
  }

  // ============================================
  // HELPER METHODS
  // ============================================

  String _getStatusText(SurveyStatus status) => switch (status) {
      SurveyStatus.draft => 'Draft',
      SurveyStatus.inProgress => 'In Progress',
      SurveyStatus.paused => 'Paused',
      SurveyStatus.completed => 'Completed',
      SurveyStatus.pendingReview => 'Pending Review',
      SurveyStatus.approved => 'Approved',
      SurveyStatus.rejected => 'Rejected',
    };

  String _getTypeText(SurveyType type) => type.displayName;
}

/// Provider for the survey actions service
final surveyActionsServiceProvider = Provider<SurveyActionsService>(
  (ref) => SurveyActionsService.instance,
);
