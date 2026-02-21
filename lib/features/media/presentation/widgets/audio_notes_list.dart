import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_spacing.dart';
import '../providers/media_provider.dart';
import 'audio_player_tile.dart';
import 'audio_recorder.dart';

/// List of audio notes for a survey section with recording capability
class AudioNotesList extends ConsumerStatefulWidget {
  const AudioNotesList({
    required this.surveyId,
    required this.sectionId,
    this.maxNotes = 10,
    this.showRecorder = true,
    super.key,
  });

  final String surveyId;
  final String sectionId;
  final int maxNotes;
  final bool showRecorder;

  @override
  ConsumerState<AudioNotesList> createState() => _AudioNotesListState();
}

class _AudioNotesListState extends ConsumerState<AudioNotesList> {
  bool _showRecorder = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mediaState = ref.watch(sectionMediaProvider(widget.sectionId));
    final audioNotes = mediaState.audioNotes;

    final canAddMore = audioNotes.length < widget.maxNotes;

    if (audioNotes.isEmpty && !widget.showRecorder) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Icon(
              Icons.mic_rounded,
              size: 20,
              color: colorScheme.primary,
            ),
            AppSpacing.gapHorizontalSm,
            Text(
              'Voice Notes',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (audioNotes.isNotEmpty) ...[
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
                  '${audioNotes.length}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const Spacer(),
            if (widget.showRecorder && canAddMore && !_showRecorder)
              TextButton.icon(
                onPressed: () => setState(() => _showRecorder = true),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
          ],
        ),

        AppSpacing.gapVerticalSm,

        // Recorder
        if (_showRecorder) ...[
          AudioRecorderWidget(
            surveyId: widget.surveyId,
            sectionId: widget.sectionId,
            onRecordingComplete: () {
              setState(() => _showRecorder = false);
            },
          ),
          AppSpacing.gapVerticalSm,
          Center(
            child: TextButton(
              onPressed: () => setState(() => _showRecorder = false),
              child: const Text('Cancel'),
            ),
          ),
          AppSpacing.gapVerticalMd,
        ],

        // Loading indicator
        if (mediaState.isLoading)
          const Center(child: CircularProgressIndicator())
        // Audio notes list
        else if (audioNotes.isEmpty && !_showRecorder)
          _buildEmptyState(context)
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: audioNotes.length,
            itemBuilder: (context, index) => AudioPlayerTile(
                audio: audioNotes[index],
                sectionId: widget.sectionId,
              ),
          ),

        // Add button at bottom if list has items
        if (audioNotes.isNotEmpty &&
            widget.showRecorder &&
            canAddMore &&
            !_showRecorder) ...[
          AppSpacing.gapVerticalSm,
          Center(
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _showRecorder = true),
              icon: const Icon(Icons.mic_rounded, size: 18),
              label: const Text('Record New Note'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(
          color: colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.mic_none_rounded,
            size: 48,
            color: colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          AppSpacing.gapVerticalMd,
          Text(
            'No voice notes yet',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          AppSpacing.gapVerticalSm,
          Text(
            'Record audio notes to document observations',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          if (widget.showRecorder) ...[
            AppSpacing.gapVerticalLg,
            FilledButton.icon(
              onPressed: () => setState(() => _showRecorder = true),
              icon: const Icon(Icons.mic_rounded, size: 18),
              label: const Text('Start Recording'),
            ),
          ],
        ],
      ),
    );
  }
}
