import 'package:flutter/material.dart';

/// Thin bar under the app bar showing the path to the current page. A long path
/// scrolls sideways and starts at its end, so the current page is always visible.
class InspectionBreadcrumbBar extends StatelessWidget
    implements PreferredSizeWidget {
  const InspectionBreadcrumbBar({required this.path, super.key});

  final List<String> path;

  @override
  Size get preferredSize => const Size.fromHeight(28);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = path.join(' > ');
    return Semantics(
      label: text,
      excludeSemantics: true,
      child: SizedBox(
        height: preferredSize.height,
        width: double.infinity,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth - 32),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  text,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
