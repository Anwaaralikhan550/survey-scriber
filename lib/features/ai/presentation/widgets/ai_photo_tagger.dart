import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/ai_repository.dart' as repo;
import '../providers/ai_providers.dart';
import 'ai_action_button.dart';
import 'ai_result_sheet.dart';
import 'ai_summary_section.dart';

/// Button to auto-tag a single photo using AI
class AiPhotoTagButton extends ConsumerWidget {
  const AiPhotoTagButton({
    required this.surveyId,
    required this.photoId,
    required this.imagePath,
    this.existingCaption,
    this.sectionContext,
    this.onTagsGenerated,
    super.key,
  });

  final String surveyId;
  final String photoId;
  final String imagePath;
  final String? existingCaption;
  final String? sectionContext;
  final void Function(List<String> tags, String description, String suggestedSection)?
      onTagsGenerated;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aiStatus = ref.watch(aiStatusProvider);
    final tagsState = ref.watch(aiPhotoTagsNotifierProvider);

    return aiStatus.when(
      data: (status) => AiIconButton(
          tooltip: status.available ? 'Auto-tag with AI' : 'AI unavailable',
          icon: Icons.auto_fix_high,
          isLoading: tagsState.isLoading,
          onPressed: status.available ? () => _generateTags(context, ref) : null,
        ),
      loading: () => const Tooltip(
        message: 'Checking AI availability...',
        child: AiIconButtonSkeleton(),
      ),
      error: (_, __) => const AiIconButton(
        tooltip: 'AI service unavailable',
        icon: Icons.auto_fix_high,
        onPressed: null,
      ),
    );
  }

  Future<void> _generateTags(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(aiPhotoTagsNotifierProvider.notifier);

    // Read and encode image
    String imageData;
    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image file not found')),
          );
        }
        return;
      }
      final bytes = await file.readAsBytes();
      imageData = base64Encode(bytes);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error reading image: $e')),
        );
      }
      return;
    }

    final request = repo.PhotoTagsRequest(
      surveyId: surveyId,
      photoId: photoId,
      imageData: imageData,
      existingCaption: existingCaption,
      sectionContext: sectionContext,
    );

    await notifier.generateTags(request);

    final state = ref.read(aiPhotoTagsNotifierProvider);

    if (!context.mounted) return;

    if (state.hasResponse && state.response != null) {
      final response = state.response!;
      final content = _formatTagsResult(response);

      final accepted = await AiResultSheet.show(
        context: context,
        title: 'Photo Analysis',
        content: content,
        disclaimer: AiDisclaimers.photoTags,
        onRetry: () => _generateTags(context, ref),
        isEditable: false,
      );

      if (accepted == true && onTagsGenerated != null) {
        onTagsGenerated!(
          response.tags.map((t) => t.label).toList(),
          response.description,
          response.suggestedSection,
        );
      }
    } else if (state.error != null) {
      AiErrorSheet.show(
        context: context,
        title: 'Tagging Failed',
        errorMessage: 'Unable to analyze photo. Please try again.',
        onRetry: () => _generateTags(context, ref),
      );
    }
  }

  String _formatTagsResult(dynamic response) {
    final buffer = StringBuffer();

    buffer.writeln('DESCRIPTION:');
    buffer.writeln(response.description);
    buffer.writeln();

    if (response.tags.isNotEmpty) {
      buffer.writeln('TAGS:');
      for (final tag in response.tags) {
        final confidence = (tag.confidence * 100).toStringAsFixed(0);
        buffer.writeln('- ${tag.label} ($confidence% confidence)');
      }
      buffer.writeln();
    }

    if (response.suggestedSection.isNotEmpty) {
      buffer.writeln('SUGGESTED SECTION:');
      buffer.writeln(response.suggestedSection);
    }

    return buffer.toString().trim();
  }
}

/// Bulk photo tagging button for gallery view
class AiBulkPhotoTagButton extends ConsumerStatefulWidget {
  const AiBulkPhotoTagButton({
    required this.surveyId,
    required this.photos,
    this.onComplete,
    super.key,
  });

  final String surveyId;
  final List<PhotoInfo> photos;
  final void Function(Map<String, PhotoTagResult> results)? onComplete;

  @override
  ConsumerState<AiBulkPhotoTagButton> createState() => _AiBulkPhotoTagButtonState();
}

class PhotoInfo {
  const PhotoInfo({
    required this.id,
    required this.path,
    this.existingCaption,
    this.sectionContext,
  });

  final String id;
  final String path;
  final String? existingCaption;
  final String? sectionContext;
}

class PhotoTagResult {
  const PhotoTagResult({
    required this.tags,
    required this.description,
    required this.suggestedSection,
  });

  final List<String> tags;
  final String description;
  final String suggestedSection;
}

class _AiBulkPhotoTagButtonState extends ConsumerState<AiBulkPhotoTagButton> {
  bool _isProcessing = false;
  int _processed = 0;
  int _total = 0;

  @override
  Widget build(BuildContext context) {
    final aiStatus = ref.watch(aiStatusProvider);
    final hasPhotos = widget.photos.isNotEmpty;

    return aiStatus.when(
      data: (status) {
        if (_isProcessing) {
          return _buildProgressIndicator(context);
        }

        final isEnabled = status.available && hasPhotos;
        final disabledReason = _getDisabledReason(status.available, hasPhotos);

        return Tooltip(
          message: disabledReason ?? 'Auto-tag all photos with AI',
          child: AiActionButton(
            label: 'Auto-tag All Photos',
            icon: Icons.auto_fix_high,
            isOutlined: true,
            onPressed: isEnabled ? _startBulkTagging : null,
          ),
        );
      },
      loading: () => const Tooltip(
        message: 'Checking AI availability...',
        child: AiButtonSkeleton(),
      ),
      error: (_, __) => const Tooltip(
        message: 'AI service unavailable',
        child: AiActionButton(
          label: 'Auto-tag All Photos',
          icon: Icons.auto_fix_high,
          isOutlined: true,
          onPressed: null,
        ),
      ),
    );
  }

  String? _getDisabledReason(bool isAvailable, bool hasPhotos) {
    if (!isAvailable) return 'AI service unavailable';
    if (!hasPhotos) return 'No photos to tag';
    return null;
  }

  Widget _buildProgressIndicator(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              value: _total > 0 ? _processed / _total : null,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Processing $_processed/$_total...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startBulkTagging() async {
    setState(() {
      _isProcessing = true;
      _processed = 0;
      _total = widget.photos.length;
    });

    final results = <String, PhotoTagResult>{};
    final notifier = ref.read(aiPhotoTagsNotifierProvider.notifier);

    for (final photo in widget.photos) {
      if (!mounted) break;

      try {
        final file = File(photo.path);
        if (!await file.exists()) continue;

        final bytes = await file.readAsBytes();
        final imageData = base64Encode(bytes);

        final request = repo.PhotoTagsRequest(
          surveyId: widget.surveyId,
          photoId: photo.id,
          imageData: imageData,
          existingCaption: photo.existingCaption,
          sectionContext: photo.sectionContext,
        );

        await notifier.generateTags(request);

        final state = ref.read(aiPhotoTagsNotifierProvider);
        if (state.hasResponse && state.response != null) {
          final response = state.response!;
          results[photo.id] = PhotoTagResult(
            tags: response.tags.map((t) => t.label).toList(),
            description: response.description,
            suggestedSection: response.suggestedSection,
          );
        }
      } catch (e) {
        // Continue with next photo
      }

      setState(() => _processed++);

      // Small delay to avoid rate limiting
      await Future.delayed(const Duration(milliseconds: 500));
    }

    setState(() => _isProcessing = false);

    if (mounted && widget.onComplete != null) {
      widget.onComplete!(results);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tagged ${results.length} of ${widget.photos.length} photos'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
