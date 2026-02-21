import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/ai_repository.dart' as repo;
import '../providers/ai_providers.dart';
import 'ai_action_button.dart';
import 'ai_result_sheet.dart';
import 'ai_summary_section.dart';

/// A button that generates AI risk summary when pressed
class AiRiskSummaryButton extends ConsumerWidget {
  const AiRiskSummaryButton({
    required this.surveyId,
    required this.propertyAddress,
    required this.sections,
    this.propertyType,
    this.issues,
    this.onAccepted,
    this.isCompact = false,
    super.key,
  });

  final String surveyId;
  final String propertyAddress;
  final String? propertyType;
  final List<SectionAnswersInput> sections;
  final List<IssueInput>? issues;
  final ValueChanged<String>? onAccepted;
  final bool isCompact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aiStatus = ref.watch(aiStatusProvider);
    final riskState = ref.watch(aiRiskSummaryNotifierProvider);

    return aiStatus.when(
      data: (status) {
        final isAvailable = status.available;
        return _buildButton(
          context,
          ref,
          isEnabled: isAvailable,
          isLoading: riskState.isLoading,
          disabledReason: isAvailable ? null : 'AI service unavailable',
        );
      },
      loading: () => Tooltip(
        message: 'Checking AI availability...',
        child: AiButtonSkeleton(isCompact: isCompact),
      ),
      error: (_, __) => _buildButton(
        context,
        ref,
        isEnabled: false,
        isLoading: false,
        disabledReason: 'AI service unavailable',
      ),
    );
  }

  Widget _buildButton(
    BuildContext context,
    WidgetRef ref, {
    required bool isEnabled,
    required bool isLoading,
    String? disabledReason,
  }) => Tooltip(
      message: disabledReason ?? 'Generate AI risk summary',
      child: AiActionButton(
        label: 'AI Risk Summary',
        icon: Icons.shield_outlined,
        isLoading: isLoading,
        isCompact: isCompact,
        isOutlined: true,
        onPressed: isEnabled ? () => _generateRiskSummary(context, ref) : null,
      ),
    );

  Future<void> _generateRiskSummary(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(aiRiskSummaryNotifierProvider.notifier);

    final request = repo.GenerateRiskSummaryRequest(
      surveyId: surveyId,
      propertyAddress: propertyAddress,
      propertyType: propertyType,
      sections: sections,
      issues: issues,
    );

    await notifier.generateRiskSummary(request);

    final state = ref.read(aiRiskSummaryNotifierProvider);

    if (!context.mounted) return;

    if (state.hasResponse && state.response != null) {
      final response = state.response!;
      final content = _formatRiskSummary(response);

      final accepted = await AiResultSheet.show(
        context: context,
        title: 'Risk Summary',
        content: content,
        disclaimer: AiDisclaimers.riskSummary,
        onRetry: () => _generateRiskSummary(context, ref),
        isEditable: false,
      );

      if (accepted == true && onAccepted != null) {
        onAccepted!(response.summary);
      }
    } else if (state.error != null) {
      // Show specific message for service unavailability (503)
      final errorMessage = state.isServiceUnavailable
          ? 'AI service is temporarily unavailable. Please try again in a few moments.'
          : 'Unable to generate risk summary. Please try again.';
      final errorTitle = state.isServiceUnavailable
          ? 'Service Unavailable'
          : 'Generation Failed';
      AiErrorSheet.show(
        context: context,
        title: errorTitle,
        errorMessage: errorMessage,
        onRetry: () => _generateRiskSummary(context, ref),
      );
    }
  }

  String _formatRiskSummary(dynamic response) {
    final buffer = StringBuffer();

    buffer.writeln('OVERALL RISK: ${response.overallRiskLevel.toUpperCase()}');
    buffer.writeln();

    // Overall rationale
    if (response.overallRationale.isNotEmpty) {
      buffer.writeln('WHY THIS RISK LEVEL:');
      for (final line in response.overallRationale) {
        buffer.writeln('  $line');
      }
      buffer.writeln();
    }

    // Summary narrative
    buffer.writeln(response.summary);

    // Key risk drivers
    if (response.keyRiskDrivers.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('KEY RISK DRIVERS:');
      for (final driver in response.keyRiskDrivers) {
        buffer.writeln('- $driver');
      }
    }

    // Risk by category
    if (response.riskByCategory.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('RISK BY CATEGORY:');
      for (final cat in response.riskByCategory) {
        buffer.writeln();
        buffer.writeln('  ${cat.category.toUpperCase()} [${cat.risk.toUpperCase()}]');
        for (final evidence in cat.evidence) {
          buffer.writeln('    Evidence: $evidence');
        }
        for (final verify in cat.verifyNext) {
          buffer.writeln('    Verify: $verify');
        }
      }
    }

    // Key risks (legacy format)
    if (response.keyRisks.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('KEY RISKS:');
      for (final risk in response.keyRisks) {
        buffer.writeln('- [${risk.level.toUpperCase()}] ${risk.category}: ${risk.description}');
      }
    }

    // Immediate actions
    if (response.immediateActions.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('IMMEDIATE ACTIONS (0-7 DAYS):');
      for (final action in response.immediateActions) {
        buffer.writeln('- $action');
      }
    }

    // Short-term actions
    if (response.shortTermActions.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('SHORT TERM ACTIONS (1-3 MONTHS):');
      for (final action in response.shortTermActions) {
        buffer.writeln('- $action');
      }
    }

    // Long-term actions
    if (response.longTermActions.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('LONG TERM ACTIONS (3-12 MONTHS):');
      for (final action in response.longTermActions) {
        buffer.writeln('- $action');
      }
    }

    // Positives
    if (response.keyPositives.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('POSITIVES:');
      for (final positive in response.keyPositives) {
        buffer.writeln('+ $positive');
      }
    }

    // Data gaps
    if (response.dataGaps.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('DATA GAPS AND MISSING ASSESSMENTS:');
      for (final gap in response.dataGaps) {
        buffer.writeln('! $gap');
      }
    }

    return buffer.toString();
  }
}

/// A button that generates AI recommendations when pressed.
/// Works with explicit issues or section data (infers concerns from sections).
class AiRecommendationsButton extends ConsumerWidget {
  const AiRecommendationsButton({
    required this.surveyId,
    required this.propertyAddress,
    this.issues = const [],
    this.sections = const [],
    this.propertyType,
    this.onAccepted,
    this.isCompact = false,
    super.key,
  });

  final String surveyId;
  final String propertyAddress;
  final String? propertyType;
  final List<IssueInput> issues;
  final List<SectionAnswersInput> sections;
  final ValueChanged<String>? onAccepted;
  final bool isCompact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aiStatus = ref.watch(aiStatusProvider);
    final recState = ref.watch(aiRecommendationsNotifierProvider);
    final hasData = issues.isNotEmpty || sections.isNotEmpty;

    return aiStatus.when(
      data: (status) {
        final isAvailable = status.available;
        return _buildButton(
          context,
          ref,
          isEnabled: isAvailable && hasData,
          isLoading: recState.isLoading,
          disabledReason: _getDisabledReason(isAvailable, hasData),
        );
      },
      loading: () => Tooltip(
        message: 'Checking AI availability...',
        child: AiButtonSkeleton(isCompact: isCompact),
      ),
      error: (_, __) => _buildButton(
        context,
        ref,
        isEnabled: false,
        isLoading: false,
        disabledReason: 'AI service unavailable',
      ),
    );
  }

  String? _getDisabledReason(bool isAvailable, bool hasData) {
    if (!isAvailable) return 'AI service unavailable';
    if (!hasData) return 'Add inspection data to get recommendations';
    return null;
  }

  Widget _buildButton(
    BuildContext context,
    WidgetRef ref, {
    required bool isEnabled,
    required bool isLoading,
    String? disabledReason,
  }) => Tooltip(
      message: disabledReason ?? 'Generate AI recommendations',
      child: AiActionButton(
        label: 'AI Recommendations',
        icon: Icons.lightbulb_outline,
        isLoading: isLoading,
        isCompact: isCompact,
        isOutlined: true,
        onPressed: isEnabled ? () => _generateRecommendations(context, ref) : null,
      ),
    );

  Future<void> _generateRecommendations(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(aiRecommendationsNotifierProvider.notifier);

    final request = repo.GenerateRecommendationsRequest(
      surveyId: surveyId,
      propertyAddress: propertyAddress,
      propertyType: propertyType,
      issues: issues,
      sections: sections.isNotEmpty ? sections : null,
    );

    await notifier.generateRecommendations(request);

    final state = ref.read(aiRecommendationsNotifierProvider);

    if (!context.mounted) return;

    if (state.hasResponse && state.response != null) {
      final response = state.response!;
      final content = _formatRecommendations(response);

      final accepted = await AiResultSheet.show(
        context: context,
        title: 'Repair Recommendations',
        content: content,
        disclaimer: AiDisclaimers.recommendations,
        onRetry: () => _generateRecommendations(context, ref),
        isEditable: false,
      );

      if (accepted == true && onAccepted != null) {
        onAccepted!(content);
      }
    } else if (state.error != null) {
      final isUnavailable = state.error!.contains('503') ||
          state.error!.contains('unavailable') ||
          state.error!.contains('timeout');
      AiErrorSheet.show(
        context: context,
        title: isUnavailable ? 'Service Unavailable' : 'Generation Failed',
        errorMessage: isUnavailable
            ? 'AI service is temporarily unavailable. Please try again in a few moments.'
            : 'Unable to generate recommendations. Please try again.',
        onRetry: () => _generateRecommendations(context, ref),
      );
    }
  }

  String _formatRecommendations(dynamic response) {
    final buffer = StringBuffer();

    final byPriority = <String, List<dynamic>>{};
    for (final rec in response.recommendations) {
      byPriority.putIfAbsent(rec.priority, () => []).add(rec);
    }

    final priorityOrder = ['immediate', 'short_term', 'medium_term', 'long_term', 'monitor'];

    for (final priority in priorityOrder) {
      final recs = byPriority[priority];
      if (recs == null || recs.isEmpty) continue;

      buffer.writeln('${_formatPriorityLabel(priority)}:');
      for (final rec in recs) {
        buffer.writeln('- ${rec.action}');
        if (rec.reasoning.isNotEmpty) {
          buffer.writeln('  Reason: ${rec.reasoning}');
        }
        if (rec.specialistReferral != null && rec.specialistReferral.isNotEmpty) {
          buffer.writeln('  Specialist: ${rec.specialistReferral}');
        }
        buffer.writeln();
      }
    }

    return buffer.toString().trim();
  }

  String _formatPriorityLabel(String priority) {
    switch (priority) {
      case 'immediate':
        return 'IMMEDIATE ACTION REQUIRED';
      case 'short_term':
        return 'SHORT TERM (1-3 months)';
      case 'medium_term':
        return 'MEDIUM TERM (3-12 months)';
      case 'long_term':
        return 'LONG TERM (1+ years)';
      case 'monitor':
        return 'MONITOR';
      default:
        return priority.toUpperCase();
    }
  }
}
