import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/storage/storage_service.dart';

/// A cached network avatar with loading, error, and initials fallback states.
///
/// Uses CachedNetworkImage for efficient memory and disk caching.
class CachedAvatar extends StatelessWidget {
  const CachedAvatar({
    super.key,
    this.imageUrl,
    required this.size,
    this.initials,
    this.semanticLabel,
  });

  /// The URL of the avatar image (null or empty shows initials).
  final String? imageUrl;

  /// Size of the avatar (both width and height).
  final double size;

  /// Initials to show when image is unavailable.
  final String? initials;

  /// Accessibility label for the avatar.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildInitialsAvatar(theme, colorScheme);
    }

    return Semantics(
      label: semanticLabel ?? 'Avatar',
      image: true,
      child: CachedNetworkImage(
        imageUrl: imageUrl!,
        httpHeaders: {
          if (StorageService.authToken != null)
            'Authorization': 'Bearer ${StorageService.authToken}',
        },
        width: size,
        height: size,
        fit: BoxFit.cover,
        memCacheWidth: (size * 2).toInt(), // 2x for high DPI
        memCacheHeight: (size * 2).toInt(),
        placeholder: (context, url) => _buildLoadingState(colorScheme),
        errorWidget: (context, url, error) =>
            _buildInitialsAvatar(theme, colorScheme),
      ),
    );
  }

  Widget _buildLoadingState(ColorScheme colorScheme) => Container(
      width: size,
      height: size,
      color: colorScheme.primaryContainer,
      child: Center(
        child: SizedBox(
          width: size * 0.3,
          height: size * 0.3,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );

  Widget _buildInitialsAvatar(ThemeData theme, ColorScheme colorScheme) {
    final displayInitials = initials ?? 'U';
    final fontSize = size * 0.35;

    return Container(
      width: size,
      height: size,
      color: colorScheme.primaryContainer,
      child: Center(
        child: Text(
          displayInitials,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w600,
            fontSize: fontSize,
          ),
        ),
      ),
    );
  }
}
