import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../ai/ai.dart';
import '../../domain/entities/media_item.dart';
import '../providers/media_provider.dart';
import '../widgets/audio_player_tile.dart';
import '../widgets/photo_viewer.dart';

/// Full gallery view of all media for a survey
class SurveyMediaGalleryPage extends ConsumerStatefulWidget {
  const SurveyMediaGalleryPage({
    required this.surveyId,
    required this.surveyTitle,
    super.key,
  });

  final String surveyId;
  final String surveyTitle;

  @override
  ConsumerState<SurveyMediaGalleryPage> createState() =>
      _SurveyMediaGalleryPageState();
}

class _SurveyMediaGalleryPageState
    extends ConsumerState<SurveyMediaGalleryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final mediaAsync = ref.watch(surveyMediaProvider(widget.surveyId));
    final countsAsync = ref.watch(surveyMediaCountsProvider(widget.surveyId));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.surveyTitle),
        actions: [
          mediaAsync.when(
            data: (items) {
              final photos = items.whereType<PhotoItem>().toList();
              if (photos.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: AiBulkPhotoTagButton(
                  surveyId: widget.surveyId,
                  photos: photos.map((p) => PhotoInfo(
                    id: p.id,
                    path: p.localPath,
                    existingCaption: p.caption,
                    sectionContext: p.sectionId,
                  ),).toList(),
                  onComplete: (results) {
                    // Tags generated - could update media metadata
                  },
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: countsAsync.when(
            data: (counts) => TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.center,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.photo_outlined, size: 18),
                      AppSpacing.gapHorizontalXs,
                      Flexible(
                        child: Text(
                          'Photos (${counts.photos})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.mic_outlined, size: 18),
                      AppSpacing.gapHorizontalXs,
                      Flexible(
                        child: Text(
                          'Audio (${counts.audio})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.videocam_outlined, size: 18),
                      AppSpacing.gapHorizontalXs,
                      Flexible(
                        child: Text(
                          'Video (${counts.video})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            loading: () => TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Photos'),
                Tab(text: 'Audio'),
                Tab(text: 'Video'),
              ],
            ),
            error: (_, __) => TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Photos'),
                Tab(text: 'Audio'),
                Tab(text: 'Video'),
              ],
            ),
          ),
        ),
      ),
      body: mediaAsync.when(
        data: (items) {
          final photos =
              items.whereType<PhotoItem>().toList();
          final audio =
              items.whereType<AudioItem>().toList();
          final videos =
              items.whereType<VideoItem>().toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _PhotosTab(photos: photos, surveyId: widget.surveyId),
              _AudioTab(audioNotes: audio),
              _VideosTab(videos: videos),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: colorScheme.error,
              ),
              AppSpacing.gapVerticalMd,
              Text(
                'Failed to load media',
                style: theme.textTheme.titleMedium,
              ),
              AppSpacing.gapVerticalSm,
              Text(
                error.toString(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotosTab extends StatelessWidget {
  const _PhotosTab({
    required this.photos,
    required this.surveyId,
  });

  final List<PhotoItem> photos;
  final String surveyId;

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return _buildEmptyState(
        context,
        Icons.photo_library_outlined,
        'No photos',
        'Photos captured during the survey will appear here',
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        final photo = photos[index];
        return _PhotoGridItem(
          photo: photo,
          onTap: () => _openViewer(context, index),
        );
      },
    );
  }

  void _openViewer(BuildContext context, int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PhotoViewerPage(
          photos: photos,
          initialIndex: index,
          sectionId: photos[index].sectionId,
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            AppSpacing.gapVerticalMd,
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            AppSpacing.gapVerticalSm,
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoGridItem extends StatelessWidget {
  const _PhotoGridItem({
    required this.photo,
    required this.onTap,
  });

  final PhotoItem photo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final file = File(photo.localPath);

    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: AppSpacing.borderRadiusMd,
          border: Border.all(
            color: colorScheme.outlineVariant.withOpacity(0.5),
          ),
        ),
        child: ClipRRect(
          borderRadius: AppSpacing.borderRadiusMd,
          child: Stack(
            fit: StackFit.expand,
            children: [
              FutureBuilder<bool>(
                future: file.exists(),
                builder: (context, snapshot) {
                  if (snapshot.data == true) {
                    return Image.file(
                      file,
                      fit: BoxFit.cover,
                      cacheWidth: 200,
                      errorBuilder: (_, __, ___) => _buildPlaceholder(colorScheme),
                    );
                  }
                  return _buildPlaceholder(colorScheme);
                },
              ),
              // Annotation indicator
              if (photo.hasAnnotations)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: AppSpacing.borderRadiusSm,
                    ),
                    child: Icon(
                      Icons.edit_rounded,
                      size: 12,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(ColorScheme colorScheme) => Container(
      color: colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.image_outlined,
        color: colorScheme.onSurfaceVariant,
      ),
    );
}

class _AudioTab extends StatelessWidget {
  const _AudioTab({required this.audioNotes});

  final List<AudioItem> audioNotes;

  @override
  Widget build(BuildContext context) {
    if (audioNotes.isEmpty) {
      return _buildEmptyState(
        context,
        Icons.mic_none_rounded,
        'No audio notes',
        'Voice notes recorded during the survey will appear here',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: audioNotes.length,
      itemBuilder: (context, index) {
        final audio = audioNotes[index];
        return AudioPlayerTile(
          audio: audio,
          sectionId: audio.sectionId,
        );
      },
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            AppSpacing.gapVerticalMd,
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            AppSpacing.gapVerticalSm,
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _VideosTab extends StatelessWidget {
  const _VideosTab({required this.videos});

  final List<VideoItem> videos;

  @override
  Widget build(BuildContext context) {
    if (videos.isEmpty) {
      return _buildEmptyState(
        context,
        Icons.videocam_off_outlined,
        'No videos',
        'Video clips recorded during the survey will appear here',
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 16 / 9,
      ),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final video = videos[index];
        return _VideoGridItem(video: video);
      },
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            AppSpacing.gapVerticalMd,
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            AppSpacing.gapVerticalSm,
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoGridItem extends StatelessWidget {
  const _VideoGridItem({required this.video});

  final VideoItem video;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: () {
        // TODO: Open video player
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video player coming soon'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: AppSpacing.borderRadiusMd,
          border: Border.all(
            color: colorScheme.outlineVariant.withOpacity(0.5),
          ),
        ),
        child: Stack(
          children: [
            // Thumbnail placeholder
            Center(
              child: Icon(
                Icons.videocam_rounded,
                size: 48,
                color: colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
            ),
            // Play button overlay
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surface.withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.play_arrow_rounded,
                  size: 32,
                  color: colorScheme.primary,
                ),
              ),
            ),
            // Duration badge
            if (video.duration != null)
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    borderRadius: AppSpacing.borderRadiusSm,
                  ),
                  child: Text(
                    _formatDuration(video.duration!),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
