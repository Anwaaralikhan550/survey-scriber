import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';

/// Data model for analytics
class AnalyticsData {
  const AnalyticsData({
    this.completionRate = 0.0,
    this.weeklyProgress = const [],
    this.statusDistribution = const {},
    this.avgCompletionTime = Duration.zero,
    this.surveysThisWeek = 0,
    this.surveysLastWeek = 0,
  });

  final double completionRate;
  final List<double> weeklyProgress; // 7 days of progress data (0.0 - 1.0)
  final Map<String, int> statusDistribution;
  final Duration avgCompletionTime;
  final int surveysThisWeek;
  final int surveysLastWeek;

  int get weeklyChange => surveysThisWeek - surveysLastWeek;
  double get weeklyChangePercent =>
      surveysLastWeek > 0 ? (weeklyChange / surveysLastWeek) * 100 : 0;
  bool get isPositiveChange => weeklyChange >= 0;
}

/// Analytics section with card-based insights
class AnalyticsSection extends StatelessWidget {
  const AnalyticsSection({
    required this.data,
    this.isLoading = false,
    this.onViewDetails,
    super.key,
  });

  final AnalyticsData data;
  final bool isLoading;
  final VoidCallback? onViewDetails;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                'Insights',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const Spacer(),
              if (onViewDetails != null)
                TextButton(
                  onPressed: onViewDetails,
                  child: Text(
                    'View all',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          AppSpacing.gapVerticalMd,
          // Cards row
          Row(
            children: [
              Expanded(
                child: CompletionRateCard(
                  rate: data.completionRate,
                  weeklyChange: data.weeklyChangePercent,
                  isPositive: data.isPositiveChange,
                  isLoading: isLoading,
                ),
              ),
              AppSpacing.gapHorizontalMd,
              Expanded(
                child: WeeklyProgressCard(
                  progressData: data.weeklyProgress,
                  totalThisWeek: data.surveysThisWeek,
                  isLoading: isLoading,
                ),
              ),
            ],
          ),
          AppSpacing.gapVerticalMd,
          // Status distribution card (full width)
          StatusDistributionCard(
            distribution: data.statusDistribution,
            isLoading: isLoading,
          ),
        ],
      ),
    );
  }
}

/// Card showing completion rate with percentage
class CompletionRateCard extends StatelessWidget {
  const CompletionRateCard({
    required this.rate,
    required this.weeklyChange,
    required this.isPositive,
    this.isLoading = false,
    super.key,
  });

  final double rate;
  final double weeklyChange;
  final bool isPositive;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.statusCompleted.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: const Icon(
                  Icons.check_circle_outline_rounded,
                  size: 18,
                  color: AppColors.statusCompleted,
                ),
              ),
              const Spacer(),
              if (!isLoading && weeklyChange != 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: (isPositive ? AppColors.success : AppColors.error)
                        .withOpacity(0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        size: 12,
                        color: isPositive ? AppColors.success : AppColors.error,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${weeklyChange.abs().toStringAsFixed(0)}%',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isPositive ? AppColors.success : AppColors.error,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          AppSpacing.gapVerticalMd,
          if (isLoading)
            _buildShimmer(theme, 60, 32)
          else
            Text(
              '${(rate * 100).toInt()}%',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                height: 1.1,
              ),
            ),
          AppSpacing.gapVerticalXs,
          Text(
            'Completion rate',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer(ThemeData theme, double width, double height) =>
      Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
      );
}

/// Card showing weekly progress with mini bar chart
class WeeklyProgressCard extends StatelessWidget {
  const WeeklyProgressCard({
    required this.progressData,
    required this.totalThisWeek,
    this.isLoading = false,
    super.key,
  });

  final List<double> progressData;
  final int totalThisWeek;
  final bool isLoading;

  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              Text(
                'This week',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          AppSpacing.gapVerticalMd,
          // Mini bar chart
          if (isLoading)
            _buildShimmer(theme, double.infinity, 48)
          else
            SizedBox(
              height: 48,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(7, (index) {
                  final value = index < progressData.length
                      ? progressData[index]
                      : 0.0;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: FractionallySizedBox(
                                heightFactor: value.clamp(0.1, 1.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(
                                      value > 0 ? 0.7 : 0.2,
                                    ),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _dayLabels[index],
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 9,
                              color: theme.colorScheme.onSurfaceVariant
                                  .withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          AppSpacing.gapVerticalSm,
          if (isLoading)
            _buildShimmer(theme, 80, 14)
          else
            Text(
              '$totalThisWeek surveys',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildShimmer(ThemeData theme, double width, double height) =>
      Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
      );
}

/// Card showing status distribution with mini donut chart
class StatusDistributionCard extends StatelessWidget {
  const StatusDistributionCard({
    required this.distribution,
    this.isLoading = false,
    super.key,
  });

  final Map<String, int> distribution;
  final bool isLoading;

  static const _statusColors = {
    'draft': AppColors.statusDraft,
    'inProgress': AppColors.statusInProgress,
    'completed': AppColors.statusCompleted,
    'paused': AppColors.statusPendingReview,
    'pendingReview': AppColors.statusPendingReview,
    'approved': AppColors.statusApproved,
    'rejected': AppColors.statusRejected,
  };

  static const _statusLabels = {
    'draft': 'Draft',
    'inProgress': 'In Progress',
    'completed': 'Completed',
    'paused': 'Paused',
    'pendingReview': 'Pending',
    'approved': 'Approved',
    'rejected': 'Rejected',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = distribution.values.fold<int>(0, (a, b) => a + b);
    final entries = distribution.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: const Icon(
                  Icons.pie_chart_outline_rounded,
                  size: 18,
                  color: AppColors.info,
                ),
              ),
              AppSpacing.gapHorizontalMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status Distribution',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      '$total total surveys',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.gapVerticalMd,
          if (isLoading)
            _buildShimmer(theme, double.infinity, 60)
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mini donut chart
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CustomPaint(
                    painter: _MiniDonutPainter(
                      entries: entries
                          .map((e) => (
                                e.value / total,
                                _statusColors[e.key] ?? AppColors.statusDraft,
                              ),)
                          .toList(),
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                    ),
                    child: Center(
                      child: Text(
                        '$total',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ),
                ),
                AppSpacing.gapHorizontalMd,
                // Legend
                Expanded(
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: entries.take(4).map((entry) {
                      final color =
                          _statusColors[entry.key] ?? AppColors.statusDraft;
                      final label =
                          _statusLabels[entry.key] ?? entry.key;
                      return _LegendItem(
                        color: color,
                        label: label,
                        count: entry.value,
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildShimmer(ThemeData theme, double width, double height) =>
      Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
      );
}

/// Custom painter for mini donut chart
class _MiniDonutPainter extends CustomPainter {
  _MiniDonutPainter({
    required this.entries,
    required this.backgroundColor,
  });

  final List<(double percentage, Color color)> entries;
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final strokeWidth = radius * 0.3;

    // Background circle
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius - strokeWidth / 2, bgPaint);

    // Draw segments
    var startAngle = -math.pi / 2; // Start from top
    for (final entry in entries) {
      final sweepAngle = 2 * math.pi * entry.$1;
      final paint = Paint()
        ..color = entry.$2
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        sweepAngle - 0.02, // Small gap between segments
        false,
        paint,
      );
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _MiniDonutPainter oldDelegate) =>
      oldDelegate.entries != entries;
}

/// Activity trend card with sparkline
class ActivityTrendCard extends StatelessWidget {
  const ActivityTrendCard({
    required this.trendData,
    required this.label,
    required this.value,
    this.isLoading = false,
    this.color,
    super.key,
  });

  final List<double> trendData;
  final String label;
  final String value;
  final bool isLoading;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chartColor = color ?? AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isLoading)
                      _buildShimmer(theme, 50, 24)
                    else
                      Text(
                        value,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                    AppSpacing.gapVerticalXs,
                    Text(
                      label,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Sparkline
              if (!isLoading && trendData.isNotEmpty)
                SizedBox(
                  width: 80,
                  height: 32,
                  child: CustomPaint(
                    painter: _SparklinePainter(
                      data: trendData,
                      color: chartColor,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer(ThemeData theme, double width, double height) =>
      Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
      );
}

/// Custom painter for sparkline chart
class _SparklinePainter extends CustomPainter {
  _SparklinePainter({
    required this.data,
    required this.color,
  });

  final List<double> data;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxVal = data.reduce(math.max);
    final minVal = data.reduce(math.min);
    final range = maxVal - minVal == 0 ? 1.0 : maxVal - minVal;

    final path = Path();
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final stepX = size.width / (data.length - 1);

    for (var i = 0; i < data.length; i++) {
      final x = i * stepX;
      final normalizedY = (data[i] - minVal) / range;
      final y = size.height - (normalizedY * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // Draw gradient fill
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        color.withOpacity(0.2),
        color.withOpacity(0),
      ],
    );

    final fillPaint = Paint()
      ..shader = gradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      );

    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.data != data || oldDelegate.color != color;
}

/// Legend item widget with constrained width
class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    required this.count,
  });

  final Color color;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: const BoxConstraints(maxWidth: 110),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              '$label ($count)',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
