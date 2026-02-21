import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/storage/storage_service.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  bool _isSaving = false;
  bool _isUploadingImage = false;

  // Local image preview before upload completes
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authNotifierProvider).user;
    _fullNameController = TextEditingController(text: user?.fullName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isSaving = true);

    final fullName = _fullNameController.text.trim();
    final (success, errorMessage) = await ref
        .read(authNotifierProvider.notifier)
        .updateProfile(fullName: fullName);

    if (!mounted) return;

    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile updated successfully'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          showCloseIcon: true,
          closeIconColor: Theme.of(context).colorScheme.onPrimaryContainer,
          duration: const Duration(seconds: 2),
        ),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage ?? 'Failed to update profile'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
          showCloseIcon: true,
          closeIconColor: Theme.of(context).colorScheme.onErrorContainer,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showImagePickerSheet() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              AppSpacing.gapVerticalLg,

              // Title
              Text(
                'Change Profile Photo',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              AppSpacing.gapVerticalLg,

              // Options
              _ImagePickerOption(
                icon: Icons.camera_alt_rounded,
                iconColor: colorScheme.primary,
                label: 'Take Photo',
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              _ImagePickerOption(
                icon: Icons.photo_library_rounded,
                iconColor: colorScheme.secondary,
                label: 'Choose from Gallery',
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              // Show remove option if local preview exists OR user has avatar
              if (_selectedImage != null || ref.read(authNotifierProvider).user?.avatarUrl != null)
                _ImagePickerOption(
                  icon: Icons.delete_outline_rounded,
                  iconColor: colorScheme.error,
                  label: 'Remove Photo',
                  onTap: () {
                    Navigator.pop(context);
                    _removeImage();
                  },
                ),
              AppSpacing.gapVerticalMd,
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (pickedFile != null && mounted) {
        final imageFile = File(pickedFile.path);

        // Show local preview immediately
        setState(() {
          _selectedImage = imageFile;
          _isUploadingImage = true;
        });

        // Upload to backend
        final (success, errorMessage) = await ref
            .read(authNotifierProvider.notifier)
            .uploadProfileImage(imageFile: imageFile);

        if (!mounted) return;

        setState(() => _isUploadingImage = false);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Profile photo updated'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              showCloseIcon: true,
              closeIconColor: Theme.of(context).colorScheme.onPrimaryContainer,
              duration: const Duration(seconds: 2),
            ),
          );
          // Clear local preview since server image is now active
          setState(() => _selectedImage = null);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage ?? 'Failed to upload photo'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
              showCloseIcon: true,
              closeIconColor: Theme.of(context).colorScheme.onErrorContainer,
              duration: const Duration(seconds: 3),
            ),
          );
          // Keep local preview so user can retry or see what they picked
        }
      }
    } on Exception {
      if (mounted) {
        setState(() => _isUploadingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not access camera/gallery'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _removeImage() async {
    // If only local preview, just clear it
    if (_selectedImage != null && ref.read(authNotifierProvider).user?.avatarUrl == null) {
      setState(() => _selectedImage = null);
      return;
    }

    // Delete from server
    setState(() => _isUploadingImage = true);

    final (success, errorMessage) = await ref
        .read(authNotifierProvider.notifier)
        .deleteProfileImage();

    if (!mounted) return;

    setState(() {
      _isUploadingImage = false;
      if (success) _selectedImage = null;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile photo removed'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          showCloseIcon: true,
          closeIconColor: Theme.of(context).colorScheme.onPrimaryContainer,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage ?? 'Failed to remove photo'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
          showCloseIcon: true,
          closeIconColor: Theme.of(context).colorScheme.onErrorContainer,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: colorScheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Form content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Avatar Section with Edit Button
                      Center(
                        child: Column(
                          children: [
                            // Avatar with edit overlay
                            Semantics(
                              button: true,
                              label: 'Profile photo. Tap to change',
                              child: GestureDetector(
                                onTap: _showImagePickerSheet,
                                child: Stack(
                                  children: [
                                    // Avatar
                                    Container(
                                      width: 120,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        color: colorScheme.primaryContainer,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: colorScheme.primary.withOpacity(0.2),
                                          width: 3,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: colorScheme.shadow.withOpacity(0.1),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: ClipOval(
                                        child: _buildAvatarContent(theme, colorScheme),
                                      ),
                                    ),

                                    // Camera edit button (decorative, parent handles semantics)
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: ExcludeSemantics(
                                        child: Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: colorScheme.primary,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: colorScheme.surface,
                                              width: 3,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: colorScheme.shadow.withOpacity(0.15),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Icon(
                                            Icons.camera_alt_rounded,
                                            size: 20,
                                            color: colorScheme.onPrimary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            AppSpacing.gapVerticalMd,
                            Text(
                              'Tap to change photo',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppSpacing.gapVerticalXxl,

                      // Form Section Header
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline_rounded,
                            size: 20,
                            color: colorScheme.primary,
                          ),
                          AppSpacing.gapHorizontalSm,
                          Text(
                            'Personal Information',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.gapVerticalMd,

                      // Full Name Field
                      const _FormFieldLabel(label: 'Full Name'),
                      AppSpacing.gapVerticalSm,
                      TextFormField(
                        controller: _fullNameController,
                        decoration: _buildInputDecoration(
                          context,
                          hintText: 'Enter your full name',
                          prefixIcon: Icons.badge_outlined,
                        ),
                        textInputAction: TextInputAction.done,
                        textCapitalization: TextCapitalization.words,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your name';
                          }
                          if (value.trim().length < 2) {
                            return 'Name must be at least 2 characters';
                          }
                          return null;
                        },
                        onChanged: (_) => setState(() {}),
                      ),
                      AppSpacing.gapVerticalLg,

                      // Email Field (Read-only)
                      _FormFieldLabel(
                        label: 'Email Address',
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Read Only',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                      AppSpacing.gapVerticalSm,
                      TextFormField(
                        controller: _emailController,
                        enabled: false,
                        decoration: _buildInputDecoration(
                          context,
                          hintText: 'Your email address',
                          prefixIcon: Icons.email_outlined,
                          isDisabled: true,
                          suffixIcon: Icons.lock_outline_rounded,
                        ),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      AppSpacing.gapVerticalSm,
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 14,
                            color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                          ),
                          AppSpacing.gapHorizontalXs,
                          Text(
                            'Email address cannot be changed for security reasons',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),

                      AppSpacing.gapVerticalXxl,
                    ],
                  ),
                ),
              ),
            ),

            // Save Button at bottom
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isSaving ? null : _handleSave,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _isSaving
                          ? SizedBox(
                              key: const ValueKey('loading'),
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: colorScheme.onPrimary,
                              ),
                            )
                          : const Text(
                              key: ValueKey('text'),
                              'Save Changes',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarContent(ThemeData theme, ColorScheme colorScheme) {
    final user = ref.watch(authNotifierProvider).user;
    final avatarUrl = user?.avatarAbsoluteUrl; // Use absolute URL for Image.network

    // Priority: local preview > server avatar > initials
    Widget imageWidget;

    if (_selectedImage != null) {
      // Local preview (during upload or failed upload)
      // ExcludeSemantics: parent Semantics widget handles accessibility
      imageWidget = ExcludeSemantics(
        child: Image.file(
          _selectedImage!,
          fit: BoxFit.cover,
          width: 120,
          height: 120,
        ),
      );
    } else if (avatarUrl != null && avatarUrl.isNotEmpty) {
      // Server avatar with caching
      // ExcludeSemantics: parent Semantics widget handles accessibility
      imageWidget = ExcludeSemantics(
        child: CachedNetworkImage(
          imageUrl: avatarUrl,
          httpHeaders: {
            if (StorageService.authToken != null)
              'Authorization': 'Bearer ${StorageService.authToken}',
          },
          fit: BoxFit.cover,
          width: 120,
          height: 120,
          memCacheWidth: 240, // 2x for high DPI
          memCacheHeight: 240,
          placeholder: (context, url) => Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colorScheme.primary,
            ),
          ),
          errorWidget: (context, url, error) => Center(
            child: Text(
              _getInitials(_fullNameController.text),
              style: theme.textTheme.displaySmall?.copyWith(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    } else {
      // Initials fallback
      imageWidget = Center(
        child: Text(
          _getInitials(_fullNameController.text),
          style: theme.textTheme.displaySmall?.copyWith(
            color: colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    // Overlay loading indicator while uploading
    if (_isUploadingImage) {
      return Stack(
        alignment: Alignment.center,
        children: [
          imageWidget,
          Container(
            width: 120,
            height: 120,
            color: colorScheme.surface.withOpacity(0.6),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      );
    }

    return imageWidget;
  }

  InputDecoration _buildInputDecoration(
    BuildContext context, {
    required String hintText,
    required IconData prefixIcon,
    IconData? suffixIcon,
    bool isDisabled = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final opacity = isDisabled ? 0.5 : 1.0;

    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: isDisabled
          ? colorScheme.surfaceContainerHigh.withOpacity(0.5)
          : colorScheme.surfaceContainerHighest,
      border: const OutlineInputBorder(
        borderRadius: AppSpacing.borderRadiusMd,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppSpacing.borderRadiusMd,
        borderSide: BorderSide(
          color: colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppSpacing.borderRadiusMd,
        borderSide: BorderSide(
          color: colorScheme.primary,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppSpacing.borderRadiusMd,
        borderSide: BorderSide(
          color: colorScheme.error,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppSpacing.borderRadiusMd,
        borderSide: BorderSide(
          color: colorScheme.error,
          width: 2,
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: AppSpacing.borderRadiusMd,
        borderSide: BorderSide(
          color: colorScheme.outlineVariant.withOpacity(0.3),
        ),
      ),
      prefixIcon: Icon(
        prefixIcon,
        color: colorScheme.onSurfaceVariant.withOpacity(opacity),
      ),
      suffixIcon: suffixIcon != null
          ? Tooltip(
              message: 'This field cannot be changed',
              child: Icon(
                suffixIcon,
                size: 18,
                color: colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
            )
          : null,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
    );
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }
}

/// Form field label widget
class _FormFieldLabel extends StatelessWidget {
  const _FormFieldLabel({
    required this.label,
    this.trailing,
  });

  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        if (trailing != null) ...[
          const Spacer(),
          trailing!,
        ],
      ],
    );
  }
}

/// Image picker option tile
class _ImagePickerOption extends StatelessWidget {
  const _ImagePickerOption({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      button: true,
      label: label,
      child: ListTile(
        leading: ExcludeSemantics(
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
        ),
        title: ExcludeSemantics(
          child: Text(
            label,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        trailing: ExcludeSemantics(
          child: Icon(
            Icons.chevron_right_rounded,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xs,
        ),
      ),
    );
  }
}
