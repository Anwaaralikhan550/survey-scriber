import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/feature_flags/feature_flag_providers.dart';
import '../../../../core/feature_flags/feature_flags.dart';
import '../../../ai/presentation/providers/ai_inspection_providers.dart';
import '../../../ai/presentation/widgets/ai_consistency_sheet.dart';
import '../../../ai/presentation/widgets/ai_risk_sheet.dart';
import '../../../professional_recommendations/presentation/providers/recommendation_providers.dart';
import '../../../professional_recommendations/presentation/widgets/recommendation_sheet.dart';
import '../../../report_export/domain/models/report_document.dart';
import '../../../report_export/presentation/widgets/export_bottom_sheet.dart';
import '../../../surveys/presentation/providers/survey_detail_provider.dart';
import '../providers/valuation_providers.dart';
import '../../../../shared/presentation/widgets/survey_duration_timer.dart';
import '../../../../shared/presentation/widgets/survey_progress_card.dart';

class ValuationOverviewPage extends ConsumerWidget {
  const ValuationOverviewPage({
    required this.surveyId,
    super.key,
  });

  final String surveyId;

  static const _sectionIcons = <String, IconData>{
    'valuation_details': Icons.description_outlined,
    'property_assessment': Icons.assessment_outlined,
    'property_inspection': Icons.search_outlined,
    'condition_restrictions': Icons.gavel_outlined,
    'valuation_completion': Icons.verified_outlined,
  };

  static const _sectionColors = <String, Color>{
    'valuation_details': Color(0xFF1565C0),
    'property_assessment': Color(0xFF00796B),
    'property_inspection': Color(0xFF6A1B9A),
    'condition_restrictions': Color(0xFFE65100),
    'valuation_completion': Color(0xFF2E7D32),
  };

  static const _groupLabels = <String, String>{
    'valuation_details': 'Valuation Details',
    'property_assessment': 'Property Assessment',
    'property_inspection': 'Property Inspection',
    'condition_restrictions': 'Condition & Restrictions',
    'valuation_completion': 'Valuation & Completion',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surveyState = ref.watch(surveyDetailProvider(surveyId));
    final theme = Theme.of(context);
    final sectionsAsync = ref.watch(valuationSectionsProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          context.canPop() ? context.pop() : context.go(Routes.forms);
        }
      },
      child: Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(Routes.forms),
        ),
        title: Text(surveyState.survey?.title ?? 'Valuation'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SurveyHeaderCard(
              title: surveyState.survey?.title ?? 'Valuation',
              address: surveyState.survey?.address,
              jobRef: surveyState.survey?.jobRef,
              clientName: surveyState.survey?.clientName,
              surveyId: surveyId,
            ),
            const SizedBox(height: 12),
            if (surveyState.survey != null)
              SurveyProgressCard(
                completedSections: surveyState.survey!.completedSections,
                totalSections: surveyState.survey!.totalSections,
              ),
            const SizedBox(height: 20),
            sectionsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text('Failed to load sections: $error'),
              ),
              data: (sections) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final section in sections) ...[
                      _SectionCard(
                        surveyId: surveyId,
                        sectionKey: section.key,
                        title: _groupLabels[section.key] ?? section.title,
                        description: section.description,
                        color: _sectionColors[section.key] ?? theme.colorScheme.primary,
                        icon: _sectionIcons[section.key] ?? Icons.article_outlined,
                      ),
                      const SizedBox(height: 12),
                    ],
                    // AI Analysis
                    if (ref.watch(aiFeatureEnabledProvider(AiFeature.consistencyCheck))) ...[
                      _ValAiActionCard(
                        title: 'AI Consistency Check',
                        description: 'Find contradictions and missing data.',
                        icon: Icons.fact_check_outlined,
                        color: const Color(0xFF6A1B9A),
                        surveyId: surveyId,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (ref.watch(aiFeatureEnabledProvider(AiFeature.riskAssessment))) ...[
                      _ValAiActionCard(
                        title: 'AI Risk Assessment',
                        description: 'AI-powered property risk analysis.',
                        icon: Icons.shield_outlined,
                        color: const Color(0xFFC62828),
                        surveyId: surveyId,
                        isRisk: true,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (ref.watch(aiFeatureEnabledProvider(AiFeature.professionalRecommendations))) ...[
                      _ValRecommendationActionCard(surveyId: surveyId),
                      const SizedBox(height: 12),
                    ],
                    _ActionCard(
                      title: 'Attachments & Signatures',
                      description: 'Photos, sketches, and party signatures.',
                      color: const Color(0xFF00796B),
                      icon: Icons.attachment_rounded,
                      onTap: () => context.push(
                        '${Routes.surveyAttachmentsPath(surveyId)}?title=${Uri.encodeComponent(surveyState.survey?.title ?? 'Valuation')}',
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ActionCard(
                      title: 'Export Report',
                      description: 'Generate PDF or DOCX report.',
                      color: const Color(0xFF1565C0),
                      icon: Icons.picture_as_pdf_outlined,
                      onTap: () {
                        ExportBottomSheet.show(
                          context,
                          surveyId: surveyId,
                          surveyTitle:
                              surveyState.survey?.title ?? 'Valuation',
                          reportType: ReportType.valuation,
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _SurveyHeaderCard extends StatelessWidget {
  const _SurveyHeaderCard({
    required this.title,
    required this.address,
    required this.jobRef,
    required this.clientName,
    required this.surveyId,
  });

  final String title;
  final String? address;
  final String? jobRef;
  final String? clientName;
  final String surveyId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.surface,
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          if (address != null && address!.isNotEmpty)
            Text(
              address!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              if (jobRef != null && jobRef!.isNotEmpty)
                _InfoChip(label: 'Job Ref', value: jobRef!),
              if (clientName != null && clientName!.isNotEmpty)
                _InfoChip(label: 'Client', value: clientName!),
              SurveyDurationTimer(surveyId: surveyId),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SectionCard extends ConsumerWidget {
  const _SectionCard({
    required this.surveyId,
    required this.sectionKey,
    required this.title,
    required this.description,
    required this.color,
    required this.icon,
  });

  final String surveyId;
  final String sectionKey;
  final String title;
  final String description;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final nodesAsync = ref.watch(
        valuationNodesProvider((surveyId: surveyId, sectionKey: sectionKey)));

    final trailing = nodesAsync.when(
      data: (nodes) {
        final screenNodes = nodes.where((n) => n.nodeType == 'screen').toList();
        return _ProgressBadge(
          completed: screenNodes.where((s) => s.isCompleted).length,
          total: screenNodes.length,
        );
      },
      loading: () => const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, __) => Icon(
        Icons.error_outline_rounded,
        size: 20,
        color: theme.colorScheme.error,
      ),
    );

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => context.push(Routes.valuationSectionPath(surveyId, sectionKey)),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.4),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: 24,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description.isEmpty ? 'Open $title' : description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
    this.icon = Icons.verified_outlined,
  });

  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.4),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: 24,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ValAiActionCard extends ConsumerWidget {
  const _ValAiActionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.surveyId,
    this.isRisk = false,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String surveyId;
  final bool isRisk;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final treeAsync = ref.watch(aiValuationTreeProvider);
    final answersAsync = ref.watch(aiValuationAllAnswersProvider(surveyId));

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          final tree = treeAsync.valueOrNull;
          final answers = answersAsync.valueOrNull;
          if (tree == null || answers == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Loading survey data...')),
            );
            return;
          }
          if (isRisk) {
            final surveyState = ref.read(surveyDetailProvider(surveyId));
            final survey = surveyState.survey;
            if (survey == null) return;
            AiRiskSheet.show(
              context,
              surveyId: surveyId,
              survey: survey,
              tree: tree,
              allAnswers: answers,
            );
          } else {
            AiConsistencySheet.show(
              context,
              surveyId: surveyId,
              tree: tree,
              allAnswers: answers,
            );
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.2), color.withOpacity(0.08)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(child: Icon(icon, size: 24, color: color)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'AI',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w800,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.auto_awesome_outlined,
                size: 20,
                color: color.withOpacity(0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ValRecommendationActionCard extends ConsumerWidget {
  const _ValRecommendationActionCard({required this.surveyId});

  final String surveyId;

  static const _kTeal = Color(0xFF00695C);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final treeAsync = ref.watch(aiValuationTreeProvider);
    final answersAsync = ref.watch(aiValuationAllAnswersProvider(surveyId));
    final recState = ref.watch(recommendationProvider);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          final tree = treeAsync.valueOrNull;
          final answers = answersAsync.valueOrNull;
          if (tree == null || answers == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Loading survey data...')),
            );
            return;
          }
          RecommendationSheet.show(
            context,
            surveyId: surveyId,
            tree: tree,
            allAnswers: answers,
            isValuation: true,
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _kTeal.withOpacity(0.4)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _kTeal.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Icon(
                    Icons.assignment_turned_in_outlined,
                    size: 24,
                    color: _kTeal,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Professional Recommendations',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'RICS-based analysis of report quality and completeness.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (recState.isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _kTeal,
                  ),
                )
              else if (recState.hasResult)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _kTeal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${recState.result!.recommendations.length}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: _kTeal,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressBadge extends StatelessWidget {
  const _ProgressBadge({
    required this.completed,
    required this.total,
  });

  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$completed/$total',
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
