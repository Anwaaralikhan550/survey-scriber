import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/sync/sync_manager.dart';
import '../core/utils/logger.dart';
import '../features/config/presentation/providers/config_providers.dart';
import '../features/settings/domain/entities/app_preferences.dart';
import '../features/settings/presentation/providers/preferences_provider.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class SurveyScriber extends ConsumerStatefulWidget {
  const SurveyScriber({super.key});

  @override
  ConsumerState<SurveyScriber> createState() => _SurveyScriberState();
}

class _SurveyScriberState extends ConsumerState<SurveyScriber>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Load config on app startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(configProvider.notifier).loadConfig();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      AppLogger.d('App', 'Resumed from background, checking config version');
      ref.read(syncStateProvider.notifier).checkConfigVersion();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final prefs = ref.watch(preferencesProvider);

    return MaterialApp.router(
      title: 'SurveyScriber',
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: _resolveThemeMode(prefs.themeMode),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }

  static ThemeMode _resolveThemeMode(ThemePreference pref) {
    switch (pref) {
      case ThemePreference.system:
        return ThemeMode.system;
      case ThemePreference.light:
        return ThemeMode.light;
      case ThemePreference.dark:
        return ThemeMode.dark;
    }
  }
}
