import 'package:drift/drift.dart';

import '../database/app_database.dart';

/// Stores one answer pulled from the backend in the V2 answers table.
///
/// A plain field id ([overwriteLocal] false) comes from before answers carried
/// their screen, and its value may belong to another screen that shares the field
/// id. For a home survey it only fills a gap and never replaces what is here.
Future<void> writePulledV2Answer(
  AppDatabase db, {
  required String surveyId,
  required String screenId,
  required String fieldKey,
  required String value,
  required bool isValuation,
  required DateTime? createdAt,
  required DateTime? updatedAt,
  required bool overwriteLocal,
}) async {
  final prefix = isValuation ? 'val_' : '';
  final id = '${surveyId}_$prefix${screenId}_$fieldKey';

  if (!overwriteLocal && !isValuation) {
    final existing = await (db.select(db.inspectionV2Answers)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if ((existing?.value ?? '').trim().isNotEmpty) return;
  }

  await db.into(db.inspectionV2Answers).insertOnConflictUpdate(
        InspectionV2AnswersCompanion(
          id: Value(id),
          surveyId: Value(surveyId),
          screenId: Value(screenId),
          fieldKey: Value(fieldKey),
          value: Value(value),
          createdAt: Value(createdAt ?? DateTime.now()),
          updatedAt: Value(updatedAt),
        ),
      );
}
