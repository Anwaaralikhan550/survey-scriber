import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../property_inspection/domain/models/inspection_models.dart';
import '../../../../shared/domain/entities/survey.dart';
import '../../domain/entities/ai_response.dart';
import '../providers/ai_inspection_providers.dart';

/// Bottom sheet displaying AI risk assessment results for a survey.
///
/// Shows: overall risk level, key risks, positives, action items.
/// AI never overwrites user text — results are read-only.
class AiRiskSheet extends ConsumerStatefulWidget {
  const AiRiskSheet({
    required this.surveyId,
    required this.survey,
    required this.tree,
    required this.allAnswers,
    this.scrollController,
    super.key,
  });

  final String surveyId;
  final Survey survey;
  final InspectionTreePayload tree;
  final Map<String, Map<String, String>> allAnswers;
  final ScrollController? scrollController;

  static Future<void> show(
    BuildContext context, {
    required String surveyId,
    required Survey survey,
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
        builder: (context, scrollController) => AiRiskSheet(
          surveyId: surveyId,
          survey: survey,
          tree: tree,
          allAnswers: allAnswers,
          scrollController: scrollController,
        ),
      ),
    );
  }

  @override
  ConsumerState<AiRiskSheet> createState() => _AiRiskSheetState();
}

class _AiRiskSheetState extends ConsumerState<AiRiskSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(aiInspectionRiskProvider.notifier).generate(
            surveyId: widget.surveyId,
            survey: widget.survey,
            tree: widget.tree,
            allAnswers: widget.allAnswers,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiInspectionRiskProvider);
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
                Icon(Icons.shield_outlined,
                    size: 24, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Text(
                  'AI Risk Assessment',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'AI-powered analysis of property risks and recommended actions.',
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
              'Assessing property risks...',
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
              ref.read(aiInspectionRiskProvider.notifier).generate(
                    surveyId: widget.surveyId,
                    survey: widget.survey,
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

  List<Widget> _buildResults(
      ThemeData theme, AiRiskSummaryResponse response) {
    return [
      // Overall risk level
      _RiskLevelBanner(
        level: response.overallRiskLevel,
        summary: response.summary,
      ),
      const SizedBox(height: 16),

      // Key risks
      if (response.keyRisks.isNotEmpty) ...[
        _SectionHeader(title: 'Key Risks', icon: Icons.warning_amber_outlined),
        const SizedBox(height: 8),
        ...response.keyRisks.map((risk) => _RiskItemCard(risk: risk)),
        const SizedBox(height: 16),
      ],

      // Key positives
      if (response.keyPositives.isNotEmpty) ...[
        _SectionHeader(title: 'Positives', icon: Icons.thumb_up_outlined),
        const SizedBox(height: 8),
        ...response.keyPositives
            .map((p) => _BulletItem(text: p, color: const Color(0xFF2E7D32))),
        const SizedBox(height: 16),
      ],

      // Immediate actions
      if (response.immediateActions.isNotEmpty) ...[
        _SectionHeader(
            title: 'Immediate Actions', icon: Icons.priority_high_outlined),
        const SizedBox(height: 8),
        ...response.immediateActions
            .map((a) => _BulletItem(text: a, color: const Color(0xFFC62828))),
        const SizedBox(height: 16),
      ],

      // Short-term actions
      if (response.shortTermActions.isNotEmpty) ...[
        _SectionHeader(
            title: 'Short-Term Actions', icon: Icons.schedule_outlined),
        const SizedBox(height: 8),
        ...response.shortTermActions
            .map((a) => _BulletItem(text: a, color: const Color(0xFFE65100))),
        const SizedBox(height: 16),
      ],

      // Data gaps
      if (response.dataGaps.isNotEmpty) ...[
        _SectionHeader(
            title: 'Data Gaps', icon: Icons.help_outline),
        const SizedBox(height: 8),
        ...response.dataGaps.map(
            (g) => _BulletItem(text: g, color: theme.colorScheme.primary)),
        const SizedBox(height: 16),
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

class _RiskLevelBanner extends StatelessWidget {
  const _RiskLevelBanner({required this.level, required this.summary});

  final String level;
  final String summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final Color color;
    final IconData icon;
    final String label;
    switch (level.toLowerCase()) {
      case 'high':
        color = const Color(0xFFC62828);
        icon = Icons.dangerous_outlined;
        label = 'HIGH RISK';
        break;
      case 'medium':
        color = const Color(0xFFE65100);
        icon = Icons.warning_amber_outlined;
        label = 'MEDIUM RISK';
        break;
      default:
        color = const Color(0xFF2E7D32);
        icon = Icons.verified_outlined;
        label = 'LOW RISK';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.12), color.withOpacity(0.04)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 28, color: color),
              const SizedBox(width: 10),
              Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          if (summary.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              summary,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 6),
        Text(
          title,
          style:
              theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _RiskItemCard extends StatelessWidget {
  const _RiskItemCard({required this.risk});

  final RiskItem risk;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final Color color;
    switch (risk.level) {
      case 'high':
        color = const Color(0xFFC62828);
        break;
      case 'medium':
        color = const Color(0xFFE65100);
        break;
      default:
        color = const Color(0xFF1565C0);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 5),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
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
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          risk.level.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        risk.category,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    risk.description,
                    style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BulletItem extends StatelessWidget {
  const _BulletItem({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
