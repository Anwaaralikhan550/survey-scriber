import 'package:flutter/widgets.dart';

/// Padding for a page's scrolling body that also clears the phone's own
/// navigation bar at the bottom. A scroll view given a fixed padding does not
/// add that bar's height, so on Android 15 (drawn edge to edge) the last
/// buttons sat under the bar (client file 3, 10 Nov 2026: Booking Details
/// Cancel/Confirm).
EdgeInsets safePagePadding(BuildContext context, [double all = 16]) =>
    EdgeInsets.fromLTRB(
      all,
      all,
      all,
      all + MediaQuery.paddingOf(context).bottom,
    );
