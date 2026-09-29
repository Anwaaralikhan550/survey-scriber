import 'package:flutter/material.dart';

import '../providers/dashboard_provider.dart';

/// Survey Folder — replaces the old "Recent Surveys" list per the client's
/// App-Edit brief: "Recent surveys replace with Survey folder — folder will
/// have two sections, Home Surveys and Valuations. Folder content will list
/// after user select Home Surveys and Valuations."
///
/// Renders a titled section with two folder cards (Home Surveys, Valuations),
/// each showing its survey count. Tapping a card opens that category's list
/// (which carries the All / Live / In Progress / Completed "View all" filter).
class SurveyFolderSection extends StatelessWidget {
  const SurveyFolderSection({
    required this.homeSurveysCount,
    required this.valuationsCount,
    this.onOpenFolder,
    super.key,
  });

  final int homeSurveysCount;
  final int valuationsCount;
  final void Function(HomeSegment segment)? onOpenFolder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Survey Folder',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: _FolderCard(
                  label: 'Home Surveys',
                  count: homeSurveysCount,
                  icon: Icons.home_work_outlined,
                  onTap: () => onOpenFolder?.call(HomeSegment.homeSurveys),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FolderCard(
                  label: 'Valuations',
                  count: valuationsCount,
                  icon: Icons.request_quote_outlined,
                  onTap: () => onOpenFolder?.call(HomeSegment.valuations),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FolderCard extends StatelessWidget {
  const _FolderCard({
    required this.label,
    required this.count,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final int count;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: colorScheme.outlineVariant.withOpacity(0.4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, size: 22, color: colorScheme.primary),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                count == 1 ? '1 survey' : '$count surveys',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
