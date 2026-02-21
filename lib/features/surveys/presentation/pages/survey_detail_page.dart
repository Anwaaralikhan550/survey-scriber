import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/router/routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../shared/domain/entities/survey.dart';
import '../../../../shared/domain/entities/survey_section.dart';
import '../../../../shared/presentation/widgets/empty_state.dart';
import '../../../../shared/presentation/widgets/survey_card.dart';
import '../../../ai/presentation/providers/ai_providers.dart';
import '../../../property_inspection/presentation/pages/inspection_overview_page.dart';
import '../../../property_valuation/presentation/pages/valuation_overview_page.dart';
import '../providers/survey_detail_provider.dart';

class SurveyDetailPage extends ConsumerWidget {
  const SurveyDetailPage({
    required this.surveyId,
    super.key,
  });

  final String surveyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(surveyDetailProvider(surveyId));
    final theme = Theme.of(context);

    if (state.isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (state.hasError || !state.hasSurvey) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: theme.colorScheme.error,
              ),
              AppSpacing.gapVerticalMd,
              Text(
                state.errorMessage ?? 'Survey not found',
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              AppSpacing.gapVerticalLg,
              FilledButton.icon(
                onPressed: () => context.go(Routes.forms),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Forms'),
              ),
            ],
          ),
        ),
      );
    }

    final survey = state.survey!;
    if (survey.type.isInspection) {
      return InspectionOverviewPage(surveyId: surveyId);
    }
    if (survey.type.isValuation) {
      return ValuationOverviewPage(surveyId: surveyId);
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.read(surveyDetailProvider(surveyId).notifier).refresh(),
        child: CustomScrollView(
          slivers: [
            _buildAppBar(context, ref, survey, theme),
            SliverToBoxAdapter(
              child: _buildHeader(context, survey, state, theme),
            ),
            SliverToBoxAdapter(
              child: _buildAiStatusIndicator(ref, theme, surveyStatus: survey.status),
            ),
            SliverToBoxAdapter(
              child: _buildProgressCard(state, theme),
            ),
            _buildSectionsList(context, state, theme),
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context, ref, survey, theme),
    );
  }

  Widget _buildAppBar(
    BuildContext context,
    WidgetRef ref,
    Survey survey,
    ThemeData theme,
  ) =>
      SliverAppBar(
        pinned: true,
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.arrow_back_rounded,
              size: 20,
              color: theme.colorScheme.onSurface,
            ),
          ),
          onPressed: () => context.go(Routes.forms),
        ),
        title: Text(
          survey.jobRef ?? 'Survey',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'export_pdf':
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Use the inspection/valuation overview to export reports'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                case 'share':
                  await _shareSurvey(context, survey);
                case 'view_media':
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('View Media - Navigate to media gallery'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                case 'view_signatures':
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('View Signatures - Navigate to signatures'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                case 'pause':
                  await ref
                      .read(surveyDetailProvider(surveyId).notifier)
                      .updateStatus(SurveyStatus.paused);
                case 'delete':
                  _showDeleteDialog(context, ref);
              }
            },
            itemBuilder: (context) => [
              // Export PDF - available for completed, pendingReview, approved
              if (survey.status == SurveyStatus.completed ||
                  survey.status == SurveyStatus.pendingReview ||
                  survey.status == SurveyStatus.approved)
                const PopupMenuItem(
                  value: 'export_pdf',
                  child: ListTile(
                    leading: Icon(Icons.picture_as_pdf_rounded),
                    title: Text('Export PDF'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              // Share - available for all statuses
              const PopupMenuItem(
                value: 'share',
                child: ListTile(
                  leading: Icon(Icons.share_rounded),
                  title: Text('Share'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              // View Media - available for all statuses with media
              const PopupMenuItem(
                value: 'view_media',
                child: ListTile(
                  leading: Icon(Icons.photo_library_outlined),
                  title: Text('View Media'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              // View Signatures - available for completed+ surveys
              if (survey.status == SurveyStatus.completed ||
                  survey.status == SurveyStatus.pendingReview ||
                  survey.status == SurveyStatus.approved)
                const PopupMenuItem(
                  value: 'view_signatures',
                  child: ListTile(
                    leading: Icon(Icons.draw_outlined),
                    title: Text('View Signatures'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              // Pause Survey - only for inProgress
              if (survey.status == SurveyStatus.inProgress)
                const PopupMenuItem(
                  value: 'pause',
                  child: ListTile(
                    leading: Icon(Icons.pause),
                    title: Text('Pause Survey'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              // Divider before destructive action
              const PopupMenuDivider(),
              // Delete - available for draft, paused, rejected
              if (survey.status == SurveyStatus.draft ||
                  survey.status == SurveyStatus.paused ||
                  survey.status == SurveyStatus.rejected)
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete_outline, color: Colors.red),
                    title: Text('Delete', style: TextStyle(color: Colors.red)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
            ],
          ),
        ],
      );

  Widget _buildHeader(
    BuildContext context,
    Survey survey,
    SurveyDetailState state,
    ThemeData theme,
  ) =>
      Padding(
        padding: AppSpacing.paddingMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (survey.jobRef != null)
                        Text(
                          survey.jobRef!,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      AppSpacing.gapVerticalXs,
                      Text(
                        survey.title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                SurveyStatusBadge(status: survey.status),
              ],
            ),
            if (survey.address != null) ...[
              AppSpacing.gapVerticalMd,
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  AppSpacing.gapHorizontalSm,
                  Expanded(
                    child: Text(
                      survey.address!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (survey.clientName != null) ...[
              AppSpacing.gapVerticalSm,
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  AppSpacing.gapHorizontalSm,
                  Text(
                    survey.clientName!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      );

  Widget _buildAiStatusIndicator(
    WidgetRef ref,
    ThemeData theme, {
    SurveyStatus? surveyStatus,
  }) {
    final aiStatus = ref.watch(aiStatusProvider);
    final isApproved = surveyStatus == SurveyStatus.approved;

    return Padding(
      padding: AppSpacing.paddingHorizontalMd,
      child: Row(
        children: [
          aiStatus.when(
            data: (status) => _buildAiChip(
              theme,
              isAvailable: status.available,
              message: status.available
                  ? 'AI Assistant ready'
                  : 'AI temporarily unavailable',
            ),
            loading: () => _buildAiChip(
              theme,
              isAvailable: false,
              message: 'Checking AI...',
              isLoading: true,
            ),
            error: (_, __) => _buildAiChip(
              theme,
              isAvailable: false,
              message: 'AI unavailable',
            ),
          ),
          if (isApproved) ...[
            const SizedBox(width: 8),
            Tooltip(
              message: 'This survey has been approved',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified,
                      size: 14,
                      color: theme.colorScheme.onTertiaryContainer,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Approved',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onTertiaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAiChip(
    ThemeData theme, {
    required bool isAvailable,
    required String message,
    bool isLoading = false,
  }) {
    final chipColor = isAvailable
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHighest;
    final textColor = isAvailable
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurfaceVariant;
    final iconColor = isAvailable
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant.withOpacity(0.7);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: chipColor,
              borderRadius: BorderRadius.circular(20),
              border: isAvailable
                  ? Border.all(color: theme.colorScheme.primary.withOpacity(0.3))
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLoading)
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: iconColor,
                    ),
                  )
                else
                  Icon(
                    isAvailable ? Icons.auto_awesome : Icons.cloud_off_outlined,
                    size: 16,
                    color: iconColor,
                  ),
                const SizedBox(width: 6),
                Text(
                  message,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: textColor,
                    fontWeight: isAvailable ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(SurveyDetailState state, ThemeData theme) {
    final completed = state.completedSectionsCount;
    final total = state.sections.length;
    final progress = state.progressPercent;

    return Padding(
      padding: AppSpacing.paddingHorizontalMd,
      child: Container(
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primaryContainer,
              theme.colorScheme.primaryContainer.withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: AppSpacing.borderRadiusMd,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progress',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                Text(
                  '${progress.toInt()}%',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            AppSpacing.gapVerticalMd,
            ClipRRect(
              borderRadius: AppSpacing.borderRadiusFull,
              child: LinearProgressIndicator(
                value: progress / 100,
                minHeight: 8,
                backgroundColor: theme.colorScheme.surface.withOpacity(0.5),
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
              ),
            ),
            AppSpacing.gapVerticalSm,
            Text(
              '$completed of $total sections completed',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionsList(
    BuildContext context,
    SurveyDetailState state,
    ThemeData theme,
  ) {
    if (state.sections.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyState(
          icon: Icons.view_list_outlined,
          title: 'No Sections Available',
          description:
              'This survey has no sections configured. '
              'An administrator may need to set up section types for this survey type.',
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(AppSpacing.md),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Text(
                  'Sections',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }

            final section = state.sections[index - 1];
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _SectionTile(
                section: section,
                onTap: () {
                  context.push(
                    Routes.inspectionSectionPath(surveyId, section.id),
                  );
                },
              ),
            );
          },
          childCount: state.sections.length + 1,
        ),
      ),
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    WidgetRef ref,
    Survey survey,
    ThemeData theme,
  ) {
    final state = ref.watch(surveyDetailProvider(surveyId));
    final isComplete = state.completedSectionsCount == state.sections.length;
    final hasSignificantProgress = state.progressPercent >= 50;

    final buttonLabel = switch (survey.status) {
      SurveyStatus.draft => 'Start Survey',
      SurveyStatus.paused => 'Resume Survey',
      SurveyStatus.inProgress => 'Continue',
      SurveyStatus.completed => 'View Summary',
      _ => 'View',
    };

    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // AI discovery hint for users with low progress
            if (!hasSignificantProgress && !isComplete)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Preview AI insights anytime. Results improve as you complete more sections.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary.withOpacity(0.8),
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            // Action button group - equal visual weight, clear hierarchy
            LayoutBuilder(
              builder: (context, constraints) {
                // Use vertical stack on very narrow screens (< 320dp)
                final useVerticalLayout = constraints.maxWidth < 320;

                if (useVerticalLayout) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Primary action first in vertical layout
                      _ActionButton(
                        label: buttonLabel,
                        icon: Icons.play_arrow_rounded,
                        isPrimary: true,
                        onPressed: () async {
                          if (survey.status == SurveyStatus.draft ||
                              survey.status == SurveyStatus.paused) {
                            await ref
                                .read(surveyDetailProvider(surveyId).notifier)
                                .updateStatus(SurveyStatus.inProgress);
                          }
                          if (context.mounted) {
                            final currentState =
                                ref.read(surveyDetailProvider(surveyId));
                            if (currentState.sections.isEmpty) return;
                            final firstIncomplete =
                                currentState.sections.firstWhere(
                              (s) => !s.isCompleted,
                              orElse: () => currentState.sections.first,
                            );
                            context.push(
                              Routes.inspectionSectionPath(
                                  surveyId, firstIncomplete.id,),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      _ActionButton(
                        label: 'Review & AI',
                        icon: Icons.auto_awesome,
                        isPrimary: false,
                        onPressed: () {
                          context.push(Routes.surveyOverviewPath(surveyId));
                        },
                      ),
                    ],
                  );
                }

                // Horizontal layout - equal width buttons
                return Row(
                  children: [
                    // Review button - secondary action
                    Expanded(
                      child: _ActionButton(
                        label: 'Review & AI',
                        icon: Icons.auto_awesome,
                        isPrimary: false,
                        onPressed: () {
                          context.push(Routes.surveyOverviewPath(surveyId));
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Primary action button
                    Expanded(
                      child: _ActionButton(
                        label: buttonLabel,
                        icon: Icons.play_arrow_rounded,
                        isPrimary: true,
                        onPressed: () async {
                          if (survey.status == SurveyStatus.draft ||
                              survey.status == SurveyStatus.paused) {
                            await ref
                                .read(surveyDetailProvider(surveyId).notifier)
                                .updateStatus(SurveyStatus.inProgress);
                          }
                          if (context.mounted) {
                            final currentState =
                                ref.read(surveyDetailProvider(surveyId));
                            if (currentState.sections.isEmpty) return;
                            final firstIncomplete =
                                currentState.sections.firstWhere(
                              (s) => !s.isCompleted,
                              orElse: () => currentState.sections.first,
                            );
                            context.push(
                              Routes.inspectionSectionPath(
                                  surveyId, firstIncomplete.id,),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareSurvey(BuildContext context, Survey survey) async {
    final shareText = StringBuffer()
      ..writeln('Survey: ${survey.title}')
      ..writeln('Job Ref: ${survey.jobRef ?? 'N/A'}');

    if (survey.address != null) {
      shareText.writeln('Address: ${survey.address}');
    }
    if (survey.clientName != null) {
      shareText.writeln('Client: ${survey.clientName}');
    }
    shareText.writeln('Status: ${survey.status.name}');

    await Share.share(
      shareText.toString(),
      subject: 'Survey: ${survey.title}',
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Survey'),
        content: const Text(
          'Are you sure you want to delete this survey? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref
                  .read(surveyDetailProvider(surveyId).notifier)
                  .deleteSurvey();
              if (context.mounted) {
                context.go(Routes.forms);
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _SectionTile extends StatelessWidget {
  const _SectionTile({
    required this.section,
    required this.onTap,
  });

  final SurveySection section;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompleted = section.isCompleted;

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: AppSpacing.borderRadiusMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.borderRadiusMd,
        child: Container(
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            borderRadius: AppSpacing.borderRadiusMd,
            border: Border.all(
              color: isCompleted
                  ? AppColors.statusCompleted.withOpacity(0.5)
                  : theme.colorScheme.outlineVariant.withOpacity(0.5),
              width: isCompleted ? 2 : 1,
            ),
            color: isCompleted
                ? AppColors.statusCompleted.withOpacity(0.04)
                : null,
          ),
          child: Row(
            children: [
              // Leading icon container with completion indicator
              Stack(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppColors.statusCompleted.withOpacity(0.15)
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: AppSpacing.borderRadiusSm,
                    ),
                    child: Icon(
                      _getSectionIcon(section.sectionType),
                      color: isCompleted
                          ? AppColors.statusCompleted
                          : theme.colorScheme.onSurfaceVariant,
                      size: 22,
                    ),
                  ),
                  // Completion checkmark overlay
                  if (isCompleted)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: AppColors.statusCompleted,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.surface,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              AppSpacing.gapHorizontalMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      section.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isCompleted
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Status indicator row
                    Row(
                      children: [
                        if (isCompleted) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.statusCompleted.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.check_circle_outline,
                                  size: 12,
                                  color: AppColors.statusCompleted,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Completed',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: AppColors.statusCompleted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.edit_outlined,
                                  size: 12,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Tap to fill',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isCompleted
                    ? AppColors.statusCompleted
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getSectionIcon(SectionType type) => switch (type) {
        // New inspection sections
        SectionType.aboutInspection => Icons.assignment_outlined,
        SectionType.externalItems => Icons.roofing_outlined,
        SectionType.internalItems => Icons.door_front_door_outlined,
        SectionType.issuesAndRisks => Icons.warning_amber_outlined,
        // Existing sections
        SectionType.aboutProperty => Icons.home_outlined,
        SectionType.construction => Icons.construction_outlined,
        SectionType.rooms => Icons.meeting_room_outlined,
        SectionType.exterior => Icons.landscape_outlined,
        SectionType.interior => Icons.weekend_outlined,
        SectionType.services => Icons.electrical_services_outlined,
        SectionType.photos => Icons.camera_alt_outlined,
        SectionType.notes => Icons.note_outlined,
        SectionType.signature => Icons.draw_outlined,
        // Valuation sections
        SectionType.aboutValuation => Icons.request_quote_outlined,
        SectionType.propertySummary => Icons.fact_check_outlined,
        SectionType.marketAnalysis => Icons.analytics_outlined,
        SectionType.comparables => Icons.compare_outlined,
        SectionType.adjustments => Icons.tune_outlined,
        SectionType.valuation => Icons.price_check_outlined,
        SectionType.summary => Icons.summarize_outlined,
      };
}

/// Unified action button with consistent styling for bottom action bars.
/// Provides primary (filled) and secondary (outlined) variants with
/// equal visual weight and proper touch targets.
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.isPrimary,
    required this.onPressed,
    this.isEnabled = true,
  });

  final String label;
  final IconData icon;
  final bool isPrimary;
  final VoidCallback? onPressed;
  final bool isEnabled;

  static const double _buttonHeight = 48;
  static const double _iconSize = 20;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveOnPressed = isEnabled ? onPressed : null;

    if (isPrimary) {
      return FilledButton(
        onPressed: effectiveOnPressed,
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, _buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: _iconSize),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      );
    }

    return OutlinedButton(
      onPressed: effectiveOnPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, _buttonHeight),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        side: BorderSide(
          color: effectiveOnPressed != null
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withOpacity(0.5),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: _iconSize,
            color: effectiveOnPressed != null
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withOpacity(0.5),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
