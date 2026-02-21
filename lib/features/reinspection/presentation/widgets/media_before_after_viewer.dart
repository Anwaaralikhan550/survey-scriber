import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../media/domain/entities/media_item.dart';
import '../../domain/entities/comparison_result.dart';

/// Viewer for comparing before/after media items
class MediaBeforeAfterViewer extends StatelessWidget {
  const MediaBeforeAfterViewer({
    required this.mediaDiffs,
    super.key,
  });

  final List<MediaDiff> mediaDiffs;

  @override
  Widget build(BuildContext context) {
    if (mediaDiffs.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: mediaDiffs.map((diff) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: _MediaComparisonTile(diff: diff),
        ),).toList(),
    );
  }
}

class _MediaComparisonTile extends StatelessWidget {
  const _MediaComparisonTile({required this.diff});

  final MediaDiff diff;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(
          color: _getBorderColor(colorScheme),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with change type
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: _getHeaderColor(colorScheme),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppSpacing.md - 1),
                topRight: Radius.circular(AppSpacing.md - 1),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getChangeIcon(),
                  size: 16,
                  color: _getIconColor(colorScheme),
                ),
                AppSpacing.gapHorizontalSm,
                Text(
                  diff.changeType.label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _getIconColor(colorScheme),
                  ),
                ),
                const Spacer(),
                if (diff.displayMedia?.caption != null)
                  Expanded(
                    child: Text(
                      diff.displayMedia!.caption!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                    ),
                  ),
              ],
            ),
          ),

          // Content based on change type
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: _buildContent(theme, colorScheme),
          ),
        ],
      ),
    );
  }

  Color _getBorderColor(ColorScheme colorScheme) => switch (diff.changeType) {
      ChangeType.added => colorScheme.primary.withOpacity(0.3),
      ChangeType.modified => colorScheme.tertiary.withOpacity(0.3),
      ChangeType.removed => colorScheme.error.withOpacity(0.3),
      ChangeType.unchanged => colorScheme.outlineVariant,
    };

  Color _getHeaderColor(ColorScheme colorScheme) => switch (diff.changeType) {
      ChangeType.added => colorScheme.primaryContainer.withOpacity(0.5),
      ChangeType.modified => colorScheme.tertiaryContainer.withOpacity(0.5),
      ChangeType.removed => colorScheme.errorContainer.withOpacity(0.5),
      ChangeType.unchanged => colorScheme.surfaceContainerHighest,
    };

  Color _getIconColor(ColorScheme colorScheme) => switch (diff.changeType) {
      ChangeType.added => colorScheme.primary,
      ChangeType.modified => colorScheme.tertiary,
      ChangeType.removed => colorScheme.error,
      ChangeType.unchanged => colorScheme.onSurfaceVariant,
    };

  IconData _getChangeIcon() => switch (diff.changeType) {
      ChangeType.added => Icons.add_photo_alternate_rounded,
      ChangeType.modified => Icons.compare_rounded,
      ChangeType.removed => Icons.hide_image_rounded,
      ChangeType.unchanged => Icons.check_circle_rounded,
    };

  Widget _buildContent(ThemeData theme, ColorScheme colorScheme) => switch (diff.changeType) {
      ChangeType.added => _SingleMediaView(
          media: diff.currentMedia!,
          label: 'New Photo',
        ),
      ChangeType.removed => _SingleMediaView(
          media: diff.previousMedia!,
          label: 'Removed Photo',
          isRemoved: true,
        ),
      ChangeType.modified => _BeforeAfterView(
          previousMedia: diff.previousMedia,
          currentMedia: diff.currentMedia,
        ),
      ChangeType.unchanged => _SingleMediaView(
          media: diff.currentMedia ?? diff.previousMedia!,
          label: 'No Change',
        ),
    };
}

class _SingleMediaView extends StatelessWidget {
  const _SingleMediaView({
    required this.media,
    required this.label,
    this.isRemoved = false,
  });

  final MediaItem media;
  final String label;
  final bool isRemoved;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: AppSpacing.borderRadiusSm,
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: _MediaImage(
              media: media,
              grayscale: isRemoved,
            ),
          ),
          if (isRemoved)
            Positioned.fill(
              child: Container(
                color: colorScheme.error.withOpacity(0.2),
                child: const Center(
                  child: Icon(
                    Icons.close_rounded,
                    size: 48,
                    color: Colors.white70,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BeforeAfterView extends StatelessWidget {
  const _BeforeAfterView({
    this.previousMedia,
    this.currentMedia,
  });

  final MediaItem? previousMedia;
  final MediaItem? currentMedia;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        // Before
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LabelChip(
                label: 'Before',
                color: colorScheme.error,
              ),
              AppSpacing.gapVerticalXs,
              ClipRRect(
                borderRadius: AppSpacing.borderRadiusSm,
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: previousMedia != null
                      ? _MediaImage(media: previousMedia!)
                      : _PlaceholderImage(colorScheme: colorScheme),
                ),
              ),
            ],
          ),
        ),

        // Arrow indicator
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Icon(
            Icons.arrow_forward_rounded,
            color: colorScheme.tertiary,
            size: 24,
          ),
        ),

        // After
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LabelChip(
                label: 'After',
                color: colorScheme.primary,
              ),
              AppSpacing.gapVerticalXs,
              ClipRRect(
                borderRadius: AppSpacing.borderRadiusSm,
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: currentMedia != null
                      ? _MediaImage(media: currentMedia!)
                      : _PlaceholderImage(colorScheme: colorScheme),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MediaImage extends StatelessWidget {
  const _MediaImage({
    required this.media,
    this.grayscale = false,
  });

  final MediaItem media;
  final bool grayscale;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Determine the path to use
    String? imagePath;
    if (media is PhotoItem) {
      final photo = media as PhotoItem;
      imagePath = photo.thumbnailPath ?? photo.localPath;
    } else {
      imagePath = media.localPath;
    }

    final file = File(imagePath);

    if (!file.existsSync()) {
      return Container(
        color: colorScheme.surfaceContainerHighest,
        child: Center(
          child: Icon(
            Icons.broken_image_rounded,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return ColorFiltered(
      colorFilter: grayscale
          ? const ColorFilter.matrix([
              0.2126, 0.7152, 0.0722, 0, 0,
              0.2126, 0.7152, 0.0722, 0, 0,
              0.2126, 0.7152, 0.0722, 0, 0,
              0, 0, 0, 1, 0,
            ])
          : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
      child: Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
            color: colorScheme.surfaceContainerHighest,
            child: Center(
              child: Icon(
                Icons.broken_image_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ),
    );
  }
}

class _PlaceholderImage extends StatelessWidget {
  const _PlaceholderImage({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) => Container(
      color: colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.image_not_supported_rounded,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
}

class _LabelChip extends StatelessWidget {
  const _LabelChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: AppSpacing.borderRadiusXs,
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
}

/// Full-screen before/after comparison viewer
class FullScreenMediaComparison extends StatefulWidget {
  const FullScreenMediaComparison({
    required this.previousMedia,
    required this.currentMedia,
    super.key,
  });

  final MediaItem? previousMedia;
  final MediaItem? currentMedia;

  @override
  State<FullScreenMediaComparison> createState() =>
      _FullScreenMediaComparisonState();
}

class _FullScreenMediaComparisonState extends State<FullScreenMediaComparison> {
  double _sliderValue = 0.5;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Before / After'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                // Previous (before) image - full width
                if (widget.previousMedia != null)
                  Positioned.fill(
                    child: _MediaImage(media: widget.previousMedia!),
                  ),

                // Current (after) image - clipped by slider
                if (widget.currentMedia != null)
                  Positioned.fill(
                    child: ClipRect(
                      clipper: _SliderClipper(sliderValue: _sliderValue),
                      child: _MediaImage(media: widget.currentMedia!),
                    ),
                  ),

                // Slider line
                Positioned(
                  left: MediaQuery.of(context).size.width * _sliderValue - 1,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 2,
                    color: Colors.white,
                  ),
                ),

                // Slider handle
                Positioned(
                  left: MediaQuery.of(context).size.width * _sliderValue - 20,
                  top: MediaQuery.of(context).size.height * 0.3,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.compare_arrows_rounded,
                      color: Colors.black87,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Slider control
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            color: Colors.black,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Before',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      'After',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _sliderValue,
                  onChanged: (value) {
                    setState(() {
                      _sliderValue = value;
                    });
                  },
                  activeColor: colorScheme.primary,
                  inactiveColor: Colors.white24,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SliderClipper extends CustomClipper<Rect> {
  _SliderClipper({required this.sliderValue});

  final double sliderValue;

  @override
  Rect getClip(Size size) => Rect.fromLTRB(
      size.width * sliderValue,
      0,
      size.width,
      size.height,
    );

  @override
  bool shouldReclip(covariant _SliderClipper oldClipper) => sliderValue != oldClipper.sliderValue;
}
