import 'package:flutter/material.dart';

import '../../../../shared/domain/entities/survey.dart';
import '../../../../shared/presentation/widgets/empty_state.dart';
import '../../../../shared/presentation/widgets/survey_card.dart';

class RecentSurveysSection extends StatelessWidget {
  const RecentSurveysSection({
    required this.surveys,
    this.isLoading = false,
    this.onSurveyTap,
    this.onViewAll,
    super.key,
  });

  final List<Survey> surveys;
  final bool isLoading;
  final void Function(Survey)? onSurveyTap;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Surveys',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              if (surveys.isNotEmpty)
                TextButton(
                  onPressed: onViewAll,
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View all',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (isLoading)
          _buildLoadingState(theme)
        else if (surveys.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: EmptyState(
              icon: Icons.assignment_outlined,
              title: 'No surveys yet',
              description: 'Create your first survey to get started',
              actionLabel: 'New Survey',
            ),
          )
        else
          _buildSurveyList(),
      ],
    );
  }

  Widget _buildLoadingState(ThemeData theme) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: List.generate(
            3,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _AnimatedShimmerCard(theme: theme, delay: index * 150),
            ),
          ),
        ),
      );

  Widget _buildSurveyList() => ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: surveys.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final survey = surveys[index];
          return SurveyCard(
            survey: survey,
            onTap: () => onSurveyTap?.call(survey),
          );
        },
      );
}

class _AnimatedShimmerCard extends StatefulWidget {
  const _AnimatedShimmerCard({
    required this.theme,
    this.delay = 0,
  });

  final ThemeData theme;
  final int delay;

  @override
  State<_AnimatedShimmerCard> createState() => _AnimatedShimmerCardState();
}

class _AnimatedShimmerCardState extends State<_AnimatedShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: widget.theme.colorScheme.outlineVariant.withOpacity(0.4),
          ),
        ),
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _shimmerBox(40, 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _shimmerBox(double.infinity, 16),
                        const SizedBox(height: 8),
                        _shimmerBox(120, 12),
                      ],
                    ),
                  ),
                  _shimmerBox(60, 24),
                ],
              ),
              const SizedBox(height: 14),
              _shimmerBox(200, 12),
              const SizedBox(height: 14),
              Row(
                children: [
                  _shimmerBox(40, 12),
                  const SizedBox(width: 12),
                  _shimmerBox(40, 12),
                  const Spacer(),
                  _shimmerBox(60, 12),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _shimmerBox(double width, double height) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: widget.theme.colorScheme.surfaceContainerHighest
              .withOpacity(_animation.value),
          borderRadius: BorderRadius.circular(6),
        ),
      );
}
