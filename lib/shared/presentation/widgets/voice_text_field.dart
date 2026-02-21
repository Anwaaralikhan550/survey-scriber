import 'dart:async';

import 'package:flutter/material.dart';
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
    this.prefixIcon,
    this.fieldBorder,
    this.keyboardType,
    super.key,
  });

  final String? initialValue;
  final String? labelText;
  final Widget? prefixIcon;
  final InputBorder? fieldBorder;
  final TextInputType? keyboardType;
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
        onError: (_) {
          if (mounted) setState(() => _isListening = false);
          _pulseController.stop();
        },
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (mounted) setState(() => _isListening = false);
            _pulseController.stop();
          }
        },
      );
    } catch (_) {
      _speechAvailable = false;
    }
    if (mounted) setState(() {});
  }

  void _onTextChanged() {
    widget.onChanged(_controller.text);
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      _pulseController.stop();
      return;
    }

    if (!_speechAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Speech recognition not available on this device'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    setState(() => _isListening = true);
    unawaited(_pulseController.repeat(reverse: true));

    await _speech.listen(
      onResult: (result) {
        if (!mounted) return;
        final recognized = result.recognizedWords;
        if (recognized.isEmpty) return;

        // Append to existing text with a space separator
        final current = _controller.text;
        final newText = current.isEmpty
            ? recognized
            : '$current $recognized';
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
      decoration: InputDecoration(
        labelText: widget.labelText,
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
            : null,
        border: widget.fieldBorder,
        enabledBorder: widget.fieldBorder,
      ),
    );
  }
}
