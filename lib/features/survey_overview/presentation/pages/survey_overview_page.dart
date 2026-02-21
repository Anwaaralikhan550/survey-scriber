import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../app/router/routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../shared/domain/entities/survey.dart';
import '../../../../shared/domain/entities/survey_section.dart';
import '../../../../shared/services/survey_actions_service.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../forms/presentation/providers/forms_provider.dart';
import '../../../media/presentation/pages/survey_media_gallery_page.dart';
import '../../../media/presentation/providers/media_provider.dart';
import '../../../media/presentation/widgets/section_media_panel.dart';
import '../../../reinspection/presentation/pages/reinspection_overview_page.dart';
import '../../../report_export/domain/models/report_document.dart';
import '../../../report_export/presentation/widgets/export_bottom_sheet.dart';
import '../../../signature/presentation/pages/survey_signatures_page.dart';
import '../../../surveys/presentation/providers/survey_providers.dart';
import '../providers/survey_overview_provider.dart';
import '../widgets/activity_timeline_card.dart';
import '../widgets/survey_actions_card.dart';

class SurveyOverviewPage extends ConsumerWidget {
  const SurveyOverviewPage({
    required this.surveyId,
    super.key,
  });

  final String surveyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(surveyOverviewProvider(surveyId));
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: state.isLoading
          ? const _LoadingState()
          : state.hasError
              ? _ErrorState(
                  message: state.errorMessage!,
                  onRetry: () =>
                      ref.read(surveyOverviewProvider(surveyId).notifier).refresh(),
                )
              : state.hasSurvey
                  ? _SurveyContent(
                      surveyId: surveyId,
                      survey: state.survey!,
                      sections: state.sections,
                      primaryActionLabel: state.primaryActionLabel,
                      isPrimaryActionEnabled: state.isPrimaryActionEnabled,
                      shouldNavigateToSection: state.shouldNavigateToSection,
                      targetSection: state.targetSection,
                    )
                  : const _ErrorState(message: 'Survey not found'),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                strokeCap: StrokeCap.round,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Loading survey...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 40,
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Something went wrong',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: -0.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  label: const Text(
                    'Try Again',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.1,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SurveyContent extends ConsumerWidget {
  const _SurveyContent({
    required this.surveyId,
    required this.survey,
    required this.sections,
    required this.primaryActionLabel,
    required this.isPrimaryActionEnabled,
    required this.shouldNavigateToSection,
    this.targetSection,
  });

  final String surveyId;
  final Survey survey;
  final List<SurveySection> sections;
  final String primaryActionLabel;
  final bool isPrimaryActionEnabled;
  final bool shouldNavigateToSection;
  final SurveySection? targetSection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              _SurveyAppBar(survey: survey, surveyId: surveyId),
              SliverToBoxAdapter(
                child: _SurveyHeader(survey: survey),
              ),
              SliverToBoxAdapter(
                child: _ProgressCard(survey: survey),
              ),
              // Activity Timeline - shows chronological audit feed
              SliverToBoxAdapter(
                child: ActivityTimelineCard(surveyId: surveyId),
              ),
              // Survey Actions - centralized action buttons
              SliverToBoxAdapter(
                child: SurveyActionsCard(surveyId: surveyId),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                  child: Row(
                    children: [
                      Text(
                        'Sections',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${sections.length}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _SectionsList(
                sections: sections,
                surveyId: survey.id,
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 120),
              ),
            ],
          ),
        ),
        _BottomActionBar(
          surveyId: surveyId,
          survey: survey,
          primaryActionLabel: primaryActionLabel,
          isPrimaryActionEnabled: isPrimaryActionEnabled,
          shouldNavigateToSection: shouldNavigateToSection,
          targetSection: targetSection,
        ),
      ],
    );
  }
}

class _SurveyAppBar extends ConsumerWidget {
  const _SurveyAppBar({
    required this.survey,
    required this.surveyId,
  });

  final Survey survey;
  final String surveyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return SliverAppBar(
      pinned: true,
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.8),
            borderRadius: AppSpacing.borderRadiusMd,
          ),
          child: Icon(
            Icons.arrow_back_rounded,
            size: 20,
            color: theme.colorScheme.onSurface,
          ),
        ),
        onPressed: () => context.pop(),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.8),
              borderRadius: AppSpacing.borderRadiusMd,
            ),
            child: Icon(
              Icons.more_vert_rounded,
              size: 20,
              color: theme.colorScheme.onSurface,
            ),
          ),
          onPressed: () {
            _showOptionsMenu(context, ref);
          },
        ),
        const SizedBox(width: AppSpacing.sm),
      ],
    );
  }

  void _showOptionsMenu(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle indicator
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.edit_rounded, size: 20),
                ),
                title: const Text(
                  'Edit Survey Details',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showEditSurveyDialog(context, ref);
                },
              ),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.perm_media_rounded, size: 20),
                ),
                title: const Text(
                  'View Media Gallery',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SurveyMediaGalleryPage(
                        surveyId: survey.id,
                        surveyTitle: survey.title,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.draw_rounded, size: 20),
                ),
                title: const Text(
                  'View Signatures',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SurveySignaturesPage(
                        surveyId: survey.id,
                        surveyTitle: survey.title,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.picture_as_pdf_rounded,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                ),
                title: const Text(
                  'Export PDF Report',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  Navigator.pop(context);
                  ExportBottomSheet.show(
                    context,
                    surveyId: survey.id,
                    surveyTitle: survey.title,
                    reportType: survey.type.isValuation
                        ? ReportType.valuation
                        : ReportType.inspection,
                  );
                },
              ),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.history_rounded, size: 20),
                ),
                title: const Text(
                  'View PDF History',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  Navigator.pop(context);
                  context.push(Routes.pdfHistory);
                },
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Divider(height: 1),
              ),
              // Re-inspection options
              if (survey.isReinspection)
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.compare_arrows_rounded,
                      size: 20,
                      color: theme.colorScheme.tertiary,
                    ),
                  ),
                  title: const Text(
                    'View Comparison',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    'Compare with previous inspection',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ReinspectionOverviewPage(
                          surveyId: survey.id,
                        ),
                      ),
                    );
                  },
                ),
              if (!survey.isReinspection && survey.isCompleted)
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.replay_rounded,
                      size: 20,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  title: const Text(
                    'Create Re-Inspection',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    'Start a follow-up inspection',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showCreateReinspectionDialog(context, ref, survey);
                  },
                ),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.share_rounded, size: 20),
                ),
                title: const Text(
                  'Share Survey',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _shareSurvey(context);
                },
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Divider(height: 1),
              ),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.delete_rounded,
                    size: 20,
                    color: theme.colorScheme.error,
                  ),
                ),
                title: Text(
                  'Delete Survey',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.error,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  SurveyActionsService.instance.confirmAndDeleteSurvey(
                    context: context,
                    ref: ref,
                    surveyId: surveyId,
                    surveyTitle: survey.title,
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateReinspectionDialog(
    BuildContext context,
    WidgetRef ref,
    Survey survey,
  ) {
    final theme = Theme.of(context);

    showDialog(
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
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.replay_rounded,
                color: theme.colorScheme.secondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Create Re-Inspection'),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will create a new inspection based on "${survey.title}" for comparison.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'The new inspection will copy the structure and allow you to update values.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
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
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _createReinspection(context, ref, survey);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _createReinspection(
    BuildContext context,
    WidgetRef ref,
    Survey parentSurvey,
  ) async {
    const uuid = Uuid();
    final repository = ref.read(localSurveyRepositoryProvider);
    final now = DateTime.now();

    try {
      // Generate new survey ID
      final newSurveyId = uuid.v4();

      // Get parent sections to copy structure
      final parentSections = await repository.getSectionsForSurvey(parentSurvey.id);

      // Create new sections with new IDs
      final newSections = parentSections.map((section) => SurveySection(
        id: uuid.v4(),
        surveyId: newSurveyId,
        sectionType: section.sectionType,
        title: section.title,
        order: section.order,
        createdAt: now,
      ),).toList();

      // Create re-inspection survey
      final reinspection = Survey(
        id: newSurveyId,
        title: 'Re-inspection: ${parentSurvey.title}',
        type: SurveyType.reinspection,
        status: SurveyStatus.draft,
        createdAt: now,
        jobRef: parentSurvey.jobRef,
        address: parentSurvey.address,
        clientName: parentSurvey.clientName,
        parentSurveyId: parentSurvey.id,
        totalSections: newSections.length,
      );

      // Save to database
      await repository.createSurvey(reinspection);
      await repository.createSections(newSections);

      // Invalidate list providers
      ref.invalidate(dashboardProvider);
      ref.invalidate(formsProvider);

      if (!context.mounted) return;

      // Show success and navigate
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Re-inspection created successfully'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );

      // Navigate to new survey (use surveyDetailPath for consistent new layout with AI)
      context.push(Routes.surveyDetailPath(newSurveyId));
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create re-inspection: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  Future<void> _shareSurvey(BuildContext context) async {
    await SurveyActionsService.instance.shareSurvey(survey, context);
  }

  void _showEditSurveyDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController(text: survey.title);
    final clientNameController = TextEditingController(text: survey.clientName ?? '');
    final addressController = TextEditingController(text: survey.address ?? '');
    final jobRefController = TextEditingController(text: survey.jobRef ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        var isLoading = false;

        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Edit Survey Details'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Survey Title *',
                      hintText: 'Enter survey title',
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: clientNameController,
                    decoration: const InputDecoration(
                      labelText: 'Client Name',
                      hintText: 'Enter client name',
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: addressController,
                    decoration: const InputDecoration(
                      labelText: 'Property Address',
                      hintText: 'Enter property address',
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: jobRefController,
                    decoration: const InputDecoration(
                      labelText: 'Job Reference',
                      hintText: 'Enter job reference',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        final title = titleController.text.trim();
                        if (title.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Title is required'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }

                        setState(() => isLoading = true);

                        final success = await ref
                            .read(surveyOverviewProvider(surveyId).notifier)
                            .updateSurveyDetails(
                              title: title,
                              clientName: clientNameController.text.trim().isEmpty
                                  ? null
                                  : clientNameController.text.trim(),
                              address: addressController.text.trim().isEmpty
                                  ? null
                                  : addressController.text.trim(),
                              jobRef: jobRefController.text.trim().isEmpty
                                  ? null
                                  : jobRefController.text.trim(),
                            );

                        if (!dialogContext.mounted) return;
                        Navigator.pop(dialogContext);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'Survey updated successfully'
                                  : 'Failed to update survey',
                            ),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: success ? null : theme.colorScheme.error,
                          ),
                        );
                      },
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SurveyHeader extends StatelessWidget {
  const _SurveyHeader({required this.survey});

  final Survey survey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type badge and status
          Row(
            children: [
              _TypeBadge(type: survey.type),
              const Spacer(),
              _StatusBadge(status: survey.status),
            ],
          ),
          const SizedBox(height: 16),
          // Title
          Text(
            survey.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              height: 1.2,
              color: theme.colorScheme.onSurface,
            ),
          ),
          if (survey.address != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.location_on_rounded,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    survey.address!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          // Meta info row
          Wrap(
            spacing: 16,
            runSpacing: 10,
            children: [
              if (survey.jobRef != null)
                _MetaChip(
                  icon: Icons.tag_rounded,
                  label: survey.jobRef!,
                ),
              if (survey.clientName != null)
                _MetaChip(
                  icon: Icons.person_outline_rounded,
                  label: survey.clientName!,
                ),
              _MetaChip(
                icon: Icons.schedule_rounded,
                label: _formatDate(survey.updatedAt ?? survey.createdAt),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return '${date.day}/${date.month}/${date.year}';
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});

  final SurveyType type;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, label, color) = _getTypeInfo();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: AppSpacing.borderRadiusSm,
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          AppSpacing.gapHorizontalXs,
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  (IconData, String, Color) _getTypeInfo() => switch (type) {
        SurveyType.inspection => (
            Icons.home_work_rounded,
            'Inspection',
            AppColors.primary
          ),
        SurveyType.valuation => (
            Icons.real_estate_agent_rounded,
            'Valuation',
            AppColors.success
          ),
        SurveyType.reinspection => (
            Icons.refresh_rounded,
            'Re-inspection',
            AppColors.secondary
          ),
        SurveyType.other => (
            Icons.assignment_outlined,
            'Other',
            AppColors.secondary
          ),
      };
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final SurveyStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (label, color, bgColor) = _getStatusInfo();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppSpacing.borderRadiusFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          AppSpacing.gapHorizontalXs,
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  (String, Color, Color) _getStatusInfo() => switch (status) {
        SurveyStatus.draft => (
            'Draft',
            AppColors.statusDraft,
            AppColors.statusDraft.withOpacity(0.12)
          ),
        SurveyStatus.inProgress => (
            'In Progress',
            AppColors.statusInProgress,
            AppColors.statusInProgress.withOpacity(0.12)
          ),
        SurveyStatus.paused => (
            'Paused',
            AppColors.statusPendingReview,
            AppColors.statusPendingReview.withOpacity(0.12)
          ),
        SurveyStatus.completed => (
            'Completed',
            AppColors.statusCompleted,
            AppColors.statusCompleted.withOpacity(0.12)
          ),
        SurveyStatus.pendingReview => (
            'Pending Review',
            AppColors.statusPendingReview,
            AppColors.statusPendingReview.withOpacity(0.12)
          ),
        SurveyStatus.approved => (
            'Approved',
            AppColors.statusApproved,
            AppColors.statusApproved.withOpacity(0.12)
          ),
        SurveyStatus.rejected => (
            'Rejected',
            AppColors.statusRejected,
            AppColors.statusRejected.withOpacity(0.12)
          ),
      };
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        AppSpacing.gapHorizontalXs,
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.survey});

  final Survey survey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progressPercent = survey.progressPercent.round();
    final progressValue = progressPercent / 100;

    return Padding(
      padding: AppSpacing.paddingHorizontalMd,
      child: Container(
        padding: AppSpacing.paddingMd,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primaryContainer.withOpacity(0.5),
              theme.colorScheme.primaryContainer.withOpacity(0.2),
            ],
          ),
          borderRadius: AppSpacing.borderRadiusLg,
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.1),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Progress circle
                SizedBox(
                  width: 72,
                  height: 72,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 72,
                        height: 72,
                        child: CircularProgressIndicator(
                          value: progressValue,
                          strokeWidth: 6,
                          backgroundColor:
                              theme.colorScheme.primary.withOpacity(0.15),
                          valueColor: AlwaysStoppedAnimation(
                            theme.colorScheme.primary,
                          ),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Text(
                        '$progressPercent%',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                AppSpacing.gapHorizontalMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Survey Progress',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                      ),
                      AppSpacing.gapVerticalXs,
                      Text(
                        '${survey.completedSections} of ${survey.totalSections} sections completed',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      AppSpacing.gapVerticalSm,
                      // Linear progress bar
                      ClipRRect(
                        borderRadius: AppSpacing.borderRadiusFull,
                        child: LinearProgressIndicator(
                          value: progressValue,
                          minHeight: 6,
                          backgroundColor:
                              theme.colorScheme.primary.withOpacity(0.15),
                          valueColor: AlwaysStoppedAnimation(
                            theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionsList extends StatelessWidget {
  const _SectionsList({
    required this.sections,
    required this.surveyId,
  });

  final List<SurveySection> sections;
  final String surveyId;

  @override
  Widget build(BuildContext context) => SliverPadding(
      padding: AppSpacing.paddingHorizontalMd,
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final section = sections[index];
            final isFirst = index == 0;
            final isLast = index == sections.length - 1;

            return _SectionItem(
              section: section,
              surveyId: surveyId,
              index: index,
              isFirst: isFirst,
              isLast: isLast,
            );
          },
          childCount: sections.length,
        ),
      ),
    );
}

class _SectionItem extends ConsumerWidget {
  const _SectionItem({
    required this.section,
    required this.surveyId,
    required this.index,
    required this.isFirst,
    required this.isLast,
  });

  final SurveySection section;
  final String surveyId;
  final int index;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final mediaState = ref.watch(sectionMediaProvider(section.id));

    return Padding(
      padding: EdgeInsets.only(
        top: isFirst ? 0 : AppSpacing.xs,
        bottom: isLast ? 0 : AppSpacing.xs,
      ),
      child: Material(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(AppSpacing.radiusMd) : Radius.zero,
          bottom: isLast ? const Radius.circular(AppSpacing.radiusMd) : Radius.zero,
        ),
        child: InkWell(
          onTap: () async {
            // Ensure survey transitions from draft → inProgress before
            // entering any section. Prevents 100% completion while still draft.
            await ref
                .read(surveyOverviewProvider(surveyId).notifier)
                .ensureSurveyStarted();
            if (!context.mounted) return;
            context.push(Routes.inspectionDetailPath(surveyId));
          },
          borderRadius: BorderRadius.vertical(
            top: isFirst ? const Radius.circular(AppSpacing.radiusMd) : Radius.zero,
            bottom: isLast ? const Radius.circular(AppSpacing.radiusMd) : Radius.zero,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              border: isLast
                  ? null
                  : Border(
                      bottom: BorderSide(
                        color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                      ),
                    ),
            ),
            child: Row(
              children: [
                // Index number with completion state
                _SectionIndexIndicator(
                  index: index + 1,
                  isCompleted: section.isCompleted,
                ),
                AppSpacing.gapHorizontalMd,
                // Section info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        section.title,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: section.isCompleted
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                      AppSpacing.gapVerticalXs,
                      Row(
                        children: [
                          Text(
                            section.isCompleted ? 'Completed' : 'Not started',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: section.isCompleted
                                  ? AppColors.statusCompleted
                                  : theme.colorScheme.onSurfaceVariant,
                              fontWeight:
                                  section.isCompleted ? FontWeight.w500 : null,
                            ),
                          ),
                          // Media indicator
                          if (mediaState.hasMedia) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                              child: Container(
                                width: 3,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            SectionMediaSummary(
                              surveyId: surveyId,
                              sectionId: section.id,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Arrow
                Icon(
                  Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionIndexIndicator extends StatelessWidget {
  const _SectionIndexIndicator({
    required this.index,
    required this.isCompleted,
  });

  final int index;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isCompleted) {
      return Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: AppColors.statusCompleted,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check_rounded,
          size: 18,
          color: Colors.white,
        ),
      );
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '$index',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _BottomActionBar extends ConsumerWidget {
  const _BottomActionBar({
    required this.surveyId,
    required this.survey,
    required this.primaryActionLabel,
    required this.isPrimaryActionEnabled,
    required this.shouldNavigateToSection,
    this.targetSection,
  });

  final String surveyId;
  final Survey survey;
  final String primaryActionLabel;
  final bool isPrimaryActionEnabled;
  final bool shouldNavigateToSection;
  final SurveySection? targetSection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: FilledButton(
          onPressed: isPrimaryActionEnabled
              ? () => _handlePrimaryAction(context, ref)
              : null,
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  primaryActionLabel,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.1,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.arrow_forward_rounded, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handlePrimaryAction(BuildContext context, WidgetRef ref) async {
    if (shouldNavigateToSection) {
      // Use the provider to handle status update and get target section
      final sectionId = await ref
          .read(surveyOverviewProvider(surveyId).notifier)
          .handlePrimaryAction();

      if (sectionId != null && context.mounted) {
        context.push(Routes.inspectionDetailPath(surveyId));
      }
    } else {
      // Handle non-navigation actions
      switch (survey.status) {
        case SurveyStatus.completed:
          // Submit for review - handled by the actions card now
          await ref
              .read(surveyOverviewProvider(surveyId).notifier)
              .submitForReview();
          break;
        case SurveyStatus.pendingReview:
          // No action - button is disabled
          break;
        case SurveyStatus.approved:
          // Show export bottom sheet for viewing report
          await ExportBottomSheet.show(
            context,
            surveyId: surveyId,
            surveyTitle: survey.title,
            reportType: survey.type.isValuation
                ? ReportType.valuation
                : ReportType.inspection,
          );
          break;
        default:
          break;
      }
    }
  }
}
