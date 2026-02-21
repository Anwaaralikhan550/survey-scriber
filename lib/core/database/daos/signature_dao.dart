import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../features/signature/domain/entities/signature_item.dart';
import '../app_database.dart';
import '../tables/signatures_table.dart';

part 'signature_dao.g.dart';

@DriftAccessor(tables: [Signatures])
class SignatureDao extends DatabaseAccessor<AppDatabase> with _$SignatureDaoMixin {
  SignatureDao(super.db);

  // ============= Query Operations =============

  /// Get all signatures for a survey
  Future<List<SignatureData>> getSignaturesBySurvey(String surveyId) => (select(signatures)
          ..where((t) => t.surveyId.equals(surveyId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();

  /// Get all signatures for a section
  Future<List<SignatureData>> getSignaturesBySection(String sectionId) => (select(signatures)
          ..where((t) => t.sectionId.equals(sectionId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();

  /// Get a single signature by ID
  Future<SignatureData?> getSignatureById(String id) => (select(signatures)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Get signature count for a survey
  Future<int> getSignatureCount(String surveyId) async {
    final count = signatures.id.count();
    final query = selectOnly(signatures)
      ..addColumns([count])
      ..where(signatures.surveyId.equals(surveyId));
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  /// Watch signatures for a survey
  Stream<List<SignatureData>> watchSignaturesBySurvey(String surveyId) => (select(signatures)
          ..where((t) => t.surveyId.equals(surveyId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();

  // ============= Insert/Update Operations =============

  /// Insert a new signature
  Future<int> insertSignature(SignaturesCompanion signature) => into(signatures).insert(signature);

  /// Update a signature
  Future<bool> updateSignature(SignaturesCompanion signature) => (update(signatures)..where((t) => t.id.equals(signature.id.value)))
        .write(signature)
        .then((rows) => rows > 0);

  /// Update signature signer info
  Future<void> updateSignerInfo(String id, String? name, String? role) => (update(signatures)..where((t) => t.id.equals(id))).write(
      SignaturesCompanion(
        signerName: Value(name),
        signerRole: Value(role),
        updatedAt: Value(DateTime.now()),
      ),
    );

  /// Update signature preview path
  Future<void> updatePreviewPath(String id, String previewPath) => (update(signatures)..where((t) => t.id.equals(id))).write(
      SignaturesCompanion(
        previewPath: Value(previewPath),
        updatedAt: Value(DateTime.now()),
      ),
    );

  /// Update signature status
  Future<void> updateStatus(String id, SignatureStatus status) => (update(signatures)..where((t) => t.id.equals(id))).write(
      SignaturesCompanion(
        status: Value(status.name),
        updatedAt: Value(DateTime.now()),
      ),
    );

  // ============= Delete Operations =============

  /// Delete a signature
  Future<int> deleteSignature(String id) => (delete(signatures)..where((t) => t.id.equals(id))).go();

  /// Delete all signatures for a survey
  Future<int> deleteSignaturesBySurvey(String surveyId) => (delete(signatures)..where((t) => t.surveyId.equals(surveyId))).go();

  /// Delete all signatures for a section
  Future<int> deleteSignaturesBySection(String sectionId) => (delete(signatures)..where((t) => t.sectionId.equals(sectionId))).go();

  // ============= Conversion Helpers =============

  /// Convert database row to SignatureItem domain entity
  SignatureItem toSignatureItem(SignatureData data) {
    final strokes = _parseStrokes(data.strokesJson);

    return SignatureItem(
      id: data.id,
      surveyId: data.surveyId,
      sectionId: data.sectionId,
      signerName: data.signerName,
      signerRole: data.signerRole,
      strokes: strokes,
      status: SignatureStatus.values.firstWhere(
        (s) => s.name == data.status,
        orElse: () => SignatureStatus.local,
      ),
      previewPath: data.previewPath,
      width: data.width,
      height: data.height,
      createdAt: data.createdAt,
    );
  }

  /// Parse strokes from JSON string
  List<SignatureStroke> _parseStrokes(String strokesJson) {
    try {
      final list = jsonDecode(strokesJson) as List;
      return list
          .map((e) => SignatureStroke.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Encode strokes to JSON string
  static String encodeStrokes(List<SignatureStroke> strokes) => jsonEncode(strokes.map((s) => s.toJson()).toList());
}
