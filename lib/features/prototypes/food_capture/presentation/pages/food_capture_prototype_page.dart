import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/food_capture_channel.dart';

class FoodCapturePrototypePage extends StatefulWidget {
  const FoodCapturePrototypePage({super.key});

  @override
  State<FoodCapturePrototypePage> createState() =>
      _FoodCapturePrototypePageState();
}

class _FoodCapturePrototypePageState extends State<FoodCapturePrototypePage> {
  Map<String, dynamic>? _availability;
  Map<String, dynamic>? _captureResult;
  String? _error;
  bool _loadingAvailability = true;
  bool _startingCapture = false;

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    setState(() {
      _loadingAvailability = true;
      _error = null;
    });

    try {
      final availability = await FoodCaptureChannel.getAvailability();
      if (!mounted) return;
      setState(() {
        _availability = availability;
      });
    } on PlatformException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message ?? error.code;
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingAvailability = false;
        });
      }
    }
  }

  Future<void> _startCapture() async {
    setState(() {
      _startingCapture = true;
      _error = null;
    });

    try {
      final result = await FoodCaptureChannel.startCapture();
      if (!mounted) return;
      setState(() {
        _captureResult = result;
      });
    } on PlatformException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message ?? error.code;
      });
    } finally {
      if (mounted) {
        setState(() {
          _startingCapture = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sessionSupported = _availability?['sessionSupported'] == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Capture Prototype'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadAvailability,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _InfoCard(
              title: 'What This Prototype Does',
              child: Text(
                'This screen launches Apple\'s native iPhone Object Capture session, saves the captured image dataset, and reports the shot count back to Flutter. It does not promise a perfect final food model on-device.',
                style: theme.textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 16),
            _StatusCard(
              loading: _loadingAvailability,
              availability: _availability,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed:
                  !_loadingAvailability && !_startingCapture && sessionSupported
                      ? _startCapture
                      : null,
              icon: _startingCapture
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.camera_alt_outlined),
              label: Text(
                _startingCapture
                    ? 'Opening Native Capture'
                    : 'Start Native Capture',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Best results: matte plate, soft light, no steam, and one hero dish at a time.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              _InfoCard(
                title: 'Error',
                color: theme.colorScheme.errorContainer,
                child: Text(
                  _error!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],
            if (_captureResult != null) ...[
              const SizedBox(height: 16),
              _CaptureResultCard(result: _captureResult!),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.loading,
    required this.availability,
  });

  final bool loading;
  final Map<String, dynamic>? availability;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (loading) {
      return const _InfoCard(
        title: 'Native Availability',
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    final sessionSupported = availability?['sessionSupported'] == true;
    final iosVersion = availability?['iosVersion']?.toString() ?? 'Unknown';
    final message = availability?['message']?.toString() ??
        'No availability data returned.';

    return _InfoCard(
      title: 'Native Availability',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                sessionSupported
                    ? Icons.verified_outlined
                    : Icons.warning_amber_rounded,
                color: sessionSupported
                    ? theme.colorScheme.primary
                    : theme.colorScheme.error,
              ),
              const SizedBox(width: 8),
              Text(
                sessionSupported
                    ? 'Supported on this device'
                    : 'Not supported on this device',
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('iOS version: $iosVersion', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text(message, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _CaptureResultCard extends StatelessWidget {
  const _CaptureResultCard({required this.result});

  final Map<String, dynamic> result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cancelled = result['cancelled'] == true;

    return _InfoCard(
      title: 'Last Capture Result',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            cancelled ? 'Capture cancelled' : 'Capture finished',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Text('State: ${result['state'] ?? 'Unknown'}'),
          Text('Shots taken: ${result['shotsTaken'] ?? 0}'),
          const SizedBox(height: 12),
          Text(
            result['note']?.toString() ??
                'Dataset captured. Final reconstruction still requires a later step.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          SelectableText(
            'Dataset folder: ${result['sessionDirectory'] ?? 'Unavailable'}',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.child,
    this.color,
  });

  final String title;
  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
