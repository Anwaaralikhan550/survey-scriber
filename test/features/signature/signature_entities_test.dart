import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/signature/domain/entities/signature_item.dart';

void main() {
  group('SignaturePoint', () {
    test('creates with required parameters', () {
      const point = SignaturePoint(x: 10, y: 20);

      expect(point.x, equals(10.0));
      expect(point.y, equals(20.0));
      expect(point.pressure, equals(1.0));
      expect(point.timestamp, isNull);
    });

    test('creates with all parameters', () {
      const point = SignaturePoint(
        x: 10,
        y: 20,
        pressure: 0.5,
        timestamp: 100,
      );

      expect(point.x, equals(10.0));
      expect(point.y, equals(20.0));
      expect(point.pressure, equals(0.5));
      expect(point.timestamp, equals(100));
    });

    test('converts to Offset correctly', () {
      const point = SignaturePoint(x: 15, y: 25);
      final offset = point.toOffset();

      expect(offset, equals(const Offset(15, 25)));
    });

    test('creates from Offset', () {
      final point = SignaturePoint.fromOffset(
        const Offset(30, 40),
        pressure: 0.8,
        timestamp: 200,
      );

      expect(point.x, equals(30.0));
      expect(point.y, equals(40.0));
      expect(point.pressure, equals(0.8));
      expect(point.timestamp, equals(200));
    });

    group('JSON serialization', () {
      test('toJson includes all fields', () {
        const point = SignaturePoint(
          x: 10,
          y: 20,
          pressure: 0.5,
          timestamp: 100,
        );

        final json = point.toJson();

        expect(json['x'], equals(10.0));
        expect(json['y'], equals(20.0));
        expect(json['pressure'], equals(0.5));
        expect(json['timestamp'], equals(100));
      });

      test('toJson omits null timestamp', () {
        const point = SignaturePoint(x: 10, y: 20);
        final json = point.toJson();

        expect(json.containsKey('timestamp'), isFalse);
      });

      test('fromJson parses all fields', () {
        final json = {
          'x': 15.0,
          'y': 25.0,
          'pressure': 0.7,
          'timestamp': 150,
        };

        final point = SignaturePoint.fromJson(json);

        expect(point.x, equals(15.0));
        expect(point.y, equals(25.0));
        expect(point.pressure, equals(0.7));
        expect(point.timestamp, equals(150));
      });

      test('fromJson handles missing optional fields', () {
        final json = {'x': 10, 'y': 20};

        final point = SignaturePoint.fromJson(json);

        expect(point.x, equals(10.0));
        expect(point.y, equals(20.0));
        expect(point.pressure, equals(1.0));
        expect(point.timestamp, isNull);
      });

      test('fromJson handles integer values', () {
        final json = {'x': 10, 'y': 20, 'pressure': 1};

        final point = SignaturePoint.fromJson(json);

        expect(point.x, equals(10.0));
        expect(point.y, equals(20.0));
        expect(point.pressure, equals(1.0));
      });

      test('roundtrip serialization preserves data', () {
        const original = SignaturePoint(
          x: 123.456,
          y: 789.012,
          pressure: 0.42,
          timestamp: 999,
        );

        final json = original.toJson();
        final restored = SignaturePoint.fromJson(json);

        expect(restored, equals(original));
      });
    });

    test('equality works correctly', () {
      const point1 = SignaturePoint(x: 10, y: 20, pressure: 0.5);
      const point2 = SignaturePoint(x: 10, y: 20, pressure: 0.5);
      const point3 = SignaturePoint(x: 10, y: 20, pressure: 0.6);

      expect(point1, equals(point2));
      expect(point1, isNot(equals(point3)));
    });
  });

  group('SignatureStroke', () {
    test('creates with required parameters', () {
      const stroke = SignatureStroke(
        points: [
          SignaturePoint(x: 0, y: 0),
          SignaturePoint(x: 10, y: 10),
        ],
      );

      expect(stroke.points.length, equals(2));
      expect(stroke.color, equals(0xFF000000));
      expect(stroke.strokeWidth, equals(2.5));
    });

    test('creates with custom color and width', () {
      const stroke = SignatureStroke(
        points: [SignaturePoint(x: 0, y: 0)],
        color: 0xFFFF0000,
        strokeWidth: 5,
      );

      expect(stroke.color, equals(0xFFFF0000));
      expect(stroke.strokeWidth, equals(5.0));
      expect(stroke.colorValue, equals(const Color(0xFFFF0000)));
    });

    test('isEmpty returns true for empty points', () {
      const stroke = SignatureStroke(points: []);
      expect(stroke.isEmpty, isTrue);
      expect(stroke.isNotEmpty, isFalse);
    });

    test('isNotEmpty returns true for non-empty points', () {
      const stroke = SignatureStroke(
        points: [SignaturePoint(x: 0, y: 0)],
      );
      expect(stroke.isEmpty, isFalse);
      expect(stroke.isNotEmpty, isTrue);
    });

    group('bounds calculation', () {
      test('returns zero rect for empty stroke', () {
        const stroke = SignatureStroke(points: []);
        expect(stroke.bounds, equals(Rect.zero));
      });

      test('calculates correct bounds for single point', () {
        const stroke = SignatureStroke(
          points: [SignaturePoint(x: 50, y: 100)],
        );

        expect(stroke.bounds, equals(const Rect.fromLTRB(50, 100, 50, 100)));
      });

      test('calculates correct bounds for multiple points', () {
        const stroke = SignatureStroke(
          points: [
            SignaturePoint(x: 10, y: 20),
            SignaturePoint(x: 50, y: 10),
            SignaturePoint(x: 30, y: 80),
            SignaturePoint(x: 5, y: 40),
          ],
        );

        expect(stroke.bounds, equals(const Rect.fromLTRB(5, 10, 50, 80)));
      });
    });

    test('copyWith creates new instance with updated values', () {
      const original = SignatureStroke(
        points: [SignaturePoint(x: 0, y: 0)],
      );

      final copied = original.copyWith(
        color: 0xFFFF0000,
        strokeWidth: 5,
      );

      expect(copied.color, equals(0xFFFF0000));
      expect(copied.strokeWidth, equals(5.0));
      expect(copied.points, equals(original.points));
    });

    group('JSON serialization', () {
      test('toJson includes all fields', () {
        const stroke = SignatureStroke(
          points: [
            SignaturePoint(x: 10, y: 20),
            SignaturePoint(x: 30, y: 40),
          ],
          color: 0xFFFF0000,
          strokeWidth: 3,
        );

        final json = stroke.toJson();

        expect(json['color'], equals(0xFFFF0000));
        expect(json['strokeWidth'], equals(3.0));
        expect(json['points'], isA<List>());
        expect((json['points'] as List).length, equals(2));
      });

      test('fromJson parses all fields', () {
        final json = {
          'points': [
            {'x': 10.0, 'y': 20.0},
            {'x': 30.0, 'y': 40.0},
          ],
          'color': 0xFF00FF00,
          'strokeWidth': 4.0,
        };

        final stroke = SignatureStroke.fromJson(json);

        expect(stroke.points.length, equals(2));
        expect(stroke.color, equals(0xFF00FF00));
        expect(stroke.strokeWidth, equals(4.0));
      });

      test('fromJson handles missing optional fields', () {
        final json = {
          'points': [
            {'x': 10.0, 'y': 20.0},
          ],
        };

        final stroke = SignatureStroke.fromJson(json);

        expect(stroke.color, equals(0xFF000000));
        expect(stroke.strokeWidth, equals(2.5));
      });

      test('roundtrip serialization preserves data', () {
        const original = SignatureStroke(
          points: [
            SignaturePoint(x: 10, y: 20, pressure: 0.5),
            SignaturePoint(x: 30, y: 40, pressure: 0.8),
          ],
          color: 0xFF123456,
          strokeWidth: 3.5,
        );

        final json = original.toJson();
        final restored = SignatureStroke.fromJson(json);

        expect(restored.points.length, equals(original.points.length));
        expect(restored.color, equals(original.color));
        expect(restored.strokeWidth, equals(original.strokeWidth));
      });
    });
  });

  group('SignatureItem', () {
    final testDate = DateTime(2024, 1, 15, 10, 30);

    SignatureItem createTestSignature({
      List<SignatureStroke>? strokes,
      String? signerName,
      String? signerRole,
      String? previewPath,
    }) => SignatureItem(
        id: 'sig-123',
        surveyId: 'survey-456',
        sectionId: 'section-789',
        createdAt: testDate,
        strokes: strokes ??
            [
              const SignatureStroke(
                points: [
                  SignaturePoint(x: 0, y: 0),
                  SignaturePoint(x: 100, y: 50),
                ],
              ),
            ],
        signerName: signerName,
        signerRole: signerRole,
        previewPath: previewPath,
      );

    test('creates with required parameters', () {
      final signature = SignatureItem(
        id: 'test-id',
        surveyId: 'survey-id',
        createdAt: testDate,
        strokes: const [],
      );

      expect(signature.id, equals('test-id'));
      expect(signature.surveyId, equals('survey-id'));
      expect(signature.sectionId, isNull);
      expect(signature.signerName, isNull);
      expect(signature.signerRole, isNull);
      expect(signature.status, equals(SignatureStatus.local));
      expect(signature.previewPath, isNull);
    });

    test('isEmpty returns true for empty strokes', () {
      final signature = createTestSignature(strokes: const []);
      expect(signature.isEmpty, isTrue);
      expect(signature.isNotEmpty, isFalse);
    });

    test('isEmpty returns true for strokes with no points', () {
      final signature = createTestSignature(
        strokes: const [SignatureStroke(points: [])],
      );
      expect(signature.isEmpty, isTrue);
    });

    test('isNotEmpty returns true for strokes with points', () {
      final signature = createTestSignature();
      expect(signature.isEmpty, isFalse);
      expect(signature.isNotEmpty, isTrue);
    });

    test('hasSignerInfo returns false when no signer info', () {
      final signature = createTestSignature();
      expect(signature.hasSignerInfo, isFalse);
    });

    test('hasSignerInfo returns true when signerName is set', () {
      final signature = createTestSignature(signerName: 'John Doe');
      expect(signature.hasSignerInfo, isTrue);
    });

    test('hasSignerInfo returns true when signerRole is set', () {
      final signature = createTestSignature(signerRole: 'Client');
      expect(signature.hasSignerInfo, isTrue);
    });

    test('hasPreview returns correct value', () {
      final withoutPreview = createTestSignature();
      final withPreview = createTestSignature(previewPath: '/path/to/preview.png');

      expect(withoutPreview.hasPreview, isFalse);
      expect(withPreview.hasPreview, isTrue);
    });

    test('totalPoints counts all points across strokes', () {
      final signature = SignatureItem(
        id: 'test',
        surveyId: 'survey',
        createdAt: testDate,
        strokes: const [
          SignatureStroke(
            points: [
              SignaturePoint(x: 0, y: 0),
              SignaturePoint(x: 10, y: 10),
            ],
          ),
          SignatureStroke(
            points: [
              SignaturePoint(x: 20, y: 20),
              SignaturePoint(x: 30, y: 30),
              SignaturePoint(x: 40, y: 40),
            ],
          ),
        ],
      );

      expect(signature.totalPoints, equals(5));
    });

    test('bounds calculates correct bounding box', () {
      final signature = SignatureItem(
        id: 'test',
        surveyId: 'survey',
        createdAt: testDate,
        strokes: const [
          SignatureStroke(
            points: [
              SignaturePoint(x: 10, y: 20),
              SignaturePoint(x: 50, y: 60),
            ],
          ),
          SignatureStroke(
            points: [
              SignaturePoint(x: 5, y: 30),
              SignaturePoint(x: 80, y: 10),
            ],
          ),
        ],
      );

      expect(signature.bounds, equals(const Rect.fromLTRB(5, 10, 80, 60)));
    });

    test('bounds returns zero for empty signature', () {
      final signature = createTestSignature(strokes: const []);
      expect(signature.bounds, equals(Rect.zero));
    });

    test('copyWith creates new instance with updated values', () {
      final original = createTestSignature(signerName: 'John');

      final copied = original.copyWith(
        signerName: 'Jane',
        signerRole: 'Witness',
        status: SignatureStatus.synced,
      );

      expect(copied.signerName, equals('Jane'));
      expect(copied.signerRole, equals('Witness'));
      expect(copied.status, equals(SignatureStatus.synced));
      expect(copied.id, equals(original.id));
      expect(copied.surveyId, equals(original.surveyId));
    });

    test('equality works correctly', () {
      final sig1 = createTestSignature(signerName: 'John');
      final sig2 = createTestSignature(signerName: 'John');
      final sig3 = createTestSignature(signerName: 'Jane');

      expect(sig1, equals(sig2));
      expect(sig1, isNot(equals(sig3)));
    });
  });

  group('SignerRoles', () {
    test('all contains expected roles', () {
      expect(SignerRoles.all, contains(SignerRoles.surveyor));
      expect(SignerRoles.all, contains(SignerRoles.client));
      expect(SignerRoles.all, contains(SignerRoles.witness));
      expect(SignerRoles.all, contains(SignerRoles.inspector));
      expect(SignerRoles.all, contains(SignerRoles.propertyOwner));
      expect(SignerRoles.all, contains(SignerRoles.tenant));
      expect(SignerRoles.all, contains(SignerRoles.contractor));
    });

    test('all has correct number of roles', () {
      expect(SignerRoles.all.length, equals(7));
    });
  });

  group('SignatureStatus', () {
    test('has all expected values', () {
      expect(SignatureStatus.values, contains(SignatureStatus.local));
      expect(SignatureStatus.values, contains(SignatureStatus.uploading));
      expect(SignatureStatus.values, contains(SignatureStatus.synced));
      expect(SignatureStatus.values, contains(SignatureStatus.failed));
    });
  });
}
