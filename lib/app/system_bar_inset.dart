import 'package:flutter/material.dart';

/// Keeps every screen above the phone's own navigation bar.
///
/// On Android 15 the app is drawn edge to edge, so a button at the bottom of a
/// page sat under the bar (client file 4, 10 Nov 2026: Create Booking). Doing it
/// once here covers every page. The strip under the app is painted in the page
/// colour so it does not read as a footer. SafeArea hands its children a
/// MediaQuery with the bottom padding already removed, so pages that handle the
/// bar themselves are not padded twice.
Widget keepAboveNavigationBar(BuildContext context, Widget? child) => ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        top: false,
        left: false,
        right: false,
        child: child ?? const SizedBox.shrink(),
      ),
    );
