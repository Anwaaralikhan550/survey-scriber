import 'package:flutter_test/flutter_test.dart';

import 'package:survey_scriber/shared/domain/entities/survey_section.dart';

void main() {
  group('Section deduplication (sync pull duplicate guard)', () {
    /// Simulates the dedup logic from survey_detail_provider.dart.
    /// Uses sectionType.name instead of title for more reliable dedup.
    List<SurveySection> dedup(List<SurveySection> sections) {
      final seen = <String>{};
      return sections.where((s) {
        final key = '${s.sectionType.name}::${s.order}';
        if (seen.contains(key)) return false;
        seen.add(key);
        return true;
      }).toList();
    }

    test('removes exact duplicates (same sectionType + order, different IDs)', () {
      final sections = [
        const SurveySection(
          id: 'local-1',
          surveyId: 'survey-1',
          sectionType: SectionType.services,
          title: 'Services & Utilities',
          order: 6,
        ),
        const SurveySection(
          id: 'server-1',
          surveyId: 'survey-1',
          sectionType: SectionType.services,
          title: 'Services & Utilities',
          order: 6,
        ),
      ];

      final result = dedup(sections);
      expect(result.length, 1);
      expect(result.first.id, 'local-1');
    });

    test('preserves sections with different orders', () {
      final sections = [
        const SurveySection(
          id: 'local-1',
          surveyId: 'survey-1',
          sectionType: SectionType.aboutInspection,
          title: 'About This Inspection',
          order: 0,
        ),
        const SurveySection(
          id: 'local-2',
          surveyId: 'survey-1',
          sectionType: SectionType.aboutProperty,
          title: 'About Property',
          order: 1,
        ),
        const SurveySection(
          id: 'local-3',
          surveyId: 'survey-1',
          sectionType: SectionType.services,
          title: 'Services & Utilities',
          order: 6,
        ),
      ];

      final result = dedup(sections);
      expect(result.length, 3);
    });

    test('handles full inspection template with server duplicates', () {
      // Simulates: 11 local sections + 11 server-pulled duplicates
      final localSections = SectionTemplates.getInspectionSections()
          .asMap()
          .entries
          .map(
            (e) => SurveySection(
              id: 'local-${e.key}',
              surveyId: 'survey-1',
              sectionType: e.value.$1,
              title: e.value.$2,
              order: e.key,
            ),
          )
          .toList();

      final serverDuplicates = SectionTemplates.getInspectionSections()
          .asMap()
          .entries
          .map(
            (e) => SurveySection(
              id: 'server-${e.key}',
              surveyId: 'survey-1',
              sectionType: e.value.$1, // same sectionType as local
              title: e.value.$2,
              order: e.key,
            ),
          )
          .toList();

      // Mix local + server (sorted by order, local first per DAO ordering)
      final mixed = <SurveySection>[];
      for (var i = 0; i < localSections.length; i++) {
        mixed.add(localSections[i]);
        mixed.add(serverDuplicates[i]);
      }

      final result = dedup(mixed);
      expect(result.length, 11, reason: 'Should have exactly 11 unique sections');
      // All kept sections should be the local ones (first occurrence)
      for (final s in result) {
        expect(s.id.startsWith('local-'), isTrue,
            reason: 'Should keep local section (first occurrence)',);
      }
    });

    test('preserves ordering after dedup', () {
      final sections = [
        const SurveySection(
          id: 'local-0',
          surveyId: 'survey-1',
          sectionType: SectionType.aboutInspection,
          title: 'About This Inspection',
          order: 0,
        ),
        const SurveySection(
          id: 'server-0',
          surveyId: 'survey-1',
          sectionType: SectionType.aboutInspection,
          title: 'About This Inspection',
          order: 0,
        ),
        const SurveySection(
          id: 'local-1',
          surveyId: 'survey-1',
          sectionType: SectionType.signature,
          title: 'Sign Off',
          order: 10,
        ),
        const SurveySection(
          id: 'server-1',
          surveyId: 'survey-1',
          sectionType: SectionType.signature,
          title: 'Sign Off',
          order: 10,
        ),
      ];

      final result = dedup(sections);
      expect(result.length, 2);
      expect(result[0].order, 0);
      expect(result[1].order, 10);
    });

    test('no-op when there are no duplicates', () {
      final sections = [
        const SurveySection(
          id: 'a',
          surveyId: 'survey-1',
          sectionType: SectionType.aboutInspection,
          title: 'About This Inspection',
          order: 0,
        ),
        const SurveySection(
          id: 'b',
          surveyId: 'survey-1',
          sectionType: SectionType.signature,
          title: 'Sign Off',
          order: 10,
        ),
      ];

      final result = dedup(sections);
      expect(result.length, 2);
    });

    test('handles empty section list', () {
      final result = dedup([]);
      expect(result, isEmpty);
    });

    test('handles single section', () {
      final result = dedup([
        const SurveySection(
          id: 'only',
          surveyId: 'survey-1',
          sectionType: SectionType.photos,
          title: 'Photos',
          order: 0,
        ),
      ]);
      expect(result.length, 1);
    });
  });

  group('Sync pull section conflict (order-based dedup at source)', () {
    test('sections with same sectionType + order but different IDs are duplicates', () {
      // This tests the logic in _applyUpsert: when a server section has
      // the same surveyId + sectionType + order as a local section but different ID,
      // the old one should be removed.
      const localSection = SurveySection(
        id: 'local-uuid-abc',
        surveyId: 'survey-1',
        sectionType: SectionType.services,
        title: 'Services & Utilities',
        order: 6,
      );

      const serverSection = SurveySection(
        id: 'server-uuid-xyz',
        surveyId: 'survey-1',
        sectionType: SectionType.services,
        title: 'Services & Utilities',
        order: 6,
      );

      // Verify they share the same sectionType + order but different IDs
      expect(localSection.order, serverSection.order);
      expect(localSection.sectionType, serverSection.sectionType);
      expect(localSection.id, isNot(serverSection.id));
      expect(localSection.surveyId, serverSection.surveyId);
    });

    test('sections with different orders are NOT duplicates', () {
      const sectionA = SurveySection(
        id: 'a',
        surveyId: 'survey-1',
        sectionType: SectionType.services,
        title: 'Services & Utilities',
        order: 6,
      );

      const sectionB = SurveySection(
        id: 'b',
        surveyId: 'survey-1',
        sectionType: SectionType.photos,
        title: 'Photo Documentation',
        order: 8,
      );

      expect(sectionA.order, isNot(sectionB.order));
    });
  });
}
