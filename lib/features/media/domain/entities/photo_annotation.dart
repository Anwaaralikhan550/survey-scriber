import 'dart:ui';

import 'package:equatable/equatable.dart';

/// Types of annotations that can be added to photos
enum AnnotationType {
  freehand,   // Free drawing
  arrow,      // Arrow pointing to something
  rectangle,  // Rectangle highlight
  circle,     // Circle highlight
  text,       // Text label
  marker,     // Pin/marker point
}

/// A single annotation element on a photo
class AnnotationElement extends Equatable {
  const AnnotationElement({
    required this.id,
    required this.type,
    required this.color,
    required this.strokeWidth,
    required this.points,
    this.text,
    this.fontSize,
    this.createdAt,
  });

  factory AnnotationElement.fromJson(Map<String, dynamic> json) => AnnotationElement(
      id: json['id'] as String,
      type: AnnotationType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => AnnotationType.freehand,
      ),
      color: json['color'] as int,
      strokeWidth: (json['strokeWidth'] as num).toDouble(),
      points: (json['points'] as List)
          .map((p) => AnnotationPoint.fromJson(p as Map<String, dynamic>))
          .toList(),
      text: json['text'] as String?,
      fontSize: (json['fontSize'] as num?)?.toDouble(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );

  final String id;
  final AnnotationType type;
  final int color; // Color as int (Color.value)
  final double strokeWidth;
  final List<AnnotationPoint> points;
  final String? text; // For text annotations
  final double? fontSize;
  final DateTime? createdAt;

  Color get colorValue => Color(color);

  /// Get bounding box of this annotation
  Rect get bounds {
    if (points.isEmpty) return Rect.zero;

    var minX = points.first.x;
    var maxX = points.first.x;
    var minY = points.first.y;
    var maxY = points.first.y;

    for (final point in points) {
      if (point.x < minX) minX = point.x;
      if (point.x > maxX) maxX = point.x;
      if (point.y < minY) minY = point.y;
      if (point.y > maxY) maxY = point.y;
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  AnnotationElement copyWith({
    String? id,
    AnnotationType? type,
    int? color,
    double? strokeWidth,
    List<AnnotationPoint>? points,
    String? text,
    double? fontSize,
    DateTime? createdAt,
  }) => AnnotationElement(
      id: id ?? this.id,
      type: type ?? this.type,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      points: points ?? this.points,
      text: text ?? this.text,
      fontSize: fontSize ?? this.fontSize,
      createdAt: createdAt ?? this.createdAt,
    );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'color': color,
        'strokeWidth': strokeWidth,
        'points': points.map((p) => p.toJson()).toList(),
        'text': text,
        'fontSize': fontSize,
        'createdAt': createdAt?.toIso8601String(),
      };

  @override
  List<Object?> get props => [
        id,
        type,
        color,
        strokeWidth,
        points,
        text,
        fontSize,
        createdAt,
      ];
}

/// A point in an annotation (normalized 0-1 coordinates)
class AnnotationPoint extends Equatable {
  const AnnotationPoint({
    required this.x,
    required this.y,
    this.pressure = 1.0,
  });

  factory AnnotationPoint.fromOffset(Offset offset, Size imageSize) => AnnotationPoint(
      x: offset.dx / imageSize.width,
      y: offset.dy / imageSize.height,
    );

  factory AnnotationPoint.fromJson(Map<String, dynamic> json) => AnnotationPoint(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      pressure: (json['pressure'] as num?)?.toDouble() ?? 1.0,
    );

  /// X coordinate (0-1, normalized to image width)
  final double x;

  /// Y coordinate (0-1, normalized to image height)
  final double y;

  /// Pressure (for stylus support)
  final double pressure;

  Offset toOffset(Size imageSize) => Offset(x * imageSize.width, y * imageSize.height);

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'pressure': pressure,
      };

  @override
  List<Object?> get props => [x, y, pressure];
}

/// Complete annotation data for a photo
class PhotoAnnotation extends Equatable {
  const PhotoAnnotation({
    required this.id,
    required this.photoId,
    required this.elements,
    required this.createdAt,
    this.updatedAt,
    this.annotatedImagePath,
  });

  final String id;
  final String photoId;
  final List<AnnotationElement> elements;
  final DateTime createdAt;
  final DateTime? updatedAt;

  /// Path to the rendered annotated image (for export/preview)
  final String? annotatedImagePath;

  bool get hasAnnotations => elements.isNotEmpty;
  int get annotationCount => elements.length;

  PhotoAnnotation copyWith({
    String? id,
    String? photoId,
    List<AnnotationElement>? elements,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? annotatedImagePath,
  }) => PhotoAnnotation(
      id: id ?? this.id,
      photoId: photoId ?? this.photoId,
      elements: elements ?? this.elements,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      annotatedImagePath: annotatedImagePath ?? this.annotatedImagePath,
    );

  @override
  List<Object?> get props => [
        id,
        photoId,
        elements,
        createdAt,
        updatedAt,
        annotatedImagePath,
      ];
}

/// Default annotation colors
abstract class AnnotationColors {
  static const int red = 0xFFE53935;
  static const int orange = 0xFFFB8C00;
  static const int yellow = 0xFFFFEB3B;
  static const int green = 0xFF43A047;
  static const int blue = 0xFF1E88E5;
  static const int purple = 0xFF8E24AA;
  static const int white = 0xFFFFFFFF;
  static const int black = 0xFF212121;

  static const List<int> palette = [
    red,
    orange,
    yellow,
    green,
    blue,
    purple,
    white,
    black,
  ];
}

/// Default stroke widths
abstract class AnnotationStrokes {
  static const double thin = 2;
  static const double medium = 4;
  static const double thick = 8;
  static const double extraThick = 12;

  static const List<double> options = [thin, medium, thick, extraThick];
}
