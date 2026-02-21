import 'package:flutter/material.dart';

/// Responsive breakpoints for the app
class Breakpoints {
  Breakpoints._();

  /// Mobile: < 600dp
  static const double mobile = 600;

  /// Tablet: 600dp - 900dp
  static const double tablet = 900;

  /// Desktop: > 900dp
  static const double desktop = 1200;
}

/// Device type enum
enum DeviceType { mobile, tablet, desktop }

/// Responsive utility class
class Responsive {
  Responsive._();

  /// Get device type based on screen width
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < Breakpoints.mobile) {
      return DeviceType.mobile;
    } else if (width < Breakpoints.tablet) {
      return DeviceType.tablet;
    } else {
      return DeviceType.desktop;
    }
  }

  /// Check if device is mobile
  static bool isMobile(BuildContext context) =>
      getDeviceType(context) == DeviceType.mobile;

  /// Check if device is tablet
  static bool isTablet(BuildContext context) =>
      getDeviceType(context) == DeviceType.tablet;

  /// Check if device is desktop
  static bool isDesktop(BuildContext context) =>
      getDeviceType(context) == DeviceType.desktop;

  /// Check if device is tablet or larger
  static bool isTabletOrLarger(BuildContext context) =>
      !isMobile(context);

  /// Check if orientation is landscape
  static bool isLandscape(BuildContext context) =>
      MediaQuery.orientationOf(context) == Orientation.landscape;

  /// Check if orientation is portrait
  static bool isPortrait(BuildContext context) =>
      MediaQuery.orientationOf(context) == Orientation.portrait;

  /// Get responsive value based on device type
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
    }
  }

  /// Get screen width
  static double screenWidth(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  /// Get screen height
  static double screenHeight(BuildContext context) =>
      MediaQuery.sizeOf(context).height;

  /// Get horizontal padding based on screen size
  static double horizontalPadding(BuildContext context) => value(
      context,
      mobile: 16,
      tablet: 32,
      desktop: 48,
    );

  /// Get content max width based on screen size
  static double contentMaxWidth(BuildContext context) => value(
      context,
      mobile: double.infinity,
      tablet: 600,
      desktop: 800,
    );
}

/// Responsive builder widget
class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({
    required this.mobile,
    this.tablet,
    this.desktop,
    super.key,
  });

  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  @override
  Widget build(BuildContext context) => Responsive.value(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
}

/// Responsive layout widget that adapts to screen size
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    required this.child,
    this.maxWidth,
    this.padding,
    this.alignment = Alignment.topCenter,
    super.key,
  });

  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final effectiveMaxWidth = maxWidth ?? Responsive.contentMaxWidth(context);
    final effectivePadding = padding ??
        EdgeInsets.symmetric(
          horizontal: Responsive.horizontalPadding(context),
        );

    return Align(
      alignment: alignment,
      child: Padding(
        padding: effectivePadding,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
          child: child,
        ),
      ),
    );
  }
}

/// Extension for easy responsive values
extension ResponsiveExtension on BuildContext {
  /// Get device type
  DeviceType get deviceType => Responsive.getDeviceType(this);

  /// Check if mobile
  bool get isMobile => Responsive.isMobile(this);

  /// Check if tablet
  bool get isTablet => Responsive.isTablet(this);

  /// Check if desktop
  bool get isDesktop => Responsive.isDesktop(this);

  /// Check if tablet or larger
  bool get isTabletOrLarger => Responsive.isTabletOrLarger(this);

  /// Check if landscape
  bool get isLandscape => Responsive.isLandscape(this);

  /// Check if portrait
  bool get isPortrait => Responsive.isPortrait(this);

  /// Screen width
  double get screenWidth => Responsive.screenWidth(this);

  /// Screen height
  double get screenHeight => Responsive.screenHeight(this);

  /// Responsive value helper
  T responsive<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) =>
      Responsive.value(
        this,
        mobile: mobile,
        tablet: tablet,
        desktop: desktop,
      );
}
