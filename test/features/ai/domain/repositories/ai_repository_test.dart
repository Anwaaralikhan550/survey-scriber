import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/ai/domain/repositories/ai_repository.dart';

void main() {
  group('GenerateReportRequest', () {
    test('toJson includes all required fields', () {
      const request = GenerateReportRequest(
        surveyId: 'survey-123',
        propertyAddress: '123 Main St',
        sections: [
          SectionAnswersInput(
            sectionId: 'section-1',
            sectionType: 'roof',
            title: 'Roof Inspection',
            answers: {'condition': 'good', 'material': 'tiles'},
          ),
        ],
      );

      final json = request.toJson();

      expect(json['surveyId'], 'survey-123');
      expect(json['propertyAddress'], '123 Main St');
      expect(json['sections'], isA<List>());
      expect((json['sections'] as List).length, 1);
      expect(json.containsKey('skipCache'), false);
    });

    test('toJson includes optional fields when provided', () {
      const request = GenerateReportRequest(
        surveyId: 'survey-123',
        propertyAddress: '123 Main St',
        propertyType: 'detached_house',
        sections: [],
        issues: [
          IssueInput(
            id: 'issue-1',
            title: 'Roof damage',
            category: 'structural',
            severity: 'high',
          ),
        ],
        skipCache: true,
      );

      final json = request.toJson();

      expect(json['propertyType'], 'detached_house');
      expect(json['issues'], isA<List>());
      expect(json['skipCache'], true);
    });
  });

  group('SectionAnswersInput', () {
    test('toJson creates correct structure', () {
      const input = SectionAnswersInput(
        sectionId: 'section-1',
        sectionType: 'roof',
        title: 'Roof',
        answers: {
          'condition': 'fair',
          'age': '15 years',
        },
      );

      final json = input.toJson();

      expect(json['sectionId'], 'section-1');
      expect(json['sectionType'], 'roof');
      expect(json['title'], 'Roof');
      expect(json['answers']['condition'], 'fair');
      expect(json['answers']['age'], '15 years');
    });
  });

  group('IssueInput', () {
    test('toJson includes all required fields', () {
      const input = IssueInput(
        id: 'issue-1',
        title: 'Cracked tiles',
      );

      final json = input.toJson();

      expect(json['id'], 'issue-1');
      expect(json['title'], 'Cracked tiles');
      expect(json.containsKey('category'), false);
      expect(json.containsKey('severity'), false);
    });

    test('toJson includes optional fields when provided', () {
      const input = IssueInput(
        id: 'issue-1',
        title: 'Cracked tiles',
        category: 'roofing',
        severity: 'medium',
        location: 'North side',
        description: 'Several tiles have visible cracks',
      );

      final json = input.toJson();

      expect(json['category'], 'roofing');
      expect(json['severity'], 'medium');
      expect(json['location'], 'North side');
      expect(json['description'], 'Several tiles have visible cracks');
    });
  });

  group('GenerateRecommendationsRequest', () {
    test('toJson creates correct structure with issues', () {
      const request = GenerateRecommendationsRequest(
        surveyId: 'survey-123',
        propertyAddress: '456 Oak Ave',
        issues: [
          IssueInput(id: 'issue-1', title: 'Water damage'),
          IssueInput(id: 'issue-2', title: 'Cracked foundation'),
        ],
      );

      final json = request.toJson();

      expect(json['surveyId'], 'survey-123');
      expect(json['propertyAddress'], '456 Oak Ave');
      expect((json['issues'] as List).length, 2);
      expect(json.containsKey('sections'), false);
    });

    test('toJson includes sections when provided', () {
      const request = GenerateRecommendationsRequest(
        surveyId: 'survey-123',
        propertyAddress: '456 Oak Ave',
        sections: [
          SectionAnswersInput(
            sectionId: 's1',
            sectionType: 'roof',
            title: 'Roof',
            answers: {'condition': 'poor'},
          ),
        ],
      );

      final json = request.toJson();

      expect(json['surveyId'], 'survey-123');
      expect(json.containsKey('issues'), false);
      expect((json['sections'] as List).length, 1);
    });

    test('toJson omits issues when empty', () {
      const request = GenerateRecommendationsRequest(
        surveyId: 'survey-123',
        propertyAddress: '456 Oak Ave',
      );

      final json = request.toJson();

      expect(json.containsKey('issues'), false);
    });
  });

  group('GenerateRiskSummaryRequest', () {
    test('toJson creates correct structure', () {
      const request = GenerateRiskSummaryRequest(
        surveyId: 'survey-123',
        propertyAddress: '789 Pine Rd',
        propertyType: 'flat',
        sections: [
          SectionAnswersInput(
            sectionId: 's1',
            sectionType: 'electrical',
            title: 'Electrical',
            answers: {'status': 'needs_attention'},
          ),
        ],
        issues: [
          IssueInput(id: 'i1', title: 'Outdated wiring'),
        ],
      );

      final json = request.toJson();

      expect(json['surveyId'], 'survey-123');
      expect(json['propertyType'], 'flat');
      expect((json['sections'] as List).length, 1);
      expect((json['issues'] as List).length, 1);
    });
  });

  group('ConsistencyCheckRequest', () {
    test('toJson creates correct structure', () {
      const request = ConsistencyCheckRequest(
        surveyId: 'survey-123',
        sections: [
          SectionAnswersInput(
            sectionId: 's1',
            sectionType: 'general',
            title: 'General',
            answers: {'field1': 'value1'},
          ),
        ],
        skipCache: true,
      );

      final json = request.toJson();

      expect(json['surveyId'], 'survey-123');
      expect(json['skipCache'], true);
      expect(json.containsKey('issues'), false);
    });
  });

  group('PhotoTagsRequest', () {
    test('toJson includes all required fields', () {
      const request = PhotoTagsRequest(
        surveyId: 'survey-123',
        photoId: 'photo-456',
        imageData: 'base64encodeddata',
      );

      final json = request.toJson();

      expect(json['surveyId'], 'survey-123');
      expect(json['photoId'], 'photo-456');
      expect(json['imageData'], 'base64encodeddata');
      expect(json.containsKey('existingCaption'), false);
    });

    test('toJson includes optional fields when provided', () {
      const request = PhotoTagsRequest(
        surveyId: 'survey-123',
        photoId: 'photo-456',
        imageData: 'base64data',
        existingCaption: 'Kitchen view',
        sectionContext: 'kitchen_section',
        skipCache: true,
      );

      final json = request.toJson();

      expect(json['existingCaption'], 'Kitchen view');
      expect(json['sectionContext'], 'kitchen_section');
      expect(json['skipCache'], true);
    });
  });
}
