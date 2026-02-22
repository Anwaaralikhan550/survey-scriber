import 'package:flutter/material.dart';

import '../../../../shared/presentation/widgets/voice_text_field.dart';
import '../../domain/models/inspection_models.dart';

bool shouldShowInspectionField(
  InspectionFieldDefinition field,
  Map<String, String> answers,
) {
  final controller = field.conditionalOn;
  if (controller == null || controller.isEmpty) return true;

  if (controller.contains('&') || controller.contains('|') || controller.contains('!')) {
    final expr = controller;
    final groups = expr.split('|').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    bool evalToken(String token) {
      var key = token.trim();
      var negate = false;
      if (key.startsWith('!')) {
        negate = true;
        key = key.substring(1).trim();
      }
      var truthy = false;
      if (key.contains('=')) {
        final parts = key.split('=');
        final fieldKey = parts.first.trim();
        final expected = parts.sublist(1).join('=').trim().toLowerCase();
        final rawValue = (answers[fieldKey] ?? '').trim().toLowerCase();
        truthy = rawValue == expected;
      } else {
        final rawValue = answers[key] ?? '';
        truthy = rawValue.trim().isNotEmpty && rawValue.toLowerCase() != 'false';
      }
      return negate ? !truthy : truthy;
    }

    bool evalGroup(String group) {
      final tokens = group.split('&').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      if (tokens.isEmpty) return true;
      for (final token in tokens) {
        if (!evalToken(token)) return false;
      }
      return true;
    }

    final matched = groups.isEmpty ? evalGroup(expr) : groups.any(evalGroup);
    final mode = (field.conditionalMode ?? 'show').toLowerCase();
    return mode == 'hide' ? !matched : matched;
  }

  if (controller.contains('=')) {
    final parts = controller.split('=');
    final fieldKey = parts.first.trim();
    final expected = parts.sublist(1).join('=').trim().toLowerCase();
    final rawValue = (answers[fieldKey] ?? '').trim().toLowerCase();
    final matched = rawValue == expected;
    final mode = (field.conditionalMode ?? 'show').toLowerCase();
    return mode == 'hide' ? !matched : matched;
  }

  final rawValue = answers[controller] ?? '';
  final expected = field.conditionalValue;
  final mode = (field.conditionalMode ?? 'show').toLowerCase();
  if (expected == null || expected.isEmpty) {
    final matched = rawValue.trim().isNotEmpty && rawValue.toLowerCase() != 'false';
    return mode == 'hide' ? !matched : matched;
  }

  final normalizedValue = rawValue.trim().toLowerCase();
  final candidates = expected
      .split(RegExp(r'[|,]'))
      .map((e) => e.trim().toLowerCase())
      .where((e) => e.isNotEmpty)
      .toList();
  if (candidates.isEmpty) return true;
  final matched = candidates.contains(normalizedValue);
  return mode == 'hide' ? !matched : matched;
}

class InspectionFieldInput extends StatelessWidget {
  const InspectionFieldInput({
    required this.field,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final InspectionFieldDefinition field;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: theme.colorScheme.outlineVariant.withOpacity(0.5),
      ),
    );

    switch (field.type) {
      case InspectionFieldType.label:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.label_outlined,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  field.label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        );
      case InspectionFieldType.checkbox:
        final checked = value.toLowerCase() == 'true' || value == '1';
        return Material(
          color: checked
              ? theme.colorScheme.primaryContainer.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () => onChanged(checked ? 'false' : 'true'),
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: checked
                      ? theme.colorScheme.primary.withOpacity(0.4)
                      : theme.colorScheme.outlineVariant.withOpacity(0.5),
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: checked,
                      onChanged: (next) =>
                          onChanged(next == true ? 'true' : 'false'),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      field.label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: checked ? FontWeight.w500 : FontWeight.w400,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      case InspectionFieldType.dropdown:
        final options = field.options ?? const <String>[];
        if (options.isEmpty) {
          return TextFormField(
            initialValue: value,
            decoration: InputDecoration(
              labelText: field.label,
              prefixIcon: Icon(
                Icons.list_alt_outlined,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              border: fieldBorder,
              enabledBorder: fieldBorder,
            ),
            onChanged: onChanged,
          );
        }
        return _InspectionDropdown(
          label: field.label,
          value: value,
          options: options,
          onChanged: onChanged,
        );
      case InspectionFieldType.number:
        return TextFormField(
          initialValue: value,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: field.label,
            prefixIcon: Icon(
              Icons.numbers_outlined,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            border: fieldBorder,
            enabledBorder: fieldBorder,
          ),
          onChanged: onChanged,
        );
      case InspectionFieldType.text:
        return VoiceTextFormField(
          initialValue: value,
          labelText: field.label,
          prefixIcon: Icon(
            Icons.short_text_outlined,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          fieldBorder: fieldBorder,
          onChanged: onChanged,
        );
    }
  }
}

/// A polished Material 3 dropdown that opens a bottom sheet with checkmarks,
/// subtle dividers, and smooth open/close animations.
class _InspectionDropdown extends StatefulWidget {
  const _InspectionDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  State<_InspectionDropdown> createState() => _InspectionDropdownState();
}

class _InspectionDropdownState extends State<_InspectionDropdown>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  late final AnimationController _iconController;
  late final Animation<double> _iconTurns;

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _iconTurns = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _iconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasValue =
        widget.value.isNotEmpty && widget.options.contains(widget.value);

    return InkWell(
      onTap: () => _openSheet(context),
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        isFocused: _isOpen,
        isEmpty: !hasValue,
        decoration: InputDecoration(
          labelText: widget.label,
          prefixIcon: Icon(
            Icons.view_list_outlined,
            size: 20,
            color:
                _isOpen ? colorScheme.primary : colorScheme.onSurfaceVariant,
          ),
          suffixIcon: RotationTransition(
            turns: _iconTurns,
            child: Icon(
              Icons.arrow_drop_down_rounded,
              color:
                  _isOpen ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: colorScheme.outlineVariant.withOpacity(0.5),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: colorScheme.outlineVariant.withOpacity(0.5),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: colorScheme.primary,
              width: 2,
            ),
          ),
        ),
        child: hasValue
            ? Text(
                widget.value,
                style: theme.textTheme.bodyLarge,
                overflow: TextOverflow.ellipsis,
              )
            : null,
      ),
    );
  }

  void _openSheet(BuildContext parentContext) {
    final theme = Theme.of(parentContext);
    final colorScheme = theme.colorScheme;
    final screenHeight = MediaQuery.of(parentContext).size.height;
    final bottomPadding = MediaQuery.of(parentContext).viewPadding.bottom;

    setState(() => _isOpen = true);
    _iconController.forward();

    const headerHeight = 76.0;
    const itemHeight = 49.0;
    final contentHeight =
        headerHeight + (widget.options.length * itemHeight) + bottomPadding;
    final maxHeight = screenHeight * 0.55;
    final sheetHeight =
        contentHeight.clamp(headerHeight + itemHeight, maxHeight);

    showModalBottomSheet<String>(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      elevation: 2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SizedBox(
        height: sheetHeight,
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            Divider(
              height: 1,
              color: colorScheme.outlineVariant.withOpacity(0.3),
            ),
            // Options list
            Expanded(
              child: ListView.separated(
                padding:
                    EdgeInsets.fromLTRB(0, 4, 0, bottomPadding + 4),
                itemCount: widget.options.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  indent: 52,
                  endIndent: 20,
                  color: colorScheme.outlineVariant.withOpacity(0.15),
                ),
                itemBuilder: (_, index) {
                  final option = widget.options[index];
                  final isSelected = option == widget.value;

                  return _DropdownOption(
                    label: option,
                    isSelected: isSelected,
                    onTap: () {
                      widget.onChanged(option);
                      Navigator.pop(sheetContext, option);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ).then((_) {
      if (mounted) {
        setState(() => _isOpen = false);
        _iconController.reverse();
      }
    });
  }
}

class _DropdownOption extends StatelessWidget {
  const _DropdownOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: isSelected
          ? colorScheme.primaryContainer.withOpacity(0.15)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                child: isSelected
                    ? Icon(
                        Icons.check_rounded,
                        size: 20,
                        color: colorScheme.primary,
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InspectionPhrasePreview extends StatefulWidget {
  const InspectionPhrasePreview({
    required this.phraseText,
    required this.isEdited,
    this.userNote = '',
    this.onPhraseTextChanged,
    this.onRegenerate,
    this.onUserNoteChanged,
    super.key,
  });

  /// The text to display — either auto-generated phrases joined by \n\n
  /// or the user's manually edited text.
  final String phraseText;

  /// Whether [phraseText] is the user's own edited version.
  final bool isEdited;

  final String userNote;
  final ValueChanged<String>? onPhraseTextChanged;
  final VoidCallback? onRegenerate;
  final ValueChanged<String>? onUserNoteChanged;

  @override
  State<InspectionPhrasePreview> createState() => _InspectionPhrasePreviewState();
}

class _InspectionPhrasePreviewState extends State<InspectionPhrasePreview> {
  bool _isEditingPhrases = false;
  bool _isEditingNote = false;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.userNote);
  }

  @override
  void didUpdateWidget(InspectionPhrasePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync note controller
    if (oldWidget.userNote != widget.userNote && !_isEditingNote) {
      _noteController.text = widget.userNote;
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasNote = widget.userNote.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row with action buttons ──
          Row(
            children: [
              Icon(
                Icons.auto_awesome_outlined,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Live Preview',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (_isEditingPhrases)
                // "Done" button when editing
                InkWell(
                  onTap: () => setState(() => _isEditingPhrases = false),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.check_rounded,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                )
              else ...[
                // Edit button
                InkWell(
                  onTap: () => setState(() => _isEditingPhrases = true),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.edit_rounded,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                // Regenerate button (only when user has edited)
                if (widget.isEdited) ...[
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () {
                      widget.onRegenerate?.call();
                      setState(() => _isEditingPhrases = false);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.refresh_rounded,
                        size: 16,
                        color: theme.colorScheme.tertiary,
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
          const SizedBox(height: 8),

          // ── Phrase text area ──
          if (_isEditingPhrases)
            VoiceTextFormField(
              initialValue: widget.phraseText,
              maxLines: null,
              minLines: 3,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
              hintText: 'Edit preview text...',
              fieldBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              onChanged: (value) => widget.onPhraseTextChanged?.call(value),
            )
          else
            // Read-only display
            Text(
              widget.phraseText,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),

          // ── Divider + User note section ──
          if (widget.phraseText.isNotEmpty && (hasNote || _isEditingNote))
            Divider(
              height: 16,
              color: theme.colorScheme.outlineVariant.withOpacity(0.3),
            ),

          if (_isEditingNote) ...[
            TextField(
              controller: _noteController,
              maxLines: 3,
              minLines: 2,
              style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
              decoration: InputDecoration(
                hintText: 'Add your observation...',
                hintStyle: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: theme.colorScheme.primary),
                ),
              ),
              onChanged: widget.onUserNoteChanged,
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => setState(() => _isEditingNote = false),
                icon: const Icon(Icons.check_rounded, size: 16),
                label: const Text('Done'),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  textStyle: theme.textTheme.labelSmall,
                ),
              ),
            ),
          ] else if (hasNote) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.edit_note_rounded,
                    size: 16, color: theme.colorScheme.tertiary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.userNote,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => setState(() => _isEditingNote = true),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.edit_rounded,
                        size: 16, color: theme.colorScheme.primary),
                  ),
                ),
              ],
            ),
          ] else ...[
            TextButton.icon(
              onPressed: () => setState(() => _isEditingNote = true),
              icon: Icon(Icons.edit_note_rounded,
                  size: 18, color: theme.colorScheme.primary),
              label: Text(
                'Add Note',
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: theme.colorScheme.primary),
              ),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
