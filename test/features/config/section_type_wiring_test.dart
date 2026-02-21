import 'package:flutter_test/flutter_test.dart';

import 'package:survey_scriber/shared/domain/entities/survey_section.dart';

void main() {
  group('Section dedup uses sectionType.name (not title)', () {
    /// Mirrors the updated dedup logic from survey_detail_provider.dart:
    /// key = '${s.sectionType.name}::${s.order}'
    List<SurveySection> dedupBySectionType(List<SurveySection> sections) {
      final seen = <String>{};
      return sections.where((s) {
        final key = '${s.sectionType.name}::${s.order}';
        if (seen.contains(key)) return false;
        seen.add(key);
        return true;
      }).toList();
    }

    test('same sectionType + order = duplicate, regardless of title', () {
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
          title: 'Services',
          order: 6,
        ),
      ];

      final result = dedupBySectionType(sections);
      expect(result.length, 1);
      expect(result.first.id, 'local-1');
    });

    test('different sectionType + same order = NOT duplicate', () {
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
          sectionType: SectionType.notes,
          title: 'Services & Utilities',
          order: 6,
        ),
      ];

      final result = dedupBySectionType(sections);
      expect(result.length, 2);
    });

    test('same sectionType + different order = NOT duplicate', () {
      final sections = [
        const SurveySection(
          id: 'a',
          surveyId: 'survey-1',
          sectionType: SectionType.photos,
          title: 'Photos',
          order: 5,
        ),
        const SurveySection(
          id: 'b',
          surveyId: 'survey-1',
          sectionType: SectionType.photos,
          title: 'Photos',
          order: 10,
        ),
      ];

      final result = dedupBySectionType(sections);
      expect(result.length, 2);
    });

    test('title variation does not bypass dedup when sectionType matches', () {
      // This is the key regression the fix addresses: sync can create
      // sections with the same sectionType but slightly different titles.
      // Old dedup used title, so they wouldn't be caught.
      final sections = [
        const SurveySection(
          id: 'local-1',
          surveyId: 'survey-1',
          sectionType: SectionType.aboutProperty,
          title: 'About Property',
          order: 1,
        ),
        const SurveySection(
          id: 'server-1',
          surveyId: 'survey-1',
          sectionType: SectionType.aboutProperty,
          title: 'About the Property',
          order: 1,
        ),
      ];

      final result = dedupBySectionType(sections);
      expect(result.length, 1,
          reason: 'Same sectionType+order should dedup despite different titles',);
      expect(result.first.id, 'local-1');
    });

    test('handles full inspection template with server duplicates', () {
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

      // Server duplicates with same sectionType but possibly different titles
      final serverDuplicates = SectionTemplates.getInspectionSections()
          .asMap()
          .entries
          .map(
            (e) => SurveySection(
              id: 'server-${e.key}',
              surveyId: 'survey-1',
              sectionType: e.value.$1,
              title: '${e.value.$2} (synced)',
              order: e.key,
            ),
          )
          .toList();

      final mixed = <SurveySection>[];
      for (var i = 0; i < localSections.length; i++) {
        mixed.add(localSections[i]);
        mixed.add(serverDuplicates[i]);
      }

      final result = dedupBySectionType(mixed);
      expect(result.length, localSections.length);
      for (final s in result) {
        expect(s.id.startsWith('local-'), isTrue,
            reason: 'Should keep local section (first occurrence)',);
      }
    });

    test('empty list returns empty', () {
      expect(dedupBySectionType([]), isEmpty);
    });

    test('single section returns as-is', () {
      final result = dedupBySectionType([
        const SurveySection(
          id: 'only',
          surveyId: 'survey-1',
          sectionType: SectionType.signature,
          title: 'Sign Off',
          order: 0,
        ),
      ]);
      expect(result.length, 1);
    });
  });
}
