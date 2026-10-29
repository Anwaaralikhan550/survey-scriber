import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/models/inspection_models.dart';
import 'package:survey_scriber/features/property_inspection/presentation/widgets/inspection_fields.dart';

/// Client report (Samsung S24): the dropdown bottom sheet ran under the phone's
/// navigation bar, so the last option ("Rainy") could not be tapped.
void main() {
  const options = [
    'Dry', 'Wet', 'Overcast', 'Sunny', 'Cold', 'Windy', 'Rainy', 'Snowing',
  ];
  const navBar = 48.0;

  Future<void> openSheet(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625; // ~411 x 891 dp, like a Galaxy S24
    // 3-button navigation bar = bottom system inset.
    tester.view.viewPadding = const FakeViewPadding(bottom: navBar * 2.625);
    tester.view.padding = const FakeViewPadding(bottom: navBar * 2.625);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => InspectionFieldInput(
              field: const InspectionFieldDefinition(
                id: 'prev_weather',
                label: 'Previous weather',
                type: InspectionFieldType.dropdown,
                options: options,
              ),
              value: '',
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Previous weather'));
    await tester.pumpAndSettle();
  }

  testWidgets('every option, including the last, sits above the nav bar',
      (tester) async {
    await openSheet(tester);

    final screenHeightDp = tester.view.physicalSize.height / tester.view.devicePixelRatio;
    for (final option in options) {
      final bottom = tester.getBottomLeft(find.text(option)).dy;
      expect(bottom, lessThanOrEqualTo(screenHeightDp - navBar),
          reason: '"$option" must not be covered by the navigation bar');
    }
  });

  testWidgets('the last option can be tapped and is selected', (tester) async {
    String? picked;
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    tester.view.viewPadding = const FakeViewPadding(bottom: navBar * 2.625);
    tester.view.padding = const FakeViewPadding(bottom: navBar * 2.625);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InspectionFieldInput(
            field: const InspectionFieldDefinition(
              id: 'prev_weather',
              label: 'Previous weather',
              type: InspectionFieldType.dropdown,
              options: options,
            ),
            value: '',
            onChanged: (v) => picked = v,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Previous weather'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Snowing'));
    await tester.pumpAndSettle();
    expect(picked, 'Snowing');
  });
}
