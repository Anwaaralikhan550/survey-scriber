import 'dart:ui';

import 'package:equatable/equatable.dart';

/// Status of signature (for sync)
enum SignatureStatus {
  local,
  uploading,
  synced,
  failed,
}

/// A single point in a signature stroke
class SignaturePoint extends Equatable {
  const SignaturePoint({
    required this.x,
    required this.y,
    this.pressure = 1.0,
    this.timestamp,
  });

  factory SignaturePoint.fromOffset(Offset offset, {double pressure = 1.0, int? timestamp}) => SignaturePoint(
      x: offset.dx,
      y: offset.dy,
      pressure: pressure,
      timestamp: timestamp,
    );

  factory SignaturePoint.fromJson(Map<String, dynamic> json) => SignaturePoint(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      pressure: (json['pressure'] as num?)?.toDouble() ?? 1.0,
      timestamp: json['timestamp'] as int?,
    );

  final double x;
  final double y;
  final double pressure;
  final int? timestamp; // milliseconds since stroke started

  Offset toOffset() => Offset(x, y);

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'pressure': pressure,
        if (timestamp != null) 'timestamp': timestamp,
      };

  @override
  List<Object?> get props => [x, y, pressure, timestamp];
}

/// A continuous stroke in a signature
class SignatureStroke extends Equatable {
  const SignatureStroke({
    required this.points,
    this.color = 0xFF000000,
    this.strokeWidth = 2.5,
  });

  factory SignatureStroke.fromJson(Map<String, dynamic> json) => SignatureStroke(
      points: (json['points'] as List)
          .map((p) => SignaturePoint.fromJson(p as Map<String, dynamic>))
          .toList(),
      color: json['color'] as int? ?? 0xFF000000,
      strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 2.5,
    );

  final List<SignaturePoint> points;
  final int color; // Color as int
  final double strokeWidth;

  Color get colorValue => Color(color);

  bool get isEmpty => points.isEmpty;
  bool get isNotEmpty => points.isNotEmpty;

  /// Get bounding box of this stroke
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

  SignatureStroke copyWith({
    List<SignaturePoint>? points,
    int? color,
    double? strokeWidth,
  }) => SignatureStroke(
      points: points ?? this.points,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
    );

  Map<String, dynamic> toJson() => {
        'points': points.map((p) => p.toJson()).toList(),
        'color': color,
        'strokeWidth': strokeWidth,
      };

  @override
  List<Object?> get props => [points, color, strokeWidth];
}

/// A complete signature with metadata
class SignatureItem extends Equatable {
  const SignatureItem({
    required this.id,
    required this.surveyId,
    required this.createdAt,
    required this.strokes,
    this.sectionId,
    this.signerName,
    this.signerRole,
    this.status = SignatureStatus.local,
    this.previewPath,
    this.width,
    this.height,
  });

  final String id;
  final String surveyId;
  final String? sectionId;
  final String? signerName;
  final String? signerRole;
  final List<SignatureStroke> strokes;
  final SignatureStatus status;
  final DateTime createdAt;

  /// Path to PNG preview image
  final String? previewPath;

  /// Canvas width when signature was captured
  final int? width;

  /// Canvas height when signature was captured
  final int? height;

  bool get isEmpty => strokes.isEmpty || strokes.every((s) => s.isEmpty);
  bool get isNotEmpty => !isEmpty;
  bool get hasSignerInfo => signerName != null || signerRole != null;
  bool get hasPreview => previewPath != null;

  int get totalPoints => strokes.fold(0, (sum, stroke) => sum + stroke.points.length);

  /// Get bounding box of entire signature
  Rect get bounds {
    if (strokes.isEmpty) return Rect.zero;

    var minX = double.infinity;
    var maxX = double.negativeInfinity;
    var minY = double.infinity;
    var maxY = double.negativeInfinity;

    for (final stroke in strokes) {
      final strokeBounds = stroke.bounds;
      if (strokeBounds.left < minX) minX = strokeBounds.left;
      if (strokeBounds.right > maxX) maxX = strokeBounds.right;
      if (strokeBounds.top < minY) minY = strokeBounds.top;
      if (strokeBounds.bottom > maxY) maxY = strokeBounds.bottom;
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  SignatureItem copyWith({
    String? id,
    String? surveyId,
    String? sectionId,
    String? signerName,
    String? signerRole,
    List<SignatureStroke>? strokes,
    SignatureStatus? status,
    DateTime? createdAt,
    String? previewPath,
    int? width,
    int? height,
  }) => SignatureItem(
      id: id ?? this.id,
      surveyId: surveyId ?? this.surveyId,
      sectionId: sectionId ?? this.sectionId,
      signerName: signerName ?? this.signerName,
      signerRole: signerRole ?? this.signerRole,
      strokes: strokes ?? this.strokes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      previewPath: previewPath ?? this.previewPath,
      width: width ?? this.width,
      height: height ?? this.height,
    );

  @override
  List<Object?> get props => [
        id,
        surveyId,
        sectionId,
        signerName,
        signerRole,
        strokes,
        status,
        createdAt,
        previewPath,
        width,
        height,
      ];
}

/// Common signer roles
abstract class SignerRoles {
  static const String surveyor = 'Surveyor';
  static const String client = 'Client';
  static const String witness = 'Witness';
  static const String inspector = 'Inspector';
  static const String propertyOwner = 'Property Owner';
  static const String tenant = 'Tenant';
  static const String contractor = 'Contractor';

  static const List<String> all = [
    surveyor,
    client,
    witness,
    inspector,
    propertyOwner,
    tenant,
    contractor,
  ];
}
