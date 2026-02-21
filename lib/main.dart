import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/constants/app_constants.dart';
import 'core/storage/storage_service.dart';
import 'core/utils/logger.dart';
import 'features/media/data/services/media_storage_service.dart';
import 'features/settings/presentation/providers/preferences_provider.dart';
import 'features/signature/presentation/providers/signature_provider.dart';

void main() {
  runZonedGuarded(
    () async {
      // Binding MUST be initialized inside the same zone as runApp()
      // to avoid a "Zone mismatch" FlutterError.
      WidgetsFlutterBinding.ensureInitialized();

      // Set preferred orientations (not supported on web)
      if (!kIsWeb) {
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);

        SystemChrome.setSystemUIOverlayStyle(
          const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            systemNavigationBarColor: Colors.white,
            systemNavigationBarIconBrightness: Brightness.dark,
          ),
        );
      }

      // Global error handlers for uncaught errors
      FlutterError.onError = (details) {
        AppLogger.e('FlutterError: ${details.exceptionAsString()}',
            details.exception, details.stack);
        if (kDebugMode) {
          FlutterError.dumpErrorToConsole(details);
        }
      };

      PlatformDispatcher.instance.onError = (error, stack) {
        AppLogger.e('PlatformError: $error', error, stack);
        return true; // Prevent app crash
      };

      try {
        await _initializeApp();
      } catch (error, stackTrace) {
        AppLogger.e('App initialization failed: $error', error, stackTrace);
        // Show error UI instead of crashing
        runApp(const _InitializationErrorApp());
      }
    },
    (error, stackTrace) {
      // Catches any uncaught async errors that escape the zone
      AppLogger.e('Uncaught async error: $error', error, stackTrace);
    },
  );
}

/// Initializes all app dependencies.
/// Throws on failure - caller handles error UI.
Future<void> _initializeApp() async {
  // Log API configuration in debug mode for easier troubleshooting
  if (kDebugMode) {
    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('API Base URL: ${AppConstants.baseUrl}');
    debugPrint('═══════════════════════════════════════════════════════════');
  }

  // Initialize independent services in parallel for faster startup.
  // Hive must init before StorageService (depends on Hive boxes),
  // but MediaStorageService and SharedPreferences are independent.
  await Hive.initFlutter();

  // Now StorageService (needs Hive), MediaStorageService, and
  // SharedPreferences can all run in parallel.
  // Use individual catchError so one failure doesn't prevent the others.
  late final SharedPreferences sharedPreferences;
  final results = await Future.wait<Object?>([
    if (!kIsWeb) StorageService.init().catchError((Object e, StackTrace st) {
      AppLogger.e('StorageService init failed: $e', e, st);
      return null;
    }),
    if (!kIsWeb) MediaStorageService.instance.init().catchError((Object e, StackTrace st) {
      AppLogger.e('MediaStorageService init failed: $e', e, st);
      return null;
    }),
    if (!kIsWeb) SignaturePreviewService.instance.init().catchError((Object e, StackTrace st) {
      AppLogger.e('SignaturePreviewService init failed: $e', e, st);
      return null;
    }),
    SharedPreferences.getInstance().then((sp) {
      sharedPreferences = sp;
      return sp;
    }),
  ]);

  // SharedPreferences is mandatory - fail fast if missing
  if (!results.any((r) => r is SharedPreferences)) {
    throw StateError('SharedPreferences failed to initialize');
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const SurveyScriber(),
    ),
  );
}

/// Fallback UI shown when app initialization fails.
class _InitializationErrorApp extends StatelessWidget {
  const _InitializationErrorApp();

  @override
  Widget build(BuildContext context) => const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                SizedBox(height: 24),
                Text(
                  'Unable to Start App',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12),
                Text(
                  'Something went wrong during startup. Please try restarting the app or clearing app data.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32),
                ElevatedButton(
                  onPressed: main,
                  child: Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
}
