import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../domain/entities/media_item.dart';
import '../../domain/entities/photo_annotation.dart';
import '../providers/annotation_provider.dart';

const _uuid = Uuid();

/// Photo annotation editor with drawing tools
class AnnotationEditorPage extends ConsumerStatefulWidget {
  const AnnotationEditorPage({
    required this.photo,
    required this.sectionId,
    super.key,
  });

  final PhotoItem photo;
  final String sectionId;

  @override
  ConsumerState<AnnotationEditorPage> createState() => _AnnotationEditorPageState();
}

class _AnnotationEditorPageState extends ConsumerState<AnnotationEditorPage> {
  final GlobalKey _canvasKey = GlobalKey();

  AnnotationType _selectedTool = AnnotationType.freehand;
  Color _selectedColor = Colors.red;
  double _strokeWidth = 4;

  List<AnnotationElement> _elements = [];
  List<AnnotationElement> _undoneElements = [];
  List<AnnotationPoint> _currentPoints = [];
  bool _isDrawing = false;
  bool _hasChanges = false;
  bool _isSaving = false;

  final List<Color> _colorOptions = [
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.purple,
    Colors.black,
    Colors.white,
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingAnnotations();
  }

  Future<void> _loadExistingAnnotations() async {
    final annotation = await ref
        .read(annotationProvider(widget.photo.id).future);

    if (annotation != null && mounted) {
      setState(() {
        _elements = List.from(annotation.elements);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Annotate Photo'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _confirmClose,
        ),
        actions: [
          if (_elements.isNotEmpty || _hasChanges)
            IconButton(
              icon: const Icon(Icons.undo_rounded),
              onPressed: _elements.isEmpty ? null : _undo,
              tooltip: 'Undo',
            ),
          if (_undoneElements.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.redo_rounded),
              onPressed: _redo,
              tooltip: 'Redo',
            ),
          if (_hasChanges)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: _clearAll,
              tooltip: 'Clear All',
            ),
          AppSpacing.gapHorizontalSm,
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            )
          else
            FilledButton.icon(
              onPressed: _hasChanges ? _save : null,
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text('Save'),
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
            ),
          AppSpacing.gapHorizontalSm,
        ],
      ),
      body: Column(
        children: [
          // Canvas area
          Expanded(
            child: Center(
              child: RepaintBoundary(
                key: _canvasKey,
                child: Stack(
                  children: [
                    // Base photo
                    Image.file(
                      File(widget.photo.localPath),
                      fit: BoxFit.contain,
                    ),
                    // Drawing canvas
                    Positioned.fill(
                      child: GestureDetector(
                        onPanStart: _onPanStart,
                        onPanUpdate: _onPanUpdate,
                        onPanEnd: _onPanEnd,
                        onTapUp: _selectedTool == AnnotationType.text
                            ? _onTapForText
                            : null,
                        child: CustomPaint(
                          painter: _AnnotationPainter(
                            elements: _elements,
                            currentPoints: _currentPoints,
                            currentColor: _selectedColor,
                            currentStrokeWidth: _strokeWidth,
                            currentTool: _selectedTool,
                          ),
                          size: Size.infinite,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Tool bar
          Container(
            color: colorScheme.surface,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tool selection
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _ToolButton(
                          icon: Icons.gesture_rounded,
                          label: 'Draw',
                          isSelected: _selectedTool == AnnotationType.freehand,
                          onTap: () => setState(() => _selectedTool = AnnotationType.freehand),
                        ),
                        _ToolButton(
                          icon: Icons.arrow_forward_rounded,
                          label: 'Arrow',
                          isSelected: _selectedTool == AnnotationType.arrow,
                          onTap: () => setState(() => _selectedTool = AnnotationType.arrow),
                        ),
                        _ToolButton(
                          icon: Icons.crop_square_rounded,
                          label: 'Rectangle',
                          isSelected: _selectedTool == AnnotationType.rectangle,
                          onTap: () => setState(() => _selectedTool = AnnotationType.rectangle),
                        ),
                        _ToolButton(
                          icon: Icons.circle_outlined,
                          label: 'Circle',
                          isSelected: _selectedTool == AnnotationType.circle,
                          onTap: () => setState(() => _selectedTool = AnnotationType.circle),
                        ),
                        _ToolButton(
                          icon: Icons.text_fields_rounded,
                          label: 'Text',
                          isSelected: _selectedTool == AnnotationType.text,
                          onTap: () => setState(() => _selectedTool = AnnotationType.text),
                        ),
                        _ToolButton(
                          icon: Icons.push_pin_rounded,
                          label: 'Marker',
                          isSelected: _selectedTool == AnnotationType.marker,
                          onTap: () => setState(() => _selectedTool = AnnotationType.marker),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  // Color and stroke options
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        // Color options
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _colorOptions.map((color) {
                                final isSelected = _selectedColor == color;
                                return GestureDetector(
                                  onTap: () => setState(() => _selectedColor = color),
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    margin: const EdgeInsets.only(right: AppSpacing.sm),
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? colorScheme.primary
                                            : colorScheme.outline,
                                        width: isSelected ? 3 : 1,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),

                        AppSpacing.gapHorizontalMd,

                        // Stroke width slider
                        SizedBox(
                          width: 100,
                          child: Column(
                            children: [
                              Text(
                                'Size',
                                style: theme.textTheme.labelSmall,
                              ),
                              Slider(
                                value: _strokeWidth,
                                min: 2,
                                max: 12,
                                divisions: 5,
                                onChanged: (value) {
                                  setState(() => _strokeWidth = value);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    if (_selectedTool == AnnotationType.text) return;

    setState(() {
      _isDrawing = true;
      _currentPoints = [
        AnnotationPoint(
          x: details.localPosition.dx,
          y: details.localPosition.dy,
        ),
      ];
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDrawing || _selectedTool == AnnotationType.text) return;

    setState(() {
      _currentPoints = [
        ..._currentPoints,
        AnnotationPoint(
          x: details.localPosition.dx,
          y: details.localPosition.dy,
        ),
      ];
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_isDrawing || _currentPoints.isEmpty) return;

    final element = AnnotationElement(
      id: _uuid.v4(),
      type: _selectedTool,
      color: _selectedColor.value,
      strokeWidth: _strokeWidth,
      points: _currentPoints,
    );

    setState(() {
      _elements.add(element);
      _currentPoints = [];
      _isDrawing = false;
      _hasChanges = true;
      _undoneElements.clear();
    });
  }

  Future<void> _onTapForText(TapUpDetails details) async {
    final text = await _showTextInputDialog();
    if (text == null || text.isEmpty) return;

    final element = AnnotationElement(
      id: _uuid.v4(),
      type: AnnotationType.text,
      color: _selectedColor.value,
      strokeWidth: _strokeWidth,
      points: [
        AnnotationPoint(
          x: details.localPosition.dx,
          y: details.localPosition.dy,
        ),
      ],
      text: text,
    );

    setState(() {
      _elements.add(element);
      _hasChanges = true;
      _undoneElements.clear();
    });
  }

  Future<String?> _showTextInputDialog() async {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Text'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter text...',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _undo() {
    if (_elements.isEmpty) return;

    setState(() {
      _undoneElements.add(_elements.removeLast());
      _hasChanges = true;
    });
  }

  void _redo() {
    if (_undoneElements.isEmpty) return;

    setState(() {
      _elements.add(_undoneElements.removeLast());
      _hasChanges = true;
    });
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All?'),
        content: const Text('This will remove all annotations.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _undoneElements = List.from(_elements);
        _elements.clear();
        _hasChanges = true;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    try {
      final annotation = PhotoAnnotation(
        id: _uuid.v4(),
        photoId: widget.photo.id,
        elements: _elements,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ref
          .read(annotationProvider(widget.photo.id).notifier)
          .saveAnnotation(annotation);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _confirmClose() async {
    if (!_hasChanges) {
      Navigator.pop(context);
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text('You have unsaved changes. Do you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      Navigator.pop(context);
    }
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primaryContainer : Colors.transparent,
          borderRadius: AppSpacing.borderRadiusSm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurface,
            ),
            AppSpacing.gapVerticalXs,
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnnotationPainter extends CustomPainter {
  _AnnotationPainter({
    required this.elements,
    required this.currentPoints,
    required this.currentColor,
    required this.currentStrokeWidth,
    required this.currentTool,
  });

  final List<AnnotationElement> elements;
  final List<AnnotationPoint> currentPoints;
  final Color currentColor;
  final double currentStrokeWidth;
  final AnnotationType currentTool;

  @override
  void paint(Canvas canvas, Size size) {
    // Draw existing elements
    for (final element in elements) {
      _drawElement(canvas, element);
    }

    // Draw current stroke
    if (currentPoints.isNotEmpty) {
      final tempElement = AnnotationElement(
        id: 'temp',
        type: currentTool,
        color: currentColor.value,
        strokeWidth: currentStrokeWidth,
        points: currentPoints,
      );
      _drawElement(canvas, tempElement);
    }
  }

  void _drawElement(Canvas canvas, AnnotationElement element) {
    final color = Color(element.color);
    final paint = Paint()
      ..color = color
      ..strokeWidth = element.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    switch (element.type) {
      case AnnotationType.freehand:
        _drawFreehand(canvas, element.points, paint);
      case AnnotationType.arrow:
        _drawArrow(canvas, element.points, paint, color);
      case AnnotationType.rectangle:
        _drawRectangle(canvas, element.points, paint);
      case AnnotationType.circle:
        _drawCircle(canvas, element.points, paint);
      case AnnotationType.text:
        _drawText(canvas, element);
      case AnnotationType.marker:
        _drawMarker(canvas, element.points, color);
    }
  }

  void _drawFreehand(Canvas canvas, List<AnnotationPoint> points, Paint paint) {
    if (points.length < 2) return;

    final path = Path();
    path.moveTo(points.first.x, points.first.y);

    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].x, points[i].y);
    }

    canvas.drawPath(path, paint);
  }

  void _drawArrow(Canvas canvas, List<AnnotationPoint> points, Paint paint, Color color) {
    if (points.length < 2) return;

    final start = Offset(points.first.x, points.first.y);
    final end = Offset(points.last.x, points.last.y);

    // Draw line
    canvas.drawLine(start, end, paint);

    // Draw arrowhead
    final angle = (end - start).direction;
    const arrowLength = 20.0;
    const arrowAngle = 0.5;

    final arrowPoint1 = Offset(
      end.dx - arrowLength * (start.dx - end.dx).sign.abs() *
          (end.dx > start.dx ? 1 : -1) * 0.7 -
          arrowLength * (end.dy > start.dy ? 0.3 : -0.3),
      end.dy - arrowLength * (start.dy - end.dy).sign.abs() *
          (end.dy > start.dy ? 1 : -1) * 0.7 -
          arrowLength * (end.dx > start.dx ? -0.3 : 0.3),
    );

    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final length = dx * dx + dy * dy;
    if (length == 0) return;

    final unitDx = dx / length.abs().clamp(1, double.infinity);
    final unitDy = dy / length.abs().clamp(1, double.infinity);

    final arrowHead1 = Offset(
      end.dx - arrowLength * unitDx + arrowLength * 0.5 * unitDy,
      end.dy - arrowLength * unitDy - arrowLength * 0.5 * unitDx,
    );
    final arrowHead2 = Offset(
      end.dx - arrowLength * unitDx - arrowLength * 0.5 * unitDy,
      end.dy - arrowLength * unitDy + arrowLength * 0.5 * unitDx,
    );

    final arrowPath = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(arrowHead1.dx, arrowHead1.dy)
      ..moveTo(end.dx, end.dy)
      ..lineTo(arrowHead2.dx, arrowHead2.dy);

    canvas.drawPath(arrowPath, paint);
  }

  void _drawRectangle(Canvas canvas, List<AnnotationPoint> points, Paint paint) {
    if (points.length < 2) return;

    final start = Offset(points.first.x, points.first.y);
    final end = Offset(points.last.x, points.last.y);

    final rect = Rect.fromPoints(start, end);
    canvas.drawRect(rect, paint);
  }

  void _drawCircle(Canvas canvas, List<AnnotationPoint> points, Paint paint) {
    if (points.length < 2) return;

    final start = Offset(points.first.x, points.first.y);
    final end = Offset(points.last.x, points.last.y);

    final center = Offset(
      (start.dx + end.dx) / 2,
      (start.dy + end.dy) / 2,
    );
    final radius = (end - start).distance / 2;

    canvas.drawCircle(center, radius, paint);
  }

  void _drawText(Canvas canvas, AnnotationElement element) {
    if (element.points.isEmpty || element.text == null) return;

    final textSpan = TextSpan(
      text: element.text,
      style: TextStyle(
        color: Color(element.color),
        fontSize: 16 + element.strokeWidth,
        fontWeight: FontWeight.bold,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(element.points.first.x, element.points.first.y),
    );
  }

  void _drawMarker(Canvas canvas, List<AnnotationPoint> points, Color color) {
    if (points.isEmpty) return;

    final center = Offset(points.first.x, points.first.y);

    // Draw pin shape
    final paint = Paint()..color = color;

    // Circle head
    canvas.drawCircle(center.translate(0, -15), 12, paint);

    // Triangle pointer
    final path = Path()
      ..moveTo(center.dx, center.dy)
      ..lineTo(center.dx - 8, center.dy - 15)
      ..lineTo(center.dx + 8, center.dy - 15)
      ..close();

    canvas.drawPath(path, paint);

    // White dot in center
    canvas.drawCircle(
      center.translate(0, -15),
      4,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _AnnotationPainter oldDelegate) => oldDelegate.elements != elements ||
        oldDelegate.currentPoints != currentPoints ||
        oldDelegate.currentColor != currentColor ||
        oldDelegate.currentStrokeWidth != currentStrokeWidth;
}
