import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

import '../../../../app/theme/app_spacing.dart';
import '../providers/media_provider.dart';

const _uuid = Uuid();

/// Audio recording widget with waveform visualization
class AudioRecorderWidget extends ConsumerStatefulWidget {
  const AudioRecorderWidget({
    required this.surveyId,
    required this.sectionId,
    this.onRecordingComplete,
    super.key,
  });

  final String surveyId;
  final String sectionId;
  final VoidCallback? onRecordingComplete;

  @override
  ConsumerState<AudioRecorderWidget> createState() => _AudioRecorderWidgetState();
}

class _AudioRecorderWidgetState extends ConsumerState<AudioRecorderWidget> {
  final AudioRecorder _recorder = AudioRecorder();

  bool _isRecording = false;
  bool _isPaused = false;
  bool _isSaving = false;
  String? _recordingPath;
  Duration _duration = Duration.zero;
  Timer? _timer;
  double _amplitude = 0;
  List<double> _amplitudeHistory = [];

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.mic_rounded,
                color: _isRecording ? colorScheme.error : colorScheme.primary,
                size: 24,
              ),
              AppSpacing.gapHorizontalSm,
              Text(
                _isRecording ? 'Recording' : 'Voice Note',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              // Duration display
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _isRecording
                      ? colorScheme.errorContainer
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: AppSpacing.borderRadiusFull,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isRecording && !_isPaused)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: colorScheme.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                    Text(
                      _formatDuration(_duration),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontFeatures: [const FontFeature.tabularFigures()],
                        color: _isRecording
                            ? colorScheme.onErrorContainer
                            : colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          AppSpacing.gapVerticalLg,

          // Waveform visualization
          Container(
            height: 60,
            width: double.infinity,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: AppSpacing.borderRadiusMd,
            ),
            child: ClipRRect(
              borderRadius: AppSpacing.borderRadiusMd,
              child: _isRecording
                  ? CustomPaint(
                      painter: _WaveformPainter(
                        amplitudes: _amplitudeHistory,
                        color: _isPaused ? colorScheme.outline : colorScheme.error,
                      ),
                      size: const Size(double.infinity, 60),
                    )
                  : Center(
                      child: Text(
                        'Tap record to start',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
            ),
          ),

          AppSpacing.gapVerticalLg,

          // Control buttons - use smaller gaps and buttons to prevent overflow
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isRecording) ...[
                // Cancel button - smaller size (48px)
                _ControlButton(
                  icon: Icons.close_rounded,
                  label: 'Cancel',
                  onTap: _cancelRecording,
                  color: colorScheme.error,
                  size: 48,
                ),
                AppSpacing.gapHorizontalMd,
                // Pause/Resume button - smaller size (48px)
                _ControlButton(
                  icon: _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                  label: _isPaused ? 'Resume' : 'Pause',
                  onTap: _isPaused ? _resumeRecording : _pauseRecording,
                  size: 48,
                ),
                AppSpacing.gapHorizontalMd,
                // Stop and save button
                if (_isSaving) const SizedBox(
                        width: 48,
                        height: 48,
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      ) else _ControlButton(
                        icon: Icons.check_rounded,
                        label: 'Save',
                        onTap: _stopAndSave,
                        color: colorScheme.primary,
                        isPrimary: true,
                        size: 48,
                      ),
              ] else ...[
                // Record button
                _ControlButton(
                  icon: Icons.mic_rounded,
                  label: 'Record',
                  onTap: _startRecording,
                  color: colorScheme.error,
                  isPrimary: true,
                  size: 72,
                ),
              ],
            ],
          ),

          if (_isRecording) ...[
            AppSpacing.gapVerticalMd,
            Text(
              'Recording audio note for this section',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _startRecording() async {
    try {
      if (!await _recorder.hasPermission()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Microphone permission required'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      final tempDir = await getTemporaryDirectory();
      _recordingPath = '${tempDir.path}/audio_${_uuid.v4()}.m4a';

      await _recorder.start(
        const RecordConfig(
          
        ),
        path: _recordingPath!,
      );

      setState(() {
        _isRecording = true;
        _isPaused = false;
        _duration = Duration.zero;
        _amplitudeHistory = [];
      });

      _startTimer();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start recording: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      if (!_isPaused && _isRecording) {
        final amp = await _recorder.getAmplitude();
        setState(() {
          _duration += const Duration(milliseconds: 100);
          _amplitude = (amp.current + 40) / 40; // Normalize -40dB to 0dB
          _amplitudeHistory.add(_amplitude.clamp(0.0, 1.0));
          if (_amplitudeHistory.length > 100) {
            _amplitudeHistory.removeAt(0);
          }
        });
      }
    });
  }

  Future<void> _pauseRecording() async {
    await _recorder.pause();
    setState(() => _isPaused = true);
  }

  Future<void> _resumeRecording() async {
    await _recorder.resume();
    setState(() => _isPaused = false);
  }

  Future<void> _cancelRecording() async {
    _timer?.cancel();
    await _recorder.cancel();

    // Delete temp file if exists
    if (_recordingPath != null) {
      final file = File(_recordingPath!);
      if (await file.exists()) {
        await file.delete();
      }
    }

    if (mounted) {
      setState(() {
        _isRecording = false;
        _isPaused = false;
        _duration = Duration.zero;
        _recordingPath = null;
        _amplitudeHistory = [];
      });
    }
  }

  Future<void> _stopAndSave() async {
    if (_recordingPath == null) return;

    setState(() => _isSaving = true);
    _timer?.cancel();

    try {
      final path = await _recorder.stop();
      if (path == null) throw Exception('Recording failed');

      final file = File(path);
      final durationMs = _duration.inMilliseconds;

      // Save to media storage
      final notifier = ref.read(sectionMediaProvider(widget.sectionId).notifier);
      final audio = await notifier.addAudio(
        surveyId: widget.surveyId,
        file: file,
        duration: durationMs,
      );

      // Delete temp file
      if (await file.exists()) {
        await file.delete();
      }

      if (audio != null && mounted) {
        widget.onRecordingComplete?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Audio note saved'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      if (mounted) {
        setState(() {
          _isRecording = false;
          _isPaused = false;
          _duration = Duration.zero;
          _recordingPath = null;
          _amplitudeHistory = [];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save recording: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.isPrimary = false,
    this.size = 56,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final bool isPrimary;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final effectiveColor = color ?? colorScheme.onSurface;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: isPrimary ? effectiveColor : colorScheme.surfaceContainerHighest,
          shape: const CircleBorder(),
          elevation: isPrimary ? 2 : 0,
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(
                icon,
                color: isPrimary ? colorScheme.onPrimary : effectiveColor,
                size: size * 0.45,
              ),
            ),
          ),
        ),
        AppSpacing.gapVerticalXs,
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _WaveformPainter extends CustomPainter {
  _WaveformPainter({
    required this.amplitudes,
    required this.color,
  });

  final List<double> amplitudes;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (amplitudes.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final barWidth = size.width / 50;
    final spacing = barWidth * 0.5;
    final totalBarWidth = barWidth + spacing;
    final startIndex = (amplitudes.length - 50).clamp(0, amplitudes.length);
    final displayAmps = amplitudes.sublist(startIndex);

    for (var i = 0; i < displayAmps.length && i < 50; i++) {
      final x = i * totalBarWidth + barWidth / 2;
      final amp = displayAmps[i].clamp(0.1, 1.0);
      final barHeight = amp * (size.height - 10);
      final y1 = (size.height - barHeight) / 2;
      final y2 = y1 + barHeight;

      canvas.drawLine(
        Offset(x, y1),
        Offset(x, y2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) => oldDelegate.amplitudes != amplitudes;
}
