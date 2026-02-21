import 'dart:math' as math;
import 'package:flutter/material.dart';

/// SurveyScriber Logo Colors
class LogoColors {
  LogoColors._();

  /// Primary blue gradient start
  static const Color primaryLight = Color(0xFF1E88E5);

  /// Primary blue gradient end
  static const Color primaryDark = Color(0xFF1565C0);

  /// Deep blue for accents
  static const Color deepBlue = Color(0xFF0D47A1);

  /// Light blue for form lines
  static const Color lightBlue = Color(0xFFBBDEFB);

  /// Green for checkmark
  static const Color success = Color(0xFF4CAF50);

  /// Accent gradient start
  static const Color accentLight = Color(0xFF42A5F5);

  /// Accent gradient end
  static const Color accentDark = Color(0xFF1E88E5);
}

/// SurveyScriber App Logo Widget
///
/// A professional, modern logo representing:
/// - Clipboard (Survey/Forms)
/// - Pen/Stylus (Scriber/Writing)
/// - Checkmark (Completion/Verification)
///
/// Follows Material 3 design principles with clean geometric shapes.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 120,
    this.showPen = true,
    this.showCheckmark = true,
  });

  /// Size of the logo (width and height)
  final double size;

  /// Whether to show the pen element
  final bool showPen;

  /// Whether to show the checkmark
  final bool showCheckmark;

  @override
  Widget build(BuildContext context) => SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _LogoPainter(
          showPen: showPen,
          showCheckmark: showCheckmark,
        ),
      ),
    );
}

/// Custom painter for the SurveyScriber logo
class _LogoPainter extends CustomPainter {
  _LogoPainter({
    this.showPen = true,
    this.showCheckmark = true,
  });

  final bool showPen;
  final bool showCheckmark;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 512;

    // Clipboard body gradient paint
    const clipboardGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [LogoColors.primaryLight, LogoColors.primaryDark],
    );

    // Shadow paint
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity( 0.15)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 * scale);

    // Draw clipboard shadow
    final clipboardShadowRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(96 * scale, 84 * scale, 280 * scale, 352 * scale),
      Radius.circular(24 * scale),
    );
    canvas.drawRRect(clipboardShadowRect, shadowPaint);

    // Draw clipboard body
    final clipboardRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(96 * scale, 80 * scale, 280 * scale, 352 * scale),
      Radius.circular(24 * scale),
    );
    final clipboardPaint = Paint()
      ..shader = clipboardGradient.createShader(
        Rect.fromLTWH(96 * scale, 80 * scale, 280 * scale, 352 * scale),
      );
    canvas.drawRRect(clipboardRect, clipboardPaint);

    // Draw clipboard clip (top holder)
    final clipHolderPaint = Paint()..color = LogoColors.deepBlue;
    final clipHolderRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(176 * scale, 56 * scale, 120 * scale, 48 * scale),
      Radius.circular(8 * scale),
    );
    canvas.drawRRect(clipHolderRect, clipHolderPaint);

    // Draw clipboard clip inner
    final clipInnerPaint = Paint()..color = LogoColors.lightBlue;
    final clipInnerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(192 * scale, 72 * scale, 88 * scale, 24 * scale),
      Radius.circular(6 * scale),
    );
    canvas.drawRRect(clipInnerRect, clipInnerPaint);

    // Draw survey lines (form fields)
    _drawSurveyLine(canvas, scale, 136, 160, 200, 0.9);
    _drawSurveyLine(canvas, scale, 136, 200, 160, 0.7);
    _drawSurveyLine(canvas, scale, 136, 240, 180, 0.5);

    // Draw checkmark circle
    if (showCheckmark) {
      final checkCirclePaint = Paint()..color = LogoColors.success;
      canvas.drawCircle(
        Offset(200 * scale, 340 * scale),
        48 * scale,
        checkCirclePaint,
      );

      // Draw checkmark
      final checkPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 12 * scale
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final checkPath = Path()
        ..moveTo(176 * scale, 340 * scale)
        ..lineTo(192 * scale, 356 * scale)
        ..lineTo(224 * scale, 324 * scale);
      canvas.drawPath(checkPath, checkPaint);
    }

    // Draw pen element
    if (showPen) {
      _drawPen(canvas, scale);
    }
  }

  void _drawSurveyLine(
    Canvas canvas,
    double scale,
    double x,
    double y,
    double width,
    double opacity,
  ) {
    final paint = Paint()
      ..color = LogoColors.lightBlue.withOpacity( opacity);
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x * scale, y * scale, width * scale, 16 * scale),
      Radius.circular(8 * scale),
    );
    canvas.drawRRect(rect, paint);
  }

  void _drawPen(Canvas canvas, double scale) {
    canvas.save();

    // Rotate around pen center point
    final pivotX = 380 * scale;
    final pivotY = 320 * scale;
    canvas.translate(pivotX, pivotY);
    canvas.rotate(-math.pi / 4); // -45 degrees
    canvas.translate(-pivotX, -pivotY);

    // Pen gradient
    const penGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [LogoColors.accentLight, LogoColors.accentDark],
    );

    // Pen body
    final penBodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(340 * scale, 200 * scale, 40 * scale, 180 * scale),
      Radius.circular(6 * scale),
    );
    final penBodyPaint = Paint()
      ..shader = penGradient.createShader(
        Rect.fromLTWH(340 * scale, 200 * scale, 40 * scale, 180 * scale),
      );
    canvas.drawRRect(penBodyRect, penBodyPaint);

    // Pen tip
    final penTipPaint = Paint()..color = LogoColors.deepBlue;
    final penTipPath = Path()
      ..moveTo(340 * scale, 380 * scale)
      ..lineTo(380 * scale, 380 * scale)
      ..lineTo(360 * scale, 420 * scale)
      ..close();
    canvas.drawPath(penTipPath, penTipPaint);

    // Pen grip rings
    final gripPaint = Paint()
      ..color = LogoColors.deepBlue.withOpacity( 0.3);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(340 * scale, 260 * scale, 40 * scale, 6 * scale),
        Radius.circular(2 * scale),
      ),
      gripPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(340 * scale, 280 * scale, 40 * scale, 6 * scale),
        Radius.circular(2 * scale),
      ),
      gripPaint,
    );

    // Pen top cap
    final penTopPaint = Paint()..color = LogoColors.deepBlue;
    final penTopRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(340 * scale, 200 * scale, 40 * scale, 20 * scale),
      Radius.circular(6 * scale),
    );
    canvas.drawRRect(penTopRect, penTopPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Simplified logo for icon use (no pen, just clipboard with checkmark)
class AppLogoIcon extends StatelessWidget {
  const AppLogoIcon({
    super.key,
    this.size = 48,
  });

  final double size;

  @override
  Widget build(BuildContext context) => AppLogo(
      size: size,
      showPen: false,
    );
}

/// Logo with text for branding
class AppLogoWithText extends StatelessWidget {
  const AppLogoWithText({
    super.key,
    this.logoSize = 80,
    this.textStyle,
    this.spacing = 16,
    this.direction = Axis.horizontal,
  });

  final double logoSize;
  final TextStyle? textStyle;
  final double spacing;
  final Axis direction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultTextStyle = theme.textTheme.headlineMedium?.copyWith(
      fontWeight: FontWeight.bold,
      color: LogoColors.primaryDark,
      letterSpacing: -0.5,
    );

    final children = [
      AppLogo(size: logoSize),
      SizedBox(
        width: direction == Axis.horizontal ? spacing : 0,
        height: direction == Axis.vertical ? spacing : 0,
      ),
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: direction == Axis.horizontal
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Text(
            'Survey',
            style: textStyle ?? defaultTextStyle,
          ),
          Text(
            'Scriber',
            style: (textStyle ?? defaultTextStyle)?.copyWith(
              color: LogoColors.success,
            ),
          ),
        ],
      ),
    ];

    return direction == Axis.horizontal
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: children,
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: children,
          );
  }
}
