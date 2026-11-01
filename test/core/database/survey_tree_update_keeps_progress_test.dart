// An app update that changes the inspection tree rebuilds each survey's screen
// rows. 1 Nov 2026: the rebuild used to drop the surveyor's completed ticks,
// edited phrase text and notes, and a placement-only change (tile order) was not
// detected at all, so existing surveys kept the old order.
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/core/database/app_database.dart';
import 'package:survey_scriber/features/property_inspection/data/inspection_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('rebuild after a tree change keeps ticks, phrase edits and notes', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = InspectionRepository(db);
    const survey = 's1';
    const screen = 'activity_outside_property_repair_flashing';

    expect(await repo.ensureSurveyInitialized(survey), isTrue);
    await repo.setScreenCompleted(surveyId: survey, screenId: screen, isCompleted: true);
    await repo.savePhraseOutput(
        surveyId: survey, screenId: screen, phraseJson: '["edited"]', phraseEditedManually: true);
    await repo.saveUserNote(surveyId: survey, screenId: screen, note: 'my note');

    Future<InspectionV2Screen> row() => (db.select(db.inspectionV2Screens)
          ..where((t) => t.surveyId.equals(survey) & t.screenId.equals(screen)))
        .getSingle();
    final correctOrder = (await row()).displayOrder;

    // Simulate a survey created on an older tree: same structure, different placement.
    await (db.update(db.inspectionV2Screens)
          ..where((t) => t.surveyId.equals(survey) & t.screenId.equals(screen)))
        .write(const InspectionV2ScreensCompanion(displayOrder: Value(99999)));

    expect(await repo.ensureSurveyInitialized(survey), isTrue, reason: 'placement change must rebuild');

    final after = await row();
    expect(after.displayOrder, correctOrder);
    expect(after.isCompleted, isTrue);
    expect(after.phraseOutput, '["edited"]');
    expect(after.phraseEditedManually, isTrue);
    expect(after.userNote, 'my note');

    // Unchanged tree: no rebuild.
    expect(await repo.ensureSurveyInitialized(survey), isFalse);
  });
}
