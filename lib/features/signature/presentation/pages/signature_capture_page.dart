import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../domain/entities/signature_item.dart';
import '../providers/signature_provider.dart';
import '../widgets/signature_pad.dart';

/// Full-screen page for capturing signatures
class SignatureCapturePage extends ConsumerStatefulWidget {
  const SignatureCapturePage({
    required this.surveyId,
    this.sectionId,
    this.initialSignerName,
    this.initialSignerRole,
    super.key,
  });

  final String surveyId;
  final String? sectionId;
  final String? initialSignerName;
  final String? initialSignerRole;

  @override
  ConsumerState<SignatureCapturePage> createState() =>
      _SignatureCapturePageState();
}

class _SignatureCapturePageState extends ConsumerState<SignatureCapturePage> {
  final _signaturePadKey = GlobalKey<SignaturePadState>();
  final _nameController = TextEditingController();
  final _nameFocusNode = FocusNode();

  List<SignatureStroke> _strokes = [];
  String? _selectedRole;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.initialSignerName ?? '';
    _selectedRole = widget.initialSignerRole;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  bool get _canSave => _strokes.isNotEmpty && !_isSaving;
  bool get _canUndo => _strokes.isNotEmpty;
  bool get _canClear => _strokes.isNotEmpty;

  void _onStrokesChanged(List<SignatureStroke> strokes) {
    setState(() {
      _strokes = strokes;
    });
  }

  void _undo() {
    _signaturePadKey.currentState?.undo();
  }

  void _clear() {
    _signaturePadKey.currentState?.clear();
  }

  Future<void> _save() async {
    if (!_canSave) return;

    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    setState(() {
      _isSaving = true;
    });

    try {
      final notifier = ref.read(surveySignaturesProvider(widget.surveyId).notifier);

      // Get canvas size for preview generation
      final canvasSize = _signaturePadKey.currentState?.getCanvasSize(context);

      final signature = await notifier.addSignature(
        strokes: _strokes,
        sectionId: widget.sectionId,
        signerName: _nameController.text.trim().isNotEmpty
            ? _nameController.text.trim()
            : null,
        signerRole: _selectedRole,
        width: canvasSize?.width.toInt(),
        height: canvasSize?.height.toInt(),
      );

      if (signature != null && mounted) {
        // Generate PNG preview
        final previewService = ref.read(signaturePreviewServiceProvider);
        if (canvasSize != null) {
          try {
            final previewPath = await previewService.savePreview(
              signatureId: signature.id,
              strokes: _strokes,
              canvasSize: canvasSize,
            );
            await notifier.updatePreviewPath(signature.id, previewPath);
          } catch (e) {
            // Preview generation failed, but signature is saved
            debugPrint('Failed to generate signature preview: $e');
          }
        }

        if (mounted) {
          Navigator.of(context).pop(signature);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save signature: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _cancel() {
    if (_strokes.isNotEmpty) {
      _showDiscardDialog();
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _showDiscardDialog() async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard signature?'),
        content: const Text(
          'You have an unsaved signature. Are you sure you want to discard it?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    if (discard == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mediaQuery = MediaQuery.of(context);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: _cancel,
          tooltip: 'Cancel',
        ),
        title: const Text('Add Signature'),
        centerTitle: true,
        actions: [
          FilledButton(
            onPressed: _canSave ? _save : null,
            child: _isSaving
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.onPrimary,
                    ),
                  )
                : const Text('Save'),
          ),
          AppSpacing.gapHorizontalMd,
        ],
      ),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // Signer info section
            _SignerInfoSection(
              nameController: _nameController,
              nameFocusNode: _nameFocusNode,
              selectedRole: _selectedRole,
              onRoleChanged: (role) {
                setState(() {
                  _selectedRole = role;
                });
              },
            ),

            // Instructions
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.md,
                right: AppSpacing.md,
                top: AppSpacing.sm,
                bottom: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.draw_rounded,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  AppSpacing.gapHorizontalXs,
                  Text(
                    'Draw your signature below',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // Signature canvas - expands to fill available space
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: AppSpacing.borderRadiusMd,
                    border: Border.all(
                      color: colorScheme.outlineVariant,
                    ),
                  ),
                  child: SignaturePad(
                    key: _signaturePadKey,
                    onChanged: _onStrokesChanged,
                    strokeColor: colorScheme.onSurface,
                    backgroundColor: colorScheme.surface,
                  ),
                ),
              ),
            ),

            // Action bar - fixed at bottom
            Container(
              padding: EdgeInsets.only(
                left: AppSpacing.md,
                right: AppSpacing.md,
                top: AppSpacing.sm,
                bottom: mediaQuery.padding.bottom + AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: colorScheme.outlineVariant.withOpacity(0.5),
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Undo button
                  _ActionButton(
                    icon: Icons.undo_rounded,
                    label: 'Undo',
                    onPressed: _canUndo ? _undo : null,
                  ),
                  AppSpacing.gapHorizontalMd,
                  // Clear button
                  _ActionButton(
                    icon: Icons.delete_outline_rounded,
                    label: 'Clear',
                    onPressed: _canClear ? _clear : null,
                    isDestructive: true,
                  ),
                  const Spacer(),
                  // Stroke indicator
                  if (_strokes.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withOpacity(0.5),
                        borderRadius: AppSpacing.borderRadiusSm,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 14,
                            color: colorScheme.primary,
                          ),
                          AppSpacing.gapHorizontalXs,
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Captured',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignerInfoSection extends StatelessWidget {
  const _SignerInfoSection({
    required this.nameController,
    required this.nameFocusNode,
    required this.selectedRole,
    required this.onRoleChanged,
  });

  final TextEditingController nameController;
  final FocusNode nameFocusNode;
  final String? selectedRole;
  final ValueChanged<String?> onRoleChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withOpacity(0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          // Name field
          Expanded(
            flex: 3,
            child: TextField(
              controller: nameController,
              focusNode: nameFocusNode,
              decoration: InputDecoration(
                labelText: 'Signer name',
                hintText: 'Enter name (optional)',
                prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                filled: true,
                fillColor: colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: AppSpacing.borderRadiusSm,
                  borderSide: BorderSide(color: colorScheme.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppSpacing.borderRadiusSm,
                  borderSide: BorderSide(color: colorScheme.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppSpacing.borderRadiusSm,
                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
              ),
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
            ),
          ),
          AppSpacing.gapHorizontalSm,
          // Role dropdown
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<String>(
              value: selectedRole,
              decoration: InputDecoration(
                labelText: 'Role',
                filled: true,
                fillColor: colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: AppSpacing.borderRadiusSm,
                  borderSide: BorderSide(color: colorScheme.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppSpacing.borderRadiusSm,
                  borderSide: BorderSide(color: colorScheme.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppSpacing.borderRadiusSm,
                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
              ),
              hint: const Text('Select'),
              isExpanded: true,
              items: [
                const DropdownMenuItem<String>(
                  child: Text('None'),
                ),
                ...SignerRoles.all.map(
                  (role) => DropdownMenuItem<String>(
                    value: role,
                    child: Text(_formatRole(role)),
                  ),
                ),
              ],
              onChanged: onRoleChanged,
            ),
          ),
        ],
      ),
    );
  }

  String _formatRole(String role) {
    // Convert camelCase to Title Case - with safety checks
    if (role.isEmpty) return role;
    return role
        .replaceAllMapped(
          RegExp('([A-Z])'),
          (match) => ' ${match.group(1)}',
        )
        .trim()
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isEnabled = onPressed != null;
    final color = isEnabled
        ? (isDestructive ? colorScheme.error : colorScheme.onSurfaceVariant)
        : colorScheme.onSurfaceVariant.withOpacity(0.4);

    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18, color: color),
      label: Text(
        label,
        style: TextStyle(color: color),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),
    );
  }
}
