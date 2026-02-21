import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../shared/services/survey_actions_service.dart';
import '../../domain/entities/media_item.dart';
import '../providers/media_provider.dart';
import 'annotation_editor.dart';

/// Full-screen photo viewer with swipe navigation
class PhotoViewerPage extends ConsumerStatefulWidget {
  const PhotoViewerPage({
    required this.photos,
    required this.initialIndex,
    required this.sectionId,
    super.key,
  });

  final List<PhotoItem> photos;
  final int initialIndex;
  final String sectionId;

  @override
  ConsumerState<PhotoViewerPage> createState() => _PhotoViewerPageState();
}

class _PhotoViewerPageState extends ConsumerState<PhotoViewerPage> {
  late PageController _pageController;
  late int _currentIndex;
  bool _showOverlay = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);

    // Set immersive mode
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [],
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mediaState = ref.watch(sectionMediaProvider(widget.sectionId));
    final photos = mediaState.photos;

    if (photos.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.photo_outlined,
                size: 64,
                color: Colors.white54,
              ),
              AppSpacing.gapVerticalMd,
              Text(
                'No photos available',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white54,
                ),
              ),
              AppSpacing.gapVerticalLg,
              TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                label: const Text('Go Back', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Photo page view
          GestureDetector(
            onTap: () => setState(() => _showOverlay = !_showOverlay),
            child: PageView.builder(
              controller: _pageController,
              itemCount: photos.length,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemBuilder: (context, index) => _PhotoPage(photo: photos[index]),
            ),
          ),

          // Top overlay - back button and actions
          if (_showOverlay)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black54,
                      Colors.transparent,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded),
                          color: Colors.white,
                          tooltip: 'Close',
                        ),
                        const Spacer(),
                        Text(
                          '${_currentIndex + 1} / ${photos.length}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => _showPhotoOptions(
                            context,
                            photos[_currentIndex],
                          ),
                          icon: const Icon(Icons.more_vert_rounded),
                          color: Colors.white,
                          tooltip: 'Options',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Bottom overlay - photo info and actions
          if (_showOverlay)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black54,
                      Colors.transparent,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Caption
                        if (photos[_currentIndex].caption != null) ...[
                          Text(
                            photos[_currentIndex].caption!,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: Colors.white,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          AppSpacing.gapVerticalSm,
                        ],

                        // Photo metadata
                        Row(
                          children: [
                            // Annotation indicator
                            if (photos[_currentIndex].hasAnnotations) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  borderRadius: AppSpacing.borderRadiusSm,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.edit_rounded,
                                      size: 14,
                                      color: colorScheme.onPrimary,
                                    ),
                                    AppSpacing.gapHorizontalXs,
                                    Text(
                                      'Annotated',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: colorScheme.onPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              AppSpacing.gapHorizontalMd,
                            ],

                            // Date
                            const Icon(
                              Icons.access_time_rounded,
                              size: 14,
                              color: Colors.white70,
                            ),
                            AppSpacing.gapHorizontalXs,
                            Text(
                              _formatDate(photos[_currentIndex].createdAt),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white70,
                              ),
                            ),

                            // File size
                            if (photos[_currentIndex].fileSize != null) ...[
                              AppSpacing.gapHorizontalMd,
                              const Icon(
                                Icons.photo_size_select_actual_outlined,
                                size: 14,
                                color: Colors.white70,
                              ),
                              AppSpacing.gapHorizontalXs,
                              Text(
                                _formatFileSize(photos[_currentIndex].fileSize!),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ],
                        ),

                        AppSpacing.gapVerticalMd,

                        // Action buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _ActionButton(
                              icon: Icons.edit_rounded,
                              label: 'Annotate',
                              onTap: () => _annotatePhoto(photos[_currentIndex]),
                            ),
                            _ActionButton(
                              icon: Icons.text_fields_rounded,
                              label: 'Caption',
                              onTap: () => _editCaption(photos[_currentIndex]),
                            ),
                            _ActionButton(
                              icon: Icons.share_rounded,
                              label: 'Share',
                              onTap: () => _sharePhoto(photos[_currentIndex]),
                            ),
                            _ActionButton(
                              icon: Icons.delete_outline_rounded,
                              label: 'Delete',
                              onTap: () => _deletePhoto(photos[_currentIndex]),
                              color: colorScheme.error,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Page indicators
          if (_showOverlay && photos.length > 1)
            Positioned(
              bottom: 160,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  photos.length,
                  (index) => Container(
                    width: index == _currentIndex ? 24 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: index == _currentIndex
                          ? Colors.white
                          : Colors.white38,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _showPhotoOptions(BuildContext context, PhotoItem photo) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: const Text('Annotate'),
              onTap: () => Navigator.pop(context, 'annotate'),
            ),
            ListTile(
              leading: const Icon(Icons.text_fields_rounded),
              title: const Text('Edit Caption'),
              onTap: () => Navigator.pop(context, 'caption'),
            ),
            ListTile(
              leading: const Icon(Icons.share_rounded),
              title: const Text('Share'),
              onTap: () => Navigator.pop(context, 'share'),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: const Text('Details'),
              onTap: () => Navigator.pop(context, 'details'),
            ),
            ListTile(
              leading: Icon(
                Icons.delete_rounded,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                'Delete',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
            AppSpacing.gapVerticalMd,
          ],
        ),
      ),
    );

    if (!mounted || result == null) return;

    switch (result) {
      case 'annotate':
        _annotatePhoto(photo);
      case 'caption':
        _editCaption(photo);
      case 'share':
        _sharePhoto(photo);
      case 'details':
        _showDetails(photo);
      case 'delete':
        _deletePhoto(photo);
    }
  }

  Future<void> _annotatePhoto(PhotoItem photo) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AnnotationEditorPage(
          photo: photo,
          sectionId: widget.sectionId,
        ),
      ),
    );

    // Refresh if annotations were saved
    if (result == true && mounted) {
      ref.invalidate(sectionMediaProvider(widget.sectionId));
    }
  }

  Future<void> _editCaption(PhotoItem photo) async {
    final controller = TextEditingController(text: photo.caption);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Photo Caption'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter caption...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      await ref
          .read(sectionMediaProvider(widget.sectionId).notifier)
          .updatePhotoCaption(photo.id, result.isEmpty ? null : result);
    }

    controller.dispose();
  }

  void _sharePhoto(PhotoItem photo) {
    SurveyActionsService.instance.sharePhoto(
      filePath: photo.localPath,
      caption: photo.caption,
      context: context,
    );
  }

  Future<void> _showDetails(PhotoItem photo) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    await showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Photo Details',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              AppSpacing.gapVerticalLg,
              _DetailRow(
                label: 'Created',
                value: '${photo.createdAt.day}/${photo.createdAt.month}/${photo.createdAt.year} '
                    '${photo.createdAt.hour.toString().padLeft(2, '0')}:${photo.createdAt.minute.toString().padLeft(2, '0')}',
              ),
              if (photo.fileSize != null)
                _DetailRow(
                  label: 'Size',
                  value: _formatFileSize(photo.fileSize!),
                ),
              if (photo.width != null && photo.height != null)
                _DetailRow(
                  label: 'Dimensions',
                  value: '${photo.width} x ${photo.height}',
                ),
              _DetailRow(
                label: 'Has Annotations',
                value: photo.hasAnnotations ? 'Yes' : 'No',
              ),
              _DetailRow(
                label: 'Status',
                value: photo.status.name.toUpperCase(),
              ),
              AppSpacing.gapVerticalMd,
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deletePhoto(PhotoItem photo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Photo?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(sectionMediaProvider(widget.sectionId).notifier)
          .deletePhoto(photo.id);

      if (mounted) {
        final state = ref.read(sectionMediaProvider(widget.sectionId));
        if (state.photos.isEmpty) {
          Navigator.pop(context);
        } else if (_currentIndex >= state.photos.length) {
          setState(() {
            _currentIndex = state.photos.length - 1;
          });
          _pageController.jumpToPage(_currentIndex);
        }
      }
    }
  }
}

class _PhotoPage extends StatefulWidget {
  const _PhotoPage({required this.photo});

  final PhotoItem photo;

  @override
  State<_PhotoPage> createState() => _PhotoPageState();
}

class _PhotoPageState extends State<_PhotoPage> {
  final TransformationController _transformController = TransformationController();

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final file = File(widget.photo.localPath);

    return InteractiveViewer(
      transformationController: _transformController,
      minScale: 0.5,
      maxScale: 4,
      onInteractionEnd: (_) {
        // Reset zoom on double tap
      },
      child: Center(
        child: FutureBuilder<bool>(
          future: file.exists(),
          builder: (context, snapshot) {
            if (snapshot.data == true) {
              return Image.file(
                file,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => _buildPlaceholder(),
              );
            }
            return _buildPlaceholder();
          },
        ),
      ),
    );
  }

  Widget _buildPlaceholder() => const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.broken_image_outlined,
          size: 64,
          color: Colors.white54,
        ),
        AppSpacing.gapVerticalMd,
        Text(
          'Image not available',
          style: TextStyle(color: Colors.white54),
        ),
      ],
    );
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? Colors.white;

    return InkWell(
      onTap: onTap,
      borderRadius: AppSpacing.borderRadiusMd,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: effectiveColor, size: 24),
            AppSpacing.gapVerticalXs,
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: effectiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
