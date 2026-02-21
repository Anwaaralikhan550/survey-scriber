import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../shared/domain/entities/survey_action.dart';
import '../../../../shared/domain/services/survey_action_resolver.dart';
import '../../../../shared/services/survey_actions_service.dart';
import '../../../report_export/domain/models/report_document.dart';
import '../../../report_export/presentation/widgets/export_bottom_sheet.dart';
import '../providers/survey_overview_provider.dart';

/// Card widget displaying survey actions (primary + secondary).
/// Handles action execution through the provider.
class SurveyActionsCard extends ConsumerWidget {
  const SurveyActionsCard({
    required this.surveyId,
    super.key,
  });

  final String surveyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(surveyOverviewProvider(surveyId));
    final theme = Theme.of(context);

    if (!state.hasSurvey || !state.hasActions) {
      return const SizedBox.shrink();
    }

    final primaryAction = state.primaryAction;
    final secondaryActions = state.secondaryActions;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        0,
      ),
      child: Container(
        padding: AppSpacing.paddingMd,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: AppSpacing.borderRadiusLg,
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withOpacity(0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.bolt_rounded,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                AppSpacing.gapHorizontalSm,
                Text(
                  'Actions',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
            AppSpacing.gapVerticalMd,

            // Primary action button
            if (primaryAction != null) ...[
              _PrimaryActionButton(
                surveyId: surveyId,
                action: primaryAction,
                isLoading: state.isUpdatingStatus,
              ),
            ],

            // Secondary actions
            if (secondaryActions.isNotEmpty) ...[
              AppSpacing.gapVerticalMd,
              _SecondaryActionsRow(
                surveyId: surveyId,
                actions: secondaryActions,
                isLoading: state.isUpdatingStatus,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PrimaryActionButton extends ConsumerWidget {
  const _PrimaryActionButton({
    required this.surveyId,
    required this.action,
    required this.isLoading,
  });

  final String surveyId;
  final SurveyActionUiModel action;
  final bool isLoading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return FilledButton(
      onPressed: action.isEnabled && !isLoading
          ? () => _handleAction(context, ref)
          : null,
      style: FilledButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
        shape: const RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusMd,
        ),
      ),
      child: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.onPrimary,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(action.action.icon, size: 20),
                AppSpacing.gapHorizontalSm,
                Flexible(
                  child: Text(
                    action.label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _handleAction(BuildContext context, WidgetRef ref) async {
    final state = ref.read(surveyOverviewProvider(surveyId));
    final survey = state.survey;

    // Handle Share action specially using service
    if (action.action == SurveyAction.share && survey != null) {
      await SurveyActionsService.instance.shareSurvey(survey, context);
      return;
    }

    // Handle Delete action specially using service
    if (action.action == SurveyAction.delete && survey != null) {
      await SurveyActionsService.instance.confirmAndDeleteSurvey(
        context: context,
        ref: ref,
        surveyId: surveyId,
        surveyTitle: survey.title,
      );
      return;
    }

    // Handle Export PDF action - show PDF export dialog
    if (action.action == SurveyAction.exportPdf && survey != null) {
      await ExportBottomSheet.show(
        context,
        surveyId: surveyId,
        surveyTitle: survey.title,
        reportType: survey.type.isValuation
            ? ReportType.valuation
            : ReportType.inspection,
      );
      return;
    }

    // Handle View Report action - show PDF export dialog (same as export)
    if (action.action == SurveyAction.viewReport && survey != null) {
      await ExportBottomSheet.show(
        context,
        surveyId: surveyId,
        surveyTitle: survey.title,
        reportType: survey.type.isValuation
            ? ReportType.valuation
            : ReportType.inspection,
      );
      return;
    }

    // Check if confirmation is required
    if (action.requiresConfirmation) {
      final confirmed = await _showConfirmationDialog(context, action.action);
      if (confirmed != true) return;
    }

    // Execute the action
    final intent = await ref
        .read(surveyOverviewProvider(surveyId).notifier)
        .handleAction(action.action);

    if (!context.mounted) return;

    // Handle navigation intent
    _handleNavigationIntent(context, intent);
  }

  Future<bool?> _showConfirmationDialog(
    BuildContext context,
    SurveyAction action,
  ) async {
    final content = SurveyActionResolver.instance.getConfirmationContent(action);
    if (content == null) return true;

    return showDialog<bool>(
      context: context,
      builder: (context) => _ConfirmationDialog(
        title: content.title,
        message: content.message,
        confirmLabel: content.confirmLabel,
        isDestructive: action == SurveyAction.delete ||
            action == SurveyAction.reject,
      ),
    );
  }

  void _handleNavigationIntent(BuildContext context, ActionNavigationIntent intent) {
    switch (intent) {
      case NavigateToSection():
        context.push(Routes.inspectionDetailPath(surveyId));
      case StayOnScreen():
        // Refresh will happen automatically via provider
        break;
      case NavigateToReport():
        // Show PDF export dialog - this case shouldn't normally be reached
        // since we intercept exportPdf/viewReport actions before handleAction()
        _showPdfExportForReport(context);
      case ShowMessage(:final message, :final isError):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            behavior: SnackBarBehavior.floating,
            backgroundColor: isError ? AppColors.error : null,
          ),
        );
      case ActionNotImplemented(:final actionLabel):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$actionLabel coming soon'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  void _showPdfExportForReport(BuildContext context) {
    // Get survey title from provider state
    // This is a fallback path - normally intercepted before handleAction()
    ExportBottomSheet.show(
      context,
      surveyId: surveyId,
      surveyTitle: 'Survey Report',
      reportType: ReportType.inspection,
    );
  }
}

class _SecondaryActionsRow extends ConsumerWidget {
  const _SecondaryActionsRow({
    required this.surveyId,
    required this.actions,
    required this.isLoading,
  });

  final String surveyId;
  final List<SurveyActionUiModel> actions;
  final bool isLoading;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: actions.map((action) => _SecondaryActionChip(
          surveyId: surveyId,
          action: action,
          isLoading: isLoading,
        ),).toList(),
    );
}

class _SecondaryActionChip extends ConsumerWidget {
  const _SecondaryActionChip({
    required this.surveyId,
    required this.action,
    required this.isLoading,
  });

  final String surveyId;
  final SurveyActionUiModel action;
  final bool isLoading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDestructive = action.action == SurveyAction.delete ||
        action.action == SurveyAction.reject;

    return OutlinedButton.icon(
      onPressed: action.isEnabled && !isLoading
          ? () => _handleAction(context, ref)
          : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: isDestructive
            ? theme.colorScheme.error
            : theme.colorScheme.onSurface,
        side: BorderSide(
          color: isDestructive
              ? theme.colorScheme.error.withOpacity(0.5)
              : theme.colorScheme.outline.withOpacity(0.5),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusMd,
        ),
      ),
      icon: Icon(
        action.action.icon,
        size: 18,
        color: isDestructive
            ? theme.colorScheme.error
            : theme.colorScheme.onSurfaceVariant,
      ),
      label: Text(
        action.label,
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w500,
          color: isDestructive
              ? theme.colorScheme.error
              : theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  Future<void> _handleAction(BuildContext context, WidgetRef ref) async {
    final state = ref.read(surveyOverviewProvider(surveyId));
    final survey = state.survey;

    // Handle Share action specially using service
    if (action.action == SurveyAction.share && survey != null) {
      await SurveyActionsService.instance.shareSurvey(survey, context);
      return;
    }

    // Handle Delete action specially using service
    if (action.action == SurveyAction.delete && survey != null) {
      await SurveyActionsService.instance.confirmAndDeleteSurvey(
        context: context,
        ref: ref,
        surveyId: surveyId,
        surveyTitle: survey.title,
      );
      return;
    }

    // Handle Export PDF action - show PDF export dialog
    if (action.action == SurveyAction.exportPdf && survey != null) {
      await ExportBottomSheet.show(
        context,
        surveyId: surveyId,
        surveyTitle: survey.title,
        reportType: survey.type.isValuation
            ? ReportType.valuation
            : ReportType.inspection,
      );
      return;
    }

    // Handle View Report action - show PDF export dialog (same as export)
    if (action.action == SurveyAction.viewReport && survey != null) {
      await ExportBottomSheet.show(
        context,
        surveyId: surveyId,
        surveyTitle: survey.title,
        reportType: survey.type.isValuation
            ? ReportType.valuation
            : ReportType.inspection,
      );
      return;
    }

    // Check if confirmation is required
    if (action.requiresConfirmation) {
      final confirmed = await _showConfirmationDialog(context, action.action);
      if (confirmed != true) return;
    }

    // Execute the action
    final intent = await ref
        .read(surveyOverviewProvider(surveyId).notifier)
        .handleAction(action.action);

    if (!context.mounted) return;

    // Handle navigation intent
    _handleNavigationIntent(context, intent);
  }

  Future<bool?> _showConfirmationDialog(
    BuildContext context,
    SurveyAction action,
  ) async {
    final content = SurveyActionResolver.instance.getConfirmationContent(action);
    if (content == null) return true;

    return showDialog<bool>(
      context: context,
      builder: (context) => _ConfirmationDialog(
        title: content.title,
        message: content.message,
        confirmLabel: content.confirmLabel,
        isDestructive: action == SurveyAction.delete ||
            action == SurveyAction.reject,
      ),
    );
  }

  void _handleNavigationIntent(BuildContext context, ActionNavigationIntent intent) {
    switch (intent) {
      case NavigateToSection():
        context.push(Routes.inspectionDetailPath(surveyId));
      case StayOnScreen():
        // Refresh will happen automatically via provider
        break;
      case NavigateToReport():
        // Show PDF export dialog - this case shouldn't normally be reached
        // since we intercept exportPdf/viewReport actions before handleAction()
        _showPdfExportForReport(context);
      case ShowMessage(:final message, :final isError):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            behavior: SnackBarBehavior.floating,
            backgroundColor: isError ? AppColors.error : null,
          ),
        );
      case ActionNotImplemented(:final actionLabel):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$actionLabel coming soon'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  void _showPdfExportForReport(BuildContext context) {
    // Get survey title from provider state
    // This is a fallback path - normally intercepted before handleAction()
    ExportBottomSheet.show(
      context,
      surveyId: surveyId,
      surveyTitle: 'Survey Report',
      reportType: ReportType.inspection,
    );
  }
}

class _ConfirmationDialog extends StatelessWidget {
  const _ConfirmationDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.isDestructive = false,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: const RoundedRectangleBorder(
        borderRadius: AppSpacing.borderRadiusLg,
      ),
      title: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: isDestructive
                ? theme.colorScheme.error
                : theme.colorScheme.primary,
          ),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
