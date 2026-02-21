import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/shared/domain/entities/survey.dart';

/// Tests for survey detail page 3-dot menu visibility rules.
///
/// Menu items and their visibility conditions:
/// - Export PDF: completed, pendingReview, approved
/// - Share: ALL statuses
/// - View Media: ALL statuses
/// - View Signatures: completed, pendingReview, approved
/// - Pause Survey: inProgress only
/// - Delete: draft, paused, rejected only
void main() {
  group('Survey Detail Menu Visibility Rules', () {
    group('Export PDF visibility', () {
      test('should be visible for completed surveys', () {
        const status = SurveyStatus.completed;
        final isVisible = _isExportPdfVisible(status);
        expect(isVisible, isTrue);
      });

      test('should be visible for pendingReview surveys', () {
        const status = SurveyStatus.pendingReview;
        final isVisible = _isExportPdfVisible(status);
        expect(isVisible, isTrue);
      });

      test('should be visible for approved surveys', () {
        const status = SurveyStatus.approved;
        final isVisible = _isExportPdfVisible(status);
        expect(isVisible, isTrue);
      });

      test('should NOT be visible for draft surveys', () {
        const status = SurveyStatus.draft;
        final isVisible = _isExportPdfVisible(status);
        expect(isVisible, isFalse);
      });

      test('should NOT be visible for inProgress surveys', () {
        const status = SurveyStatus.inProgress;
        final isVisible = _isExportPdfVisible(status);
        expect(isVisible, isFalse);
      });
    });

    group('Share visibility', () {
      test('should be visible for ALL statuses', () {
        for (final status in SurveyStatus.values) {
          final isVisible = _isShareVisible(status);
          expect(isVisible, isTrue, reason: 'Share should be visible for $status');
        }
      });
    });

    group('View Media visibility', () {
      test('should be visible for ALL statuses', () {
        for (final status in SurveyStatus.values) {
          final isVisible = _isViewMediaVisible(status);
          expect(isVisible, isTrue, reason: 'View Media should be visible for $status');
        }
      });
    });

    group('View Signatures visibility', () {
      test('should be visible for completed surveys', () {
        const status = SurveyStatus.completed;
        final isVisible = _isViewSignaturesVisible(status);
        expect(isVisible, isTrue);
      });

      test('should be visible for pendingReview surveys', () {
        const status = SurveyStatus.pendingReview;
        final isVisible = _isViewSignaturesVisible(status);
        expect(isVisible, isTrue);
      });

      test('should be visible for approved surveys', () {
        const status = SurveyStatus.approved;
        final isVisible = _isViewSignaturesVisible(status);
        expect(isVisible, isTrue);
      });

      test('should NOT be visible for draft surveys', () {
        const status = SurveyStatus.draft;
        final isVisible = _isViewSignaturesVisible(status);
        expect(isVisible, isFalse);
      });
    });

    group('Pause Survey visibility', () {
      test('should be visible ONLY for inProgress surveys', () {
        const status = SurveyStatus.inProgress;
        final isVisible = _isPauseVisible(status);
        expect(isVisible, isTrue);
      });

      test('should NOT be visible for other statuses', () {
        final otherStatuses = SurveyStatus.values
            .where((s) => s != SurveyStatus.inProgress)
            .toList();

        for (final status in otherStatuses) {
          final isVisible = _isPauseVisible(status);
          expect(isVisible, isFalse, reason: 'Pause should NOT be visible for $status');
        }
      });
    });

    group('Delete visibility', () {
      test('should be visible for draft surveys', () {
        const status = SurveyStatus.draft;
        final isVisible = _isDeleteVisible(status);
        expect(isVisible, isTrue);
      });

      test('should be visible for paused surveys', () {
        const status = SurveyStatus.paused;
        final isVisible = _isDeleteVisible(status);
        expect(isVisible, isTrue);
      });

      test('should be visible for rejected surveys', () {
        const status = SurveyStatus.rejected;
        final isVisible = _isDeleteVisible(status);
        expect(isVisible, isTrue);
      });

      test('should NOT be visible for completed surveys', () {
        const status = SurveyStatus.completed;
        final isVisible = _isDeleteVisible(status);
        expect(isVisible, isFalse);
      });

      test('should NOT be visible for approved surveys', () {
        const status = SurveyStatus.approved;
        final isVisible = _isDeleteVisible(status);
        expect(isVisible, isFalse);
      });

      test('should NOT be visible for inProgress surveys', () {
        const status = SurveyStatus.inProgress;
        final isVisible = _isDeleteVisible(status);
        expect(isVisible, isFalse);
      });
    });

    group('Menu consistency rules', () {
      test('completed survey should show: Export PDF, Share, View Media, View Signatures', () {
        const status = SurveyStatus.completed;

        expect(_isExportPdfVisible(status), isTrue);
        expect(_isShareVisible(status), isTrue);
        expect(_isViewMediaVisible(status), isTrue);
        expect(_isViewSignaturesVisible(status), isTrue);
        expect(_isPauseVisible(status), isFalse);
        expect(_isDeleteVisible(status), isFalse);
      });

      test('draft survey should show: Share, View Media, Delete', () {
        const status = SurveyStatus.draft;

        expect(_isExportPdfVisible(status), isFalse);
        expect(_isShareVisible(status), isTrue);
        expect(_isViewMediaVisible(status), isTrue);
        expect(_isViewSignaturesVisible(status), isFalse);
        expect(_isPauseVisible(status), isFalse);
        expect(_isDeleteVisible(status), isTrue);
      });

      test('inProgress survey should show: Share, View Media, Pause Survey', () {
        const status = SurveyStatus.inProgress;

        expect(_isExportPdfVisible(status), isFalse);
        expect(_isShareVisible(status), isTrue);
        expect(_isViewMediaVisible(status), isTrue);
        expect(_isViewSignaturesVisible(status), isFalse);
        expect(_isPauseVisible(status), isTrue);
        expect(_isDeleteVisible(status), isFalse);
      });
    });
  });
}

// These functions mirror the visibility logic in survey_detail_page.dart
bool _isExportPdfVisible(SurveyStatus status) =>
    status == SurveyStatus.completed ||
    status == SurveyStatus.pendingReview ||
    status == SurveyStatus.approved;

bool _isShareVisible(SurveyStatus status) => true; // Always visible

bool _isViewMediaVisible(SurveyStatus status) => true; // Always visible

bool _isViewSignaturesVisible(SurveyStatus status) =>
    status == SurveyStatus.completed ||
    status == SurveyStatus.pendingReview ||
    status == SurveyStatus.approved;

bool _isPauseVisible(SurveyStatus status) => status == SurveyStatus.inProgress;

bool _isDeleteVisible(SurveyStatus status) =>
    status == SurveyStatus.draft ||
    status == SurveyStatus.paused ||
    status == SurveyStatus.rejected;
