import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/surveys/presentation/pages/create_survey_page.dart';
import 'package:survey_scriber/features/surveys/presentation/providers/create_survey_provider.dart';
import 'package:survey_scriber/shared/domain/entities/survey.dart';

void main() {
  Future<SurveyType?> openWith(WidgetTester t, SurveyType type) async {
    late WidgetRef captured;
    await t.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: Consumer(builder: (c, ref, _) {
          captured = ref;
          return CreateSurveyPage(initialType: type);
        }),
      ),
    ));
    await t.pumpAndSettle();
    return captured.read(createSurveyProvider).surveyType;
  }

  testWidgets('big plus on Home Surveys opens the inspection form', (t) async {
    expect(await openWith(t, SurveyType.inspection), SurveyType.inspection);
    expect(find.textContaining('inspection survey'), findsOneWidget);
  });

  testWidgets('big plus on Valuations opens the valuation form', (t) async {
    expect(await openWith(t, SurveyType.valuation), SurveyType.valuation);
    expect(find.textContaining('valuation survey'), findsOneWidget);
  });

  _flash();
}

void _flash() {
  testWidgets('the retired type-selection cards never appear, even on the first frame', (t) async {
    await t.pumpWidget(const ProviderScope(
      child: MaterialApp(home: CreateSurveyPage(initialType: SurveyType.valuation)),
    ));
    expect(find.text('Select Survey Type'), findsNothing); // first frame
    await t.pump(const Duration(milliseconds: 50));
    expect(find.text('Select Survey Type'), findsNothing);
    await t.pumpAndSettle();
    expect(find.text('Select Survey Type'), findsNothing);
    expect(find.textContaining('valuation survey'), findsOneWidget);
  });
}
