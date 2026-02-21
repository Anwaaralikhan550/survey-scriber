import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/signature_item.dart';

/// A widget for capturing signatures with smooth drawing.
///
/// Uses [Listener] + [RawGestureDetector] with an eager gesture recognizer
/// to capture touch immediately, preventing parent ScrollView interference.
class SignaturePad extends StatefulWidget {
  const SignaturePad({
    required this.onChanged,
    this.initialStrokes,
    this.strokeColor = Colors.black,
    this.strokeWidth = 2.5,
    this.backgroundColor = Colors.white,
    this.showGuideLines = true,
    super.key,
  });

  final ValueChanged<List<SignatureStroke>> onChanged;
  final List<SignatureStroke>? initialStrokes;
  final Color strokeColor;
  final double strokeWidth;
  final Color backgroundColor;
  final bool showGuideLines;

  @override
  State<SignaturePad> createState() => SignaturePadState();
}

class SignaturePadState extends State<SignaturePad> {
  final List<SignatureStroke> _strokes = [];
  List<SignaturePoint> _currentPoints = [];
  bool _isDrawing = false;

  // Track counts for efficient shouldRepaint comparison
  // (comparing list references doesn't detect mutations)
  int _strokeCount = 0;
  int _currentPointCount = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initialStrokes != null && widget.initialStrokes!.isNotEmpty) {
      _strokes.addAll(widget.initialStrokes!);
      _strokeCount = _strokes.length;
    }
  }

  /// Get all strokes
  List<SignatureStroke> get strokes => List.unmodifiable(_strokes);

  /// Check if signature is empty
  bool get isEmpty => _strokes.isEmpty;

  /// Check if signature is not empty
  bool get isNotEmpty => _strokes.isNotEmpty;

  /// Undo last stroke - removes the entire last drawn segment
  void undo() {
    if (_strokes.isNotEmpty) {
      setState(() {
        _strokes.removeLast();
        _strokeCount = _strokes.length;
      });
      widget.onChanged(_strokes);
    }
  }

  /// Clear all strokes
  void clear() {
    setState(() {
      _strokes.clear();
      _strokeCount = 0;
      _currentPoints.clear();
      _currentPointCount = 0;
    });
    widget.onChanged(_strokes);
  }

  /// Get canvas size
  Size? getCanvasSize(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    return box?.size;
  }

  void _onPanStart(Offset localPosition) {
    setState(() {
      _isDrawing = true;
      _currentPoints = [SignaturePoint.fromOffset(localPosition)];
      _currentPointCount = 1;
    });
  }

  void _onPanUpdate(Offset localPosition) {
    if (!_isDrawing) return;

    setState(() {
      _currentPoints.add(SignaturePoint.fromOffset(localPosition));
      _currentPointCount = _currentPoints.length;
    });
  }

  void _onPanEnd() {
    if (!_isDrawing || _currentPoints.isEmpty) return;

    setState(() {
      _strokes.add(
        SignatureStroke(
          points: List.from(_currentPoints),
          color: widget.strokeColor.value,
          strokeWidth: widget.strokeWidth,
        ),
      );
      _strokeCount = _strokes.length;
      _currentPoints.clear();
      _currentPointCount = 0;
      _isDrawing = false;
    });

    widget.onChanged(_strokes);
  }

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: widget.backgroundColor,
          child: RawGestureDetector(
            gestures: <Type, GestureRecognizerFactory>{
              _ImmediatePanGestureRecognizer:
                  GestureRecognizerFactoryWithHandlers<_ImmediatePanGestureRecognizer>(
                _ImmediatePanGestureRecognizer.new,
                (instance) {
                  instance.onStart = (details) => _onPanStart(details.localPosition);
                  instance.onUpdate = (details) => _onPanUpdate(details.localPosition);
                  instance.onEnd = (_) => _onPanEnd();
                  instance.onCancel = _onPanEnd;
                },
              ),
            },
            behavior: HitTestBehavior.opaque,
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _SignaturePainter(
                  strokes: _strokes,
                  strokeCount: _strokeCount,
                  currentPoints: _currentPoints,
                  currentPointCount: _currentPointCount,
                  currentColor: widget.strokeColor,
                  currentStrokeWidth: widget.strokeWidth,
                  showGuideLines: widget.showGuideLines,
                ),
                size: Size.infinite,
              ),
            ),
          ),
        ),
      );
}

/// Custom pan gesture recognizer that wins the gesture arena immediately.
/// This prevents parent ScrollView from stealing the gesture.
class _ImmediatePanGestureRecognizer extends PanGestureRecognizer {
  _ImmediatePanGestureRecognizer() {
    // Allow all pointer device kinds
    supportedDevices = PointerDeviceKind.values.toSet();
  }

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    // CRITICAL: Immediately claim the gesture to prevent scroll interference
    resolve(GestureDisposition.accepted);
  }
}

class _SignaturePainter extends CustomPainter {
  _SignaturePainter({
    required this.strokes,
    required this.strokeCount,
    required this.currentPoints,
    required this.currentPointCount,
    required this.currentColor,
    required this.currentStrokeWidth,
    this.showGuideLines = true,
  });

  final List<SignatureStroke> strokes;
  final int strokeCount; // Track stroke count for undo detection
  final List<SignaturePoint> currentPoints;
  final int currentPointCount; // Track point count for real-time rendering
  final Color currentColor;
  final double currentStrokeWidth;
  final bool showGuideLines;

  @override
  void paint(Canvas canvas, Size size) {
    // Draw guide line
    if (showGuideLines) {
      _drawGuideLine(canvas, size);
    }

    // Draw completed strokes
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke);
    }

    // Draw current stroke
    if (currentPoints.isNotEmpty) {
      final currentStroke = SignatureStroke(
        points: currentPoints,
        color: currentColor.value,
        strokeWidth: currentStrokeWidth,
      );
      _drawStroke(canvas, currentStroke);
    }
  }

  void _drawGuideLine(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Draw a subtle line at ~70% height
    final y = size.height * 0.7;
    canvas.drawLine(
      Offset(20, y),
      Offset(size.width - 20, y),
      paint,
    );
  }

  void _drawStroke(Canvas canvas, SignatureStroke stroke) {
    if (stroke.points.length < 2) {
      // Draw a single dot for single-point strokes
      if (stroke.points.isNotEmpty) {
        final point = stroke.points.first;
        final paint = Paint()
          ..color = stroke.colorValue
          ..strokeWidth = stroke.strokeWidth
          ..style = PaintingStyle.fill;
        canvas.drawCircle(
          Offset(point.x, point.y),
          stroke.strokeWidth / 2,
          paint,
        );
      }
      return;
    }

    final paint = Paint()
      ..color = stroke.colorValue
      ..strokeWidth = stroke.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // Use quadratic bezier curves for smooth lines
    final path = Path();
    path.moveTo(stroke.points.first.x, stroke.points.first.y);

    for (var i = 1; i < stroke.points.length; i++) {
      final p0 = stroke.points[i - 1];
      final p1 = stroke.points[i];

      // Use midpoint for smoother curves
      final midX = (p0.x + p1.x) / 2;
      final midY = (p0.y + p1.y) / 2;

      if (i == 1) {
        path.lineTo(midX, midY);
      } else {
        path.quadraticBezierTo(p0.x, p0.y, midX, midY);
      }
    }

    // Draw line to the last point
    final last = stroke.points.last;
    path.lineTo(last.x, last.y);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) =>
      oldDelegate.strokeCount != strokeCount ||
      oldDelegate.currentPointCount != currentPointCount ||
      oldDelegate.currentColor != currentColor ||
      oldDelegate.currentStrokeWidth != currentStrokeWidth;
}

/// A read-only widget for displaying a signature
class SignaturePreview extends StatelessWidget {
  const SignaturePreview({
    required this.strokes,
    this.backgroundColor = Colors.white,
    this.borderRadius = 14,
    this.showBorder = true,
    super.key,
  });

  final List<SignatureStroke> strokes;
  final Color backgroundColor;
  final double borderRadius;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: showBorder
            ? Border.all(color: colorScheme.outlineVariant)
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: CustomPaint(
          painter: _SignaturePainter(
            strokes: strokes,
            strokeCount: strokes.length,
            currentPoints: const [],
            currentPointCount: 0,
            currentColor: Colors.black,
            currentStrokeWidth: 2.5,
            showGuideLines: false,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}
