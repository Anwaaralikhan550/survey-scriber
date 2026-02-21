import 'package:flutter/material.dart';

import '../../shared/utils/responsive.dart';
import 'app_logo.dart';

/// SurveyScriber Splash Screen
///
/// Displays the professional app logo centered on a clean white background.
/// Matches the launcher icon design for visual consistency during app launch.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final logoSize = context.responsive<double>(
      mobile: 160,
      tablet: 200,
      desktop: 240,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AppLogo(size: logoSize),
      ),
    );
  }
}

/// Minimal splash screen with simplified logo (no pen)
class SplashScreenMinimal extends StatelessWidget {
  const SplashScreenMinimal({super.key});

  @override
  Widget build(BuildContext context) {
    final logoSize = context.responsive<double>(
      mobile: 120,
      tablet: 160,
      desktop: 200,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AppLogoIcon(size: logoSize),
      ),
    );
  }
}
