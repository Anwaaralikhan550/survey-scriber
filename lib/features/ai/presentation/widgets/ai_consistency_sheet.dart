import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../property_inspection/domain/models/inspection_models.dart';
import '../../domain/entities/ai_response.dart';
import '../providers/ai_inspection_providers.dart';

/// Bottom sheet displaying AI consistency check results for a survey.
///
/// Shows: score badge, issues grouped by severity, suggestions.
/// AI never overwrites user text — results are read-only.
class AiConsistencySheet extends ConsumerStatefulWidget {
  const AiConsistencySheet({
    required this.surveyId,
    required this.tree,
    required this.allAnswers,
    this.scrollController,
    super.key,
  });

  final String surveyId;
  final InspectionTreePayload tree;
  final Map<String, Map<String, String>> allAnswers;
  final ScrollController? scrollController;

  static Future<void> show(
    BuildContext context, {
    required String surveyId,
    required InspectionTreePayload tree,
    required Map<String, Map<String, String>> allAnswers,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => AiConsistencySheet(
          surveyId: surveyId,
          tree: tree,
          allAnswers: allAnswers,
          scrollController: scrollController,
        ),
      ),
    );
  }

  @override
  ConsumerState<AiConsistencySheet> createState() =>
      _AiConsistencySheetState();
}

class _AiConsistencySheetState extends ConsumerState<AiConsistencySheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(aiInspectionConsistencyProvider.notifier).check(
            surveyId: widget.surveyId,
            tree: widget.tree,
            allAnswers: widget.allAnswers,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiInspectionConsistencyProvider);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: SingleChildScrollView(
        controller: widget.scrollController,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.fact_check_outlined,
                    size: 24, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Text(
                  'AI Consistency Check',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Checks for contradictions and missing data across all sections.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            if (state.isLoading) _buildLoading(theme),
            if (state.hasError) _buildError(theme, state.error!),
            if (state.hasResponse) ..._buildResults(theme, state.response!),
            const SizedBox(height: 8),
            _buildDisclaimer(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Analysing survey data...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'This may take up to 60 seconds.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(ThemeData theme, String error) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
          const SizedBox(height: 12),
          Text(
            error,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              ref.read(aiInspectionConsistencyProvider.notifier).check(
                    surveyId: widget.surveyId,
                    tree: widget.tree,
                    allAnswers: widget.allAnswers,
                  );
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildResults(ThemeData theme, AiConsistencyResponse response) {
    return [
      // Score badge
      _ScoreBadge(score: response.score),
      const SizedBox(height: 16),

      // Issue counts
      if (response.issues.isNotEmpty) ...[
        Text(
          'Issues Found (${response.issues.length})',
          style:
              theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        ...response.issues.map((issue) => _IssueCard(issue: issue)),
      ] else ...[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF2E7D32).withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF2E7D32).withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              const Icon(Icons.check_circle_outline,
                  size: 40, color: Color(0xFF2E7D32)),
              const SizedBox(height: 8),
              Text(
                'No Issues Found',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'The survey data appears consistent.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF2E7D32).withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    ];
  }

  Widget _buildDisclaimer(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'AI-generated analysis. Always verify results independently.',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final Color color;
    final String label;
    if (score >= 80) {
      color = const Color(0xFF2E7D32);
      label = 'Good';
    } else if (score >= 50) {
      color = const Color(0xFFE65100);
      label = 'Fair';
    } else {
      color = const Color(0xFFC62828);
      label = 'Needs Review';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.15),
              border: Border.all(color: color, width: 3),
            ),
            child: Center(
              child: Text(
                '$score',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Consistency Score',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IssueCard extends StatelessWidget {
  const _IssueCard({required this.issue});

  final ConsistencyIssue issue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final Color severityColor;
    final IconData severityIcon;
    switch (issue.severity) {
      case 'high':
        severityColor = const Color(0xFFC62828);
        severityIcon = Icons.error_outline;
        break;
      case 'medium':
        severityColor = const Color(0xFFE65100);
        severityIcon = Icons.warning_amber_outlined;
        break;
      default:
        severityColor = const Color(0xFF1565C0);
        severityIcon = Icons.info_outline;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: severityColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: severityColor.withOpacity(0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(severityIcon, size: 20, color: severityColor),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: severityColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          issue.severity.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: severityColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color:
                              theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          issue.type.replaceAll('_', ' '),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    issue.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      height: 1.4,
                    ),
                  ),
                  if (issue.suggestion != null &&
                      issue.suggestion!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer
                            .withOpacity(0.3),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.lightbulb_outline,
                              size: 14,
                              color: theme.colorScheme.primary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              issue.suggestion!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
