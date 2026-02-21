import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../domain/entities/media_item.dart';
import '../providers/media_provider.dart';
import 'annotation_editor.dart';
import 'photo_viewer.dart';

/// Grid display of photos for a section with add button
class PhotoGrid extends ConsumerWidget {
  const PhotoGrid({
    required this.surveyId,
    required this.sectionId,
    this.maxPhotos = 20,
    this.crossAxisCount = 3,
    this.showAddButton = true,
    super.key,
  });

  final String surveyId;
  final String sectionId;
  final int maxPhotos;
  final int crossAxisCount;
  final bool showAddButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaState = ref.watch(sectionMediaProvider(sectionId));
    final photos = mediaState.photos;

    if (photos.isEmpty && !showAddButton) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (photos.isNotEmpty || showAddButton)
          _buildHeader(context, photos.length),
        AppSpacing.gapVerticalSm,
        if (mediaState.isLoading)
          const Center(child: CircularProgressIndicator())
        else
          _buildGrid(context, ref, photos),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, int count) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(
          Icons.photo_library_outlined,
          size: 20,
          color: colorScheme.primary,
          semanticLabel: 'Photos section',
        ),
        AppSpacing.gapHorizontalSm,
        Text(
          'Photos',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        if (count > 0) ...[
          AppSpacing.gapHorizontalSm,
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
              '$count',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGrid(BuildContext context, WidgetRef ref, List<PhotoItem> photos) {
    final canAddMore = photos.length < maxPhotos;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
      ),
      itemCount: photos.length + (showAddButton && canAddMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (showAddButton && canAddMore && index == photos.length) {
          return _AddPhotoTile(
            surveyId: surveyId,
            sectionId: sectionId,
          );
        }
        return _PhotoTile(
          photo: photos[index],
          sectionId: sectionId,
          index: index,
          totalCount: photos.length,
        );
      },
    );
  }
}

class _PhotoTile extends ConsumerWidget {
  const _PhotoTile({
    required this.photo,
    required this.sectionId,
    required this.index,
    required this.totalCount,
  });

  final PhotoItem photo;
  final String sectionId;
  final int index;
  final int totalCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final file = File(photo.localPath);

    return Semantics(
      button: true,
      label: 'Photo ${index + 1} of $totalCount${photo.hasAnnotations ? ', has annotations' : ''}${photo.caption != null ? ', ${photo.caption}' : ''}. Tap to view, long press for options',
      child: GestureDetector(
        onTap: () => _openViewer(context, ref),
        onLongPress: () => _showOptions(context, ref),
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
                // Photo image
                FutureBuilder<bool>(
                  future: file.exists(),
                  builder: (context, snapshot) {
                    if (snapshot.data == true) {
                      return ExcludeSemantics(
                        child: Image.file(
                          file,
                          fit: BoxFit.cover,
                          cacheWidth: 300,
                          errorBuilder: (_, __, ___) => _buildPlaceholder(colorScheme),
                        ),
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
                    child: ExcludeSemantics(
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
                  ),
                // Index badge
                Positioned(
                  bottom: 4,
                  left: 4,
                  child: ExcludeSemantics(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        borderRadius: AppSpacing.borderRadiusSm,
                      ),
                      child: Text(
                        '${index + 1}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
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

  void _openViewer(BuildContext context, WidgetRef ref) {
    final state = ref.read(sectionMediaProvider(sectionId));
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PhotoViewerPage(
          photos: state.photos,
          initialIndex: index,
          sectionId: sectionId,
        ),
      ),
    );
  }

  Future<void> _openAnnotationEditor(BuildContext context, WidgetRef ref) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AnnotationEditorPage(
          photo: photo,
          sectionId: sectionId,
        ),
      ),
    );

    // Refresh if annotations were saved
    if (result == true && context.mounted) {
      ref.invalidate(sectionMediaProvider(sectionId));
    }
  }

  Future<void> _showOptions(BuildContext context, WidgetRef ref) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final result = await showModalBottomSheet<String>(
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
          children: [
            ListTile(
              leading: const Icon(Icons.visibility_rounded),
              title: const Text('View'),
              onTap: () => Navigator.pop(context, 'view'),
            ),
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: const Text('Annotate'),
              onTap: () => Navigator.pop(context, 'annotate'),
            ),
            ListTile(
              leading: const Icon(Icons.text_fields_rounded),
              title: const Text('Add Caption'),
              onTap: () => Navigator.pop(context, 'caption'),
            ),
            ListTile(
              leading: Icon(Icons.delete_rounded, color: colorScheme.error),
              title: Text('Delete', style: TextStyle(color: colorScheme.error)),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
            AppSpacing.gapVerticalMd,
          ],
        ),
      ),
    );

    if (!context.mounted || result == null) return;

    switch (result) {
      case 'view':
        _openViewer(context, ref);
      case 'annotate':
        _openAnnotationEditor(context, ref);
      case 'caption':
        _showCaptionDialog(context, ref);
      case 'delete':
        _confirmDelete(context, ref);
    }
  }

  Future<void> _showCaptionDialog(BuildContext context, WidgetRef ref) async {
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
          .read(sectionMediaProvider(sectionId).notifier)
          .updatePhotoCaption(photo.id, result.isEmpty ? null : result);
    }

    controller.dispose();
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
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
          .read(sectionMediaProvider(sectionId).notifier)
          .deletePhoto(photo.id);
    }
  }
}

class _AddPhotoTile extends ConsumerWidget {
  const _AddPhotoTile({
    required this.surveyId,
    required this.sectionId,
  });

  final String surveyId;
  final String sectionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      button: true,
      label: 'Add photo. Tap to take a photo or choose from gallery',
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: AppSpacing.borderRadiusMd,
          border: Border.all(
            color: colorScheme.outlineVariant,
          ),
          color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showCaptureOptions(context, ref),
            borderRadius: AppSpacing.borderRadiusMd,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo_outlined,
                    size: 28,
                    color: colorScheme.onSurfaceVariant,
                    semanticLabel: 'Add photo',
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Add',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Shows modal bottom sheet with Camera/Gallery options (Horizontal Card Layout)
  void _showCaptureOptions(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet<ImageSource>(
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Add Photo',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              AppSpacing.gapVerticalLg,
              // Horizontal Row of Cards
              Row(
                children: [
                  // Camera Card (Left)
                  Expanded(
                    child: _MediaOptionCard(
                      icon: Icons.camera_alt_rounded,
                      label: 'Take Photo',
                      subtitle: 'Camera',
                      containerColor: colorScheme.primaryContainer,
                      iconColor: colorScheme.onPrimaryContainer,
                      onTap: () => Navigator.pop(context, ImageSource.camera),
                    ),
                  ),
                  AppSpacing.gapHorizontalMd,
                  // Gallery Card (Right)
                  Expanded(
                    child: _MediaOptionCard(
                      icon: Icons.photo_library_rounded,
                      label: 'Gallery',
                      subtitle: 'Choose existing',
                      containerColor: colorScheme.secondaryContainer,
                      iconColor: colorScheme.onSecondaryContainer,
                      onTap: () => Navigator.pop(context, ImageSource.gallery),
                    ),
                  ),
                ],
              ),
              AppSpacing.gapVerticalLg,
            ],
          ),
        ),
      ),
    ).then((source) async {
      if (source != null && context.mounted) {
        await _captureFromSource(context, ref, source);
      }
    });
  }

  Future<void> _captureFromSource(BuildContext context, WidgetRef ref, ImageSource source) async {
    try {
      final picker = ref.read(imagePickerProvider);
      final image = await picker.pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 85,
      );

      if (image == null) return;

      final file = File(image.path);
      final notifier = ref.read(sectionMediaProvider(sectionId).notifier);

      final photo = await notifier.addPhoto(
        surveyId: surveyId,
        file: file,
      );

      if (photo != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo added'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to capture photo: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}

/// Horizontal card option for media picker bottom sheet
class _MediaOptionCard extends StatelessWidget {
  const _MediaOptionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.containerColor,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color containerColor;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      button: true,
      label: '$label. $subtitle',
      child: Material(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.lg,
              horizontal: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.outlineVariant.withOpacity(0.5),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon container
                ExcludeSemantics(
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: containerColor,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: containerColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      icon,
                      color: iconColor,
                      size: 28,
                    ),
                  ),
                ),
                AppSpacing.gapVerticalMd,
                // Label
                ExcludeSemantics(
                  child: Text(
                    label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 2),
                // Subtitle
                ExcludeSemantics(
                  child: Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
