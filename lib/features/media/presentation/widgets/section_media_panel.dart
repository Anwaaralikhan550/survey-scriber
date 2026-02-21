import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_spacing.dart';
import '../providers/media_provider.dart';
import 'audio_notes_list.dart';
import 'photo_grid.dart';

/// A comprehensive media panel for survey sections
/// Includes photos, audio notes, and expandable sections
class SectionMediaPanel extends ConsumerStatefulWidget {
  const SectionMediaPanel({
    required this.surveyId,
    required this.sectionId,
    this.maxPhotos = 20,
    this.maxAudioNotes = 10,
    this.showPhotos = true,
    this.showAudio = true,
    this.initiallyExpanded = true,
    super.key,
  });

  final String surveyId;
  final String sectionId;
  final int maxPhotos;
  final int maxAudioNotes;
  final bool showPhotos;
  final bool showAudio;
  final bool initiallyExpanded;

  @override
  ConsumerState<SectionMediaPanel> createState() => _SectionMediaPanelState();
}

class _SectionMediaPanelState extends ConsumerState<SectionMediaPanel> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mediaState = ref.watch(sectionMediaProvider(widget.sectionId));

    final photoCount = mediaState.photos.length;
    final audioCount = mediaState.audioNotes.length;
    final totalCount = photoCount + audioCount;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(AppSpacing.radiusLg),
              bottom: _isExpanded
                  ? Radius.zero
                  : const Radius.circular(AppSpacing.radiusLg),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Icon(
                    Icons.perm_media_outlined,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                  AppSpacing.gapHorizontalSm,
                  Text(
                    'Media',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  AppSpacing.gapHorizontalSm,
                  if (totalCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: AppSpacing.borderRadiusFull,
                      ),
                      child: Text(
                        '$totalCount',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const Spacer(),
                  // Media type indicators
                  if (photoCount > 0) ...[
                    Icon(
                      Icons.photo_outlined,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    AppSpacing.gapHorizontalXs,
                    Text(
                      '$photoCount',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    AppSpacing.gapHorizontalMd,
                  ],
                  if (audioCount > 0) ...[
                    Icon(
                      Icons.mic_outlined,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    AppSpacing.gapHorizontalXs,
                    Text(
                      '$audioCount',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    AppSpacing.gapHorizontalMd,
                  ],
                  AnimatedRotation(
                    turns: _isExpanded ? 0 : -0.25,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.expand_more_rounded,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Photos section
                      if (widget.showPhotos) ...[
                        PhotoGrid(
                          surveyId: widget.surveyId,
                          sectionId: widget.sectionId,
                          maxPhotos: widget.maxPhotos,
                        ),
                        if (widget.showAudio) AppSpacing.gapVerticalLg,
                      ],

                      // Audio section
                      if (widget.showAudio)
                        AudioNotesList(
                          surveyId: widget.surveyId,
                          sectionId: widget.sectionId,
                          maxNotes: widget.maxAudioNotes,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}

/// A compact media summary widget showing counts and quick actions
class SectionMediaSummary extends ConsumerWidget {
  const SectionMediaSummary({
    required this.surveyId,
    required this.sectionId,
    this.onTap,
    super.key,
  });

  final String surveyId;
  final String sectionId;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mediaState = ref.watch(sectionMediaProvider(sectionId));

    final photoCount = mediaState.photos.length;
    final audioCount = mediaState.audioNotes.length;

    if (photoCount == 0 && audioCount == 0) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: AppSpacing.borderRadiusMd,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (photoCount > 0) ...[
              Icon(
                Icons.photo_outlined,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              AppSpacing.gapHorizontalXs,
              Text(
                '$photoCount',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (photoCount > 0 && audioCount > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Container(
                  width: 1,
                  height: 12,
                  color: colorScheme.outlineVariant,
                ),
              ),
            if (audioCount > 0) ...[
              Icon(
                Icons.mic_outlined,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              AppSpacing.gapHorizontalXs,
              Text(
                '$audioCount',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (onTap != null) ...[
              AppSpacing.gapHorizontalSm,
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
