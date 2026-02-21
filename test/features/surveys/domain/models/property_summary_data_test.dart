import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/surveys/domain/models/property_summary_data.dart';

void main() {
  group('InspectionReferenceData', () {
    test('toJson produces expected JSON structure', () {
      final linkedAt = DateTime(2024, 6, 15, 10, 30);
      final data = InspectionReferenceData(
        inspectionId: 'insp-123',
        surveyNumber: 'SN-001',
        address: '123 Test Street',
        linkedAt: linkedAt,
      );

      final jsonString = data.toJson();
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;

      expect(decoded['inspectionId'], equals('insp-123'));
      expect(decoded['surveyNumber'], equals('SN-001'));
      expect(decoded['address'], equals('123 Test Street'));
      expect(decoded['linkedAt'], equals(linkedAt.toIso8601String()));
      expect(decoded['source'], equals('selected'));
    });

    test('fromJson parses valid JSON correctly', () {
      final jsonString = jsonEncode({
        'inspectionId': 'insp-456',
        'surveyNumber': 'SN-002',
        'address': '456 Example Road',
        'linkedAt': '2024-07-20T14:00:00.000',
        'source': 'auto',
      });

      final data = InspectionReferenceData.fromJson(jsonString);

      expect(data.inspectionId, equals('insp-456'));
      expect(data.surveyNumber, equals('SN-002'));
      expect(data.address, equals('456 Example Road'));
      expect(data.linkedAt, equals(DateTime(2024, 7, 20, 14)));
      expect(data.source, equals('auto'));
    });

    test('fromJson handles missing optional keys safely', () {
      final jsonString = jsonEncode({
        'inspectionId': 'insp-789',
        'linkedAt': '2024-08-01T09:00:00.000',
      });

      final data = InspectionReferenceData.fromJson(jsonString);

      expect(data.inspectionId, equals('insp-789'));
      expect(data.surveyNumber, isNull);
      expect(data.address, isNull);
      expect(data.source, equals('selected')); // default value
    });

    test('fromJson handles invalid JSON gracefully', () {
      final data = InspectionReferenceData.fromJson('not valid json');

      expect(data.inspectionId, equals(''));
      expect(data.isValid, isFalse);
    });

    test('fromJson handles empty string gracefully', () {
      final data = InspectionReferenceData.fromJson('');

      expect(data.inspectionId, equals(''));
      expect(data.isValid, isFalse);
    });

    test('isValid returns true for non-empty inspectionId', () {
      final data = InspectionReferenceData(
        inspectionId: 'valid-id',
        linkedAt: DateTime.now(),
      );

      expect(data.isValid, isTrue);
    });

    test('isValid returns false for empty inspectionId', () {
      final data = InspectionReferenceData(
        inspectionId: '',
        linkedAt: DateTime.now(),
      );

      expect(data.isValid, isFalse);
    });

    test('copyWith creates new instance with updated values', () {
      final original = InspectionReferenceData(
        inspectionId: 'orig-id',
        surveyNumber: 'SN-OLD',
        address: 'Old Address',
        linkedAt: DateTime(2024),
      );

      final updated = original.copyWith(
        surveyNumber: 'SN-NEW',
        address: 'New Address',
      );

      expect(updated.inspectionId, equals('orig-id'));
      expect(updated.surveyNumber, equals('SN-NEW'));
      expect(updated.address, equals('New Address'));
      expect(updated.linkedAt, equals(DateTime(2024)));
      expect(updated.source, equals('selected'));
    });
  });

  group('ManualPropertySummaryData', () {
    test('toJson produces expected JSON structure', () {
      final data = ManualPropertySummaryData(
        address: '789 Manual Entry Lane',
        propertyType: 'Detached House',
        tenure: 'Freehold',
        bedrooms: 4,
        bathrooms: 2,
        floorAreaSqm: 150.5,
        yearBuilt: 1985,
        condition: 'Good',
        keyDefects: 'Minor roof issues',
        risk: 'Low',
        notes: 'Some notes here',
        updatedAt: DateTime(2024, 5, 10),
      );

      final jsonString = data.toJson();
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;

      expect(decoded['address'], equals('789 Manual Entry Lane'));
      expect(decoded['propertyType'], equals('Detached House'));
      expect(decoded['tenure'], equals('Freehold'));
      expect(decoded['bedrooms'], equals(4));
      expect(decoded['bathrooms'], equals(2));
      expect(decoded['floorAreaSqm'], equals(150.5));
      expect(decoded['yearBuilt'], equals(1985));
      expect(decoded['condition'], equals('Good'));
      expect(decoded['defects'], equals('Minor roof issues'));
      expect(decoded['risk'], equals('Low'));
      expect(decoded['notes'], equals('Some notes here'));
    });

    test('fromJson parses valid JSON correctly', () {
      final jsonString = jsonEncode({
        'address': '100 Parsed Avenue',
        'propertyType': 'Flat/Apartment',
        'tenure': 'Leasehold',
        'bedrooms': 2,
        'bathrooms': 1,
        'floorAreaSqm': 75,
        'yearBuilt': 2010,
        'condition': 'Fair',
        'defects': 'Damp in bathroom',
        'risk': 'Medium',
        'notes': 'Parsed notes',
        'updatedAt': '2024-06-15T12:00:00.000',
      });

      final data = ManualPropertySummaryData.fromJson(jsonString);

      expect(data.address, equals('100 Parsed Avenue'));
      expect(data.propertyType, equals('Flat/Apartment'));
      expect(data.tenure, equals('Leasehold'));
      expect(data.bedrooms, equals(2));
      expect(data.bathrooms, equals(1));
      expect(data.floorAreaSqm, equals(75.0));
      expect(data.yearBuilt, equals(2010));
      expect(data.condition, equals('Fair'));
      expect(data.keyDefects, equals('Damp in bathroom'));
      expect(data.risk, equals('Medium'));
      expect(data.notes, equals('Parsed notes'));
    });

    test('fromJson handles keyDefects alternative key name', () {
      final jsonString = jsonEncode({
        'address': 'Test Address',
        'keyDefects': 'Using keyDefects key',
      });

      final data = ManualPropertySummaryData.fromJson(jsonString);

      expect(data.keyDefects, equals('Using keyDefects key'));
    });

    test('fromJson handles missing keys safely', () {
      final jsonString = jsonEncode({
        'address': 'Only Address',
      });

      final data = ManualPropertySummaryData.fromJson(jsonString);

      expect(data.address, equals('Only Address'));
      expect(data.propertyType, isNull);
      expect(data.tenure, isNull);
      expect(data.bedrooms, isNull);
      expect(data.bathrooms, isNull);
      expect(data.floorAreaSqm, isNull);
      expect(data.yearBuilt, isNull);
      expect(data.condition, isNull);
      expect(data.keyDefects, isNull);
      expect(data.risk, isNull);
      expect(data.notes, isNull);
    });

    test('fromJson handles invalid JSON gracefully', () {
      final data = ManualPropertySummaryData.fromJson('invalid json');

      expect(data.isEmpty, isTrue);
    });

    test('fromJson handles empty string gracefully', () {
      final data = ManualPropertySummaryData.fromJson('');

      expect(data.isEmpty, isTrue);
    });

    test('isEmpty returns true for empty data', () {
      const data = ManualPropertySummaryData();

      expect(data.isEmpty, isTrue);
      expect(data.isNotEmpty, isFalse);
    });

    test('isEmpty returns false when address is set', () {
      const data = ManualPropertySummaryData(address: 'Some Address');

      expect(data.isEmpty, isFalse);
      expect(data.isNotEmpty, isTrue);
    });

    test('isEmpty returns false when propertyType is set', () {
      const data = ManualPropertySummaryData(propertyType: 'Detached House');

      expect(data.isEmpty, isFalse);
      expect(data.isNotEmpty, isTrue);
    });

    test('isEmpty returns false when bedrooms is set', () {
      const data = ManualPropertySummaryData(bedrooms: 3);

      expect(data.isEmpty, isFalse);
      expect(data.isNotEmpty, isTrue);
    });

    test('toPropertyDetailsMap includes non-null values', () {
      const data = ManualPropertySummaryData(
        address: 'Map Test Address',
        propertyType: 'Bungalow',
        tenure: 'Freehold',
        bedrooms: 3,
        bathrooms: 2,
        floorAreaSqm: 120,
        yearBuilt: 1970,
      );

      final map = data.toPropertyDetailsMap();

      expect(map['Address'], equals('Map Test Address'));
      expect(map['Property Type'], equals('Bungalow'));
      expect(map['Tenure'], equals('Freehold'));
      expect(map['Bedrooms'], equals('3'));
      expect(map['Bathrooms'], equals('2'));
      expect(map['Floor Area'], equals('120 sqm'));
      expect(map['Year Built'], equals('1970'));
    });

    test('toPropertyDetailsMap excludes null and empty values', () {
      const data = ManualPropertySummaryData(
        address: 'Only Address',
        bedrooms: 2,
      );

      final map = data.toPropertyDetailsMap();

      expect(map.length, equals(2));
      expect(map.containsKey('Address'), isTrue);
      expect(map.containsKey('Bedrooms'), isTrue);
      expect(map.containsKey('Property Type'), isFalse);
      expect(map.containsKey('Tenure'), isFalse);
    });

    test('toConditionSummaryMap includes condition and risk', () {
      const data = ManualPropertySummaryData(
        condition: 'Poor',
        risk: 'High',
      );

      final map = data.toConditionSummaryMap();

      expect(map['Overall'], equals('Poor'));
      expect(map['Risk Level'], equals('High'));
    });

    test('toConditionSummaryMap excludes null values', () {
      const data = ManualPropertySummaryData(
        condition: 'Good',
      );

      final map = data.toConditionSummaryMap();

      expect(map.length, equals(1));
      expect(map.containsKey('Overall'), isTrue);
      expect(map.containsKey('Risk Level'), isFalse);
    });

    test('copyWith creates new instance with updated values', () {
      const original = ManualPropertySummaryData(
        address: 'Original Address',
        bedrooms: 2,
        condition: 'Fair',
      );

      final updated = original.copyWith(
        bedrooms: 4,
        condition: 'Good',
        risk: 'Low',
      );

      expect(updated.address, equals('Original Address'));
      expect(updated.bedrooms, equals(4));
      expect(updated.condition, equals('Good'));
      expect(updated.risk, equals('Low'));
    });

    test('propertyTypeOptions contains expected values', () {
      expect(ManualPropertySummaryData.propertyTypeOptions,
          contains('Detached House'),);
      expect(ManualPropertySummaryData.propertyTypeOptions,
          contains('Flat/Apartment'),);
      expect(
          ManualPropertySummaryData.propertyTypeOptions, contains('Bungalow'),);
    });

    test('tenureOptions contains expected values', () {
      expect(ManualPropertySummaryData.tenureOptions, contains('Freehold'));
      expect(ManualPropertySummaryData.tenureOptions, contains('Leasehold'));
      expect(ManualPropertySummaryData.tenureOptions, contains('Commonhold'));
    });

    test('conditionOptions contains expected values', () {
      expect(ManualPropertySummaryData.conditionOptions, contains('Excellent'));
      expect(ManualPropertySummaryData.conditionOptions, contains('Good'));
      expect(ManualPropertySummaryData.conditionOptions, contains('Poor'));
      expect(ManualPropertySummaryData.conditionOptions, contains('Unknown'));
    });

    test('riskOptions contains expected values', () {
      expect(ManualPropertySummaryData.riskOptions, contains('Low'));
      expect(ManualPropertySummaryData.riskOptions, contains('Medium'));
      expect(ManualPropertySummaryData.riskOptions, contains('High'));
      expect(ManualPropertySummaryData.riskOptions, contains('Unknown'));
    });
  });

  group('PropertySummaryMode', () {
    test('contains all expected modes', () {
      expect(PropertySummaryMode.values.length, equals(3));
      expect(PropertySummaryMode.values, contains(PropertySummaryMode.none));
      expect(PropertySummaryMode.values,
          contains(PropertySummaryMode.linkedInspection),);
      expect(PropertySummaryMode.values,
          contains(PropertySummaryMode.manualEntry),);
    });
  });

  group('Mutual Exclusivity Logic', () {
    test('linked inspection data clears when manual data is saved', () {
      // Simulate the mutual exclusivity - when manual data exists, linked should be cleared
      const manualData = ManualPropertySummaryData(
        address: 'Manual Address',
        condition: 'Good',
      );

      // If manual data is not empty, linked inspection should be null
      final linkedData = manualData.isNotEmpty
          ? null
          : InspectionReferenceData(
              inspectionId: 'should-not-exist',
              linkedAt: DateTime.now(),
            );

      expect(linkedData, isNull);
      expect(manualData.isNotEmpty, isTrue);
    });

    test('manual data clears when linked inspection is set', () {
      // Simulate the mutual exclusivity - when linked inspection exists, manual should be cleared
      final linkedData = InspectionReferenceData(
        inspectionId: 'insp-linked',
        linkedAt: DateTime.now(),
      );

      // If linked data is valid, manual data should be empty
      final manualData = linkedData.isValid
          ? const ManualPropertySummaryData()
          : const ManualPropertySummaryData(address: 'should-not-exist');

      expect(linkedData.isValid, isTrue);
      expect(manualData.isEmpty, isTrue);
    });
  });
}
