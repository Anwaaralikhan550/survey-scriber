import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../property_inspection/domain/models/inspection_models.dart';
import '../../domain/models/professional_recommendation.dart';
import '../providers/recommendation_providers.dart';

/// Teal color scheme for the professional recommendations feature.
const _kTeal = Color(0xFF00695C);
const _kTealLight = Color(0xFFE0F2F1);

/// Full bottom sheet displaying categorised professional recommendations.
class RecommendationSheet extends ConsumerStatefulWidget {
  const RecommendationSheet({
    required this.surveyId,
    required this.tree,
    required this.allAnswers,
    required this.isValuation,
    super.key,
  });

  final String surveyId;
  final InspectionTreePayload tree;
  final Map<String, Map<String, String>> allAnswers;
  final bool isValuation;

  static Future<void> show(
    BuildContext context, {
    required String surveyId,
    required InspectionTreePayload tree,
    required Map<String, Map<String, String>> allAnswers,
    required bool isValuation,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => RecommendationSheet(
        surveyId: surveyId,
        tree: tree,
        allAnswers: allAnswers,
        isValuation: isValuation,
      ),
    );
  }

  @override
  ConsumerState<RecommendationSheet> createState() =>
      _RecommendationSheetState();
}

class _RecommendationSheetState extends ConsumerState<RecommendationSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(recommendationProvider.notifier).analyze(
            surveyId: widget.surveyId,
            tree: widget.tree,
            allAnswers: widget.allAnswers,
            isValuation: widget.isValuation,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recommendationProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Drag handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _kTealLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.assignment_turned_in_outlined,
                        color: _kTeal,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Professional Recommendations',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'RICS-based quality analysis',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // AI loading indicator
              if (state.isAiLoading)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  color: const Color(0xFFFFF8E1),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFF9A825),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Enhancing with professional analysis...',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFFF57F17),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

              // Body
              Expanded(
                child: state.isLoading
                    ? _buildLoading(theme)
                    : state.hasError
                        ? _buildError(state.error!, theme, colorScheme)
                        : state.hasResult
                            ? _buildResults(
                                state.result!, theme, colorScheme,
                                scrollController)
                            : _buildLoading(theme),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoading(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: _kTeal,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Analysing survey data...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String error, ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Analysis Failed',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(
    ProfessionalRecommendationsResult result,
    ThemeData theme,
    ColorScheme colorScheme,
    ScrollController scrollController,
  ) {
    if (result.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: _kTealLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_outline,
                    size: 36, color: _kTeal),
              ),
              const SizedBox(height: 16),
              Text(
                'No Recommendations',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'The survey data meets RICS professional standards. '
                'No additional observations are required at this time.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final categories = RecommendationCategory.values
        .where((c) => result.byCategory(c).isNotEmpty)
        .toList();

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        // Summary banner
        _SummaryBanner(result: result),
        const SizedBox(height: 12),

        // Quality scores dashboard
        if (result.scores != null) ...[
          _QualityScoresDashboard(scores: result.scores!),
          const SizedBox(height: 16),
        ],

        // Category groups
        for (final category in categories) ...[
          _CategoryHeader(category: category),
          const SizedBox(height: 8),
          for (final rec in result.byCategory(category)) ...[
            _RecommendationCard(recommendation: rec),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 8),
        ],

        // Footer
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            'Based on RICS Home Survey Standard guidelines.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

// ── Summary Banner ──────────────────────────────────────────────────────

class _SummaryBanner extends StatelessWidget {
  const _SummaryBanner({required this.result});
  final ProfessionalRecommendationsResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00695C), Color(0xFF00897B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${result.recommendations.length} Observations',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _SeverityChip(
                label: '${result.highCount} High',
                color: const Color(0xFFC62828),
              ),
              const SizedBox(width: 8),
              _SeverityChip(
                label: '${result.moderateCount} Moderate',
                color: const Color(0xFFE65100),
              ),
              const SizedBox(width: 8),
              _SeverityChip(
                label: '${result.lowCount} Low',
                color: const Color(0xFF1565C0),
              ),
            ],
          ),
          if (result.ruleCount > 0 || result.aiCount > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (result.ruleCount > 0)
                  Text(
                    '${result.ruleCount} rule-based',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                if (result.ruleCount > 0 && result.aiCount > 0)
                  Text(
                    ' · ',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white54,
                    ),
                  ),
                if (result.aiCount > 0)
                  Text(
                    '${result.aiCount} AI-enhanced',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                if (result.acceptedCount > 0) ...[
                  Text(
                    ' · ',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white54,
                    ),
                  ),
                  Text(
                    '${result.acceptedCount} accepted',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SeverityChip extends StatelessWidget {
  const _SeverityChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ── Category Header ─────────────────────────────────────────────────────

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({required this.category});
  final RecommendationCategory category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(_iconFor(category), size: 18, color: _kTeal),
          const SizedBox(width: 8),
          Text(
            category.displayName,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: _kTeal,
            ),
          ),
        ],
      ),
    );
  }

  static IconData _iconFor(RecommendationCategory c) {
    return switch (c) {
      RecommendationCategory.compliance => Icons.gavel_outlined,
      RecommendationCategory.narrativeStrength => Icons.edit_note_outlined,
      RecommendationCategory.riskClarification => Icons.warning_amber_outlined,
      RecommendationCategory.dataGaps => Icons.data_usage_outlined,
      RecommendationCategory.valuationJustification =>
        Icons.account_balance_outlined,
    };
  }
}

// ── Recommendation Card ─────────────────────────────────────────────────

class _RecommendationCard extends ConsumerWidget {
  const _RecommendationCard({required this.recommendation});
  final ProfessionalRecommendation recommendation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final severityColor = _severityColor(recommendation.severity);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: severity badge + screen title
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            decoration: BoxDecoration(
              color: severityColor.withOpacity(0.06),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: severityColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    recommendation.severity.displayName.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: severityColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Source badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: recommendation.source == RecommendationSource.ai
                        ? const Color(0xFF7B1FA2).withOpacity(0.1)
                        : _kTeal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    recommendation.source.displayName,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: recommendation.source == RecommendationSource.ai
                          ? const Color(0xFF7B1FA2)
                          : _kTeal,
                    ),
                  ),
                ),
                // Confidence indicator (AI only)
                if (recommendation.confidenceScore != null) ...[
                  const SizedBox(width: 6),
                  _ConfidenceDot(
                    confidence: recommendation.confidenceScore!,
                  ),
                ],
                const Spacer(),
                if (recommendation.accepted)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle,
                          size: 14, color: Color(0xFF2E7D32)),
                      const SizedBox(width: 4),
                      Text(
                        'Added',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: const Color(0xFF2E7D32),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Reason
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Text(
              recommendation.reason,
              style: theme.textTheme.bodySmall?.copyWith(
                height: 1.5,
              ),
            ),
          ),

          // Suggested text
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _kTealLight,
                borderRadius: BorderRadius.circular(8),
                border: Border(
                  left: BorderSide(color: _kTeal, width: 3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Suggested narrative',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: _kTeal,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    recommendation.suggestedText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Action button
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: recommendation.accepted
                ? OutlinedButton.icon(
                    onPressed: () => ref
                        .read(recommendationProvider.notifier)
                        .setAccepted(recommendation.id, accepted: false),
                    icon: const Icon(Icons.remove_circle_outline, size: 16),
                    label: const Text('Remove from Report'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.error,
                      side: BorderSide(color: colorScheme.error.withOpacity(0.3)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      textStyle: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : FilledButton.tonalIcon(
                    onPressed: () => ref
                        .read(recommendationProvider.notifier)
                        .setAccepted(recommendation.id, accepted: true),
                    icon: const Icon(Icons.add_circle_outline, size: 16),
                    label: const Text('Add to Report'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _kTealLight,
                      foregroundColor: _kTeal,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      textStyle: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  static Color _severityColor(RecommendationSeverity s) {
    return switch (s) {
      RecommendationSeverity.high => const Color(0xFFC62828),
      RecommendationSeverity.moderate => const Color(0xFFE65100),
      RecommendationSeverity.low => const Color(0xFF1565C0),
    };
  }
}

// ── Quality Scores Dashboard ────────────────────────────────────────────

class _QualityScoresDashboard extends StatelessWidget {
  const _QualityScoresDashboard({required this.scores});
  final QualityScores scores;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_outlined, size: 16, color: _kTeal),
              const SizedBox(width: 6),
              Text(
                'Quality Scores',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: _kTeal,
                ),
              ),
              const Spacer(),
              _ScorePill(
                label: 'Overall',
                score: scores.overallScore,
                bold: true,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ScoreBar(
                  label: 'Compliance',
                  score: scores.complianceScore,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ScoreBar(
                  label: 'Narrative',
                  score: scores.narrativeScore,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ScoreBar(
                  label: 'Risk',
                  score: scores.riskScore,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScoreBar extends StatelessWidget {
  const _ScoreBar({required this.label, required this.score});
  final String label;
  final double score;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _scoreColor(score);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              '${score.toStringAsFixed(0)}%',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: score / 100,
            backgroundColor: theme.colorScheme.outlineVariant.withOpacity(0.3),
            color: color,
            minHeight: 4,
          ),
        ),
      ],
    );
  }

  static Color _scoreColor(double score) {
    if (score >= 80) return const Color(0xFF2E7D32);
    if (score >= 60) return const Color(0xFFF9A825);
    return const Color(0xFFC62828);
  }
}

class _ScorePill extends StatelessWidget {
  const _ScorePill({
    required this.label,
    required this.score,
    this.bold = false,
  });
  final String label;
  final double score;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final color = _ScoreBar._scoreColor(score);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '${score.toStringAsFixed(0)}%',
        style: TextStyle(
          fontSize: 12,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ── Confidence Indicator ────────────────────────────────────────────────

class _ConfidenceDot extends StatelessWidget {
  const _ConfidenceDot({required this.confidence});
  final double confidence;

  @override
  Widget build(BuildContext context) {
    final color = confidence >= 0.8
        ? const Color(0xFF2E7D32)
        : confidence >= 0.5
            ? const Color(0xFFF9A825)
            : const Color(0xFFC62828);
    return Tooltip(
      message: 'Confidence: ${(confidence * 100).toStringAsFixed(0)}%',
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
