import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// A [TextFormField] with an integrated microphone button for voice-to-text.
///
/// Tapping the mic icon starts speech recognition. Recognized text is appended
/// to the current field value. The button pulses while listening.
class VoiceTextFormField extends StatefulWidget {
  const VoiceTextFormField({
    required this.onChanged,
    this.initialValue,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.fieldBorder,
    this.keyboardType,
    this.minLines,
    this.maxLines,
    this.style,
    super.key,
  });

  final String? initialValue;
  final String? labelText;
  final String? hintText;
  final Widget? prefixIcon;
  final InputBorder? fieldBorder;
  final TextInputType? keyboardType;
  final int? minLines;
  final int? maxLines;
  final TextStyle? style;
  final ValueChanged<String> onChanged;

  @override
  State<VoiceTextFormField> createState() => _VoiceTextFormFieldState();
}

class _VoiceTextFormFieldState extends State<VoiceTextFormField>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _controller;
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  bool _speechAvailable = false;
  bool _receivedSpeechResult = false;
  bool _stoppedManually = false;
  String _baseTextBeforeListen = '';
  bool _availabilityNoticeShown = false;
  String? _voiceUnavailableReason;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
    _controller.addListener(_onTextChanged);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      _speechAvailable = await _speech.initialize(
        onError: (error) {
          final errorMessage = error.errorMsg.trim();
          if (errorMessage.isNotEmpty) {
            _voiceUnavailableReason = errorMessage;
          }
          if (mounted) setState(() => _isListening = false);
          _pulseController.stop();
          if (!mounted) return;
          final message = errorMessage.isEmpty
              ? 'Speech input failed on this device'
              : 'Speech input failed: $errorMessage';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (mounted) setState(() => _isListening = false);
            _pulseController.stop();
            if (!mounted) return;
            if (!_receivedSpeechResult && !_stoppedManually) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No speech detected. Please try again.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
            _stoppedManually = false;
          }
        },
      );
    } catch (_) {
      _speechAvailable = false;
      _voiceUnavailableReason = 'Speech service unavailable on this device.';
    }
    if (!_speechAvailable && _voiceUnavailableReason == null) {
      _voiceUnavailableReason = 'Voice typing is not configured on this device.';
    }
    if (mounted) setState(() {});
    _showAvailabilityNoticeIfNeeded();
  }

  void _showAvailabilityNoticeIfNeeded() {
    if (!mounted || _speechAvailable || _availabilityNoticeShown) return;
    _availabilityNoticeShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final reason = _voiceUnavailableReason ?? 'Voice typing is unavailable.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(reason),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Settings',
            onPressed: openAppSettings,
          ),
        ),
      );
    });
  }

  void _onTextChanged() {
    widget.onChanged(_controller.text);
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      _stoppedManually = true;
      await _speech.stop();
      setState(() => _isListening = false);
      _pulseController.stop();
      return;
    }

    if (!_speechAvailable) {
      _showAvailabilityNoticeIfNeeded();
      return;
    }

    setState(() => _isListening = true);
    _receivedSpeechResult = false;
    _stoppedManually = false;
    _baseTextBeforeListen = _controller.text.trim();
    unawaited(_pulseController.repeat(reverse: true));

    try {
      await _speech.listen(
        onResult: (result) {
          if (!mounted) return;
          final recognized = result.recognizedWords.trim();
          if (recognized.isEmpty) return;
          _receivedSpeechResult = true;

          // Keep replacing with latest transcript to avoid duplicate fragments.
          final newText = _baseTextBeforeListen.isEmpty
              ? recognized
              : '$_baseTextBeforeListen $recognized';
          _controller
            ..text = newText
            ..selection = TextSelection.fromPosition(
              TextPosition(offset: newText.length),
            );
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        listenOptions: SpeechListenOptions(
          listenMode: ListenMode.dictation,
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(() => _isListening = false);
      }
      _pulseController.stop();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Speech service unavailable. Please enable voice typing on device.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _speech.stop();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextFormField(
      controller: _controller,
      keyboardType: widget.keyboardType,
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      style: widget.style,
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        prefixIcon: widget.prefixIcon,
        suffixIcon: _speechAvailable
            ? AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return IconButton(
                    icon: Icon(
                      _isListening ? Icons.mic : Icons.mic_none_outlined,
                      color: _isListening
                          ? Color.lerp(
                              theme.colorScheme.error,
                              theme.colorScheme.error.withOpacity(0.4),
                              _pulseController.value,
                            )
                          : theme.colorScheme.onSurfaceVariant,
                      size: 22,
                    ),
                    onPressed: _toggleListening,
                    tooltip: _isListening ? 'Stop listening' : 'Voice input',
                  );
                },
              )
            : IconButton(
                icon: Icon(
                  Icons.mic_off_outlined,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                  size: 22,
                ),
                onPressed: _showAvailabilityNoticeIfNeeded,
                tooltip: 'Voice input unavailable',
              ),
        border: widget.fieldBorder,
        enabledBorder: widget.fieldBorder,
      ),
    );
  }
}
