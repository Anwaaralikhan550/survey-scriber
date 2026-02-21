import 'package:drift/drift.dart';

import '../../../shared/domain/entities/survey_section.dart' as entities;
import '../app_database.dart';
import '../tables/survey_sections_table.dart';

part 'survey_sections_dao.g.dart';

@DriftAccessor(tables: [SurveySections])
class SurveySectionsDao extends DatabaseAccessor<AppDatabase>
    with _$SurveySectionsDaoMixin {
  SurveySectionsDao(super.db);

  /// Get all sections for a survey
  Future<List<entities.SurveySection>> getSectionsForSurvey(String surveyId) async {
    final results = await (select(surveySections)
          ..where((s) => s.surveyId.equals(surveyId))
          ..orderBy([(s) => OrderingTerm.asc(s.sectionOrder)]))
        .get();
    return results.map(_mapToSection).toList();
  }

  /// Get section by ID
  Future<entities.SurveySection?> getSectionById(String id) async {
    final result =
        await (select(surveySections)..where((s) => s.id.equals(id)))
            .getSingleOrNull();
    return result != null ? _mapToSection(result) : null;
  }

  /// Insert a new section
  @Deprecated('Legacy V1 table — all new surveys use inspection_v2_screens')
  Future<void> insertSection(entities.SurveySection section) async {
    await into(surveySections).insert(_mapToCompanion(section));
  }

  /// Insert multiple sections
  @Deprecated('Legacy V1 table — all new surveys use inspection_v2_screens')
  Future<void> insertSections(List<entities.SurveySection> sections) async {
    await batch((batch) {
      batch.insertAll(surveySections, sections.map(_mapToCompanion).toList());
    });
  }

  /// Update a section
  @Deprecated('Legacy V1 table — all new surveys use inspection_v2_screens')
  Future<void> updateSection(entities.SurveySection section) async {
    await (update(surveySections)..where((s) => s.id.equals(section.id)))
        .write(_mapToCompanion(section));
  }

  /// Upsert a section (insert or update on conflict).
  /// Used by sync pull to idempotently apply server changes.
  @Deprecated('Legacy V1 table — all new surveys use inspection_v2_screens')
  Future<void> upsertSection(entities.SurveySection section) async {
    await into(surveySections).insertOnConflictUpdate(_mapToCompanion(section));
  }

  /// Mark section as completed
  @Deprecated('Legacy V1 table — all new surveys use inspection_v2_screens')
  Future<void> markSectionCompleted(String sectionId, {required bool isCompleted}) async {
    await (update(surveySections)..where((s) => s.id.equals(sectionId))).write(
      SurveySectionsCompanion(
        isCompleted: Value(isCompleted),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Delete a single section by ID
  Future<void> deleteSection(String id) async {
    await (delete(surveySections)..where((s) => s.id.equals(id))).go();
  }

  /// Delete all sections for a survey
  Future<void> deleteSectionsForSurvey(String surveyId) async {
    await (delete(surveySections)..where((s) => s.surveyId.equals(surveyId)))
        .go();
  }

  /// Get completed sections count for a survey
  Future<int> getCompletedSectionsCount(String surveyId) async {
    final count = surveySections.id.count();
    final query = selectOnly(surveySections)
      ..addColumns([count])
      ..where(surveySections.surveyId.equals(surveyId) &
          surveySections.isCompleted.equals(true),);
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  /// Get total sections count for a survey
  Future<int> getTotalSectionsCount(String surveyId) async {
    final count = surveySections.id.count();
    final query = selectOnly(surveySections)
      ..addColumns([count])
      ..where(surveySections.surveyId.equals(surveyId));
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  /// Map database row to domain entity
  entities.SurveySection _mapToSection(SurveySection row) => entities.SurveySection(
        id: row.id,
        surveyId: row.surveyId,
        sectionType: entities.SectionType.values.firstWhere(
          (t) => t.name == row.sectionType,
          orElse: () => entities.SectionType.notes,
        ),
        title: row.title,
        order: row.sectionOrder,
        isCompleted: row.isCompleted,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );

  /// Map domain entity to database companion
  SurveySectionsCompanion _mapToCompanion(entities.SurveySection section) =>
      SurveySectionsCompanion(
        id: Value(section.id),
        surveyId: Value(section.surveyId),
        sectionType: Value(section.sectionType.name),
        title: Value(section.title),
        sectionOrder: Value(section.order),
        isCompleted: Value(section.isCompleted),
        createdAt: Value(section.createdAt ?? DateTime.now()),
        updatedAt: Value(section.updatedAt),
      );
}
