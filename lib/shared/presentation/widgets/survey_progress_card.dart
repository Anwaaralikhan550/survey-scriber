import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A card showing overall survey completion progress with a circular ring
/// and breakdown of completed / in-progress / not-started sections.
class SurveyProgressCard extends StatelessWidget {
  const SurveyProgressCard({
    required this.completedSections,
    required this.totalSections,
    this.inProgressSections = 0,
    super.key,
  });

  final int completedSections;
  final int totalSections;
  final int inProgressSections;

  @override
  Widget build(BuildContext context) {
    if (totalSections <= 0) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final notStarted = math.max(
      0,
      totalSections - completedSections - inProgressSections,
    );
    final percent = completedSections / totalSections;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.surface,
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          // Circular progress ring
          SizedBox(
            width: 80,
            height: 80,
            child: CustomPaint(
              painter: _ProgressRingPainter(
                completed: completedSections,
                inProgress: inProgressSections,
                total: totalSections,
                completedColor: _completedColor,
                inProgressColor: _inProgressColor,
                notStartedColor: _notStartedColor(theme),
              ),
              child: Center(
                child: Text(
                  '${(percent * 100).round()}%',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),

          // Breakdown rows
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Completion Progress',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                _StatRow(
                  label: 'Completed',
                  count: completedSections,
                  total: totalSections,
                  color: _completedColor,
                ),
                const SizedBox(height: 6),
                _StatRow(
                  label: 'In Progress',
                  count: inProgressSections,
                  total: totalSections,
                  color: _inProgressColor,
                ),
                const SizedBox(height: 6),
                _StatRow(
                  label: 'Not Started',
                  count: notStarted,
                  total: totalSections,
                  color: _notStartedColor(theme),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const _completedColor = Color(0xFF2E7D32);
  static const _inProgressColor = Color(0xFFF9A825);
  static Color _notStartedColor(ThemeData theme) =>
      theme.colorScheme.outlineVariant;
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  final String label;
  final int count;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fraction = total > 0 ? count / total : 0.0;

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          '$count',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 48,
          height: 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: fraction,
              backgroundColor:
                  theme.colorScheme.outlineVariant.withOpacity(0.3),
              color: color,
              minHeight: 4,
            ),
          ),
        ),
      ],
    );
  }
}

/// Custom painter for a donut-style progress ring with 3 segments.
class _ProgressRingPainter extends CustomPainter {
  _ProgressRingPainter({
    required this.completed,
    required this.inProgress,
    required this.total,
    required this.completedColor,
    required this.inProgressColor,
    required this.notStartedColor,
  });

  final int completed;
  final int inProgress;
  final int total;
  final Color completedColor;
  final Color inProgressColor;
  final Color notStartedColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (total <= 0) return;

    const strokeWidth = 8.0;
    const gapAngle = 0.04; // small gap between segments
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final completedFraction = completed / total;
    final inProgressFraction = inProgress / total;
    final notStartedFraction = 1.0 - completedFraction - inProgressFraction;

    // If all one category, draw a full circle
    if (completedFraction >= 1.0) {
      paint.color = completedColor;
      canvas.drawArc(rect, -math.pi / 2, 2 * math.pi, false, paint);
      return;
    }

    final segments = <(double, Color)>[];
    if (completedFraction > 0) {
      segments.add((completedFraction, completedColor));
    }
    if (inProgressFraction > 0) {
      segments.add((inProgressFraction, inProgressColor));
    }
    if (notStartedFraction > 0) {
      segments.add((notStartedFraction, notStartedColor));
    }

    final totalGap = segments.length > 1 ? gapAngle * segments.length : 0.0;
    final availableAngle = 2 * math.pi - totalGap;

    var startAngle = -math.pi / 2;
    for (final (fraction, color) in segments) {
      final sweepAngle = fraction * availableAngle;
      paint.color = color;
      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle + (segments.length > 1 ? gapAngle : 0);
    }
  }

  @override
  bool shouldRepaint(_ProgressRingPainter oldDelegate) =>
      completed != oldDelegate.completed ||
      inProgress != oldDelegate.inProgress ||
      total != oldDelegate.total;
}
