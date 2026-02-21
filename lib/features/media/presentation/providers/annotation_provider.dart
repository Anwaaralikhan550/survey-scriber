import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_providers.dart';
import '../../domain/entities/photo_annotation.dart';

/// Provider for loading/saving photo annotations
final annotationProvider = AsyncNotifierProvider.autoDispose
    .family<AnnotationNotifier, PhotoAnnotation?, String>(
  AnnotationNotifier.new,
);

class AnnotationNotifier extends AutoDisposeFamilyAsyncNotifier<PhotoAnnotation?, String> {
  @override
  Future<PhotoAnnotation?> build(String photoId) async => _loadAnnotation(photoId);

  Future<PhotoAnnotation?> _loadAnnotation(String photoId) async {
    final mediaDao = ref.read(mediaDaoProvider);
    final data = await mediaDao.getAnnotation(photoId);

    if (data == null) return null;

    return _parseAnnotation(data);
  }

  PhotoAnnotation? _parseAnnotation(PhotoAnnotationsData data) {
    try {
      final elementsJson = jsonDecode(data.elementsJson) as List<dynamic>;
      final elements = elementsJson
          .map((e) => _parseElement(e as Map<String, dynamic>))
          .toList();

      return PhotoAnnotation(
        id: data.id,
        photoId: data.photoId,
        elements: elements,
        createdAt: data.createdAt,
        updatedAt: data.updatedAt,
      );
    } catch (e) {
      return null;
    }
  }

  AnnotationElement _parseElement(Map<String, dynamic> json) {
    final pointsJson = json['points'] as List<dynamic>;
    final points = pointsJson.map((p) {
      final point = p as Map<String, dynamic>;
      return AnnotationPoint(
        x: (point['x'] as num).toDouble(),
        y: (point['y'] as num).toDouble(),
        pressure: point['pressure'] != null
            ? (point['pressure'] as num).toDouble()
            : 1.0,
      );
    }).toList();

    return AnnotationElement(
      id: json['id'] as String,
      type: AnnotationType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => AnnotationType.freehand,
      ),
      color: json['color'] as int,
      strokeWidth: (json['strokeWidth'] as num).toDouble(),
      points: points,
      text: json['text'] as String?,
    );
  }

  /// Save annotation to database
  Future<void> saveAnnotation(PhotoAnnotation annotation) async {
    final mediaDao = ref.read(mediaDaoProvider);

    // Use the DAO's saveAnnotation method which handles everything
    await mediaDao.saveAnnotation(
      id: annotation.id,
      photoId: annotation.photoId,
      elements: annotation.elements,
    );

    // Refresh state
    state = AsyncValue.data(annotation);
  }

  /// Delete annotation
  Future<void> deleteAnnotation() async {
    final mediaDao = ref.read(mediaDaoProvider);
    await mediaDao.deleteAnnotation(arg);

    state = const AsyncValue.data(null);
  }
}

/// Provider for checking if a photo has annotations
final hasAnnotationsProvider = FutureProvider.autoDispose
    .family<bool, String>((ref, photoId) async {
  final annotation = await ref.watch(annotationProvider(photoId).future);
  return annotation != null && annotation.elements.isNotEmpty;
});
