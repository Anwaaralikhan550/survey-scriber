import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';

/// A card widget for grouping settings sections.
/// Follows modern 2025 SaaS styling with calm spacing.
class SettingsSectionCard extends StatelessWidget {
  const SettingsSectionCard({
    required this.title,
    required this.children,
    this.icon,
    this.trailing,
    this.subtitle,
    super.key,
  });

  final String title;
  final IconData? icon;
  final String? subtitle;
  final Widget? trailing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withOpacity(0.5),
                      borderRadius: AppSpacing.borderRadiusMd,
                    ),
                    child: Icon(
                      icon,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                  ),
                  AppSpacing.gapHorizontalMd,
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      if (subtitle != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            subtitle!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          // Divider
          Divider(
            height: 1,
            color: colorScheme.outlineVariant.withOpacity(0.3),
          ),
          // Children
          ...children,
        ],
      ),
    );
  }
}

/// A single settings item/row within a section.
class SettingsItem extends StatelessWidget {
  const SettingsItem({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.enabled = true,
    this.disabledReason,
    this.showDivider = true,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;
  final String? disabledReason;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget item = InkWell(
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              AppSpacing.gapHorizontalMd,
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: enabled
                          ? colorScheme.onSurface
                          : colorScheme.onSurface.withOpacity(0.5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: enabled
                              ? colorScheme.onSurfaceVariant
                              : colorScheme.onSurfaceVariant.withOpacity(0.5),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null) ...[
              AppSpacing.gapHorizontalSm,
              Opacity(
                opacity: enabled ? 1.0 : 0.5,
                child: trailing,
              ),
            ] else if (onTap != null)
              Icon(
                Icons.chevron_right_rounded,
                color: enabled
                    ? colorScheme.onSurfaceVariant
                    : colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
          ],
        ),
      ),
    );

    // Wrap with tooltip if disabled
    if (!enabled && disabledReason != null) {
      item = Tooltip(
        message: disabledReason,
        child: item,
      );
    }

    return Column(
      children: [
        item,
        if (showDivider)
          Divider(
            height: 1,
            indent: AppSpacing.lg,
            endIndent: AppSpacing.lg,
            color: colorScheme.outlineVariant.withOpacity(0.2),
          ),
      ],
    );
  }
}

/// A settings item with a switch toggle.
class SettingsSwitchItem extends StatelessWidget {
  const SettingsSwitchItem({
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.enabled = true,
    this.disabledReason,
    this.showDivider = true,
    super.key,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool enabled;
  final String? disabledReason;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SettingsItem(
      title: title,
      subtitle: subtitle,
      enabled: enabled,
      disabledReason: disabledReason,
      showDivider: showDivider,
      trailing: Switch.adaptive(
        value: value,
        onChanged: enabled ? onChanged : null,
        activeColor: theme.colorScheme.primary,
      ),
      onTap: enabled && onChanged != null
          ? () => onChanged!(!value)
          : null,
    );
  }
}

/// A settings item that shows the current value and opens a selector.
class SettingsSelectionItem<T> extends StatelessWidget {
  const SettingsSelectionItem({
    required this.title,
    required this.value,
    required this.options,
    required this.onChanged,
    this.subtitle,
    this.enabled = true,
    this.disabledReason,
    this.showDivider = true,
    super.key,
  });

  final String title;
  final String? subtitle;
  final T value;
  final List<({T value, String label})> options;
  final ValueChanged<T>? onChanged;
  final bool enabled;
  final String? disabledReason;
  final bool showDivider;

  String get _currentLabel {
    final option = options.firstWhere(
      (o) => o.value == value,
      orElse: () => options.first,
    );
    return option.label;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SettingsItem(
      title: title,
      subtitle: subtitle,
      enabled: enabled,
      disabledReason: disabledReason,
      showDivider: showDivider,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _currentLabel,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          AppSpacing.gapHorizontalXs,
          Icon(
            Icons.chevron_right_rounded,
            color: colorScheme.onSurfaceVariant,
          ),
        ],
      ),
      onTap: enabled ? () => _showSelector(context) : null,
    );
  }

  Future<void> _showSelector(BuildContext context) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final result = await showModalBottomSheet<T>(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Divider(
              height: 1,
              color: colorScheme.outlineVariant.withOpacity(0.3),
            ),
            ...options.map(
              (option) => ListTile(
                title: Text(option.label),
                trailing: option.value == value
                    ? Icon(
                        Icons.check_rounded,
                        color: colorScheme.primary,
                      )
                    : null,
                onTap: () => Navigator.pop(context, option.value),
              ),
            ),
            AppSpacing.gapVerticalMd,
          ],
        ),
      ),
    );

    if (result != null && onChanged != null) {
      onChanged!(result);
    }
  }
}
