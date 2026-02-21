import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:go_router/go_router.dart';

class InspectionCompassPage extends StatelessWidget {
  const InspectionCompassPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        title: const Text('Compass'),
      ),
      body: SafeArea(
        child: StreamBuilder<CompassEvent>(
          stream: FlutterCompass.events,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.explore_off_outlined,
                          size: 36,
                          color: colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Compass Unavailable',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This device does not support compass functionality.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            final heading = snapshot.data?.heading;
            if (heading == null) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        strokeCap: StrokeCap.round,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Calibrating compass...',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            }

            final normalized = heading < 0 ? heading + 360 : heading;

            return LayoutBuilder(
              builder: (context, constraints) {
                final shortSide = math.min(
                  constraints.maxWidth,
                  constraints.maxHeight,
                );
                final compassSize = (shortSide * 0.72).clamp(200.0, 360.0);

                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Cardinal direction label
                      Text(
                        _cardinalLabel(normalized),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.primary,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Degree readout
                      Text(
                        '${normalized.toStringAsFixed(0)}°',
                        style: theme.textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.w300,
                          letterSpacing: -1,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Compass dial
                      SizedBox(
                        width: compassSize,
                        height: compassSize,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // The dial with tick marks and labels
                            CustomPaint(
                              size: Size(compassSize, compassSize),
                              painter: _CompassDialPainter(
                                heading: normalized,
                                primaryColor: colorScheme.primary,
                                onSurfaceColor: colorScheme.onSurface,
                                onSurfaceVariantColor:
                                    colorScheme.onSurfaceVariant,
                                outlineColor: colorScheme.outlineVariant,
                              ),
                            ),
                            // Fixed pointer at 12 o'clock
                            Positioned(
                              top: 0,
                              child: CustomPaint(
                                size: const Size(18, 12),
                                painter: _PointerPainter(
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      // Instruction
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          'Point the device toward the property frontage.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  static String _cardinalLabel(double heading) {
    if (heading >= 337.5 || heading < 22.5) return 'N';
    if (heading < 67.5) return 'NE';
    if (heading < 112.5) return 'E';
    if (heading < 157.5) return 'SE';
    if (heading < 202.5) return 'S';
    if (heading < 247.5) return 'SW';
    if (heading < 292.5) return 'W';
    return 'NW';
  }
}

/// Downward-pointing triangle used as the fixed heading indicator at 12 o'clock.
class _PointerPainter extends CustomPainter {
  _PointerPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, size.height) // point (bottom-center)
      ..lineTo(0, 0) // top-left
      ..lineTo(size.width, 0) // top-right
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _PointerPainter old) => color != old.color;
}

/// Draws the full compass dial: outer ring, tick marks at 5° intervals,
/// degree numbers at 30° intervals, and cardinal direction letters (N E S W).
///
/// The [heading] (0–360°) controls which compass degree is shown at 12 o'clock.
/// All text stays upright regardless of heading position.
class _CompassDialPainter extends CustomPainter {
  _CompassDialPainter({
    required this.heading,
    required this.primaryColor,
    required this.onSurfaceColor,
    required this.onSurfaceVariantColor,
    required this.outlineColor,
  });

  final double heading;
  final Color primaryColor;
  final Color onSurfaceColor;
  final Color onSurfaceVariantColor;
  final Color outlineColor;

  static const _northColor = Color(0xFFD32F2F);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // ── outer ring ──
    canvas.drawCircle(
      center,
      radius - 2,
      Paint()
        ..color = outlineColor.withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // ── inner decorative ring ──
    canvas.drawCircle(
      center,
      radius * 0.75,
      Paint()
        ..color = outlineColor.withOpacity(0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // ── tick marks every 5° ──
    for (int deg = 0; deg < 360; deg += 5) {
      final angle = _toScreenAngle(deg.toDouble());
      final isCardinal = deg % 90 == 0;
      final isMajor = deg % 30 == 0;
      final isMinor = deg % 10 == 0;

      final double outerR = radius - 5;
      double innerR;
      double strokeW;
      Color color;

      if (isCardinal) {
        innerR = radius * 0.80;
        strokeW = 2.5;
        color = deg == 0 ? _northColor : onSurfaceColor;
      } else if (isMajor) {
        innerR = radius * 0.84;
        strokeW = 1.5;
        color = onSurfaceVariantColor;
      } else if (isMinor) {
        innerR = radius * 0.87;
        strokeW = 1;
        color = outlineColor;
      } else {
        innerR = radius * 0.90;
        strokeW = 0.5;
        color = outlineColor.withOpacity(0.4);
      }

      canvas.drawLine(
        _pointAt(center, innerR, angle),
        _pointAt(center, outerR, angle),
        Paint()
          ..color = color
          ..strokeWidth = strokeW
          ..strokeCap = StrokeCap.round,
      );
    }

    // ── degree numbers at 30° intervals (skip cardinals) ──
    for (int deg = 30; deg < 360; deg += 30) {
      if (deg % 90 == 0) continue;
      final angle = _toScreenAngle(deg.toDouble());
      final pos = _pointAt(center, radius * 0.70, angle);

      final tp = TextPainter(
        text: TextSpan(
          text: '$deg',
          style: TextStyle(
            color: onSurfaceVariantColor.withOpacity(0.8),
            fontSize: radius * 0.08,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(
        canvas,
        Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2),
      );
    }

    // ── cardinal labels (N E S W) ──
    const cardinals = {'N': 0.0, 'E': 90.0, 'S': 180.0, 'W': 270.0};
    for (final entry in cardinals.entries) {
      final angle = _toScreenAngle(entry.value);
      final pos = _pointAt(center, radius * 0.63, angle);

      final isNorth = entry.key == 'N';
      final tp = TextPainter(
        text: TextSpan(
          text: entry.key,
          style: TextStyle(
            color: isNorth ? _northColor : onSurfaceColor,
            fontSize: radius * 0.14,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(
        canvas,
        Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2),
      );
    }

    // ── center dot ──
    canvas.drawCircle(center, 4, Paint()..color = primaryColor);
  }

  /// Maps a compass bearing (0 = N, 90 = E) to screen radians
  /// with [heading] placed at 12 o'clock.
  double _toScreenAngle(double compassDeg) =>
      (compassDeg - heading) * (math.pi / 180) - math.pi / 2;

  Offset _pointAt(Offset center, double r, double angle) =>
      Offset(center.dx + r * math.cos(angle), center.dy + r * math.sin(angle));

  @override
  bool shouldRepaint(covariant _CompassDialPainter old) =>
      heading != old.heading ||
      primaryColor != old.primaryColor ||
      onSurfaceColor != old.onSurfaceColor;
}
