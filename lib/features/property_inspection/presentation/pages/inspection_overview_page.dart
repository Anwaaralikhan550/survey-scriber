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
import '../providers/inspection_providers.dart';
import '../../domain/models/inspection_models.dart';
import '../../../../shared/presentation/widgets/survey_duration_timer.dart';
import '../../../../shared/presentation/widgets/survey_progress_card.dart';

class InspectionOverviewPage extends ConsumerWidget {
  const InspectionOverviewPage({
    required this.surveyId,
    super.key,
  });

  final String surveyId;

  static const _sectionIcons = <String, IconData>{
    'A': Icons.assignment_outlined,
    'D': Icons.home_outlined,
    'E': Icons.roofing_outlined,
    'H': Icons.yard_outlined,
    'F': Icons.door_front_door_outlined,
    'G': Icons.electrical_services_outlined,
    'R': Icons.meeting_room_outlined,
    'I': Icons.gavel_outlined,
    'J': Icons.shield_outlined,
    'O': Icons.summarize_outlined,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surveyState = ref.watch(surveyDetailProvider(surveyId));
    final theme = Theme.of(context);
    final sectionsAsync = ref.watch(inspectionSectionsProvider);
    final orderedKeys = <String>['A', 'D', 'E', 'H', 'F', 'G', 'R', 'I', 'J'];
    final colorMap = <String, Color>{
      'A': theme.colorScheme.primary,
      'D': theme.colorScheme.primary,
      'E': theme.colorScheme.tertiary,
      'F': theme.colorScheme.secondary,
      'G': const Color(0xFF00796B),
      'H': const Color(0xFF2E7D32),
      'I': const Color(0xFFE65100),
      'J': theme.colorScheme.error,
      'R': theme.colorScheme.secondary,
    };
    final displayOverride = <String, String>{
      'R': 'Room Details',
      'G': 'Services',
      'E': 'Outside the Property',
      'F': 'Inside the Property',
      'H': 'Grounds',
      'I': 'Issues for Legal Advisers',
      'J': 'Risks',
    };

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
        title: Text(surveyState.survey?.title ?? 'Inspection'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SurveyHeaderCard(
              title: surveyState.survey?.title ?? 'Inspection',
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
            const SizedBox(height: 12),
            _ConditionSummaryCard(surveyId: surveyId),
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
                final sectionMap = {for (final s in sections) s.key: s};
                final orderedSections = [
                  for (final key in orderedKeys)
                    if (sectionMap.containsKey(key)) sectionMap[key]!,
                ];

                final grouped = <String, List<InspectionSectionDefinition>>{
                  'Property Information': [],
                  'External Inspection': [],
                  'Internal Inspection': [],
                  'Assessment & Issues': [],
                  'Documentation & Completion': [],
                };

                for (final section in orderedSections) {
                  switch (section.key) {
                    case 'A':
                    case 'D':
                      grouped['Property Information']!.add(section);
                      break;
                    case 'E':
                    case 'H':
                      grouped['External Inspection']!.add(section);
                      break;
                    case 'F':
                    case 'G':
                    case 'R':
                      grouped['Internal Inspection']!.add(section);
                      break;
                    case 'I':
                    case 'J':
                      grouped['Assessment & Issues']!.add(section);
                      break;
                  }
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final entry in grouped.entries) ...[
                      Text(
                        entry.key,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      for (final section in entry.value) ...[
                        _SectionCard(
                          surveyId: surveyId,
                          sectionKey: section.key,
                          title: displayOverride[section.key] ?? section.title,
                          description: section.description.isEmpty
                              ? 'Open ${displayOverride[section.key] ?? section.title}'
                              : section.description,
                          color: colorMap[section.key] ?? theme.colorScheme.primary,
                          icon: _sectionIcons[section.key] ?? Icons.article_outlined,
                          enabled: true,
                        ),
                        const SizedBox(height: 12),
                      ],
                      // AI Features — after Assessment & Issues
                      if (entry.key == 'Assessment & Issues') ...[
                        const SizedBox(height: 4),
                        Text(
                          'AI Analysis',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (ref.watch(aiFeatureEnabledProvider(AiFeature.consistencyCheck))) ...[
                          _AiActionCard(
                            title: 'AI Consistency Check',
                            description: 'Find contradictions and missing data across all sections.',
                            icon: Icons.fact_check_outlined,
                            color: const Color(0xFF6A1B9A),
                            surveyId: surveyId,
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (ref.watch(aiFeatureEnabledProvider(AiFeature.riskAssessment))) ...[
                          _AiActionCard(
                            title: 'AI Risk Assessment',
                            description: 'AI-powered analysis of property risks and actions.',
                            icon: Icons.shield_outlined,
                            color: const Color(0xFFC62828),
                            surveyId: surveyId,
                            isRisk: true,
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (ref.watch(aiFeatureEnabledProvider(AiFeature.professionalRecommendations))) ...[
                          _RecommendationActionCard(surveyId: surveyId),
                          const SizedBox(height: 12),
                        ],
                      ],
                      if (entry.key == 'Documentation & Completion') ...[
                        _ActionCard(
                          title: 'Attachments & Signatures',
                          description: 'Photos, sketches, and party signatures.',
                          icon: Icons.attachment_rounded,
                          color: const Color(0xFF00796B),
                          onTap: () => context.push(
                            '${Routes.surveyAttachmentsPath(surveyId)}?title=${Uri.encodeComponent(surveyState.survey?.title ?? 'Inspection')}',
                          ),
                        ),
                        const SizedBox(height: 12),
                        _ActionCard(
                          title: 'Export Report',
                          description: 'Generate PDF or DOCX report.',
                          color: const Color(0xFF1565C0),
                          onTap: () {
                            ExportBottomSheet.show(
                              context,
                              surveyId: surveyId,
                              surveyTitle:
                                  surveyState.survey?.title ?? 'Inspection',
                              reportType: ReportType.inspection,
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                    ],
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
    required this.enabled,
  });

  final String surveyId;
  final String sectionKey;
  final String title;
  final String description;
  final Color color;
  final IconData icon;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final nodesAsync = enabled
        ? ref.watch(inspectionNodesProvider((surveyId: surveyId, sectionKey: sectionKey)))
        : null;

    final trailing = enabled
        ? nodesAsync!.when(
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
          )
        : const _ComingSoonBadge();

    return Material(
      color: enabled ? theme.colorScheme.surface : theme.colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: enabled
            ? () => context.push(Routes.inspectionSectionPath(surveyId, sectionKey))
            : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: enabled
                  ? color.withOpacity(0.4)
                  : theme.colorScheme.outlineVariant.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(enabled ? 0.15 : 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: 24,
                    color: enabled ? color : theme.colorScheme.onSurfaceVariant,
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

class _AiActionCard extends ConsumerWidget {
  const _AiActionCard({
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
    final treeAsync = ref.watch(aiInspectionTreeProvider);
    final answersAsync = ref.watch(aiInspectionAllAnswersProvider(surveyId));

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

class _RecommendationActionCard extends ConsumerWidget {
  const _RecommendationActionCard({required this.surveyId});

  final String surveyId;

  static const _kTeal = Color(0xFF00695C);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final treeAsync = ref.watch(aiInspectionTreeProvider);
    final answersAsync = ref.watch(aiInspectionAllAnswersProvider(surveyId));
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
            isValuation: false,
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

class _ConditionSummaryCard extends ConsumerWidget {
  const _ConditionSummaryCard({required this.surveyId});

  final String surveyId;

  static const _sectionLabels = <String, String>{
    'E': 'External',
    'F': 'Internal',
    'G': 'Services',
    'H': 'Grounds',
  };

  static const _displayOrder = ['E', 'F', 'G', 'H'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync =
        ref.watch(inspectionConditionSummaryProvider(surveyId));
    final theme = Theme.of(context);

    return summaryAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (ratingsBySection) {
        // Only show if at least one rating exists
        if (ratingsBySection.isEmpty) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(14),
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
              Row(
                children: [
                  Icon(
                    Icons.assessment_outlined,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Condition Overview',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final key in _displayOrder)
                    if (ratingsBySection.containsKey(key))
                      _ConditionBadge(
                        label: _sectionLabels[key] ?? key,
                        ratings: ratingsBySection[key]!,
                      ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ConditionBadge extends StatelessWidget {
  const _ConditionBadge({
    required this.label,
    required this.ratings,
  });

  final String label;
  final List<String> ratings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Determine worst condition: 1=Good (green), 2=Fair (amber), 3=Poor (red)
    int worst = 0;
    for (final r in ratings) {
      final v = int.tryParse(r) ?? 0;
      if (v > worst) worst = v;
    }

    final Color badgeColor;
    final String conditionLabel;
    switch (worst) {
      case 1:
        badgeColor = const Color(0xFF2E7D32);
        conditionLabel = '1';
        break;
      case 2:
        badgeColor = const Color(0xFFE65100);
        conditionLabel = '2';
        break;
      case 3:
        badgeColor = const Color(0xFFC62828);
        conditionLabel = '3';
        break;
      default:
        badgeColor = theme.colorScheme.onSurfaceVariant;
        conditionLabel = '-';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: badgeColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$label: $conditionLabel',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: badgeColor,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '(${ratings.length})',
            style: theme.textTheme.labelSmall?.copyWith(
              color: badgeColor.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComingSoonBadge extends StatelessWidget {
  const _ComingSoonBadge();

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
        'Soon',
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
