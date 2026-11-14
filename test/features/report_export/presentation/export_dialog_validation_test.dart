// Client file (3), 10 Nov 2026: "Export error - Retry not working". A
// validation error cannot be fixed by exporting again, so the dialog offers
// Close and says which screen to open; other errors still offer Retry.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_valuation/domain/valuation_answer_validator.dart';
import 'package:survey_scriber/features/report_export/domain/models/export_config.dart';
import 'package:survey_scriber/features/report_export/domain/models/report_document.dart';
import 'package:survey_scriber/features/report_export/presentation/providers/export_providers.dart';
import 'package:survey_scriber/features/report_export/presentation/widgets/export_dialog.dart';

class _FixedExport extends ExportNotifier {
  _FixedExport(super.ref, this.result);

  final ExportState result;

  @override
  Future<String?> exportValuation(
    String surveyId, {
    ExportConfig config = const ExportConfig(),
  }) async {
    state = result;
    return null;
  }

  @override
  void reset() {}
}

Future<void> _pump(WidgetTester tester, ExportState result) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [exportProvider.overrideWith((ref) => _FixedExport(ref, result))],
      child: const MaterialApp(
        home: Scaffold(
          body: ExportDialog(
            surveyId: 's1',
            surveyTitle: 'Valuation - VL1',
            reportType: ReportType.valuation,
            config: ExportConfig(),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('validation error: Close only, no Retry', (tester) async {
    await _pump(
      tester,
      const ExportState(
        errorMessage: 'Please correct these answers first:\nRoad: Select one road surface.',
        canRetry: false,
      ),
    );
    expect(find.text('Retry'), findsNothing);
    expect(find.text('Close'), findsOneWidget);
    expect(find.textContaining('Road: Select one road surface.'), findsOneWidget);
  });

  testWidgets('other errors still offer Retry', (tester) async {
    await _pump(tester, const ExportState(errorMessage: 'Export timed out.'));
    expect(find.text('Retry'), findsOneWidget);
  });

  test('validation errors name the screen', () {
    final errors = ValuationAnswerValidator.validateSurvey(
      {
        'general_details': {'cb_c_other': 'true'},
      },
      titles: {'general_details': 'General Details'},
    );
    expect(errors.single, startsWith('General Details: Provide a description when Other construction is selected.'));
  });
}
