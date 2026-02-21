import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A lightweight survey duration timer that tracks time-on-site.
///
/// Persists start timestamp and accumulated seconds to SharedPreferences
/// so the timer survives app restarts. Auto-starts on first mount.
class SurveyDurationTimer extends StatefulWidget {
  const SurveyDurationTimer({
    required this.surveyId,
    super.key,
  });

  final String surveyId;

  /// SharedPreferences key for accumulated timer seconds.
  ///
  /// Shared between this widget and [ExportService] to read duration
  /// at export time.  Always use this helper to avoid key drift.
  static String accumulatedSecondsKey(String surveyId) =>
      'survey_timer_acc_$surveyId';

  @override
  State<SurveyDurationTimer> createState() => _SurveyDurationTimerState();
}

class _SurveyDurationTimerState extends State<SurveyDurationTimer>
    with WidgetsBindingObserver {
  Timer? _ticker;
  Duration _elapsed = Duration.zero;
  DateTime? _sessionStart;
  bool _loaded = false;

  String get _accKey => SurveyDurationTimer.accumulatedSecondsKey(widget.surveyId);
  String get _startKey => 'survey_timer_start_${widget.surveyId}';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final accSeconds = prefs.getInt(_accKey) ?? 0;
    final startMs = prefs.getInt(_startKey);

    // Calculate any un-persisted time from a previous session that wasn't
    // properly paused (e.g., app killed).
    int extra = 0;
    if (startMs != null) {
      extra = DateTime.now()
          .difference(DateTime.fromMillisecondsSinceEpoch(startMs))
          .inSeconds;
      if (extra < 0) extra = 0;
    }

    _elapsed = Duration(seconds: accSeconds + extra);
    _startSession(prefs);

    if (mounted) setState(() => _loaded = true);
  }

  void _startSession(SharedPreferences prefs) {
    _sessionStart = DateTime.now();
    prefs.setInt(_startKey, _sessionStart!.millisecondsSinceEpoch);
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _elapsed += const Duration(seconds: 1);
      });
    });
  }

  Future<void> _persistAccumulated() async {
    _ticker?.cancel();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_accKey, _elapsed.inSeconds);
    await prefs.remove(_startKey);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _persistAccumulated();
    } else if (state == AppLifecycleState.resumed) {
      SharedPreferences.getInstance().then(_startSession);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _persistAccumulated();
    super.dispose();
  }

  String _format(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            size: 14,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Text(
            _format(_elapsed),
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
              fontFeatures: [const FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
