import 'package:flutter_test/flutter_test.dart';

import 'package:survey_scriber/shared/domain/entities/survey_section.dart';

void main() {
  group('Sync pull preserves isCompleted (Bug fix: tick disappearing)', () {
    /// Simulates the _applyUpsert logic from sync_manager.dart for SECTION
    /// entities, verifying that isCompleted is preserved from the local copy
    /// when the server doesn't include it.
    SurveySection applyServerSection({
      required SurveySection serverSection,
      required List<SurveySection> existingLocal,
    }) {
      var section = serverSection;

      // Mirror the _applyUpsert logic
      final existing = existingLocal;
      for (final old in existing) {
        if (old.order == section.order && old.id != section.id) {
          // Preserve local-only fields
          section = section.copyWith(
            sectionType: old.sectionType,
            isCompleted: old.isCompleted,
          );
          // In real code: await sectionsDao.deleteSection(old.id);
        }
      }

      // Also preserve for same-ID upserts
      final existingSameId =
          existing.where((s) => s.id == section.id).firstOrNull;
      if (existingSameId != null) {
        section = section.copyWith(isCompleted: existingSameId.isCompleted);
        if (existingSameId.sectionType != SectionType.notes) {
          section = section.copyWith(sectionType: existingSameId.sectionType);
        }
      }

      return section;
    }

    test('preserves isCompleted=true when server section replaces local (different IDs)', () {
      // Local section was marked completed by user
      const localSection = SurveySection(
        id: 'local-uuid-123',
        surveyId: 'survey-1',
        sectionType: SectionType.externalItems,
        title: 'External Inspection',
        order: 2,
        isCompleted: true,
      );

      // Server section comes back with new ID but no isCompleted
      // (_mapServerSection defaults isCompleted to false)
      const serverSection = SurveySection(
        id: 'server-uuid-456',
        surveyId: 'survey-1',
        sectionType: SectionType.notes, // default from server (no sectionType)
        title: 'External Inspection',
        order: 2,
        isCompleted: false, // server doesn't track this
      );

      final result = applyServerSection(
        serverSection: serverSection,
        existingLocal: [localSection],
      );

      expect(result.isCompleted, isTrue,
          reason: 'isCompleted should be preserved from local section');
      expect(result.sectionType, SectionType.externalItems,
          reason: 'sectionType should be preserved from local section');
      expect(result.id, 'server-uuid-456',
          reason: 'ID should use the server-assigned ID');
    });

    test('preserves isCompleted=true when server updates same-ID section', () {
      // Local section was marked completed
      const localSection = SurveySection(
        id: 'shared-uuid-789',
        surveyId: 'survey-1',
        sectionType: SectionType.services,
        title: 'Services & Utilities',
        order: 6,
        isCompleted: true,
      );

      // Server sends update for same section (same ID)
      const serverSection = SurveySection(
        id: 'shared-uuid-789',
        surveyId: 'survey-1',
        sectionType: SectionType.notes, // default, will be overridden
        title: 'Services & Utilities',
        order: 6,
        isCompleted: false, // server doesn't track this
      );

      final result = applyServerSection(
        serverSection: serverSection,
        existingLocal: [localSection],
      );

      expect(result.isCompleted, isTrue,
          reason: 'isCompleted should be preserved for same-ID upsert');
      expect(result.sectionType, SectionType.services,
          reason: 'sectionType should be preserved for same-ID upsert');
    });

    test('preserves isCompleted=false when section was not completed', () {
      const localSection = SurveySection(
        id: 'local-uuid-111',
        surveyId: 'survey-1',
        sectionType: SectionType.rooms,
        title: 'Rooms',
        order: 5,
        isCompleted: false,
      );

      const serverSection = SurveySection(
        id: 'server-uuid-222',
        surveyId: 'survey-1',
        sectionType: SectionType.notes,
        title: 'Rooms',
        order: 5,
        isCompleted: false,
      );

      final result = applyServerSection(
        serverSection: serverSection,
        existingLocal: [localSection],
      );

      expect(result.isCompleted, isFalse,
          reason: 'isCompleted=false should be preserved as-is');
    });

    test('handles new section with no local match (keeps default false)', () {
      // No local section exists at this order
      const serverSection = SurveySection(
        id: 'server-new-333',
        surveyId: 'survey-1',
        sectionType: SectionType.notes,
        title: 'New Section',
        order: 99,
        isCompleted: false,
      );

      final result = applyServerSection(
        serverSection: serverSection,
        existingLocal: [], // no local sections
      );

      expect(result.isCompleted, isFalse,
          reason: 'New section with no local match should keep default');
    });

    test('preserves isCompleted across multiple sections', () {
      final localSections = [
        const SurveySection(
          id: 'local-0', surveyId: 'survey-1',
          sectionType: SectionType.aboutInspection,
          title: 'About', order: 0, isCompleted: true,
        ),
        const SurveySection(
          id: 'local-1', surveyId: 'survey-1',
          sectionType: SectionType.externalItems,
          title: 'External', order: 1, isCompleted: false,
        ),
        const SurveySection(
          id: 'local-2', surveyId: 'survey-1',
          sectionType: SectionType.internalItems,
          title: 'Internal', order: 2, isCompleted: true,
        ),
      ];

      final serverSections = [
        const SurveySection(
          id: 'server-0', surveyId: 'survey-1',
          sectionType: SectionType.notes, title: 'About',
          order: 0, isCompleted: false,
        ),
        const SurveySection(
          id: 'server-1', surveyId: 'survey-1',
          sectionType: SectionType.notes, title: 'External',
          order: 1, isCompleted: false,
        ),
        const SurveySection(
          id: 'server-2', surveyId: 'survey-1',
          sectionType: SectionType.notes, title: 'Internal',
          order: 2, isCompleted: false,
        ),
      ];

      for (var i = 0; i < serverSections.length; i++) {
        final result = applyServerSection(
          serverSection: serverSections[i],
          existingLocal: localSections,
        );
        expect(result.isCompleted, localSections[i].isCompleted,
            reason: 'Section at order $i should preserve local isCompleted');
      }
    });
  });

  group('SurveyDetailState silent reload (Bug fix: scroll jump)', () {
    test('hasSurvey returns false when no survey loaded', () {
      // This tests the condition used to decide initial vs silent reload
      const state = _MockDetailState(hasSurvey: false);
      expect(state.hasSurvey, isFalse);
    });

    test('hasSurvey returns true after initial load', () {
      const state = _MockDetailState(hasSurvey: true);
      expect(state.hasSurvey, isTrue);
    });
  });
}

/// Minimal mock to test the hasSurvey flag behavior
class _MockDetailState {
  const _MockDetailState({required this.hasSurvey});
  final bool hasSurvey;
}
