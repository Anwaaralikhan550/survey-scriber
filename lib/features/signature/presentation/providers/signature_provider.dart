import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/signature_dao.dart';
import '../../../../core/database/database_providers.dart';
import '../../domain/entities/signature_item.dart';

const _uuid = Uuid();

/// State for survey signatures
class SurveySignaturesState {
  const SurveySignaturesState({
    this.signatures = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final List<SignatureItem> signatures;
  final bool isLoading;
  final String? errorMessage;

  bool get hasSignatures => signatures.isNotEmpty;
  int get count => signatures.length;

  SurveySignaturesState copyWith({
    List<SignatureItem>? signatures,
    bool? isLoading,
    String? errorMessage,
  }) => SurveySignaturesState(
      signatures: signatures ?? this.signatures,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
}

/// Provider for survey signatures
final surveySignaturesProvider = StateNotifierProvider.autoDispose
    .family<SurveySignaturesNotifier, SurveySignaturesState, String>(
        (ref, surveyId) {
  final signatureDao = ref.watch(signatureDaoProvider);
  return SurveySignaturesNotifier(
    surveyId: surveyId,
    signatureDao: signatureDao,
  );
});

/// Notifier for managing survey signatures
class SurveySignaturesNotifier extends StateNotifier<SurveySignaturesState> {
  SurveySignaturesNotifier({
    required this.surveyId,
    required this.signatureDao,
  }) : super(const SurveySignaturesState(isLoading: true)) {
    _loadSignatures();
  }

  final String surveyId;
  final SignatureDao signatureDao;

  Future<void> _loadSignatures() async {
    try {
      state = state.copyWith(isLoading: true);

      final data = await signatureDao.getSignaturesBySurvey(surveyId);
      final signatures = data.map(signatureDao.toSignatureItem).toList();

      state = SurveySignaturesState(
        signatures: signatures,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load signatures: $e',
      );
    }
  }

  /// Add a new signature
  Future<SignatureItem?> addSignature({
    required List<SignatureStroke> strokes,
    String? sectionId,
    String? signerName,
    String? signerRole,
    int? width,
    int? height,
  }) async {
    try {
      final id = _uuid.v4();
      final now = DateTime.now();
      final strokesJson = SignatureDao.encodeStrokes(strokes);

      await signatureDao.insertSignature(
        SignaturesCompanion.insert(
          id: id,
          surveyId: surveyId,
          sectionId: Value(sectionId),
          signerName: Value(signerName),
          signerRole: Value(signerRole),
          strokesJson: strokesJson,
          width: Value(width),
          height: Value(height),
          createdAt: now,
        ),
      );

      final signature = SignatureItem(
        id: id,
        surveyId: surveyId,
        sectionId: sectionId,
        signerName: signerName,
        signerRole: signerRole,
        strokes: strokes,
        width: width,
        height: height,
        createdAt: now,
      );

      state = state.copyWith(signatures: [signature, ...state.signatures]);
      return signature;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to save signature: $e');
      return null;
    }
  }

  /// Update signature preview path
  Future<void> updatePreviewPath(String signatureId, String previewPath) async {
    try {
      await signatureDao.updatePreviewPath(signatureId, previewPath);

      state = state.copyWith(
        signatures: state.signatures.map((s) {
          if (s.id == signatureId) {
            return s.copyWith(previewPath: previewPath);
          }
          return s;
        }).toList(),
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update preview: $e');
    }
  }

  /// Update signer info
  Future<void> updateSignerInfo(
    String signatureId,
    String? name,
    String? role,
  ) async {
    try {
      await signatureDao.updateSignerInfo(signatureId, name, role);

      state = state.copyWith(
        signatures: state.signatures.map((s) {
          if (s.id == signatureId) {
            return s.copyWith(signerName: name, signerRole: role);
          }
          return s;
        }).toList(),
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update signer info: $e');
    }
  }

  /// Delete a signature
  Future<void> deleteSignature(String signatureId) async {
    try {
      // Get signature to delete preview file (safely)
      final signature = state.signatures
          .cast<SignatureItem?>()
          .firstWhere((s) => s?.id == signatureId, orElse: () => null);

      // Delete preview file if exists
      if (signature?.previewPath != null) {
        final file = File(signature!.previewPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }

      await signatureDao.deleteSignature(signatureId);

      state = state.copyWith(
        signatures: state.signatures.where((s) => s.id != signatureId).toList(),
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete signature: $e');
    }
  }

  /// Refresh signatures
  Future<void> refresh() async {
    await _loadSignatures();
  }

  /// Clear error
  void clearError() {
    state = state.copyWith();
  }
}

/// Provider for signature count
final signatureCountProvider = FutureProvider.autoDispose
    .family<int, String>((ref, surveyId) async {
  final signatureDao = ref.watch(signatureDaoProvider);
  return signatureDao.getSignatureCount(surveyId);
});

/// Service for generating signature PNG previews
class SignaturePreviewService {
  SignaturePreviewService._();

  static final instance = SignaturePreviewService._();

  Directory? _previewDir;

  /// Initialize preview directory
  Future<void> init() async {
    final appDir = await getApplicationDocumentsDirectory();
    _previewDir = Directory('${appDir.path}/signatures');

    if (!await _previewDir!.exists()) {
      await _previewDir!.create(recursive: true);
    }
  }

  /// Get preview directory
  Directory get previewDir {
    if (_previewDir == null) {
      throw StateError('SignaturePreviewService not initialized. Call init() first.');
    }
    return _previewDir!;
  }

  /// Generate preview path for a signature
  String getPreviewPath(String signatureId) => '${previewDir.path}/sig_$signatureId.png';

  /// Save signature as PNG
  Future<String> savePreview({
    required String signatureId,
    required List<SignatureStroke> strokes,
    required Size canvasSize,
    Color backgroundColor = Colors.white,
    double padding = 20,
  }) async {
    final previewPath = getPreviewPath(signatureId);

    // Create picture recorder
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Draw background
    final bgPaint = Paint()..color = backgroundColor;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height),
      bgPaint,
    );

    // Draw strokes
    for (final stroke in strokes) {
      if (stroke.points.length < 2) continue;

      final paint = Paint()
        ..color = stroke.colorValue
        ..strokeWidth = stroke.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final path = Path();
      path.moveTo(stroke.points.first.x, stroke.points.first.y);

      for (var i = 1; i < stroke.points.length; i++) {
        path.lineTo(stroke.points[i].x, stroke.points[i].y);
      }

      canvas.drawPath(path, paint);
    }

    // Create image
    final picture = recorder.endRecording();
    final image = await picture.toImage(
      canvasSize.width.toInt(),
      canvasSize.height.toInt(),
    );

    // Convert to PNG bytes
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw Exception('Failed to encode signature as PNG');
    }

    // Save to file
    final file = File(previewPath);
    await file.writeAsBytes(byteData.buffer.asUint8List());

    return previewPath;
  }

  /// Delete preview file
  Future<void> deletePreview(String signatureId) async {
    final path = getPreviewPath(signatureId);
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}

/// Provider for signature preview service
final signaturePreviewServiceProvider = Provider<SignaturePreviewService>((ref) => SignaturePreviewService.instance);
