import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../providers/comparison_provider.dart';

/// Toggle button for switching between comparison view modes
class ComparisonToggle extends StatelessWidget {
  const ComparisonToggle({
    required this.currentMode,
    required this.onModeChanged,
    super.key,
  });

  final ComparisonViewMode currentMode;
  final ValueChanged<ComparisonViewMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: AppSpacing.borderRadiusLg,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ComparisonViewMode.values.map((mode) {
          final isSelected = mode == currentMode;
          return _ToggleButton(
            label: _getModeLabel(mode),
            icon: _getModeIcon(mode),
            isSelected: isSelected,
            onTap: () => onModeChanged(mode),
          );
        }).toList(),
      ),
    );
  }

  String _getModeLabel(ComparisonViewMode mode) => switch (mode) {
        ComparisonViewMode.current => 'Current',
        ComparisonViewMode.previous => 'Previous',
        ComparisonViewMode.compare => 'Compare',
      };

  IconData _getModeIcon(ComparisonViewMode mode) => switch (mode) {
        ComparisonViewMode.current => Icons.article_outlined,
        ComparisonViewMode.previous => Icons.history_rounded,
        ComparisonViewMode.compare => Icons.compare_arrows_rounded,
      };
}

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : Colors.transparent,
          borderRadius: AppSpacing.borderRadiusMd,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? colorScheme.onPrimary
                  : colorScheme.onSurfaceVariant,
            ),
            AppSpacing.gapHorizontalXs,
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: isSelected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
