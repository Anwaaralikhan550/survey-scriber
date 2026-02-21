import 'package:flutter/material.dart';

/// A skeleton placeholder for AI action button during initial loading
class AiButtonSkeleton extends StatefulWidget {
  const AiButtonSkeleton({
    this.isCompact = false,
    this.width,
    super.key,
  });

  final bool isCompact;
  final double? width;

  @override
  State<AiButtonSkeleton> createState() => _AiButtonSkeletonState();
}

class _AiButtonSkeletonState extends State<AiButtonSkeleton>
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
    _animation = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final height = widget.isCompact ? 36.0 : 44.0;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => Container(
        width: widget.width,
        height: height,
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withOpacity(_animation.value),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: widget.isCompact ? 12 : 16,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: widget.isCompact ? 16 : 18,
              height: widget.isCompact ? 16 : 18,
              decoration: BoxDecoration(
                color: theme.colorScheme.onPrimaryContainer.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            SizedBox(width: widget.isCompact ? 6 : 8),
            Container(
              width: widget.isCompact ? 60 : 80,
              height: widget.isCompact ? 12 : 14,
              decoration: BoxDecoration(
                color: theme.colorScheme.onPrimaryContainer.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A skeleton placeholder for AI icon button during initial loading
class AiIconButtonSkeleton extends StatefulWidget {
  const AiIconButtonSkeleton({super.key});

  @override
  State<AiIconButtonSkeleton> createState() => _AiIconButtonSkeletonState();
}

class _AiIconButtonSkeletonState extends State<AiIconButtonSkeleton>
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
    _animation = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withOpacity(_animation.value),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

/// A Material 3 styled button for triggering AI actions.
/// Shows loading state while AI is processing.
class AiActionButton extends StatelessWidget {
  const AiActionButton({
    required this.label,
    required this.onPressed,
    this.icon = Icons.auto_awesome,
    this.isLoading = false,
    this.isOutlined = false,
    this.isCompact = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData icon;
  final bool isLoading;
  final bool isOutlined;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final buttonChild = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLoading)
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: isOutlined
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onPrimary,
            ),
          )
        else
          Icon(icon, size: isCompact ? 16 : 18),
        SizedBox(width: isCompact ? 6 : 8),
        Flexible(
          child: Text(
            isLoading ? 'Generating...' : label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: isCompact ? 13 : 14,
            ),
          ),
        ),
      ],
    );

    // Minimum touch target: 36px compact, 44px normal (Material guidelines)
    final minHeight = isCompact ? 36.0 : 44.0;

    final buttonStyle = isOutlined
        ? OutlinedButton.styleFrom(
            foregroundColor: theme.colorScheme.primary,
            side: BorderSide(color: theme.colorScheme.primary),
            minimumSize: Size(0, minHeight),
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 12 : 16,
              vertical: isCompact ? 8 : 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          )
        : FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.primaryContainer,
            foregroundColor: theme.colorScheme.onPrimaryContainer,
            minimumSize: Size(0, minHeight),
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 12 : 16,
              vertical: isCompact ? 8 : 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          );

    if (isOutlined) {
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: buttonStyle,
        child: buttonChild,
      );
    }

    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      style: buttonStyle,
      child: buttonChild,
    );
  }
}

/// A small icon button for AI actions in tight spaces
class AiIconButton extends StatelessWidget {
  const AiIconButton({
    required this.tooltip,
    required this.onPressed,
    this.icon = Icons.auto_awesome,
    this.isLoading = false,
    super.key,
  });

  final String tooltip;
  final VoidCallback? onPressed;
  final IconData icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.primary,
                ),
              )
            : Icon(icon, color: theme.colorScheme.primary),
        style: IconButton.styleFrom(
          backgroundColor: theme.colorScheme.primaryContainer.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
