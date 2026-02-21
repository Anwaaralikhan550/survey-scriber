import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../notifications/presentation/providers/notifications_provider.dart';
import '../providers/dashboard_provider.dart';

class GreetingHeader extends ConsumerWidget {
  const GreetingHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final greeting = ref.watch(greetingProvider);
    final userName = ref.watch(userNameProvider);
    final userInitials = ref.watch(userInitialsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting,',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 0.1,
                    height: 1.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  userName,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: -0.3,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _buildNotificationButton(context, theme, ref),
          const SizedBox(width: 8),
          _buildProfileAvatar(context, theme, userInitials),
        ],
      ),
    );
  }

  Widget _buildNotificationButton(
    BuildContext context,
    ThemeData theme,
    WidgetRef ref,
  ) {
    final unreadCountAsync = ref.watch(unreadCountProvider);

    return IconButton(
      onPressed: () => context.push(Routes.notifications),
      style: IconButton.styleFrom(
        backgroundColor: AppColors.surfaceVariant.withOpacity(0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        minimumSize: const Size(44, 44),
      ),
      icon: unreadCountAsync.when(
        data: (count) => Badge(
          isLabelVisible: count > 0,
          label: Text(
            count > 99 ? '99+' : count.toString(),
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
          backgroundColor: theme.colorScheme.error,
          child: Icon(
            Icons.notifications_outlined,
            color: theme.colorScheme.onSurfaceVariant,
            size: 22,
          ),
        ),
        loading: () => Icon(
          Icons.notifications_outlined,
          color: theme.colorScheme.onSurfaceVariant,
          size: 22,
        ),
        error: (_, __) => Icon(
          Icons.notifications_outlined,
          color: theme.colorScheme.onSurfaceVariant,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(
    BuildContext context,
    ThemeData theme,
    String initials,
  ) =>
      GestureDetector(
        onTap: () => context.push(Routes.settings),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                AppColors.primary.withOpacity(0.85),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              initials,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      );
}
