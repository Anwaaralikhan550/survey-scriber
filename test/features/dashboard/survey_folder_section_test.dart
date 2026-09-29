import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:survey_scriber/features/dashboard/presentation/widgets/survey_folder_section.dart';

void main() {
  Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

  group('SurveyFolderSection (App-Edit brief: replaces Recent Surveys)', () {
    testWidgets('renders the folder title and both category cards with counts',
        (tester) async {
      await tester.pumpWidget(host(
        const SurveyFolderSection(homeSurveysCount: 3, valuationsCount: 1),
      ));

      expect(find.text('Survey Folder'), findsOneWidget);
      expect(find.text('Home Surveys'), findsOneWidget);
      expect(find.text('Valuations'), findsOneWidget);
      expect(find.text('3 surveys'), findsOneWidget);
      expect(find.text('1 survey'), findsOneWidget); // singular
    });

    testWidgets('tapping a folder card fires onOpenFolder with the segment',
        (tester) async {
      final opened = <HomeSegment>[];
      await tester.pumpWidget(host(
        SurveyFolderSection(
          homeSurveysCount: 2,
          valuationsCount: 4,
          onOpenFolder: opened.add,
        ),
      ));

      await tester.tap(find.text('Home Surveys'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Valuations'));
      await tester.pumpAndSettle();

      expect(opened, [HomeSegment.homeSurveys, HomeSegment.valuations]);
    });
  });
}
