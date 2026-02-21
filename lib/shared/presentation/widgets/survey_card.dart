import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../domain/entities/survey.dart';

class SurveyCard extends StatelessWidget {
  const SurveyCard({
    required this.survey,
    this.onTap,
    this.showProgress = true,
    super.key,
  });

  final Survey survey;
  final VoidCallback? onTap;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withOpacity(0.4),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTypeIcon(theme),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          survey.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (survey.clientName != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            survey.clientName!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SurveyStatusBadge(status: survey.status),
                ],
              ),
              if (survey.address != null) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        survey.address!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              if (showProgress && survey.isInProgress) ...[
                const SizedBox(height: 14),
                _buildProgressSection(theme),
              ],
              const SizedBox(height: 14),
              _buildMetaRow(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeIcon(ThemeData theme) {
    final (icon, color) = switch (survey.type) {
      SurveyType.inspection => (Icons.home_work_rounded, AppColors.primary),
      SurveyType.valuation => (Icons.real_estate_agent_rounded, AppColors.success),
      SurveyType.reinspection => (Icons.refresh_rounded, AppColors.secondary),
      SurveyType.other => (Icons.assignment_rounded, AppColors.secondary),
    };

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        icon,
        size: 22,
        color: color,
      ),
    );
  }

  Widget _buildProgressSection(ThemeData theme) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${(survey.progress * 100).toInt()}%',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: survey.progress,
              minHeight: 6,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      );

  Widget _buildMetaRow(ThemeData theme) => Row(
        children: [
          _buildMetaItem(
            theme,
            Icons.camera_alt_rounded,
            '${survey.photoCount}',
          ),
          const SizedBox(width: 14),
          _buildMetaItem(
            theme,
            Icons.notes_rounded,
            '${survey.noteCount}',
          ),
          const Spacer(),
          Text(
            _formatDate(survey.updatedAt ?? survey.createdAt),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );

  Widget _buildMetaItem(ThemeData theme, IconData icon, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class SurveyStatusBadge extends StatelessWidget {
  const SurveyStatusBadge({
    required this.status,
    this.small = false,
    super.key,
  });

  final SurveyStatus status;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (label, color) = _getStatusInfo();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 10,
        vertical: small ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.25),
        ),
      ),
      child: Text(
        label,
        style: (small ? theme.textTheme.labelSmall : theme.textTheme.labelSmall)
            ?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
    );
  }

  (String, Color) _getStatusInfo() => switch (status) {
        SurveyStatus.draft => ('Draft', AppColors.statusDraft),
        SurveyStatus.inProgress => ('In Progress', AppColors.statusInProgress),
        SurveyStatus.paused => ('Paused', AppColors.statusPendingReview),
        SurveyStatus.completed => ('Completed', AppColors.statusCompleted),
        SurveyStatus.pendingReview => ('Pending', AppColors.statusPendingReview),
        SurveyStatus.approved => ('Approved', AppColors.statusApproved),
        SurveyStatus.rejected => ('Rejected', AppColors.statusRejected),
      };
}
